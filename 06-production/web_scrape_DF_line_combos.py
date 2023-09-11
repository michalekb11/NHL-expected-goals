from functions import get_team_lineup
import pandas as pd
import argparse
import json
import datetime as dt

# Initialize parser
parser = argparse.ArgumentParser()

# Adding optional argument
parser.add_argument("-v", "--Verbose", action='store_true', help = "Print summary of line combination data frame.")
 
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

# 3 letter code version
team_list_3letter = [team_name_dict[team] for team in team_list]

# Create a dictionary to map codes to team names
code_to_name = dict(zip(team_list_3letter, team_list))

# If you only want to scrape teams playing today...
# Use hockey reference to find the correct list of teams for today
date_of_games = dt.datetime.now().strftime('%Y-%M-%d')
schedule_url = 'https://www.hockey-reference.com/leagues/NHL_2023_games.html'

# Get the schedule from hockey reference for the given season
schedule = pd.read_html(schedule_url, attrs={'class':'stats_table', 'id':'games'})[0]
schedule['Visitor'] = schedule['Visitor'].str.lower().replace(team_name_dict)
schedule['Home'] = schedule['Home'].str.lower().replace(team_name_dict)

# Filter for date == date of interest
schedule = schedule[schedule['Date'] == date_of_games]
teams_on_date_3letter = schedule['Visitor'].tolist()
teams_on_date_3letter.extend(schedule['Home'].tolist())

# Get team names for the interested codes
teams_on_date = [code_to_name[code] for code in teams_on_date_3letter]
if len(teams_on_date) != 0:
    print(f'Found {len(teams_on_date)} teams that play games today.')

# Get the lineup for each team and store df's in list
try:
    lineups_list = list(map(get_team_lineup, teams_on_date))
except:
    print('Lineup scrape did not complete successfully.\n')
    raise

# Conactenate into a final data frame
lineups_all_teams = pd.concat(lineups_list, ignore_index = True)

# Asserts
assert lineups_all_teams.groupby("team").size().unique() == [20], 'Incorrect number of players scraped for at least 1 team.\n'

# Print a summary if verbose
if args.Verbose:
    print(f'Total row count: {len(lineups_all_teams)}\n')
    #print(f'Players scraped per team (unique set): {lineups_all_teams.groupby("team").size().unique()}')

# Save to CSV
try:
    old_lineups = pd.read_csv(path_to_lineups)
    new_lineups = pd.concat([old_lineups, lineups_all_teams], axis=0).reset_index(drop=True)
    new_lineups.to_csv(path_to_lineups, header=True, index=False)
    print(f'DF lineup CSV successfully updated.\nNumber of rows added: {len(lineups_all_teams)}\nNew total rows: {len(new_lineups)}\n')
except:
    print('DF lineup CSV was not updated.\n')
    raise
