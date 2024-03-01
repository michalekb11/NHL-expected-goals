# "Bringing Down the House" - ML Solutions to Conquer a Sportsbook's NHL Sector

### Author: Bryan Michalek

### What is in this repository?
* **00-database-engineering:** Self-architected MySQL database containing ~ 35 tables / views (player statistics, game schedules, model features, odds, etc.).
* **01-data-collection:** Space to workshop new web scraping python scripts to fill the tables listed above. Scripts in their final form are transferred to 06-production.
* **02-feature-engineering:** List of SQL views used to compose over 120 potential features for modeling.
* **03-EDA:** All things exploratory analysis related.
  - Dashboards for tracking feature stability across seasons and examining individual player performance
  - Analysis of feature utility with respect to target variables
  - Investigation of odds data, etc.
* **04-modeling:** Training of ML models (currently contains deep learning attempts).
* **05-evaluation:** Evaluation of ML models. Optimization of parameters regarding which bets to place and which to pass on.
* **06-production:** All scripts in their "final" form (improvements can always be made...).
  - Automated daily web scraping of data from numerous sources
  - Scripts to transfer data from CSV form into MySQL database
  - More to come when modeling is finished...
