import streamlit as st
import pandas as pd
import sqlalchemy
import plotly.graph_objects as go 

############# CONFIGURATION #############
# Set wide page layout 
st.set_page_config(page_title='Feature Distributions',
                   layout='wide')

############# DATA LOAD #############
@st.cache_data
def load_data():
    # Create the engine to connect to the MySQL database
    engine = sqlalchemy.create_engine('mysql+mysqlconnector://root:root@localhost/nhl')

    # Queries
    # Names
    names_query = "SELECT DISTINCT player_id, name, date FROM skater_games;"

    # Run queries
    names = pd.read_sql(names_query, con=engine)

    return names

# Load data into streamlit cache
data = load_data()

############# HEADERS/TITLE #############
# Streamlit app
st.title("Feature Distributions")

############# SIDEBAR #############
# Create a sidebar for user input
st.sidebar.title("User Input")

# Drop down to select a metric
metric_list = [col for col in data.columns if '_3' in col]
default_metric = 'G60_3'
selected_metric = st.sidebar.selectbox("Select a metric", metric_list, index=metric_list.index(default_metric))


############# DATA FILTERING #############
# Filter the DataFrame based on 


############# PLOTS #############
# 