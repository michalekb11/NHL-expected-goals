# Change to the repo root directory
cd /Users/bryanmichalek/Documents/GitHub_Personal/sports_betting_repo/

# Activate virtual environment
source .venv/bin/activate

# Run PSI script
# Skaters per 60 (3, 5, 10, 15, 20)
echo "Starting skater per 60"

python 03-EDA/feature_analysis/continuous/psi_calculation.py -t skater_per60_rolling03 -f G60_03 A60_03 P60_03 rating60_03 PIM60_03 EVG60_03 PPG60_03 SHG60_03 GWG60_03 EVA60_03 PPA60_03 SHA60_03 S60_03 shifts60_03 HIT60_03 BLK60_03 FOW60_03 FOL60_03 avgTOI_03
echo "03 finished"

python 03-EDA/feature_analysis/continuous/psi_calculation.py -t skater_per60_rolling05 -f G60_05 A60_05 P60_05 rating60_05 PIM60_05 EVG60_05 PPG60_05 SHG60_05 GWG60_05 EVA60_05 PPA60_05 SHA60_05 S60_05 shifts60_05 HIT60_05 BLK60_05 FOW60_05 FOL60_05 avgTOI_05
echo "05 finished"

python 03-EDA/feature_analysis/continuous/psi_calculation.py -t skater_per60_rolling10 -f G60_10 A60_10 P60_10 rating60_10 PIM60_10 EVG60_10 PPG60_10 SHG60_10 GWG60_10 EVA60_10 PPA60_10 SHA60_10 S60_10 shifts60_10 HIT60_10 BLK60_10 FOW60_10 FOL60_10 avgTOI_10
echo "10 finished"

python 03-EDA/feature_analysis/continuous/psi_calculation.py -t skater_per60_rolling15 -f G60_15 A60_15 P60_15 rating60_15 PIM60_15 EVG60_15 PPG60_15 SHG60_15 GWG60_15 EVA60_15 PPA60_15 SHA60_15 S60_15 shifts60_15 HIT60_15 BLK60_15 FOW60_15 FOL60_15 avgTOI_15
echo "15 finished"

python 03-EDA/feature_analysis/continuous/psi_calculation.py -t skater_per60_rolling20 -f G60_20 A60_20 P60_20 rating60_20 PIM60_20 EVG60_20 PPG60_20 SHG60_20 GWG60_20 EVA60_20 PPA60_20 SHA60_20 S60_20 shifts60_20 HIT60_20 BLK60_20 FOW60_20 FOL60_20 avgTOI_20
echo "20 finished"

# Skater point streak
echo "Starting point streak"
python 03-EDA/feature_analysis/continuous/psi_calculation.py -t point_streak -f point_streak

# Rest days
echo "Starting rest days"
python 03-EDA/feature_analysis/continuous/psi_calculation.py -t rest_days -f rest_days

# Games missed
echo "Starting games missed"
python 03-EDA/feature_analysis/continuous/psi_calculation.py -t games_missed -f games_missed

# Goalies per 60 (3, 5, 10, 15, 20)
echo "Starting goalie per60"
python 03-EDA/feature_analysis/continuous/psi_calculation.py -g -t goalie_per60_rolling03 -f GA60_03 SA60_03 SV60_03 SVpct_03 avgTOI_03
echo "03 finished"

python 03-EDA/feature_analysis/continuous/psi_calculation.py -g -t goalie_per60_rolling05 -f GA60_05 SA60_05 SV60_05 SVpct_05 avgTOI_05
echo "05 finished"

python 03-EDA/feature_analysis/continuous/psi_calculation.py -g -t goalie_per60_rolling10 -f GA60_10 SA60_10 SV60_10 SVpct_10 avgTOI_10
echo "10 finished"

python 03-EDA/feature_analysis/continuous/psi_calculation.py -g -t goalie_per60_rolling15 -f GA60_15 SA60_15 SV60_15 SVpct_15 avgTOI_15
echo "15 finished"

python 03-EDA/feature_analysis/continuous/psi_calculation.py -g -t goalie_per60_rolling20 -f GA60_20 SA60_20 SV60_20 SVpct_20 avgTOI_20
echo "20 finished"