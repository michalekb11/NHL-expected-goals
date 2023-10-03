from functions import get_DF_goalies
import pandas as pd
import argparse

# Initialize parser
parser = argparse.ArgumentParser()

# Adding optional argument
parser.add_argument("-v", "--Verbose", action='store_true', help = "Print summary of goalie data frame.")
parser.add_argument('-t', '--Today', action = 'store_true', help = 'Scrape goalie status for games occuring on current date.')
parser.add_argument('-d', '--Date', action = 'store', help = 'Date of games for which goalies should be scraped. Overridden by -t argument.')

# Read arguments from command line
args = parser.parse_args()

# CSV path
path_to_proj_goalies= './data/daily/DF_projected_goalies.csv'

print("==========================================================\nStarting DF Goalie Scrape\n")

# Scrape DF goalies on particular date
df_goalies = get_DF_goalies(date_of_games=args.Date, today_flag=args.Today)

assert not any(df_goalies.isna().sum()), f"Missing values were found in data frame\n"

# Print summary
if args.Verbose:
    print(f"Goalies found for the following {len(df_goalies['team'].unique())} teams:\n{df_goalies['team'].unique()}\n")

# Save to CSV
try:
    old_df_goalies = pd.read_csv(path_to_proj_goalies)
    new_df_goalies = pd.concat([old_df_goalies, df_goalies], axis=0).reset_index(drop=True)
    new_df_goalies.to_csv(path_to_proj_goalies, header=True, index=False)
    print(f'DF goalie CSV successfully updated.\nNumber of rows added: {len(df_goalies)}\nNew total rows: {len(new_df_goalies)}\n')
except:
    print(f'Save to CSV not completed successfully\n')
    raise

print("End DF Goalie Scrape\n==========================================================")