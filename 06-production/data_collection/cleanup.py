# All functions required for data cleanup before inserting into database
########################################################
# Libraries
import numpy as np
import pandas as pd
import sqlalchemy
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
def match_name_to_id(name, mysql_engine, team=None, age=None, date_in_history=None):
    """Find a matching player ID (or enter the correct ID) using player history table"""
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
    WHERE name = '{name}'
    {team_where_clause}
    {age_where_clause}
    {date_in_history_where_clause}
    ;
    """

    # Try query using all available information
    potential_ids = pd.read_sql(query, con=mysql_engine).values.flatten()

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
            potential_ids = pd.read_sql(query, con=mysql_engine).values.flatten()

            # If match, break away
            if potential_ids.size > 0:
                break

    # Print the final query that was used to the user:
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
            print(f"Enter the folling player information to be inserted into player history table.\n")
            team_to_insert = input('Team (3 letter code): ')
            date_to_insert = input("Date in history (ex: '2023-01-01'): ")
            dob_to_insert = input("Date of birth: ")

            # Insert information into player history by calling stored procedure
            insert_query = sqlalchemy.text(f"""
                INSERT INTO player_history (player_id, start_date, name, dob, team)
                VALUES ('{correct_id}', '{date_to_insert}', '{name}', '{dob_to_insert}', '{team_to_insert}');
            """)

            # Perform update
            with mysql_engine.begin() as conn: 
                conn.execute(insert_query)
                print(f"Player successfully inserted.\n")
            
            # Returnt the correct ID
            return correct_id
        
        else:
            return None
########################################################