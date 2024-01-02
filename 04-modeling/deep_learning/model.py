from torch import nn
from torch.utils.data import Dataset

class NeuralNetwork(nn.Module):
    def __init__(self, n_features):
        super().__init__()
        self.dropout = nn.Dropout(p=0.2)
        self.relu = nn.ReLU()
        self.fc1 = nn.Linear(n_features, 100)
        self.fc2 = nn.Linear(100, 50)
        self.fc3 = nn.Linear(50, 1)
    
    def forward(self, x):
        x = self.fc1(x)
        x = self.relu(x)
        x = self.dropout(x)
        x = self.fc2(x)
        x = self.relu(x)
        x = self.dropout(x)
        x = self.fc3(x)
        return x

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
