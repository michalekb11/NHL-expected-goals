import pandas as pd
import numpy as np
from GoalscorerBetOptimizer import GoalscorerBetOptimizer
from GoalscorerBetEvaluator import GoalscorerBetEvaluator
from MySQLClass import MySQL
import time
import json

# Set output path of best betting parameters
model_name = 'NHLXGBoost'
predictions_dir = './04-modeling/predictions'
output_dir = '/Users/bryanmichalek/Documents/GitHub_Personal/sports_betting_data/05-evaluation'
embargo = 10

# Read in predictions from NHLnet
df_preds = pd.read_csv(f'{predictions_dir}/{model_name}_predictions.csv')

# Create validation set with first 1/2 of 2024 season.To define first 1/2, we can take the number of games each player has played in 2024, subtract 10 (for the embargo period), and call this N. Then we take that players first N games of the season. For the test set, we take the players most recent N games. This guarantees that we split a players games equally between validation and testing, accounting for the 10 game embargo period. If a player has not played 10 games so far this season, they should not be used at all in the validation or testing (in reality this shouldn't matter? if they haven't played 10 games... we probably aren't betting them to score. We care more about players that consistenly participate in games)
df_preds = pd.merge(df_preds,
                    df_preds.groupby('player_id')['date'].nunique().reset_index().rename(columns={'date':'n_games_played'}),
                    how='inner',
                    on='player_id')

# Game num column
df_preds['n'] = df_preds.sort_values('date').groupby('player_id').cumcount() + 1

# Thresholds
df_preds['first_half_thresh'] = ((df_preds['n_games_played'] - embargo + 0.01) / 2).round().astype('int') # 0.01 to help with rounding purposes (0.5 was rounding down to 0)
df_preds['second_half_thresh'] = df_preds['first_half_thresh'] + embargo + 1

# Filter out those ineligible to be in validation or test set
df_preds = df_preds.loc[df_preds['n_games_played'] >= embargo + 2, :]

# Create unique groups, some will go to val set, some to test set (randomly)
#df_preds['group'] = np.where(df_preds['n'] <= df_preds['first_half_thresh'], df_preds['player_id'] + '-early',
                    #np.where(df_preds['n'] >= df_preds['second_half_thresh'], df_preds['player_id'] + '-late', None))

# Gather unique groups of data
unique_players = df_preds['player_id'].unique()

# Get 0's or 1's that decide whether the players first half of the season should be in validation or test set. 0 will be validation
np.random.seed(12)
val_test_splitter = np.random.choice(a=[0,1], size=round(len(unique_players) / 2), replace=True)
early_val_late_test = unique_players[np.where(val_test_splitter == 0)]
early_test_late_val = unique_players[np.where(val_test_splitter == 1)]

# Split the data
val = df_preds.loc[((df_preds['player_id'].isin(early_val_late_test)) & (df_preds['n'] <= df_preds['first_half_thresh'])) | 
                   ((df_preds['player_id'].isin(early_test_late_val)) & (df_preds['n'] >= df_preds['second_half_thresh']))]

test = df_preds.loc[((df_preds['player_id'].isin(early_val_late_test)) & (df_preds['n'] >= df_preds['second_half_thresh'])) | 
                   ((df_preds['player_id'].isin(early_test_late_val)) & (df_preds['n'] <= df_preds['first_half_thresh']))]

# Now create df_pred and df_G
df_pred_val = val[['player_id', 'date', 'prob']].copy()
df_G_val = val[['player_id', 'date', 'G_flag']].copy()

df_pred_test = test[['player_id', 'date', 'prob']].copy()
df_G_test = test[['player_id', 'date', 'G_flag']].copy()

# df_odds
mysql = MySQL()
mysql.connect()
goalscorer_query = f"""
    SELECT player_id,
        date_game as date,
        odds
    FROM goalscorer_odds
    WHERE date_game BETWEEN '{df_preds['date'].min()}' AND '{df_preds['date'].max()}';
"""
df_odds = pd.read_sql(goalscorer_query, con=mysql.engine)
df_odds['date'] = df_odds['date'].astype('str')
print("All data gathered. Beginning betting parameter optimization...")

# Start optimization
optim = GoalscorerBetOptimizer(
    EV_min_lower=0.0, 
    EV_max_lower=0.5, 
    odds_min_lower=-200, 
    odds_max_lower=450, 
    # odds_min_upper=500, 
    # odds_max_upper=1500,
    step_size=7)

# Send in our data
optim.fit(df_odds=df_odds, df_preds=df_pred_val, df_G=df_G_val)

# Optimize to find best betting parameters
start_time = time.time()
param_grid = optim.optimize()
end_time = time.time()
print(f"Time to optimize: {(end_time - start_time) / 60} minutes.")

# Find best row
# For now, I am defining this as the row within 10% of the highest total profit that has the widest betting bin size
# The goal here is to prevent overfitting of the betting parameters
highest_profit = param_grid['profit'].max()
filtered_param_grid = param_grid.loc[param_grid['profit'] >= highest_profit - 0.10 * abs(highest_profit), :]

filtered_param_grid.loc[:, ['odds_bin_size']] = filtered_param_grid['odds_upper'] - filtered_param_grid['odds_lower']

best_index = filtered_param_grid['odds_bin_size'].idxmax() # THIS ASSUMMES THE INDICES ARE NOT ALTERED WHEN FILTERING
best_params = param_grid.iloc[best_index,:].to_dict()

# Save best params to file
with open(f'{output_dir}/{model_name}/validation/{model_name}_betting_params.json', 'w') as f:
    json.dump(best_params, f)

# OPTIONAL: Save all combinations that were tried to a file
param_grid.to_csv(f'{output_dir}/{model_name}/validation/{model_name}_betting_combinations.csv', header=True, index=False)
##########
# Test the best betting parameters on hold out test set
# Set up evaluator class
evaluator = GoalscorerBetEvaluator(
    EV_lower=best_params['EV_lower'], 
    odds_lower=best_params['odds_lower'], 
    odds_upper=best_params['odds_upper']
)

# Pass in our test data
evaluator.fit(df_odds=df_odds, df_preds=df_pred_test, df_G=df_G_test)

# Evaluate performance on test data
performance = evaluator.record_profit()

# OPTIONAL: save list of bets using best parameters
performance['bets_df'].to_csv(f'{output_dir}/{model_name}/test/{model_name}_bet_list.csv', header=True, index=False)

# Save performance using best parameters
with open(f'{output_dir}/{model_name}/test/{model_name}_performance.json', 'w') as f:
    json.dump(performance['summary'], f)