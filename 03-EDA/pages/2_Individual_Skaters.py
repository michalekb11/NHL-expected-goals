import streamlit as st
import pandas as pd
import sqlalchemy
import plotly.graph_objects as go 

############# CONFIGURATION #############
# Set wide page layout 
st.set_page_config(page_title='Individual Skaters',
                   layout='wide')

############# DATA LOAD #############
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

############# HEADERS/TITLE #############
# Streamlit app
st.title("Feature exploration")

############# SIDEBAR #############
# Create a sidebar for user input
st.sidebar.title("User Input")

# Drop down to select a metric
metric_list = [col for col in data.columns if '_3' in col]
default_metric = 'G60_3'
selected_metric = st.sidebar.selectbox("Select a metric", metric_list, index=metric_list.index(default_metric))

# Dropdown to select a player
#selected_player = st.selectbox("Select a player", data['id_name'].unique())
selected_players = st.sidebar.multiselect("Select players", data['id_name'].unique(), default=['Connor McDavid - /m/mcdavco01'])

# Drop down to select a season
seasons_list = data['season'].unique().tolist()
default_season = data['season'].max()
selected_season = st.sidebar.radio("Select a season", seasons_list, index=seasons_list.index(default_season))

############# DATA FILTERING #############
# Filter the DataFrame based on the selected player
#filtered_df = data[data['player_id'] == selected_player]
filtered_df = data[(data['id_name'].isin(selected_players)) & (data['season'] == selected_season)]

############# PLOTS #############
# Create a line plot with points for the selected players
fig = go.Figure()

for player in selected_players:
    try:
        player_data = filtered_df[filtered_df['id_name'] == player]
        fig.add_trace(go.Scatter(
                        x=player_data['date'],
                        y=player_data[selected_metric],
                        mode='lines+markers',
                        name=player_data['name'].iloc[0]
                    )
        )
    except IndexError as e:
        # No data was found for that player/season...etc
        continue

fig.update_layout(
    title='Rolling window: 3',
    xaxis_title='Date',
    yaxis_title=selected_metric,
    legend=dict(title='Player Names')
)

st.plotly_chart(fig)