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
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

########################################################
def clean_name(name):
    """Clean player names with special characters and punctuation to standardize across data sources"""
    # Set up replace dictionary
    replace_dict = {
        # Special characters
        #'Å':'A',
        'å':'a',
        'ä':'a',
        'á':'a',
        #'Č':'C',
        'č':'c',
        #'É':'E',
        'é':'e',
        'ë':'e',
        'è':'e',
        'ě':'e',
        'í':'i',
        'ļ':'l',
        'ň':'n',
        'ö':'o',
        'ø':'o',
        'ř':'r',
        #'Š':'S',
        'š':'s',
        'ü':'u',
        'ž':'z',

        # Other punctuation
        '.':'',
        '-':' ',
        "'":''
    }
    # Strip white space
    name = name.strip()
    # Lowercase
    name = name.lower()
    # Replace characters, punctuation, phrases
    for k, v in replace_dict.items():
        name = name.replace(k, v)

    # Return cleaned name
    return name
########################################################
# Function to return data frames from DK containing the cleaned odds information for 1) Moneyline/Puckline and 2) O/U's
def retrieve_sportsbook_info(url):
    """Return dictionary containing DK cleaned odds information for 1) Moneyline/Puckline and 2) O/U's"""
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
        if date_label == 'today':
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
    """Use DK sportsbook dictionary to return pandas data frame with ML odds"""
    # Read in team name to 3 letter code dictionary
    with open('./data/team_name_dictionary.txt', 'r') as f:
        team_name_dict = json.load(f)

    # List of moneyline odds for today's games
    ml_odds = sportsbook_recording['odds'][2::3]
    ml_odds = [int(odd) for odd in ml_odds]

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
    """Use DK sportsbook dictionary to return pandas data frame with PL odds"""
    # Read in team name to 3 letter code dictionary
    with open('./data/team_name_dictionary.txt', 'r') as f:
        team_name_dict = json.load(f)

    # List of pucklines for today
    pl_lines = sportsbook_recording['lines'][::2]

    # List of odds for today's pucklines
    pl_odds = sportsbook_recording['odds'][::3]
    pl_odds = [int(odd) for odd in pl_odds]

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
    """Use DK sportsbook dictionary to return pandas data frame with total odds"""
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
    ou_odds = [int(odd) for odd in ou_odds]
        
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
def process_forwards(section_html):
    """Process forwards section of DF lines"""
    # xxxxxx
    lines = section_html.find_all(class_ = 'mb-4 flex flex-row flex-wrap justify-evenly border-b')
    lines.append(section_html.find_next(class_ = 'flex flex-row flex-wrap justify-evenly').find_next(class_ = 'flex flex-row flex-wrap justify-evenly'))

    # xxxxxxx
    standard_positions = ['LW', 'C', 'RW']
    names = []
    positions = []
    line_num = []

    for line_num_zero_index, line in enumerate(lines):
        containers = line.find_all(class_ = 'w-1/3 text-center xl:w-48')
        for ind, container in enumerate(containers):
            name_html = container.find(class_ = 'text-xs font-bold uppercase xl:text-base')
            if name_html is not None:
                name = name_html.text.strip()
                names.append(name)
                positions.append(standard_positions[ind])
                line_num.append(line_num_zero_index + 1)
            else:
                continue

    # Names
    #names_html = section_html.find_all(class_ = 'text-xs font-bold uppercase xl:text-base')
    #names = [n.text.strip() for n in names_html]

    if len(names) != 12:
        print(f'Incorrect number of forwards were found: {len(names)}.\n{names}\n')
        #return None

    # Positions
    #positions = ['LW', 'C', 'RW'] * 4

    # Line number
    #line_num = [item for item in [1, 2, 3, 4] for _ in range(3)]

    # Injury status
    injury_html = section_html.find_all(class_ = 'rounded-md bg-red-500 pl-1 pr-1 text-2xl uppercase text-white')
    injury_status = [inj.text.strip().upper() for inj in injury_html]
    injury_names = [inj.find_next('div').find_next('span').text.strip() for inj in injury_html]

    # Game time decision image (doesn't have text/letters)
    gtd_html = section_html.find_all('svg')
    gtd_names = [gtd.find_next('div').find_next('span').text.strip() for gtd in gtd_html]

    # Update the injury lists with GTD info
    if len(gtd_names) > 0:
        injury_names.extend(gtd_names)
        injury_status.extend(['GTD'] * len(gtd_names))

    assert len(injury_status) == len(injury_names), f'Lengths of injury names ({len(injury_names)}) and injury status ({len(injury_status)}) do not match.'
    assert all(name in names for name in injury_names), 'Not all injury names are found in names masterlist.'

    # Create dictionary of information to return
    forward_dict = {
        'names':names,
        'positions':positions,
        'line_num':line_num,
        'injuries':{'name':injury_names, 'injury_status':injury_status}
    }

    return forward_dict
########################################################
# Function to process defenseman
def process_defenseman(section_html):
    """Process defenseman section of DF lines"""
    # Names
    names_html = section_html.find_all(class_ = 'text-xs font-bold uppercase xl:text-base')
    names = [n.text.strip() for n in names_html]

    assert len(names) == 6, f'Incorrect number of defenseman were found: {len(names)}.'

    # Positions
    positions = ['LD', 'RD'] * 3

    # Line number
    line_num = [item for item in [1, 2, 3] for _ in range(2)]

    # Injury status
    injury_html = section_html.find_all(class_ = 'rounded-md bg-red-500 pl-1 pr-1 text-2xl uppercase text-white')
    injury_status = [inj.text.strip().upper() for inj in injury_html]
    injury_names = [inj.find_next('div').find_next('span').text.strip() for inj in injury_html]

    # Game time decision image (doesn't have text/letters)
    gtd_html = section_html.find_all('svg')
    gtd_names = [gtd.find_next('div').find_next('span').text.strip() for gtd in gtd_html]

    # Update the injury lists with GTD info
    if len(gtd_names) > 0:
        injury_names.extend(gtd_names)
        injury_status.extend(['GTD'] * len(gtd_names))

    assert len(injury_status) == len(injury_names), f'Lengths of injury names ({len(injury_names)}) and injury status ({len(injury_status)}) do not match.'
    assert all(name in names for name in injury_names), 'Not all injury names are found in names masterlist.'

    # Create dictionary of information to return
    defense_dict = {
        'names':names,
        'positions':positions,
        'line_num':line_num,
        'injuries':{'name':injury_names, 'injury_status':injury_status}
    }

    return defense_dict
########################################################
# Function to process power play sections
def process_power_play(section_html, unit_num):
    """Process power play section of DF lines"""
    # Names
    names_html = section_html.find_all(class_ = 'text-xs font-bold uppercase xl:text-base')
    names = [n.text.strip() for n in names_html]

    assert len(names) == 5, f'Incorrect number of power play skaters were found: {len(names)}.'

    # Unit number
    unit = [unit_num] * 5

    # Unit position
    pp_position = [1, 2, 3, 4, 5]

    # Create dictionary
    pp_dict = {
        'name':names,
        'pp_unit_num':unit,
        'pp_position':pp_position
    }

    return pp_dict
########################################################
# Function to process penalty kill sections
def process_penalty_kill(section_html, unit_num):
    """Process penalty kill section of DF lines"""
    # Names
    names_html = section_html.find_all(class_ = 'text-xs font-bold uppercase xl:text-base')
    names = [n.text.strip() for n in names_html]

    if len(names) > 4:
        print(f'Incorrect number of penalty killers were found: {len(names)}.')
        return None

    # Unit number
    unit = [unit_num] * len(names)

    # Unit position
    pk_position = [1, 2, 3, 4]
    pk_position = [pk_position[i] for i in range(len(names))]

    # Create dictionary
    pk_dict = {
        'name':names,
        'pk_unit_num':unit,
        'pk_position':pk_position
    }

    return pk_dict
########################################################
# Function to process goalie section
def process_goalies(section_html):
    """Process goalie section of DF lines"""
    # Names
    names_html = section_html.find_all(class_ = 'text-xs font-bold uppercase xl:text-base')
    names = [n.text.strip() for n in names_html]

    assert len(names) in (1, 2, 3), f'Too many goalies were found: {len(names)}.'

    # Positions
    positions = ['G'] * len(names)

    # Depth number
    depth_num = [i + 1 for i in range(len(names))]

    # Injury status
    injury_html = section_html.find_all(class_ = 'rounded-md bg-red-500 pl-1 pr-1 text-2xl uppercase text-white')
    injury_status = [inj.text.strip().upper() for inj in injury_html]
    injury_names = [inj.find_next('div').find_next('span').text.strip() for inj in injury_html]

    # Game time decision image (doesn't have text/letters)
    gtd_html = section_html.find_all('svg')
    gtd_names = [gtd.find_next('div').find_next('span').text.strip() for gtd in gtd_html]

    # Update the injury lists with GTD info
    if len(gtd_names) > 0:
        injury_names.extend(gtd_names)
        injury_status.extend(['GTD'] * len(gtd_names))

    assert len(injury_status) == len(injury_names), f'Lengths of injury names ({len(injury_names)}) and injury status ({len(injury_status)}) do not match.'
    assert all(name in names for name in injury_names), 'Not all injury names are found in names masterlist.'

    # Create dictionary of information to return
    goalie_dict = {
        'names':names,
        'positions':positions,
        'depth_num':depth_num,
        'injuries':{'name':injury_names, 'injury_status':injury_status}
    }
    
    return goalie_dict
########################################################
# Function to process injury section
def process_injuries(section_html):
    """Process injury section of DF lines"""
    # Injury status
    injury_html = section_html.find_all(class_ = 'rounded-md bg-red-500 pl-1 pr-1 text-2xl uppercase text-white')
    injury_status = [inj.text.strip().upper() for inj in injury_html]
    injury_names = [inj.find_next('div').find_next('span').text.strip() for inj in injury_html]

    ######
    # Not sure if GTD info is really required for this section. Anyone who is located here is probably not GTD?
    # Game time decision image (doesn't have text/letters)
    gtd_html = section_html.find_all('svg')
    gtd_names = [gtd.find_next('div').find_next('span').text.strip() for gtd in gtd_html]

    # Update the injury lists with GTD info
    if len(gtd_names) > 0:
        injury_names.extend(gtd_names)
        injury_status.extend(['GTD'] * len(gtd_names))
    #####
    
    assert len(injury_status) == len(injury_names), f'Lengths of injury names ({len(injury_names)}) and injury status ({len(injury_status)}) do not match.'

    injury_dict = {
        'name':injury_names,
        'injury_status':injury_status
    }
    
    return injury_dict
########################################################
def get_team_lineup(team):
    """Retrieve lines (F, D, G, PP, PK, etc.) for team X off DF"""
    # Read in team name to 3 letter code dictionary
    with open('./data/team_name_dictionary.txt', 'r') as f:
        team_name_dict = json.load(f)
        
    # Date and time of recording
    dt_now = dt.datetime.now()
    date_recorded = dt_now.date()
    time_recorded = dt_now.time().strftime(format = '%H:%M:%S')

    # Basically trick the site to think you are a genuine user?
    headers = {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2661.102 Safari/537.36'}

    # Main DF URL for line combinations
    DF_url = 'https://www.dailyfaceoff.com/teams/.../line-combinations'

    # Record the HTML code from url as bs4 object
    response = requests.get(DF_url.replace('...', team), headers=headers)
    soup = BeautifulSoup(response.content, 'html.parser')

    # Get each section individually (forwards, defense, pp1, pp2, etc.)
    sections = soup.find_all(class_ = 'text-3xl text-white')

    # Use functions for each section of webpage
    for sec in sections:
        sec_name = sec.text.strip().lower()
        parent_html = sec.find_parent('div').find_parent('div')

        if sec_name == 'forwards':
            forwards = process_forwards(parent_html)
        elif sec_name == 'defensive pairings':
            defenseman = process_defenseman(parent_html)
        elif sec_name == '1st powerplay unit':
            pp1 = process_power_play(parent_html, unit_num = 1)
        elif sec_name == '2nd powerplay unit':
            pp2 = process_power_play(parent_html, unit_num = 2)
        elif sec_name == '1st penalty kill unit':
            pk1 = process_penalty_kill(parent_html, unit_num = 1)
        elif sec_name == '2nd penalty kill unit':
            pk2 = process_penalty_kill(parent_html, unit_num = 2)
        elif sec_name == 'goalies':
            goalies = process_goalies(parent_html)
        #elif sec_name == 'injuries':
            #injuries = process_injuries(parent_html)

    if any(df is None for df in [forwards, defenseman, pp1, pp2, pk1, pk2, goalies]):
        return None
    
    # Create lineup for each team
    lineup = pd.DataFrame({
        'player_id':np.nan,
        'name':forwards['names'] + defenseman['names'] + goalies['names'],
        'team':team,
        'date_recorded':date_recorded,
        'time_recorded':time_recorded,
        'position':forwards['positions'] + defenseman['positions'] + goalies['positions'],
        'depth_chart_rank':forwards['line_num'] + defenseman['line_num'] + goalies['depth_num']
    })

    # Set up injury data frame to merge
    injuries = pd.concat([pd.DataFrame(forwards['injuries']), pd.DataFrame(defenseman['injuries']), pd.DataFrame(goalies['injuries'])])

    # Merge in injury information
    lineup = pd.merge(lineup, injuries, how = 'left', on = 'name')

    # Set up pp/pk data frame
    power_play = pd.concat([pd.DataFrame(pp1), pd.DataFrame(pp2)])
    penalty_kill = pd.concat([pd.DataFrame(pk1), pd.DataFrame(pk2)])

    # If a player plays on both units, only select the higher unit?
    #power_play = power_play.loc[power_play.groupby('name')['pp_unit_num'].idxmax()]
    #penalty_kill = penalty_kill.loc[penalty_kill.groupby('name')['pk_unit_num'].idxmax()]

    # Special teams merge
    lineup = pd.merge(lineup, power_play, how = 'left', on = 'name')
    lineup = pd.merge(lineup, penalty_kill, how = 'left', on = 'name')

    # Cleanup
    lineup[['pp_unit_num', 'pp_position', 'pk_unit_num', 'pk_position']] = lineup[['pp_unit_num', 'pp_position', 'pk_unit_num', 'pk_position']].astype('Int64')
    lineup['team'] = lineup['team'].str.lower().replace(team_name_dict)
    
    return lineup
########################################################
def get_DF_goalies(date_of_games=None, today_flag=None):
    """Scrape Daily Faceoff Starting Goalies to get data frame of projected goalie statuses"""
    # Ensure at least 1 argument is sepcified
    if date_of_games is None and today_flag is None:
        raise ValueError("At least one of 'date_of_games' or 'today_flag' must be specified.")

    # Current date and time
    dt_now = dt.datetime.now()
    date_recorded = dt_now.date()
    time_recorded = dt_now.time().strftime(format = '%H:%M:%S')

    # If today's goalies are desired
    if today_flag:
        date_of_games = str(date_recorded)
    
    # URL for DF goalies
    url = 'https://www.dailyfaceoff.com/starting-goalies/' + date_of_games

    # Basically trick the site to think you are a genuine user?
    headers = {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2661.102 Safari/537.36'}

    # Gather HTML from website
    response = requests.get(url, headers=headers)
    soup = BeautifulSoup(response.content, 'html.parser')
    game_cards = soup.find_all('article', class_ = 'w-full')

    if len(game_cards) <= 0: 
        raise ValueError(f"No games were found on daily faceoff for {date_of_games}: {url}")

    # Process each game 
    teams = []
    names = []
    status_list = []
    for card in game_cards:
        t, n, s = process_goalie_DF_card(card)
        teams.extend(t)
        names.extend(n)
        status_list.extend(s)
        
    # Assemble data frame
    DF_goalies = pd.DataFrame({
        #'game_id':game_id,
        'date_recorded':date_recorded,
        'time_recorded':time_recorded,
        'date_game':date_of_games,
        'team':teams,
        'name':names,
        'status':status_list
    })

    return DF_goalies
########################################################
def process_goalie_DF_card(section_html):
    """Process each game on Daily Faceoff to return list of teams, goalies, and their status"""
    # Read in team name to 3 letter code dictionary
    with open('./data/team_name_dictionary.txt', 'r') as f:
        team_name_dict = json.load(f)

    # Gather teams playing in this matchup
    teams_html = section_html.find(class_ = 'text-center text-3xl text-white').text
    teams = teams_html.split(' at ')
    assert len(teams) == 2, f'Only 2 teams should be on a game card: {teams}'
    teams = [team_name_dict[team.strip().lower()] for team in teams]
    
    # Gather the 2 goalie names
    names_html = section_html.find_all(class_ = 'text-center text-lg xl:text-2xl')
    names = [name.text for name in names_html]
    assert len(names) == 2, f'Only 2 names should be on a game card: {names}'
    names = [clean_name(name) for name in names]

    # What is the status of the goalies for the upcoming game?
    status_to_code_dict = {'unconfirmed':'U', 
                        'projected':'P', 
                        'likely':'P', 
                        'expected':'P', 
                        'confirmed':'C'}

    status_html = section_html.find_all('div', {'class':['flex flex-row items-center justify-center gap-1 xl:justify-end', 'flex flex-row items-center justify-center gap-1 xl:justify-start']})
    status_list = [status.text.lower().strip() for status in status_html]
    status_list = [status_to_code_dict[status] for status in status_list]
    assert all([1 if status in ['U', 'P', 'C'] else 0 for status in status_list]), f'Unknown status in status list: {status_list}'

    #game_id = dt.datetime.strptime(date_of_games, '%Y-%m-%d').strftime('%y%m%d') + '-' + teams[0] + teams[1]
    #game_id

    return teams, names, status_list
########################################################
def get_60min_odds(date_of_games = None, today_flag = None):
    """Retrieve DK 60 min line odds for specific date"""
    # Ensure at least 1 argument is sepcified
    if date_of_games is None and today_flag is None:
        raise ValueError("At least one of 'date_of_games' or 'today_flag' must be specified.")
    
    # Read in team name to 3 letter code dictionary
    with open('./data/team_name_dictionary.txt', 'r') as f:
        team_name_dict = json.load(f)

    # Current date and time
    dt_now = dt.datetime.now()
    date_recorded = dt_now.date()
    time_recorded = dt_now.time().strftime(format = '%H:%M:%S')

    # If today's goalies are desired
    if today_flag:
        date_of_games = date_recorded
    else:
        date_of_games_split = [int(part) for part in date_of_games.split('-')]
        date_of_games = dt.date(date_of_games_split[0], date_of_games_split[1], date_of_games_split[2])
    
    # URL to scrape
    url = 'https://sportsbook.draftkings.com/leagues/hockey/nhl?category=game-lines&subcategory=60-min-line'

    # Extra information and empty lists for storing
    # Only keep the game cards that are on today's date. We need to map month  to a number
    month_mapping = {
        'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4, 'MAY': 5, 'JUN': 6,
        'JUL': 7, 'AUG': 8, 'SEP': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12
    }

    # Empty lists to store bet options and odds
    bet_options = []
    odds = []
    home_teams = []
    away_teams = []

    #==========Enter into web driver scrape==========#
    # Configure Chrome options
    options = webdriver.ChromeOptions()
    options.add_argument('--headless')  # Run in headless mode

    # Create a WebDriver instance
    driver = webdriver.Chrome(options=options)

    # Open the URL
    driver.get(url)

    # Explicitly wait for the elements with the specified class to appear
    wait = WebDriverWait(driver, 30)  # Wait for up to 30 seconds

    # Get each game card
    game_cards = wait.until(EC.presence_of_all_elements_located((By.CLASS_NAME, 'sportsbook-event-accordion__wrapper.expanded')))
    game_cards_final = []

    # For each card
    for card in game_cards:
        # Get the date
        card_date = card.find_element(By.CLASS_NAME, 'sportsbook-event-accordion__date').text

        # Remove parts of date (day of week, time, the TH in 10TH)
        #split_date = card_date.split()
        #parts_to_keep = []
        #for part in split_date:
        #    if part.endswith('AM') or part.endswith('PM') or part in ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']:
        #        continue
        #    elif part.endswith('TH'):
        #        part = part[:-2]
        #        parts_to_keep.append(part)
        #    else:
        #        parts_to_keep.append(month_mapping[part])

        #if len(parts_to_keep) != 2:
        #    raise ValueError(f'A date was processed incorrectly: {parts_to_keep}')
        if 'TODAY' in card_date:
            #card_date_final = dt.date(dt.datetime.now().year, int(parts_to_keep[0]), int(parts_to_keep[1]))
            card_date_final = dt_now.date()
        else:
            continue

        # If the game card date is today's date, process the HTML to record team and odds
        if card_date_final == date_of_games:
           game_cards_final.append(card) 

    if len(game_cards_final) == 0:
        raise ValueError(f'No games were found for {str(date_of_games)}: {url}\n')
    
    for card in game_cards_final:
        # Find the bets you can place
        bet_options_single_game = card.find_elements(By.CLASS_NAME, 'sportsbook-outcome-cell__label')
        bet_options_single_game = [opt.text.strip().lower() for opt in bet_options_single_game]

        if len(bet_options_single_game) != 3:
            raise ValueError(f"There should be 3 bet options per game. Found the following: {bet_options_single_game}")
        
        bet_options_single_game = [team_name_dict[opt] if opt != 'draw' else opt for opt in bet_options_single_game]
        bet_options.extend(bet_options_single_game)

        # Find the odds for each possible bet
        odds_single_game = card.find_elements(By.CLASS_NAME, 'sportsbook-odds.american.default-color')
        odds_single_game = [int(odd.text.replace("−", "-")) for odd in odds_single_game]
        if len(odds_single_game) != 3:
            raise ValueError(f"There should be 3 odds per game. Found the following: {odds_single_game}")
        odds.extend(odds_single_game)

    # Quit the WebDriver
    driver.quit()
    #==========Exit web driver scrape==========#

    # Set home and away teams based on layout on website ("away @ home")
    home_teams = np.repeat(bet_options[2::3], 3)
    away_teams = np.repeat(bet_options[::3], 3)

    # Create final data frame
    df_60min = pd.DataFrame({
        'home':home_teams,
        'away':away_teams,
        'date_recorded':date_recorded,
        'time_recorded':time_recorded,
        'date_game':date_of_games,
        'bet_type':bet_options,
        'odds':odds
    })

    return df_60min
########################################################
def get_anytime_scorer_odds(date_of_games = None, today_flag = None):
    """Gather dataframe of DK anytime scorer odds for games occuring on particular date"""
    # Ensure at least 1 argument is sepcified
    if date_of_games is None and today_flag is None:
        raise ValueError("At least one of 'date_of_games' or 'today_flag' must be specified.")
    
    # Current date and time
    dt_now = dt.datetime.now()
    date_recorded = dt_now.date()
    time_recorded = dt_now.time().strftime(format = '%H:%M:%S')

    # Read in team name to 3 letter code dictionary
    with open('./data/team_name_dictionary.txt', 'r') as f:
        team_name_dict = json.load(f)
        
    # If today's scorer odds are desired
    if today_flag:
        date_of_games = date_recorded
    else:
        date_of_games_split = [int(part) for part in date_of_games.split('-')]
        date_of_games = dt.date(date_of_games_split[0], date_of_games_split[1], date_of_games_split[2])

    url = 'https://sportsbook.draftkings.com/leagues/hockey/nhl?category=goalscorer'

    # Empty lists to store names and odds
    names = []
    odds = []
    home_teams = []
    away_teams = []

    #==========Enter into web driver scrape==========#
    # Configure Chrome options
    options = webdriver.ChromeOptions()
    options.add_argument('--headless')  # Run in headless mode

    # Create a WebDriver instance
    driver = webdriver.Chrome(options=options)

    # Open the URL
    driver.get(url)

    # Explicitly wait for the elements with the specified class to appear
    wait = WebDriverWait(driver, 30)  # Wait for up to 30 seconds

    # Get each game card
    game_cards = wait.until(EC.presence_of_all_elements_located((By.CLASS_NAME, 'sportsbook-event-accordion__wrapper.expanded')))
    game_cards_final = []

    # For each card
    for card in game_cards:
        # Get the date
        card_date = card.find_element(By.CLASS_NAME, 'sportsbook-event-accordion__date').text

        if 'TODAY' in card_date:
            card_date_final = date_recorded
        elif 'TOMORROW' in card_date:
            # ===NOT TESTED YET===
            card_date_final = date_recorded + dt.timedelta(days=1)
        else:
            # ===NOT TESTED YET===
            # Remove parts of date (day of week, time, the TH in 10TH)
            month_mapping = {
                'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4, 'MAY': 5, 'JUN': 6,
                'JUL': 7, 'AUG': 8, 'SEP': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12
            }
            split_date = card_date.split()
            parts_to_keep = []
            for part in split_date:
                if part.endswith('AM') or part.endswith('PM') or part in ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']:
                    continue
                elif part.endswith('TH'):
                    part = part[:-2]
                    parts_to_keep.append(part)
                else:
                    parts_to_keep.append(month_mapping[part])
            if len(parts_to_keep) != 2:
                print(f'A date was processed incorrectly: {parts_to_keep}')
                continue
            card_date_final = dt.date(dt.datetime.now().year, int(parts_to_keep[0]), int(parts_to_keep[1]))

        # If the game card date is today's date, process the HTML to record team and odds
        if card_date_final == date_of_games:
            game_cards_final.append(card) 

    for card in game_cards_final:
        # Find index of "Anytime Goalscorer" column 
        colnames = card.find_element(By.CLASS_NAME, 'scorer-7__header-wrapper').text
        colnames = colnames.split('\n')
        colnames = [col.strip().lower() for col in colnames]
        assert len(colnames) == 3, f"3 column names should've been located: {colnames}\n"
        assert 'anytime scorer' in colnames, f"'anytime scorer' column not found. {colnames}\n"
        anytime_index = colnames.index('anytime scorer')
        anytime_end_index = anytime_index - 3

            # Locate teams on each card
        teams = card.find_element(By.CLASS_NAME, 'sportsbook-event-accordion__title-wrapper').text
        teams = teams.split('\n')
        teams = [team.strip().lower() for team in teams]
        teams.pop(teams.index('at'))
        teams = [team_name_dict[team] for team in teams]
        assert len(teams) == 2, f"Incorrect number of teams found: {teams}\n"

        # Locate names and odds together since if done separately, an ordering issue arises from the scrape
        names_and_odds = card.find_elements(By.CLASS_NAME, 'scorer-7__body')
        names_and_odds_split = [info.text.split('\n') for info in names_and_odds]

        # Generate list of names
        names_single_game = [splits[0] for splits in names_and_odds_split]
        names_single_game = [clean_name(name) for name in  names_single_game]
        
        # Generate list of odds
        odds_single_game = [splits[anytime_end_index] for splits in names_and_odds_split]
        odds_single_game = [int(odd.replace("−", "-")) for odd in odds_single_game]

        # Append these values to running list
        assert len(names_single_game) == len(odds_single_game), f"Number of names should be the same as the number of odds:\nNum names:{len(names_single_game)}\nNum odds: {len(odds_single_game)}\n"
        names.extend(names_single_game)
        odds.extend(odds_single_game)
        away_teams.extend([teams[0]] * len(names_single_game))
        home_teams.extend([teams[1]] * len(names_single_game))

    driver.quit()
    #==========Exit web driver scrape==========#
    # Create final data frame
    anytime_scorer = pd.DataFrame({
        'player_id':np.nan,
        'name':names,
        'home':home_teams,
        'away':away_teams,
        'date_recorded':date_recorded,
        'time_recorded':time_recorded,
        'date_game':date_of_games,
        'odds':odds
    })

    # Remove the 'No goalscorer' rows
    anytime_scorer = anytime_scorer[anytime_scorer['name'] != 'no goalscorer']

    return anytime_scorer
########################################################