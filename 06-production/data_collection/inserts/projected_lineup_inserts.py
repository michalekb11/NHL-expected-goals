# Insert projected goalie
import pandas as pd
from cleanup import match_name_to_id
from mysql_class import MySQL
from sqlalchemy.exc import IntegrityError

def main():
    # Read in projected lineup data
    path_to_lineup = "/Volumes/LUNANI/sports_betting_csv_backup/DF_lineups.csv"
    lineup = pd.read_csv(path_to_lineup)
    # Haven't figured out how to deal with names like this, will fix later...
    lineup.loc[lineup['name'] == 'emil martinsen lilleberg', 'name'] = 'emil lilleberg'

    # Connect to mysql
    mysql = MySQL()
    mysql.connect()

    # Match names to ID
    ####### In the future could think about moving this to webscrape instead #######
    lineup.loc[:,'player_id'] = lineup.apply(lambda row: match_name_to_id(name=row['name'], mysql=mysql, team=[row['team']], date_in_history=row['date_recorded'], verbose=False), axis=1)

    # lineup = lineup.astype({'pp1_position':'Int64', 'pp2_position':'Int64', 'pk1_position':'Int64', 'pk2_position':'Int64'})
    # print(lineup.info())

    # Drop the name column
    lineup.drop(columns='name', inplace=True)

    # Set correct column order
    lineup = lineup[['player_id', 'date_recorded', 'time_recorded', 'team' ,'position', 'depth_chart_rank', 'injury_status', 'pp1_position', 'pp2_position', 'pk1_position', 'pk2_position']]

    # Insert into projected lineup table
    # Pretty inefficient way of doing this, but it is the easiest to code under time constraints
    for i in range(len(lineup)):
        try:
            lineup.iloc[i:i+1].to_sql(name = 'projected_lineup', con=mysql.engine, schema='nhl', if_exists='append', index=False)
        except IntegrityError:
            print(f"A duplicate key was skipped:\n{lineup.iloc[i:i+1][['player_id', 'date_recorded', 'time_recorded', 'depth_chart_rank']]}\n")
            #pass #or any other action


if __name__ == "__main__":
    print("==========================================================\nStarting Projected Lineup MySQL Insert\n")
    main()
    print("End Projected Lineup MySQL Insert\n==========================================================")
