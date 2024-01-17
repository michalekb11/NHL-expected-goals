from functions import get_60min_odds
import argparse
import pandas as pd


def main():
    # Path to save file
    path_to_60min_odds = './data/daily/odds/60min_odds.csv'

    # Initialize parser
    parser = argparse.ArgumentParser()

    # Adding optional argument
    parser.add_argument("-v", "--Verbose", action='store_true', help = "Print summary of 60 min line data frame.")
    parser.add_argument('-t', '--Today', action = 'store_true', help = 'Scrape 60 min line for games occuring on current date.')
    parser.add_argument('-d', '--Date', action = 'store', help = 'Date of games for which 60 min lines should be scraped. Overridden by -t argument.')

    # Read arguments from command line
    args = parser.parse_args()

    # Get the 60 minute line odds for date of interest
    try:
        df_60min = get_60min_odds(date_of_games=args.Date, today_flag=args.Today)
    except ValueError as e:
        print(f'60 minute line scrape did not complete successfully:\n{e}\n')
        return

    # Ensure no missing values are in the data frame
    if any(df_60min.isna().sum()):
        print(f"60 minute line scrape did not complete successfully: Missing values were found in data frame\n")
        return

    # Print summary
    if args.Verbose:
        print(f"Number of games found: {len(df_60min['home'].unique())}\n")

    # Save to CSV
    try:
        old_60min = pd.read_csv(path_to_60min_odds)
        new_60min = pd.concat([old_60min, df_60min], axis=0).reset_index(drop=True)
        new_60min.to_csv(path_to_60min_odds, header=True, index=False)
        print(f'60 minute line CSV successfully updated.\nNumber of rows added: {len(df_60min)}\nNew total rows: {len(new_60min)}\n')
    except:
        print(f'Save to CSV not completed successfully\n')
        raise

if __name__ == '__main__':
    print("==========================================================\nStarting DK 60min Scrape\n")
    main()
    print("End DK 60min Scrape\n==========================================================")