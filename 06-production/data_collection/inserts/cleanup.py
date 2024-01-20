# All functions required for data cleanup before inserting into database
########################################################
# Libraries
import pandas as pd
import sqlalchemy
import numpy as np
import json
import re

########################################################
def match_name_to_id(name, mysql, team=None, age=None, date_in_history=None, verbose=False):
    """Find a matching player ID (or enter the correct ID) using player history table"""
    # Remove any () from name for duplicate players (Aho's)
    match = re.match(r"([^\(]+)\s*\(([^)]+)\)", name)
    if match:
        with open('./data/team_name_dictionary.txt', 'r') as f:
            team_name_dict = json.load(f)
        name = match.group(1).strip().lower()
        team = [team_name_dict[match.group(2).strip().lower()]]
    # If the name is Will or Zach, etc. we can try seaching for William or Zachary as well...
    name_splits = name.split(" ", 1)
    first_name_dict = {
        'will':['william'],
        'zach':['zachary'],
        'zac':['zachary'],
        'alexei':['alexey'],
        'egor':['yegor'],
        'matty':['matthew'],
        'alex':['alexander'],
        'matthew':['matt'],
        'matt':['mathew', 'matthew'],
        'jon':['jonathan', 'jonathon'],
        'janis':['jj'],
        'mitchell':['mitch'],
        'nicholas':['nick'],
        'mikey':['michael'],
        'nick':['nicholas', 'nicklaus'],
        'christopher':['chris'],
        'artyom':['artem'],
        'josh':['joshua'],
        'louie':['louis'],
        'danil':['daniil'],
        'grigory':['grigori'],
        'cal':['callan']
    }
    name_list = [name]
    if name_splits[0] in first_name_dict:
        name_list.extend([n + ' ' + name_splits[1] for n in first_name_dict[name_splits[0]]])

    # If you provide a list of potential teams, we will try to use that
    team_where_clause = ''
    if team:
        team_where_clause += f"""AND team IN ('{"', '".join(team)}')"""

    # If you provide an age, but in order to calculate age at a particular time in history, you must also provide the date...
    # If no date in history is provided, we assume that age is meaningless and often not the same as their current age?
    age_where_clause = ''
    if age and date_in_history:
        age_where_clause += f"AND TIMESTAMPDIFF(year, dob, '{date_in_history}') = {age}"

    # If you provide the date that this record was from, we can search for that point in this player's history
    # If you do not provide a time in history, we will ??????
    if date_in_history:
        date_in_history_where_clause = f"AND start_date <= '{date_in_history}' AND end_date >= '{date_in_history}'"
    else:
        date_in_history_where_clause = "AND end_date = '9999-12-31'"

    # Construct the main query using all possible information available to us
    query = f"""
    SELECT DISTINCT(player_id)
    FROM player_history
    WHERE name IN ('{"', '".join(name_list)}')
    {team_where_clause}
    {age_where_clause}
    {date_in_history_where_clause}
    ;
    """

    # Try query using all available information
    potential_ids = pd.read_sql(query, con=mysql.engine).values.flatten()

    # If we did not find match, start removing clauses until we do
    if potential_ids.size == 0:
        # Initalize priority list of the where clauses to remove (in order) if there is no match on the previous tries
        # Concerned that after a while, a new player might have same name and team as someone who played years ago and hit an ID match.
        remove_priority = [clause for clause in [age_where_clause] if clause] #, date_in_history_where_clause... 

        # If there are no clauses we want to remove, the list will be empty, and this loop will be skipped
        for remove_clause in remove_priority:
            # Remove the clause from query
            query = query.replace(remove_clause, '')

            # Rerun the query to see if theres a new match
            potential_ids = pd.read_sql(query, con=mysql.engine).values.flatten()

            # If match, break away
            if potential_ids.size > 0:
                break

    # Print the final query that was used to the user:
    if verbose:
        print("====================================")
        query = f'\n'.join([line for line in query.split('\n') if line.strip() != '']) # Funny looking way to remove empty lines from query
        print(f'Final query tried:\n\n{query}\n')

    # We have tried as many queries as we are willing to. Time to check what we found...
    if potential_ids.size == 1:
        return potential_ids[0]
    # If multiple, have the user choose the correct one (can select none of the above)
    elif potential_ids.size > 1:
        # Print the list of possibilities to user
        print(f"Found multiple potential IDs for:\nname = {name}\nteam = {team}\nage = {age}\ndate_in_history = {date_in_history}.\n")
        for n, id in enumerate(potential_ids):
            print(f"{n}: {id}")
        
        # Add option for none of the above
        print(f"{len(potential_ids)}: None of the above\n")
        potential_ids = np.append(potential_ids, None)

        # Prompt user for input
        correct_idx = int(input(f"Enter the number of the correct id.\n"))

        # Return correct id
        return potential_ids[correct_idx]
    else:
        # Get input from user with the correct ID if there is one
        print(f"No ID found for:\nname = {name}\nteam = {team}\nage = {age}\ndate_in_history = {date_in_history}.\n")
        correct_id = input(f"Enter the correct ID for this player. If you cannot find the ID, press enter (submit empty string).\n")

        if correct_id:
            # Before we return the correct id, we need to ask the user to enter the correct information about this player and insert the info into the player history table so that we have it stored for next time
            print(f"Enter the following player information to be inserted into player history table.")
            name_to_insert = input('Name: ').strip().lower()
            team_to_insert = input('Team (3 letter code): ').strip().lower()
            #date_to_insert = input("Date in history (ex: '2023-01-01'): ").strip()
            #dob_to_insert = input("Date of birth: ").strip()

            # Ensure team is correct 3 letter code
            if not 'team_name_dict' in locals():
                with open('./data/team_name_dictionary.txt', 'r') as f:
                    team_name_dict = json.load(f)
            team_to_insert = team_name_dict[team_to_insert]

            # Insert information into player history by calling stored procedure
            # insert_query = sqlalchemy.text(f"""
            #     INSERT INTO player_history (player_id, start_date, name, dob, team)
            #     VALUES ('{correct_id}', '{date_to_insert}', '{name_to_insert}', '{dob_to_insert}', '{team_to_insert}');
            # """)
            insert_query = sqlalchemy.text(f"""CALL InsertOrUpdatePlayerHistory ('{correct_id}', '{name_to_insert}', '{team_to_insert}', '{date_in_history}')""")

            # Perform update
            mysql.execute(insert_query)
            print(f"Player successfully inserted.\n")
            
            # Returnt the correct ID
            return correct_id
        
        else:
            return None
########################################################