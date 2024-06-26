# Libraries
import sqlalchemy
import pickle
import pandas as pd

class MySQL:
    """Class to connect and interact with MySQL database"""
    def __init__(self, user='root', password='rootdata', schema='nhl') -> None:
        self.user = user
        self.password = password
        self.schema = schema
        self.engine = None

    def connect(self):
        # Create the engine to connect to the MySQL database
        self.engine = sqlalchemy.create_engine(f'mysql+mysqlconnector://{self.user}:{self.password}@localhost/{self.schema}')
        return

    def execute(self, query):
        with self.engine.begin() as conn: 
            conn.execute(query)

    def load_data(self, reset=False):
        cache_dir = '/Users/bryanmichalek/Documents/GitHub_Personal/sports_betting_repo/04-modeling/data_cache'
        try:
            if reset:
                raise FileNotFoundError
            # Try loading the DataFrame from the cache file
            with open(f'{cache_dir}/train.pkl', 'rb') as f:
                train_df = pickle.load(f)
            with open(f'{cache_dir}/validation.pkl', 'rb') as f:
                val_df = pickle.load(f)
            with open(f'{cache_dir}/test.pkl', 'rb') as f:
                test_df = pickle.load(f)
            print('Found cached datasets.')

            # Assign attributes for access to data
            self.train_df = train_df
            self.val_df = val_df
            self.test_df = test_df

        except FileNotFoundError:
            # Set up SQL queries to gather features
            print("Gathering data from MySQL...")
            skater = pd.read_sql("""
                SELECT a.player_id,
                    a.team,
                    a.opponent,
                    a.date,
                    a.game_num,
                    CASE WHEN a.G >= 1 THEN 1 ELSE 0 END AS G_flag,
                    b.season
                FROM skater_game a
                INNER JOIN schedule b
                    ON a.team = b.team
                    AND a.date = b.date
                WHERE b.season >= 2017;
            """, con=self.engine)
            home_away = pd.read_sql("SELECT * FROM home_away_status;", con=self.engine)
            point_streak = pd.read_sql("SELECT * FROM point_streak;", con=self.engine)
            rest_days = pd.read_sql('SELECT * FROM rest_days;', con=self.engine)
            games_missed = pd.read_sql("SELECT * FROM games_missed", con=self.engine)
            skater60 = pd.read_sql("""
                SELECT player_id,
                    date,
                    G60_last_season,
                    resid_G60_05,
                    P60_last_season,
                    resid_P60_05,
                    S60_last_season,
                    resid_S60_05,
                    BLK60_last_season,
                    resid_BLK60_05,
                    HIT60_last_season,
                    resid_HIT60_05,
                    avgTOI_last_season,
                    resid_avgTOI_05
                FROM skater_per60_resid_rolling05;
            """, con=self.engine)
            goalie60 = pd.read_sql("""
                SELECT 
                    -- groll.player_id,  -- technically don't need, since there is only 1 unique row for each team/date after joining with ag
	                ag.team AS opponent, -- renaming so that joins are easier
                    groll.`date`,
                    groll.GA60_05,
                    groll.SA60_05,
                    groll.Svpct_05
                FROM goalie_per60_rolling05 groll
                INNER JOIN assigned_goalie ag
                    ON groll.player_id = ag.player_id
                    AND groll.date = ag.date;
            """, con=self.engine)

            # Merge features to create pandas DF
            train_df = skater.loc[skater['season'] <= 2022, :].merge(skater60, how='inner', on=['player_id', 'date']
                ).merge(goalie60, how='inner', on=['opponent', 'date']
                ).merge(home_away, how='inner', on=['player_id', 'date']
                ).merge(point_streak, how='inner', on=['player_id', 'date']
                ).merge(rest_days, how='inner', on=['player_id', 'date']
                ).merge(games_missed, how='inner', on=['player_id', 'date'])

            val_df = skater.loc[skater['season'] == 2023, :].merge(skater60, how='inner', on=['player_id', 'date']
                ).merge(goalie60, how='inner', on=['opponent', 'date']
                ).merge(home_away, how='inner', on=['player_id', 'date']
                ).merge(point_streak, how='inner', on=['player_id', 'date']
                ).merge(rest_days, how='inner', on=['player_id', 'date']
                ).merge(games_missed, how='inner', on=['player_id', 'date'])
            
            test_df = skater.loc[skater['season'] == 2024, :].merge(skater60, how='inner', on=['player_id', 'date']
                ).merge(goalie60, how='inner', on=['opponent', 'date']
                ).merge(home_away, how='inner', on=['player_id', 'date']
                ).merge(point_streak, how='inner', on=['player_id', 'date']
                ).merge(rest_days, how='inner', on=['player_id', 'date']
                ).merge(games_missed, how='inner', on=['player_id', 'date'])
            
            # Save the DataFrames to the cache file
            with open(f'{cache_dir}/train.pkl', 'wb') as f:
                pickle.dump(train_df, f)
            with open(f'{cache_dir}/validation.pkl', 'wb') as f:
                pickle.dump(val_df, f)
            with open(f'{cache_dir}/test.pkl', 'wb') as f:
                pickle.dump(test_df, f)
            
            # Assign attributes for access to data
            self.train_df = train_df
            self.val_df = val_df
            self.test_df = test_df
