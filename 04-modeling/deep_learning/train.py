import torch
import pandas as pd
from model import NHL_Dataset, NeuralNetwork
from torch.utils.data import DataLoader

# Set parameters
device = 'cuda' if torch.cuda.is_available() else 'cpu'
epochs = 2
batch_size = 32
learning_rate = 0.01

# Import data into pandas dataframe from SQL

# Separate all index related information (player name, date, team, etc.)

# Separate target variable (goals scored in that game)

# Convert dataframe of features into tensor

# Set custom dataset class
train_data = NHL_Dataset(features=features, targets=targets)

# Set up the data loader
dataloader = DataLoader(dataset=train_data, batch_size=batch_size, shuffle=True)

# Set up mode, optimizer, loss function
model = NeuralNetwork(n_features=train_data.n_features)
#optimizer = 
# criterion = 

# Set up a train loop that occurs once per epoch
def train_loop(dataloader, model, loss_fn, optimizer):
    # Set to training mode
    model.train()

    # Iterate through each batch
    for batch, (X, y) in enumerate(dataloader):
        # Compute predictions

        # Compute loss

        # Backpropagation

        # Every ___ batches, print the current loss as a message


# Set up a test loop that occurs once per epoch
def test_loop(dataloader, model, loss_fn):
    # Set to eval mode
    model.eval()

    # Ensure no gradients are computed

        # For each batch, get predictions, compute loss and any other metrics
    
    # Print message about the test loss

# For each epoch
for i in range(epochs):
    print(f'Epoch {i}===================')
    # Run the train loop

    # Run the test loop

print("Training complete.")