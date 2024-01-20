# Insert goalscorer
import pandas as pd
from cleanup import match_name_to_id
from mysql_class import MySQL

def main():
    # Read in goalscorer odds data
    path_to_goalscorer = "/Volumes/LUNANI/sports_betting_csv_backup/odds/anytime_goalscorer.csv"
    goalscorer = pd.read_csv(path_to_goalscorer)

    # Remove any name that is "other" since we won't be inserting that
    goalscorer = goalscorer.loc[goalscorer['name'] != 'others', :]
    # Haven't figured out how to really deal with mismatching last names yet... will come back to this later.
    goalscorer.loc[goalscorer['name'] == 'nikita okhotiuk', 'name'] = 'nikita okhotyuk'

    # Connect to mysql
    mysql = MySQL()
    mysql.connect()

    # Match names to ID
    ####### In the future could think about moving this to webscrape instead #######
    goalscorer.loc[:,'player_id'] = goalscorer.apply(lambda row: match_name_to_id(name=row['name'], mysql=mysql, team=[row['home'], row['away']], date_in_history=row['date_game'], verbose=False), axis=1)

    # Drop the name column
    goalscorer.drop(columns='name', inplace=True)

    # Set correct column order
    goalscorer = goalscorer[['player_id', 'date_recorded', 'time_recorded', 'date_game' ,'home', 'away', 'odds']]

    # Insert into goalscorer table
    goalscorer.to_sql(name = 'goalscorer_odds', con=mysql.engine, schema='nhl', if_exists='append', index=False)


if __name__ == "__main__":
    print("==========================================================\nStarting Goalscorer MySQL Insert\n")
    main()
    print("End Goalscorer MySQL Insert\n==========================================================")
