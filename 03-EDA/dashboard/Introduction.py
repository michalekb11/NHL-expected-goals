# Libraries
import streamlit as st
import sqlalchemy
import pandas as pd

@st.cache_data()
def load_data():
    # Create the engine to connect to the MySQL database
    engine = sqlalchemy.create_engine('mysql+mysqlconnector://root:root@localhost/nhl')

    # Queries
    # Names
    names_query = "SELECT DISTINCT player_id, name, date FROM skater_games;"

    # Season
    season_query = 'SELECT DISTINCT date, season FROM schedule;'

    # Skater per60's
    sk3_query = "SELECT * FROM skater_per60_rolling3;"

    # Run queries
    names = pd.read_sql(names_query, con=engine)
    seasons = pd.read_sql(season_query, con=engine)
    sk3 = pd.read_sql(sk3_query, con=engine)

    # Example feature set
    feature_set = pd.merge(names, sk3, how='left', on=['player_id', 'date']).merge(seasons, how='left', on='date')

    # Add name + ID column
    feature_set['id_name'] = feature_set['name'] + " - " + feature_set["player_id"]

    return feature_set

def main():
    # Page configuration
    st.set_page_config(
        page_title="Dashboard Main",
        layout="wide"
    )

    # Write introductory statement
    st.write("""
            # Introduction
            Hey how are ya.
            """)

    # Prompt user to select the page they want
    st.sidebar.success("Select a page above.")

if __name__ == "__main__":
    main()