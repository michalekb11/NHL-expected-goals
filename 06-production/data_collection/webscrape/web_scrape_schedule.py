# Functions
from webscrape import retrieve_schedule
import pandas as pd
import argparse
import sqlalchemy


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

    # Separate game_id table from schedule table
    df_game_id = df_schedule[['team', 'date', 'game_id']]
    df_schedule.drop(columns='game_id', inplace=True)

    # Need to insert this information into MySQL database
    # Start by creating MySQL engine
    engine = sqlalchemy.create_engine('mysql+mysqlconnector://root:rootdata@localhost/nhl')

    # Now create two insert statements
    try:
        # For the game_id table, if we encounter a duplicate key, just ignore the row
        df_game_id.to_sql(name='temp', con=engine, schema='nhl', if_exists='replace', index=False)
        schedule_upsert_query = sqlalchemy.text("""
            INSERT IGNORE INTO game_id (team, date, game_id)
            SELECT team, date, game_id FROM temp;
        """)

        # Perform upsert
        with engine.begin() as conn: 
            conn.execute(schedule_upsert_query)
        
        if args.Verbose:
            print(f'The insert into the game_id table completed successfully.\n')

    except Exception as e:
        print(f"There was an error trying to insert into the game_id table:\n{e}\n")
        return

    try:
        # For the schedule table, if we encounter a duplicate key, replace the row with the new one
        df_schedule.to_sql(name='temp', con=engine, schema='nhl', if_exists='replace', index=False)
        schedule_upsert_query = sqlalchemy.text("""
            INSERT INTO schedule (team, date, season, location, G, OT_status, win_flag)
            SELECT * FROM temp
            ON DUPLICATE KEY UPDATE
                season = VALUES(season),
                location = VALUES(location),
                G = VALUES(G),
                OT_status = VALUES(OT_status),
                win_flag = VALUES(win_flag);
        """)

        # Perform upsert
        with engine.begin() as conn: 
            conn.execute(schedule_upsert_query)

        if args.Verbose:
            print(f'The upsert into the schedule table completed successfully.\n')

    except Exception as e:
        print(f"There was an error trying to insert into the schedule table:\n{e}\n")
        return

    # Delete the temp table
    with engine.begin() as conn:
        conn.execute(sqlalchemy.text("DROP TABLE IF EXISTS temp;"))

if __name__ == '__main__':
    print("==========================================================\nStarting schedule scrape\n")
    main()
    print("End schedule scrape\n==========================================================")