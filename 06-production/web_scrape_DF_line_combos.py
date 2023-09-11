from functions import get_team_lineup
import pandas as pd
import argparse

# Initialize parser
parser = argparse.ArgumentParser()

# Adding optional argument
parser.add_argument("-v", "--Verbose", action='store_true', help = "Print summary of line combination data frame.")
 
# Read arguments from command line
args = parser.parse_args()

# CSV path
path_to_lineups = './data/daily/DF_lineups.csv'

# Use the function on each team in list
# List of teams that differentiate  each URL
team_list = ['anaheim-ducks', 'arizona-coyotes', 'boston-bruins', 'buffalo-sabres', 'calgary-flames', 'carolina-hurricanes', 'chicago-blackhawks', 'colorado-avalanche', 'columbus-blue-jackets', 'dallas-stars', 'detroit-red-wings', 'edmonton-oilers', 'florida-panthers', 'los-angeles-kings', 'minnesota-wild', 'montreal-canadiens', 'nashville-predators', 'new-jersey-devils', 'new-york-islanders', 'new-york-rangers', 'ottawa-senators', 'philadelphia-flyers', 'pittsburgh-penguins', 'san-jose-sharks', 'seattle-kraken', 'st-louis-blues', 'tampa-bay-lightning', 'toronto-maple-leafs', 'vancouver-canucks', 'vegas-golden-knights', 'washington-capitals', 'winnipeg-jets']

# Get the lineup for each team and store df's in list
try:
    lineups_list = list(map(get_team_lineup, team_list))
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
    print('DF lineup CSV successfully updated.\n')
except:
    print('DF lineup CSV was not updated.\n')
    raise
