# Convert jupyter notebooks to .py scripts for production
# Set directory to be git repo root folder
cd /Users/bryanmichalek/Documents/GitHub_Personal/sports_betting_repo

# Activate virtual environment (may not be needed?)
source ./.venv/bin/activate

# Convert data collection notebooks to .py scripts
odds_nb="01-data-collection/daily/web_scrape_odds.ipynb"
df_nb="01-data-collection/daily/web_scrape_DF_line_combos.ipynb"
rw_nb="01-data-collection/daily/web_scrape_rotowire_injury.ipynb"


jupyter nbconvert --to python "$odds_nb" "$df_nb" "$rw_nb"

mv ./01-data-collection/daily/*.py ./06-production/

