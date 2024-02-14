import sqlalchemy
import pandas as pd
import numpy as np
from MySQLClass import MySQL
from GoalscorerBetOptimizer import GoalscorerBetOptimizer

np.random.seed(11)

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
# print(len(val))
# print(len(test))

# Now create df_pred and df_G
df_pred_val = val[['player_id', 'date', 'pred_G']].copy()
df_G_val = val[['player_id', 'date', 'G']].copy()

# df_odds
goalscorer_query = f"""
    SELECT player_id,
        date_game as date,
        odds
    FROM goalscorer_odds
    WHERE date_game BETWEEN '{data['date'].min()}' AND '{data['date'].max()}';
"""
df_odds = pd.read_sql(goalscorer_query, con=mysql.engine)
##########
# Test bet optimizer class
optim = GoalscorerBetOptimizer(search_EV_min_lower=0.10, search_odds_lower=-200, search_odds_upper=200)
optim.fit(df_odds=df_odds, df_preds=df_pred_val, df_G=df_G_val)

# print(optim.df.loc[optim.df['EV'] > 0,:])
# print()
# print(optim.n_pred_rows)
# print(optim.n_optimization_rows)

# profit = optim.record_profit(EV_lower=-0.6, odds_lower=-500, odds_upper=2000)
# print(profit['df'].sample(50))
# print()
# print(profit['n_bets_placed'])
# print(profit['profit'])
# print(profit['avg_profit'])

optim.optimize()