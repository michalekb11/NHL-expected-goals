# Insert projected goalie
import pandas as pd
from cleanup import match_name_to_id
from mysql_class import MySQL

def main():
    # Read in projected goalie data
    path_to_goalie = "/Volumes/LUNANI/sports_betting_csv_backup/DF_projected_goalies.csv"
    goalie = pd.read_csv(path_to_goalie)

    # Connect to mysql
    mysql = MySQL()
    mysql.connect()

    # Match names to ID
    ####### In the future could think about moving this to webscrape instead #######
    goalie.loc[:,'player_id'] = goalie.apply(lambda row: match_name_to_id(name=row['name'], mysql=mysql, team=[row['team']], date_in_history=row['date_game'], verbose=False), axis=1)

    # Drop the name column
    goalie.drop(columns='name', inplace=True)

    # Set correct column order
    goalie = goalie[['player_id', 'date_recorded', 'time_recorded', 'date_game' ,'team', 'status']]

    # Insert into projected goalie table
    goalie.to_sql(name = 'projected_goalie', con=mysql.engine, schema='nhl', if_exists='append', index=False)


if __name__ == "__main__":
    print("==========================================================\nStarting Projected Goalie MySQL Insert\n")
    main()
    print("End Projected Goalie MySQL Insert\n==========================================================")
