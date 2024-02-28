import pandas as pd
import numpy as np
from functions import poisson_goalscorer, bet_EV, odds_to_profit

class GoalscorerBetEvaluator:
    """Evaluate optimal betting parameters on test set"""
    def __init__(self, EV_lower, odds_lower, odds_upper):
        self.EV_lower = EV_lower
        self.odds_lower = odds_lower
        self.odds_upper = odds_upper

    def fit(self, df_odds, df_preds, df_G):
        """Create the dataframe to use for optimization (requires our predictions, actual results, and odds)"""
        # Combine all data frames
        df = pd.merge(left=df_odds, right=df_preds, how='inner', on=['player_id', 'date']).merge(right=df_G, how='inner', on=['player_id', 'date'])
        # Set columns that will be used later
        #df['prob'] = df['pred_G'].apply(lambda x: poisson_goalscorer(x))
        df['EV'] = df.apply(lambda row: bet_EV(odds=row['odds'], prob=row['prob']), axis=1)
        df['G_flag'] = df['G_flag'].astype('int') # np.where(df['G'] >= 1, 1, 0)

        # Set class attributes
        self.df = df
        self.n_pred_rows = df_preds.shape[0]
        self.n_betting_rows = df.shape[0]

    def record_profit(self):
        """Return dictionary describing profit using a set of betting restrictions"""
        if self.df is None:
            raise ValueError("Object's .fit() method must be called before calculating a profit")
        
        # Don't want to actually update self.df
        df_copy = self.df.copy()

        # Decide which wagers to place
        df_copy['place_bet_flag'] = np.where((df_copy['EV'] >= self.EV_lower) & (df_copy['odds'] >= self.odds_lower) & (df_copy['odds'] <= self.odds_upper), 1, 0)

        # Calculate bet-wise profit (if bet not placed, 0 money gained or lost)
        df_copy['profit'] = df_copy.apply(lambda row: np.select(condlist=[row['place_bet_flag'] == 0, row['G_flag'] == 0], choicelist=[0, -1], default=odds_to_profit(row['odds'])), axis=1)

        # Save some interesting information as part of summary
        n_bets_placed = len(df_copy[df_copy['place_bet_flag'] == 1])
        pct_bets_placed = n_bets_placed / df_copy.shape[0]
        if n_bets_placed == 0:
            profit = None
            avg_profit = None
        else:  
            profit = df_copy['profit'].sum()
            avg_profit = profit / n_bets_placed

        # Create and return the summary dictionary
        result_dict = {
            'bets_df':df_copy,
            'summary':{
                'EV_lower':self.EV_lower,
                'odds_lower':self.odds_lower,
                'odds_upper':self.odds_upper,
                'n_bets_placed':n_bets_placed,
                'pct_bets_placed':pct_bets_placed,
                'profit':profit,
                'avg_profit':avg_profit
            }
        }

        return result_dict