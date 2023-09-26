# Libraries
import streamlit as st

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

def hey():
    print('hey')
    return