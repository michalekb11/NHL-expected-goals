# Change to the repo root directory
cd /Users/bryanmichalek/Documents/GitHub_Personal/sports_betting_repo/

# Activate virtual environment
source .venv/bin/activate 

# Run each web scrape script
python 06-production/data_collection/web_scrape_schedule.py -v -N 2 2024
python 06-production/data_collection/web_scrape_game_line_odds.py
python 06-production/data_collection/web_scrape_60min_odds.py -t
python 06-production/data_collection/web_scrape_anytime_scorer_odds.py -v -t
python 06-production/data_collection/web_scrape_DF_line_combos.py -v -t
python 06-production/data_collection/web_scrape_DF_goalies.py -v -t
python 06-production/data_collection/web_scrape_rotowire_injury.py -v