import streamlit as st
import pandas as pd
import plotly.express as px
import sqlalchemy
import plotly.graph_objects as go 

# Set wide page layout 
st.set_page_config(layout='wide')

@st.cache_data
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

# Load data into streamlit cache
data = load_data()

# Streamlit app
st.title("Feature exploration")

# Create a sidebar for user input
st.sidebar.title("User Input")

# Dropdown to select a player
#selected_player = st.selectbox("Select a player", data['id_name'].unique())
selected_players = st.sidebar.multiselect("Select players", data['id_name'].unique())

# Drop down to select a season
selected_season = st.sidebar.radio("Select a season", data['season'].unique())

# Filter the DataFrame based on the selected player
#filtered_df = data[data['player_id'] == selected_player]
filtered_df = data[(data['id_name'].isin(selected_players)) & (data['season'] == selected_season)]

# Create a line plot with points for the selected players
fig = go.Figure()

for player in selected_players:
    try:
        player_data = filtered_df[filtered_df['id_name'] == player]
        fig.add_trace(go.Scatter(
                        x=player_data['date'],
                        y=player_data['S60_3'],
                        mode='lines+markers',
                        name=player_data['name'].iloc[0]
                    )
        )
    except IndexError as e:
        # No data was found for that player/season...etc
        continue

fig.update_layout(
    title='Shots per 60 (rolling 3)',
    xaxis_title='Date',
    yaxis_title='Shots per 60',
    legend=dict(title='Player Names')
)

# Display the plot
st.plotly_chart(fig)

