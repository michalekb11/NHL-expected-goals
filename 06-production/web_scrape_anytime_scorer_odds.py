from functions import get_anytime_scorer_odds
import argparse
import pandas as pd

def main():
    # Path to save file
    path_to_anytime_scorer_odds = './data/daily/odds/anytime_goalscorer.csv'

    # Initialize parser
    parser = argparse.ArgumentParser()

    # Adding optional argument
    parser.add_argument("-v", "--Verbose", action='store_true', help = "Print summary of anytime scorer data frame.")
    parser.add_argument('-t', '--Today', action = 'store_true', help = 'Scrape anytime scorers for games occuring on current date.')
    parser.add_argument('-d', '--Date', action = 'store', help = 'Date of games for which anytime scorer odds should be scraped. Overridden by -t argument.')

    # Read arguments from command line
    args = parser.parse_args()

    # Get the 60 minute line odds for date of interest
    try:
        df_anytime_scorer = get_anytime_scorer_odds(date_of_games=args.Date, today_flag=args.Today)
    except ValueError as e:
        print(f'Anytime scorer scrape did not complete successfully:\n{e}\n')
        return
    
     # Ensure no missing values are in the data frame
    #if any(df_anytime_scorer.isna().sum()):
    #    print(f"Anytime scorer scrape did not complete successfully: Missing values were found in data frame\n")
    #    return
    
    # Print summary
    if args.Verbose:
        print(f"Number of teams found on DK: {len(set(df_anytime_scorer['home']))}\n")
        print(f"Number of players found on DK: {len(df_anytime_scorer)}\n")

    # Save to CSV
    try:
        old_anytime = pd.read_csv(path_to_anytime_scorer_odds)
        new_anytime = pd.concat([old_anytime, df_anytime_scorer], axis=0).reset_index(drop=True)
        new_anytime.to_csv(path_to_anytime_scorer_odds, header=True, index=False)
        print(f'Anytime goal scorer CSV successfully updated.\nNumber of rows added: {len(df_anytime_scorer)}\nNew total rows: {len(new_anytime)}\n')
    except:
        print(f'Save to CSV not completed successfully\n')
        raise

if __name__ == '__main__':
    print("==========================================================\nStarting DK Anytime Goalscorer Scrape\n")
    main()
    print("End DK Anytime Goalscorer Scrape\n==========================================================")