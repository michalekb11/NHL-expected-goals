from functions import bet_EV, poisson_goalscorer, odds_to_profit
import pandas as pd
import numpy as np

class GoalscorerBetOptimizer:
    """Find betting restrictions that maximize profit for Anytime Goalscorer"""
    def __init__(self, EV_min_lower=None, EV_max_lower=None, odds_min_lower=None, odds_max_lower=None, odds_min_upper=None, odds_max_upper=None, step_size=3):
        self.EV_min_lower = EV_min_lower
        self.EV_max_lower = EV_max_lower
        self.odds_min_lower = odds_min_lower
        self.odds_max_lower = odds_max_lower
        self.odds_min_upper = odds_min_upper
        self.odds_max_upper = odds_max_upper
        self.step_size = step_size

    def fit(self, df_odds, df_preds, df_G):
        """Create the dataframe to use for optimization (requires our predictions, actual results, and odds)"""
        # Combine all data frammes
        df = pd.merge(left=df_odds, right=df_preds, how='inner', on=['player_id', 'date']).merge(right=df_G, how='inner', on=['player_id', 'date'])
        # Set columns that will be used later
        df['prob'] = df['pred_G'].apply(lambda x: poisson_goalscorer(x))
        df['EV'] = df.apply(lambda row: bet_EV(odds=row['odds'], prob=row['prob']), axis=1)
        df['win_flag'] = np.where(df['G'] >= 1, 1, 0)

        # Set class attributes
        self.df = df
        self.n_pred_rows = df_preds.shape[0]
        self.n_optimization_rows = df.shape[0]
        
    def record_profit(self, EV_lower, odds_lower, odds_upper):
        """Return dictionary describing profit using a set of betting restrictions"""
        if self.df is None:
            raise ValueError("Object's .fit() method must be called before calculating a profit")
        
        # Don't want to actually update self.df
        df_copy = self.df.copy()

        # Decide which wagers to place
        df_copy['place_bet_flag'] = np.where((df_copy['EV'] >= EV_lower) & (df_copy['odds'] >= odds_lower) & (df_copy['odds'] <= odds_upper), 1, 0)

        # Calculate bet-wise profit (if bet not placed, 0 money gained or lost)
        df_copy['profit'] = df_copy.apply(lambda row: np.select(condlist=[row['place_bet_flag'] == 0, row['win_flag'] == 0], choicelist=[0, -1], default=odds_to_profit(row['odds'])), axis=1)

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
                'EV_lower':EV_lower,
                'odds_lower':odds_lower,
                'odds_upper':odds_upper,
                'n_bets_placed':n_bets_placed,
                'pct_bets_placed':pct_bets_placed,
                'profit':profit,
                'avg_profit':avg_profit
            }
        }

        return result_dict

    def optimize(self):
        """Iterate over search space to return optimal betting parameters"""
        if self.df is None:
            raise ValueError("Object's .fit() method must be called before optimizing bet parameters")
        
        # Create the search space
        search_EV_lower = np.linspace(self.EV_min_lower, self.EV_max_lower, num=self.step_size, dtype=float)
        search_min_odds = np.linspace(self.odds_min_lower, self.odds_max_lower, num=self.step_size, dtype=int)
        search_max_odds = np.linspace(self.odds_min_upper, self.odds_max_upper, num=self.step_size, dtype=int)

        # Convert arrays to DataFrames aand cross join for every combination
        search_EV_lower = pd.DataFrame({'EV_lower': search_EV_lower})
        search_min_odds = pd.DataFrame({'odds_lower': search_min_odds})
        search_max_odds = pd.DataFrame({'odds_upper': search_max_odds})
        search_space = pd.merge(search_EV_lower, search_min_odds, how='cross').merge(search_max_odds, how='cross')

        # Apply function to each row
        results_list = list(search_space.apply(lambda row: self.record_profit(row['EV_lower'], row['odds_lower'], row['odds_upper']),  axis=1))
        
        # Combine summary results 
        #bets_df_list = [result_dict['bets_df'] for result_dict in results_list]
        summary_df = pd.DataFrame([result_dict['summary'] for result_dict in results_list])

        # Return summary DF
        return summary_df