from functions import get_team_lineup, clean_name
import pandas as pd
import argparse
import json
import datetime as dt
import numpy as np

print("==========================================================\nStarting DF Line Combinations Scrape\n")

# Initialize parser
parser = argparse.ArgumentParser()

# Adding optional argument
parser.add_argument("-v", "--Verbose", action='store_true', help = "Print summary of line combination data frame.")
parser.add_argument('-t', '--Today', action = 'store_true', help = 'Scrape lineups of only teams that play on current date.')
 
# Read arguments from command line
args = parser.parse_args()

# CSV path
path_to_lineups = './data/daily/DF_lineups.csv'

# Read in team name to 3 letter code dictionary
with open('./data/team_name_dictionary.txt', 'r') as f:
    team_name_dict = json.load(f)

# Use the function on each team in list
# List of teams that differentiate  each URL
team_list = ['anaheim-ducks', 'arizona-coyotes', 'boston-bruins', 'buffalo-sabres', 'calgary-flames', 'carolina-hurricanes', 'chicago-blackhawks', 'colorado-avalanche', 'columbus-blue-jackets', 'dallas-stars', 'detroit-red-wings', 'edmonton-oilers', 'florida-panthers', 'los-angeles-kings', 'minnesota-wild', 'montreal-canadiens', 'nashville-predators', 'new-jersey-devils', 'new-york-islanders', 'new-york-rangers', 'ottawa-senators', 'philadelphia-flyers', 'pittsburgh-penguins', 'san-jose-sharks', 'seattle-kraken', 'st-louis-blues', 'tampa-bay-lightning', 'toronto-maple-leafs', 'vancouver-canucks', 'vegas-golden-knights', 'washington-capitals', 'winnipeg-jets']

# If you only want to scrape teams playing today...
if args.Today:
    # 3 letter code version
    team_list_3letter = [team_name_dict[team] for team in team_list]

    # Create a dictionary to map codes to team names
    code_to_name = dict(zip(team_list_3letter, team_list))

    # Use hockey reference to find the correct list of teams for today
    date_of_games = dt.datetime.now().strftime('%Y-%M-%d')
    schedule_url = 'https://www.hockey-reference.com/leagues/NHL_2024_games.html'

    # Get the schedule from hockey reference for the given season
    schedule = pd.read_html(schedule_url, attrs={'class':'stats_table', 'id':'games'})[0]
    schedule['Visitor'] = schedule['Visitor'].str.lower().replace(team_name_dict)
    schedule['Home'] = schedule['Home'].str.lower().replace(team_name_dict)

    # Filter for date == date of interest
    schedule = schedule[schedule['Date'] == date_of_games]
    teams_on_date_3letter = schedule['Visitor'].tolist()
    teams_on_date_3letter.extend(schedule['Home'].tolist())

    # Get team names for the interested codes
    team_list = [code_to_name[code] for code in teams_on_date_3letter]
    if len(team_list) == 0:
        raise SystemExit('No teams found playing today.')
    else:
        print(f'Found {len(team_list)} teams that play games today.')

# Get the lineup for each team and store df's in list
try:
    lineups_list = list(map(get_team_lineup, team_list))
except:
    print('Lineup scrape did not complete successfully.\n')
    raise

# Conactenate into a final data frame
lineups_all_teams = pd.concat(lineups_list, ignore_index = True)

# Clean player names
lineups_all_teams['name'] = lineups_all_teams['name'].apply(clean_name)

# Asserts & other validations
# All teams must have 20 unique names/players
assert lineups_all_teams.groupby("team")['name'].nunique().unique() == np.array([20]), 'Incorrect number of players scraped for at least 1 team.\n'

# All teams should have 10 power play names
pp_check = lineups_all_teams[~lineups_all_teams['pp_unit_num'].isna()].groupby('team')['name'].nunique()
pp_check_list = list(pp_check[pp_check != 10].index)

# All teams should have 8 pk names
pk_check = lineups_all_teams[~lineups_all_teams['pk_unit_num'].isna()].groupby('team')['name'].nunique()
pk_check_list = list(pk_check[pp_check != 8].index)

# Print a summary if verbose
if args.Verbose:
    print(f'Total row count: {len(lineups_all_teams)}\n')
    if pp_check_list:
        print(f'The following teams do not have 10 players on the power play: {pp_check_list}\n')
    if pk_check_list:
        print(f'The following teams do not have 8 players on the penalty kill: {pk_check_list}\n')

# Save to CSV
try:
    old_lineups = pd.read_csv(path_to_lineups)
    new_lineups = pd.concat([old_lineups, lineups_all_teams], axis=0).reset_index(drop=True)
    new_lineups.to_csv(path_to_lineups, header=True, index=False)
    print(f'DF lineup CSV successfully updated.\nNumber of rows added: {len(lineups_all_teams)}\nNew total rows: {len(new_lineups)}\n')
except:
    print('DF lineup CSV was not updated.\n')
    raise

print("End DF Line Combinations Scrape\n==========================================================")