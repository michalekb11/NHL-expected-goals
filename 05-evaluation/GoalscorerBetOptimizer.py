from functions import bet_EV, poisson_goalscorer, odds_to_profit
import pandas as pd
import numpy as np

class GoalscorerBetOptimizer:
    def __init__(self, search_EV_min_lower=None, search_odds_lower=None, search_odds_upper=None):
        self.search_EV_min_lower = search_EV_min_lower
        self.search_odds_lower = search_odds_lower
        self.search_odds_upper = search_odds_upper

    def fit(self, df_odds, df_preds, df_G):
        df = pd.merge(left=df_odds, right=df_preds, how='inner', on=['player_id', 'date']).merge(right=df_G, how='inner', on=['player_id', 'date'])
        df['prob'] = df['pred_G'].apply(lambda x: poisson_goalscorer(x))
        df['EV'] = df.apply(lambda row: bet_EV(odds=row['odds'], prob=row['prob']), axis=1)
        df['win_flag'] = np.where(df['G'] >= 1, 1, 0)

        self.df = df
        self.n_pred_rows = df_preds.shape[0]
        self.n_optimization_rows = df.shape[0]
        
    def record_profit(self, EV_lower, odds_lower, odds_upper):
        if self.df is None:
            raise ValueError("Object's .fit() method must be called before calculating a profit")
        
        df_copy = self.df.copy()

        # Decide which wagers to place
        df_copy['place_bet_flag'] = np.where((df_copy['EV'] >= EV_lower) & (df_copy['odds'] >= odds_lower) & (df_copy['odds'] <= odds_upper), 1, 0)

        # Calculate bet-wise profit (if bet not placed, 0 money gained or lost)
        df_copy['profit'] = df_copy.apply(lambda row: np.select(condlist=[row['place_bet_flag'] == 0, row['win_flag'] == 0], choicelist=[0, -1], default=odds_to_profit(row['odds'])), axis=1)


        n_bets_placed = len(df_copy[df_copy['place_bet_flag'] == 1])
        profit = df_copy['profit'].sum()
        avg_profit = profit / n_bets_placed

        result_dict = {
            'df':df_copy,
            'EV_lower':EV_lower,
            'odds_lower':odds_lower,
            'odds_upper':odds_upper,
            'n_bets_placed':n_bets_placed,
            'profit':profit,
            'avg_profit':avg_profit
        }

        return result_dict

    def optimize(self, verbose=False):
        if self.df is None:
            raise ValueError("Object's .fit() method must be called before optimizing bet parameters")
        
        # Create the search space
        odds_space = np.linspace(self.search_odds_lower, self.search_odds_upper, num = 4, dtype=int)
        print(odds_space)

    

# We want it to choose the best EV lower threshold, odds upper and lower threshold FROM THE USER DEFINED SEARCH SPACE
# We want to be able to call an optimize method that returns a tuple of the best thresholds?
# Allow a verbose option that writes out results of each combination to a result file (or just return as pandas DF for now)


# Needs to:
    # Read in the validation set predictions (player_id, date, xG)
    # Read in the actual validation results (player_id, date, G)
    # Read in odds data