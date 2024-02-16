import sqlalchemy
import pandas as pd
import numpy as np
import json
import time
from MySQLClass import MySQL
from GoalscorerBetOptimizer import GoalscorerBetOptimizer
from GoalscorerBetEvaluator import GoalscorerBetEvaluator

# Set output path of best betting parameters
output_dir = '/Users/bryanmichalek/Documents/GitHub_Personal/sports_betting_data/05-evaluation'

# Set seed for replication of results
np.random.seed(42)

# MySQL connection
mysql = MySQL()
mysql.connect()

# Read in file with query to run (didn't turn it into a view, so have to run entire  query)
with open('./05-evaluation/baseline/baseline_query.txt', 'r') as f:
    baseline_query = f.read()
    baseline_query = sqlalchemy.text(baseline_query)
##########
# Gather data 
# Baseline predictions
data = pd.read_sql(baseline_query, con=mysql.engine)
data = data.loc[data['season'] == 2024, :]

# To avoid leakage, we should split stratified by player id (all rows with same player id appear in same split)
# We do not have enough data to use an embargo period of 30 games... we have to split by player_id in this case
unique_ids = data['player_id'].unique()
val_ids = np.random.choice(unique_ids, size=int(len(unique_ids) * 0.5), replace=False)
test_ids = np.array([id for id in unique_ids if id not in val_ids])
val = data.loc[data['player_id'].isin(val_ids),:]
test = data.loc[data['player_id'].isin(test_ids),:]

# Now create df_pred and df_G
df_pred_val = val[['player_id', 'date', 'pred_G']].copy()
df_G_val = val[['player_id', 'date', 'G']].copy()

df_pred_test = test[['player_id', 'date', 'pred_G']].copy()
df_G_test = test[['player_id', 'date', 'G']].copy()

# df_odds
goalscorer_query = f"""
    SELECT player_id,
        date_game as date,
        odds
    FROM goalscorer_odds
    WHERE date_game BETWEEN '{data['date'].min()}' AND '{data['date'].max()}';
"""
df_odds = pd.read_sql(goalscorer_query, con=mysql.engine)

print("All data gathered. Beginning betting parameter optimization...")
##########
# Test bet optimizer class
optim = GoalscorerBetOptimizer(
    EV_min_lower=-1.0, 
    EV_max_lower=-0.4, 
    odds_min_lower=-200, 
    odds_max_lower=450, 
    odds_min_upper=500, 
    odds_max_upper=1500,
    step_size=7)

# Send in our data
optim.fit(df_odds=df_odds, df_preds=df_pred_val, df_G=df_G_val)

# Optimize to find best betting parameters
start_time = time.time()
param_grid = optim.optimize()
end_time = time.time()
print(f"Time to optimize: {(end_time - start_time) / 60} minutes.")

# Find best row
best_index = param_grid['profit'].idxmax()
best_params = param_grid.iloc[best_index,:].to_dict()

# Save best params to file
with open(f'{output_dir}/baseline_betting_params.json', 'w') as f:
    json.dump(best_params, f)

# OPTIONAL: Save all combinations that were tried to a file
param_grid.to_csv(f'{output_dir}/baseline_betting_combinations.csv', header=True, index=False)
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
performance['bets_df'].to_csv(f'{output_dir}/baseline_bet_list.csv', header=True, index=False)

# Save performance using best parameters
with open(f'{output_dir}/baseline_performance.json', 'w') as f:
    json.dump(performance['summary'], f)
##########