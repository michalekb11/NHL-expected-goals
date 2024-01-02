import numpy as np

class Baseline:
    """Baseline class for modeling expected goals per NHL game."""
    def __init__(self, y_train) -> None:
        self.target = np.array(y_train)
        self.avg_goals = np.nanmean(self.target)
        self.n_games = len(self.target)
        self.total_goals = np.sum(self.target)

    def get_predictions(self):
        """Returns array of length n_games containing the value avg_goals"""
        return np.repeat(self.avg_goals, self.n_games)
    