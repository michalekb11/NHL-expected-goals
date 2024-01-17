import pandas as pd
from selenium import webdriver
from selenium.webdriver.common.by import By
import json
import datetime as dt
import os
import time
import argparse
from functions import clean_name


def main():
    # Initialize parser
    parser = argparse.ArgumentParser()

    # Adding optional argument
    parser.add_argument("-v", "--Verbose", action='store_true', help = "Print status updates during execution.")
    
    # Read arguments from command line
    args = parser.parse_args()

    # Path to injury data
    path_to_rw = './data/daily/RW_injuries.csv'

    # Specifiy the URL where injury information is located
    roto_url = 'https://www.rotowire.com/hockey/injury-report.php'

    # Read in team name to 3 letter code dictionary
    with open('./data/team_name_dictionary.txt', 'r') as f:
        team_name_dict = json.load(f)

    # Record current date and time
    dt_now = dt.datetime.now()
    date_recorded = dt_now.date()
    time_recorded = dt_now.time().strftime(format = '%H:%M:%S')

    # Create a new instance of the Chrome driver
    options = webdriver.ChromeOptions()
    options.add_argument('headless=new')
    driver = webdriver.Chrome(options=options)

    # Navigate to the url
    driver.get(roto_url)
    if args.Verbose: print('URL successfully located. Waiting a few seconds to download CSV.\n')
    time.sleep(4)

    # Locate the "CSV" button by its HTML class and click on it
    driver.find_element(By.CLASS_NAME, 'export-button.is-csv').click()
    if args.Verbose: print('CSV successfully downloaded. Waiting a few seconds to close webdriver.\n')
    time.sleep(4)

    # Close the driver
    driver.quit()

    # Read in the CSV file from the default download location
    injuries = pd.read_csv('~/Downloads/nhl-injury-report.csv')
    os.system('rm ~/Downloads/nhl-injury-report.csv')

    # Drop columns we don't need
    injuries.drop(columns = ['Pos', 'Est. Return', 'Next Game (EST)'], inplace=True)

    # Rename remaining columns
    injuries.rename(columns={'Player':'name', 'Team':'team', 'Injury':'type', 'Status':'status'}, inplace=True)

    # Clean player names
    injuries['name'] = injuries['name'].apply(clean_name)

    # Convert team to 3-letter code
    injuries['team'] = injuries['team'].str.lower().replace(team_name_dict)

    # Lowercase for injury type
    injuries['type'] = injuries['type'].str.lower().str.strip()

    # Convert injury status to code
    injuries.loc[injuries['status'] == 'Out', 'status'] = 'O'
    injuries.loc[injuries['status'] == 'Day-To-Day', 'status'] = 'DTD'

    # Add columns for date and time of recording
    injuries['date_recorded'] = date_recorded
    injuries['time_recorded'] = time_recorded

    # Player id column
    injuries['player_id'] = None

    # Set correct column order
    injuries = injuries[['player_id', 'name', 'team', 'date_recorded', 'time_recorded', 'type', 'status']]

    # Update CSV
    try:
        old_injuries = pd.read_csv(path_to_rw)
        updated_injuries = pd.concat([old_injuries, injuries], axis=0).reset_index(drop=True)
        updated_injuries.to_csv(path_to_rw, header=True, index=False)
        print(f'RW injury CSV successfully updated.\nNumber of rows added: {len(injuries)}\nNew total row count: {len(updated_injuries)}\n')
    except:
        print('RW injury CSV was not updated.\n')
        raise

if __name__ == '__main__':
    print("==========================================================\nStarting RW Injury Scrape\n")
    main()
    print("End RW Injury Scrape\n==========================================================")