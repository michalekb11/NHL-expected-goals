from torch import nn
from torch.utils.data import Dataset
import torch
import pandas as pd

# Define the NN model
class NHLnet(nn.Module):
    def __init__(self, n_features):
        super().__init__()
        self.dropout = nn.Dropout(p=0.2)
        self.relu = nn.ReLU()
        self.softplus = nn.Softplus() # Smooth version of ReLU
        self.fc1 = nn.Linear(n_features, 100)
        self.fc2 = nn.Linear(100, 100)
        self.fc3 = nn.Linear(100, 100)
        self.fc4 = nn.Linear(100, 1)

        # What is batch normalization, and do I need it?
    
    def forward(self, x):
        x = self.fc1(x)
        x = self.relu(x)
        #x = self.dropout(x)
        x = self.fc2(x)
        x = self.relu(x)
        #x = self.dropout(x)
        x = self.fc3(x)
        x = self.relu(x)
        x = self.fc4(x)
        x = self.relu(x) # self.softplus(x)
        return x

# Custom dataset class that takes in features as tensor and targets as any iterable?
class NHL_Dataset(Dataset):
    def __init__(self, features, targets):
        self.features = features
        self.targets = targets
        self.n_features = self.features.shape[1]

    def __len__(self):
        return len(self.features)

    def __getitem__(self, idx):
        sample = self.features[idx]
        target = self.targets[idx]
        return sample, target
    
def prep_for_dataloader(df, index_cols, target_col='G'):
    # Separate all index related information (player name, date, team, etc.)
    index = pd.concat([df.pop(col) for col in index_cols], axis=1)
    # Separate target variable (goals scored in that game)
    targets = torch.tensor(df.pop(target_col), dtype=torch.float32)
    # Convert dataframe of features into tensor
    features = torch.tensor(df.values, dtype=torch.float32)
    return index, features, targets
