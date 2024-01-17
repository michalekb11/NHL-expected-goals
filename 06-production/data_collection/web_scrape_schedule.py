# Functions
from webscrape import retrieve_schedule
import pandas as pd
import argparse


def main():
    # Initialize parser
    parser = argparse.ArgumentParser()

    # Adding optional argument
    parser.add_argument('season', metavar='S', action = 'store', help = 'Season that user wants to scrape from.', type=int)
    parser.add_argument("-v", "--Verbose", action='store_true', help = "Print summary of schedule scrape and MySQL insertion.")
    parser.add_argument('-N', '--last_N_days', action = 'store', help = 'Scrape only the past N days of schedule.', type=int)
    parser.add_argument('-F', '--Future', action = 'store_true', help = 'Scrape all of the remaining games in season (after today), even if not played yet.')

    # Read arguments from command line
    args = parser.parse_args()

    # Scrape schedule using user arguments
    try:
        df_schedule = retrieve_schedule(season=args.season, last_N_days=args.last_N_days, all_future=args.Future)
    except ValueError as e:
        print(f'Schedule scrape did not complete successfully:\n{e}\n')
        return
    
    # Print summary
    if args.Verbose:
        print(f"Number of previous (completed) games scraped: {len(df_schedule.loc[df_schedule['date'] < pd.Timestamp.today().normalize(), 'game_id'].unique())}")
        print(f"Number of games today scraped: {len(df_schedule.loc[df_schedule['date'] == pd.Timestamp.today().normalize(), 'game_id'].unique())}")
        print(f"Number of games after today scraped: {len(df_schedule.loc[df_schedule['date'] > pd.Timestamp.today().normalize(), 'game_id'].unique())}\n")

    # Need to insert this information into MySQL database
    

if __name__ == '__main__':
    print("==========================================================\nStarting schedule scrape\n")
    main()
    print("End schedule scrape\n==========================================================")