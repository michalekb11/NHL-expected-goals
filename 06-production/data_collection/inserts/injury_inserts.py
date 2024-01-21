# Insert injury status
import pandas as pd
from cleanup import match_name_to_id
from mysql_class import MySQL

def main():
    # Read in injury data
    path_to_injury = "/Volumes/LUNANI/sports_betting_csv_backup/RW_injuries.csv"
    injury = pd.read_csv(path_to_injury)

    # Remove all IR-NR rows (too many players that are in the minors)
    injury = injury.loc[injury['status'] != 'IR-NR',:]

    # Connect to mysql
    mysql = MySQL()
    mysql.connect()

    # Match names to ID
    ####### In the future could think about moving this to webscrape instead #######
    injury.loc[:,'player_id'] = injury.apply(lambda row: match_name_to_id(name=row['name'], mysql=mysql, team=[row['team']], date_in_history=row['date_recorded'], verbose=False), axis=1)

    # Drop the name column
    injury.drop(columns='name', inplace=True)

    # Set correct column order
    injury = injury[['player_id', 'date_recorded', 'time_recorded', 'team' ,'type', 'status']]

    # Insert into projected goalie table
    injury.to_sql(name = 'injury', con=mysql.engine, schema='nhl', if_exists='append', index=False)


if __name__ == "__main__":
    print("==========================================================\nStarting Projected Goalie MySQL Insert\n")
    main()
    print("End Projected Goalie MySQL Insert\n==========================================================")
