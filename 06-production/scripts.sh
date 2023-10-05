cd /Users/bryanmichalek/Documents/GitHub_Personal/sports_betting_repo/

source .venv/bin/activate 

python 06-production/web_scrape_game_line_odds.py
python 06-production/web_scrape_DF_line_combos.py -v -t
python 06-production/web_scrape_DF_goalies.py -v -t
python 06-production/web_scrape_rotowire_injury.py -v