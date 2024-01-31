# Libraries
import pandas as pd
import sqlalchemy
import numpy as np
from feature_functions import psi
import argparse

# Outpu directory
results_path = '/Users/bryanmichalek/Documents/GitHub_Personal/sports_betting_data/03-EDA/feature_analysis/results/psi'

# Initialize parser
parser = argparse.ArgumentParser()

# Arguments
parser.add_argument("-t", "--Table", action='store', help = "Table that the feature(s) is stored in.", required=True, type=str)
parser.add_argument('-g', '--Goalie_Flag', action='store_true', default=False, help="Set flag if the feature is for goalies.")
parser.add_argument('-f', '--Features', action='extend', nargs='+', help='List of features to calculate PSI for.', required=True)


# Read arguments from command line
args = parser.parse_args()

# Mysql connection
engine = sqlalchemy.create_engine('mysql+mysqlconnector://root:rootdata@localhost/nhl')

if args.Goalie_Flag:
    join_table = 'goalie_game'
else:
    join_table = 'skater_game'

# Create query for mysql
query = f"""
    SELECT a.player_id,
        a.date,
        c.season,
        a.{", a.".join(args.Features)}
    FROM {args.Table} a
    LEFT JOIN {join_table} b
        ON a.player_id = b.player_id
        AND a.date = b.date
    LEFT JOIN schedule c
        ON b.team = c.team
        AND a.date = c.date;
"""

# Read table from mysql
df = pd.read_sql(query, con=engine)

# Calculate the PSI matrix for each feature in the table
for feature in args.Features:
    # Grab only that column
    df_feature = df.loc[:, ['season', feature]]

    # Separate the seasons
    min_season = df_feature['season'].min()
    max_season = df_feature['season'].max()
    values_by_season = [df_feature.loc[df['season'] == season, feature].values for season in range(min_season, max_season + 1)]

    # Apply psi function to each combo / pair of seasons
    num_seasons = len(values_by_season)

    results_matrix = np.zeros((num_seasons, num_seasons))
    results_matrix[np.tril_indices(num_seasons, k=-1)] = np.nan # Set the lower triangular region to np.nan

    for i in range(num_seasons):
        for j in range(i + 1, num_seasons):
            psi_result = psi(values_by_season[i], values_by_season[j])
            results_matrix[i, j] = psi_result

    # Clean up results
    season_list = [str(season) for season in range(min_season, max_season + 1)]
    result_df = pd.DataFrame(results_matrix, columns=season_list, index=season_list)

    # Save to a CSV
    result_df.to_csv(f'{results_path}/{feature}_psi.csv', header=True, index=True)

