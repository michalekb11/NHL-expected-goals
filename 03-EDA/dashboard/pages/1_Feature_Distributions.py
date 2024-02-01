# Libraries
import streamlit as st
from Introduction import load_data
import plotly.graph_objects as go
from plotly.subplots import make_subplots

############# CONFIGURATION #############
# Set wide page layout 
st.set_page_config(page_title='Feature Distributions',
                   layout='wide')

############# DATA LOAD #############
# Load data into streamlit cache
data = load_data()

############# HEADERS/TITLE #############
# Streamlit app
st.title("Seasonal Distributions")

############# SIDEBAR #############
# Create a sidebar for user input
st.sidebar.title("User Input")

# Drop down to select a metric
metric_list = [col for col in data.columns if '_20' in col]
default_metric = 'SV60_20' # 'G60_3'
selected_metric = st.sidebar.selectbox("Select a metric", metric_list, index=metric_list.index(default_metric))

############# PLOTS #############
# Create a Plotly histogram for each season
seasons = data['season'].unique()

# Create subplots
fig = make_subplots(rows=len(seasons), cols=1, shared_xaxes=True, shared_yaxes=True)

# Create histograms for each season
for i, season in enumerate(seasons):
    season_data = data[(data['season'] == season) & (data[selected_metric] != 0)]
    
    # Create a histogram trace with specified alpha
    trace = go.Histogram(
        x=season_data[selected_metric],
        opacity=0.5,
        name=str(season),
        histnorm='probability'
    )
    
    # Add the histogram trace to the subplot
    fig.add_trace(trace, row=i + 1, col=1)

# Update subplot layout
fig.update_layout(
    showlegend=True,
    yaxis=dict(title="Density"), 
    height=700
)

# Display the Plotly subplot in Streamlit
st.plotly_chart(fig)