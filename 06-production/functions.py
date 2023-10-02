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
    # Names
    names_html = section_html.find_all(class_ = 'text-xs font-bold uppercase xl:text-base')
    names = [n.text.strip() for n in names_html]

    assert len(names) == 12, f'Incorrect number of forwards were found: {len(names)}.'

    # Positions
    positions = ['LW', 'C', 'RW'] * 4

    # Line number
    line_num = [item for item in [1, 2, 3, 4] for _ in range(3)]

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

    assert len(names) == 4, f'Incorrect number of penalty killers were found: {len(names)}.'

    # Unit number
    unit = [unit_num] * 4

    # Unit position
    pk_position = [1, 2, 3, 4]

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

    # Set up pp data frame
    power_play = pd.concat([pd.DataFrame(pp1), pd.DataFrame(pp2)])
    penalty_kill = pd.concat([pd.DataFrame(pk1), pd.DataFrame(pk2)])

    # Special teams merge
    lineup = pd.merge(lineup, power_play, how = 'left', on = 'name')
    lineup = pd.merge(lineup, penalty_kill, how = 'left', on = 'name')

    # Cleanup
    lineup[['pp_unit_num', 'pp_position', 'pk_unit_num', 'pk_position']] = lineup[['pp_unit_num', 'pp_position', 'pk_unit_num', 'pk_position']].astype('Int64')
    lineup['team'] = lineup['team'].str.lower().replace(team_name_dict)
    
    return lineup
########################################################

########################################################
