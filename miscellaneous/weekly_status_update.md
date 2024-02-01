# Capstone Weekly Status Updates
### Fast Lookup
[Week 1](#week-1) | [Week 2](#week-2) | [Week 3](#week-3) | [Week 4](#week-4) | [Week 5](#week-5)

[Week 6](#week-6) | [Week 7](#week-7) | [Week 8](#week-8) | [Week 9](#week-9) | [Week 10](#week-10) 

[Week 11](#week-11) | [Week 12](#week-12) | [Week 13](#week-13) | [Week 14](#week-14) | [Week 15](#week-15) 

[Week 16](#week-16) | [Week 17](#week-17) | [Week 18](#week-18) | [Week 19](#week-19) | [Week 20](#week-20) 

[Week 21](#week-21) | [Week 22](#week-22) | [Week 23](#week-23) | [Week 24](#week-24) | [Week 25](#week-25) 

## Week 1 (09/11/23 - 09/17/23) <a name="week-1"></a>
* Created production python files for 3 web scrape scripts (DF lines, RW injuries, and DK game odds)
   - Results will be saved in CSVs. Some basic validations in place, but could be improved. Error handling could be improved.

## Week 2 (09/18/23 - 09/24/23) <a name="week-2"></a>
* Wrote SQL views for the following potential features
   - Point streak
   - Home/away status
   - Team change flag (in last 5 or 10 games)
 
## Week 3 (09/25/23 - 10/01/23) <a name="week-3"></a>
* Created streamlit dashboard with 2 pages 
   - Page 1 = visualizing feature distributions and feature stability across seasons
   - Page 2 = individual skater statistics as a time series throughout the season
* Created function to clean player names (ones with special characters etc. to standardize names across data sources)

## Week 4 (10/02/23 - 10/08/23) <a name="week-4"></a>
* Wrote web scrape script for projected goalies on daily faceoff
* Wrote web scrape script to record 60 minute line from draft kings
* Improved error handling in production files and tested web scrape scripts

## Week 5 (10/09/23 - 10/15/23) <a name="week-5"></a>
* Fixed scraping bugs that arose following opening day of the season
* Wrote web scrape script for anytime goalscorer odds

## Week 6 (10/16/23 - 10/22/23) <a name="week-6"></a>
* Fixed scraping bugs that arose following opening day of the season
* Wrote web scrape script for anytime goalscorer odds

## Week 7 (10/24/23 - 10/29/23) <a name="week-7"></a>
* Daily scrapes
* Fall break

## Week 8 (10/30/23 - 11/05/23) <a name="week-8"></a>
* Daily scrapes

## Week 9 (11/06/23 - 11/12/23) <a name="week-9"></a>
* Daily scrapes

## Week 10 (11/13/23 - 11/19/23) <a name="week-10"></a>
* Daily scrapes

## Week 11 (11/20/23 - 11/26/23) <a name="week-11"></a>
* Daily scrapes
* Bug fixes in Draftkings scrape after website changed

## Week 12 (11/27/23 - 12/03/23) <a name="week-12"></a>
* Daily scrapes
* Created report for feature selection (filter methods) for continuous features (statistical measures, plots)
* Began similar report for categorical/binary/ordinal features

## Week 13 (12/04/23 - 12/10/23) <a name="week-13"></a>
* Daily scrapes

## Week 14 (12/11/23 - 12/17/23) <a name="week-14"></a>
* Daily scrapes

## Week 15 (12/18/23 - 12/24/23) <a name="week-15"></a>
* Daily scrapes
* Created goalie assignment view that assigns goalies a priority for each game (chooses 1 per game)
* Updates to continuous feature report

## Week 16 (12/25/23 - 12/31/23) <a name="week-16"></a>
* Daily scrapes
* Ran the reports for continous and discrete features (as well as creating excel workbooks highlighting some results)
* Small bug fixes to scraping functions

## Week 17 (01/01/24 - 01/07/24) <a name="week-17"></a>
* Daily scrapes
* Created a baseline object class for modeling
* Wrote template PyTorch code required to train regression neural network
* (Ran into issues with MySQL crashing)

## Week 18 (01/08/24 - 01/14/24) <a name="week-18"></a>
* Daily scrapes
* Tested a new MySQL database connection using SQLAce (mac application) instead of workbench
* Redesign of entire database architecture to account for more tables and types of data that have been scraped

## Week 19 (01/15/24 - 01/21/24) <a name="week-19"></a>
* Daily scrapes
* Wrote function to gather DOB from hockey reference using player id
* Completed new database ER diagram
* Wrote stored procedure to handle inserts/upserts into new player_history table
* Forward engineered all tables
* Updated feature views to account for new tables
* Fixed a duplicate key issue for lineups table where same player plays on multiple PP or PK units
* Wrote function to match a player name to a player ID
* Wrote production code to scrape daily game schedules and insert directly into MySQL database
* Made all insertions into game_id, schedule, ml/pl/total odds, regulation odds, player_history, goalscorer odds, projected lineups, projected goalie, and injury tables

## Week 20 (01/22/24 - 01/28/24) <a name="week-20"></a>
* Daily scrapes
* Performed k-means clustering on skaters to identify 3 types of players
* Investigated why rolling20 player stats are more correlated with G than rolling 3, 5, etc.
* Investigated how much of an impact ice time affects rolling 20 stats

## Week 21 (01/29/24 - 02/04/24) <a name="week-21"></a>
* Daily scrapes
* Had to completely re-clone repo and re-install virtual environment due to problem with laptop (lots of errors reinstalling packages)
* Calculated population stability index (PSI) for all continuous features to measure feature stability
* Investigated features that seemed to be unstable across seasons
* Moved all local data to outside of the GitHub repo

## Week 22 (02/05/24 - 02/11/24) <a name="week-22"></a>
* Daily scrapes

## Week 23 (02/12/24 - 02/18/24) <a name="week-23"></a>
* Daily scrapes


