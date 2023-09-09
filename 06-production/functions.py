# All functions required for deployment of data collection and model
########################################################
# Libraries
import numpy as np
import pandas as pd
import datetime as dt
import pytz
import requests
from bs4 import BeautifulSoup
import json
########################################################
# Function to return data frames from DK containing the cleaned odds information for 1) Moneyline/Puckline and 2) O/U's
def retrieve_sportsbook_info(url):

    # Record the current date and time so we know when the recording occured
    dt_now = dt.datetime.now()

    # Record the HTML code from url as bs4 object
    response = requests.get(url)
    soup = BeautifulSoup(response.content, 'html.parser')

    # Each sportsbook table on the page separated in a list
    # We need them as separate items in list because each one is a different date.
    # This is the only way to correctly assign a date to each game.
    sportsbook_tables = soup.find_all(class_ = 'sportsbook-table')

    # If no tables were detected, raise an error.
    if len(sportsbook_tables) == 0:
        raise Exception('No DK tables were found.')

    # Establish time zones. DK stores in UTC. We will need to convert this to Central Time (taking into account whether currently in DST, etc.)
    central_tz = pytz.timezone('America/Chicago')
    utc_tz = pytz.timezone('UTC')

    # Create empty spaces to store each set of datetimes, teams, lines, and odds
    # We will extend these lists for each DK table we come across
    games_dt = []
    teams = []
    lines = []
    odds = []

    # For each sportsbook table on DK, collect the odds information
    for table in sportsbook_tables:
        # Get the DK date label
        date_label = table.find(class_ = 'always-left column-header').text.strip().lower()

        # If label is not 'today' or 'tomorrow', just go to the next table. This is because even with the time zone issues, games occuring today should never appear in a table not labeled 'today' or 'tomorrow'.
        # Set the date variable to attach to the game times
        if date_label == 'tue oct 10th':
            date = dt.date.today()
        elif date_label == 'tomorrow':
            date = dt.date.today() + dt.timedelta(days = 1)
        else:
            continue

        # Gather DK version of time information
        dk_times = [time.text for time in table.find_all(class_ = 'event-cell__start-time')]
        dk_times = [dt.datetime.strptime(time, '%I:%M%p').time() for time in dk_times]

        # Create the DK version of the game's date and time
        tbl_games_dt = [dt.datetime.combine(date, time) for time in dk_times]

        # Perform the time zone change to central time
        tbl_games_dt = [gametime.replace(tzinfo = utc_tz).astimezone(central_tz).replace(tzinfo = None) for gametime in tbl_games_dt]
        games_dt.extend(tbl_games_dt)
        
        # Get the list of teams playing
        tbl_teams = [team.text.strip() for team in table.find_all(class_ = 'event-cell__name-text')]
        teams.extend(tbl_teams)

        # Gathers puck line and O/U lines (ex: -1.5, 6.5, +1.5, 6.5, etc...)
        tbl_lines = [line.text for line in table.find_all(class_ = 'sportsbook-outcome-cell__line')]
        lines.extend(tbl_lines)
        
        # List of odds 
        # Had to add replace statement for special character
        tbl_odds = [odd.text.replace("−", "-") for odd in table.find_all(class_ = 'sportsbook-outcome-cell__elements')]  
        odds.extend(tbl_odds)

     # END For Loop

    # Check to make sure there is info in each list (and the correct amount of info)
    n = len(games_dt)
    if len(teams) != n or len(lines) != (2 * n) or len(odds) != (3 * n):
        print(f'Length of game date/times: {n}. Length should be N.')
        print(f'Length of teams: {len(teams)}. Length should be N.')
        print(f'Length of lines: {len(lines)}. Length should be 2 * N.')
        print(f'Length of odds: {len(odds)}. Length should be 3 * N')
        raise Exception('Lists are incompatable lengths.')

    # Create dictionary of information regarding the tables DK.
    # Later, we will filter this to only include todays games.
    combined_info = {
        'datetime':dt_now,
        'game_dates':[game.date() for game in games_dt],
        'game_times':[game.time() for game in games_dt],
        'teams':teams,
        'lines':lines,
        'odds':odds
    }

    return combined_info
########################################################
def get_ml_odds(sportsbook_recording, today_only = True):
    # Read in team name to 3 letter code dictionary
    with open('./data/team_name_dictionary.txt', 'r') as f:
        team_name_dict = json.load(f)

    # List of moneyline odds for today's games
    ml_odds = sportsbook_recording['odds'][2::3]

    # Create the data frame for today's odds for moneyline
    df_ml = pd.DataFrame({
        'team':sportsbook_recording['teams'],
        'date_recorded':sportsbook_recording['datetime'].date(),
        'time_recorded':sportsbook_recording['datetime'].strftime('%H:%M:%S'),
        'date_game':sportsbook_recording['game_dates'],
        'time_game':sportsbook_recording['game_times'],
        'odds':ml_odds
        })
    
    # Convert team names to 3 letter code
    df_ml['team'] = df_ml['team'].str.lower().replace(team_name_dict)
    
    # Return df of odds
    if today_only:
        return df_ml[df_ml['date_game'] == dt.date.today()]
    else:
        return df_ml
########################################################
def get_pl_odds(sportsbook_recording, today_only=True):
    # Read in team name to 3 letter code dictionary
    with open('./data/team_name_dictionary.txt', 'r') as f:
        team_name_dict = json.load(f)

    # List of pucklines for today
    pl_lines = sportsbook_recording['lines'][::2]

    # List of odds for today's pucklines
    pl_odds = sportsbook_recording['odds'][::3]

    # Create the data frame for today's odds for puckline
    df_pl = pd.DataFrame({
        'team':sportsbook_recording['teams'],
        'date_recorded':sportsbook_recording['datetime'].date(),
        'time_recorded':sportsbook_recording['datetime'].strftime('%H:%M:%S'),
        'date_game':sportsbook_recording['game_dates'],
        'time_game':sportsbook_recording['game_times'],
        'line':pl_lines,
        'odds':pl_odds
    })

    # Convert team names to 3 letter code
    df_pl['team'] = df_pl['team'].str.lower().replace(team_name_dict)
    
    # Return df of odds
    if today_only:
        return df_pl[df_pl['date_game'] == dt.date.today()]
    else:
        return df_pl
########################################################
def get_total_odds(sportsbook_recording, today_only=True):
    # Read in team name to 3 letter code dictionary
    with open('./data/team_name_dictionary.txt', 'r') as f:
        team_name_dict = json.load(f)

    # List of home teams
    home_teams = sportsbook_recording['teams'][1::2]
    home_teams = np.repeat(home_teams, 2)

    # List of away teams
    away_teams = sportsbook_recording['teams'][::2]
    away_teams = np.repeat(away_teams, 2)

    # List of O/U lines (ex: 6.5, 6.5, 5.5, 5.5, 6, 6, etc...)
    ou_lines = sportsbook_recording['lines'][1::2]

    # List of O/U bet types (O then U repeated)
    ou_bet_type = ['O', 'U'] * int(len(ou_lines) / 2)

    # List of today's O/U odds
    ou_odds = sportsbook_recording['odds'][1::3]
        
    df_total = pd.DataFrame({
        'home':home_teams,
        'away':away_teams,
        'date_recorded':sportsbook_recording['datetime'].date(),
        'time_recorded':sportsbook_recording['datetime'].strftime('%H:%M:%S'),
        'date_game':sportsbook_recording['game_dates'],
        'time_game':sportsbook_recording['game_times'],
        'bet_type':ou_bet_type,
        'line':ou_lines,
        'odds':ou_odds
    })

    # Convert team names to 3 letter code
    df_total['home'] = df_total['home'].str.lower().replace(team_name_dict)
    df_total['away'] = df_total['away'].str.lower().replace(team_name_dict)
    
    # Return df of odds
    if today_only:
        return df_total[df_total['date_game'] == dt.date.today()]
    else:
        return df_total
########################################################