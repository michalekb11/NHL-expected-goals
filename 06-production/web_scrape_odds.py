# Functions
from functions import retrieve_sportsbook_info, get_ml_odds, get_pl_odds, get_total_odds
import pandas as pd

# Paths
path_to_ml_odds = './data/daily/odds/ml_odds.csv'
path_to_pl_odds = './data/daily/odds/pl_odds.csv'
path_to_total_odds = './data/daily/odds/total_odds.csv'
dk_hockey_main_url = 'https://sportsbook.draftkings.com/leagues/hockey/nhl?category=game-lines&subcategory=game'

# Record 'today' and 'tomorrow' tables from DK since these are the tables that could possibly contain information from games occuring today (time zone issues).
try:
    sportsbook_recording = retrieve_sportsbook_info(dk_hockey_main_url)
    assert len(sportsbook_recording['game_dates']) > 0, f"No games were recorded."
    print('Sportsbook recording completed successfully.\n')
except:
    print('Sportsbook recording did not complete successfully.\n')
    raise

# Update the ML data frame
try:
    df_ml_odds = get_ml_odds(sportsbook_recording, today_only=True)
    current_ml_odds = pd.read_csv(path_to_ml_odds)
    assert len(pd.merge(df_ml_odds, current_ml_odds, how='inner', on = ['team', 'date_game'])) == 0, 'Duplicate entries in new and old CSV files.'
    updated_ml_odds = pd.concat([current_ml_odds, df_ml_odds], axis=0).reset_index(drop=True)
    updated_ml_odds.to_csv(path_to_ml_odds, header=True, index=False)
    print('Moneyline update completed successfully.\n')
except Exception as e:
    print(f"Moneyline update did not complete successfully:\n {e}")

# Update the PL data frame
try:
    df_pl_odds = get_pl_odds(sportsbook_recording, today_only=True)
    current_pl_odds = pd.read_csv(path_to_pl_odds)
    assert len(pd.merge(df_pl_odds, current_pl_odds, how='inner', on = ['team', 'date_game'])) == 0, 'Duplicate entries in new and old CSV files.'
    updated_pl_odds = pd.concat([current_pl_odds, df_pl_odds], axis=0).reset_index(drop=True)
    updated_pl_odds.to_csv(path_to_pl_odds, header=True, index=False)
    print('Puckline update completed successfully.\n')
except Exception as e:
    print(f"Puckline update did not complete successfully:\n {e}")

# Update the total data frame
try:
    df_total_odds = get_total_odds(sportsbook_recording, today_only=True)
    current_total_odds = pd.read_csv(path_to_total_odds)
    assert len(pd.merge(df_total_odds, current_total_odds, how='inner', on = ['home', 'away', 'date_game', 'bet_type'])) == 0, 'Duplicate entries in new and old CSV files.'
    updated_total_odds = pd.concat([current_total_odds, df_total_odds], axis=0).reset_index(drop=True)
    updated_total_odds.to_csv(path_to_total_odds, header=True, index=False)
    print('Total update completed successfully.\n')
except Exception as e:
    print(f"Total update did not complete successfully:\n {e}")