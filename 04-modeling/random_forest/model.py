import pandas as pd
import numpy as np

def prep_for_forest(df, index_cols, target_col='G_flag'):
    # Separate all index related information (player name, date, team, etc.)
    index = pd.concat([df.pop(col) for col in index_cols], axis=1)
    # Separate target variable (goals scored in that game)
    targets = np.array(df.pop(target_col))
    # Convert dataframe of features into numpy array
    features = df.values
    return index, features, targets