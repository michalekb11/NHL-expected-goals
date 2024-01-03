import torch
import pandas as pd
from model import NHL_Dataset, NeuralNetwork, prep_for_dataloader
from torch.utils.data import DataLoader
from tqdm import tqdm

############# Set model parameters #############
########################################################
output_model_name = './04-modeling/deep_learning/models/network1.pth'
device = 'cuda' if torch.cuda.is_available() else 'cpu'
epochs = 10
batch_size = 8
learning_rate = 0.005

############# Gather features into dataset #############
########################################################
# Set up SQL queries to gather features
train_query = """"""
test_query = """"""

# Import data into pandas dataframe from SQL
#train_df = pd.read_sql(train_query)
#test_df = pd.read_sql(test_query)

# FOR TESTING PURPOSES  ONLY
train_df = pd.read_csv('~/Desktop/train.csv')
test_df = pd.read_csv('~/Desktop/test.csv')

# Separate index info from features from targets (convert features and targets to tensors as well)
train_index, train_features, train_targets = prep_for_dataloader(train_df)
test_index, test_features, test_targets = prep_for_dataloader(test_df)

# Set custom dataset class
train_data = NHL_Dataset(features=train_features, targets=train_targets)
test_data = NHL_Dataset(features=test_features, targets=test_targets)

# Set up the data loader
train_dataloader = DataLoader(dataset=train_data, batch_size=batch_size, shuffle=True)
test_dataloader = DataLoader(dataset=test_data, batch_size=batch_size, shuffle=False)

############# Train the model #############
########################################################
# Set up mode, optimizer, loss function
model = NeuralNetwork(n_features=train_data.n_features).to(device=device)
optimizer = torch.optim.SGD(model.parameters(), lr=learning_rate, momentum=0.9)
criterion = torch.nn.MSELoss()

# Set up a train loop that occurs once per epoch
def train_loop(dataloader, model, criterion, optimizer):
    # Set to training mode
    model.train()

    # Iterate through each batch
    for batch, (X, y) in enumerate(tqdm(dataloader, unit='batch')):
        # Move data to device
        X, y = X.to(device), y.to(device)

        # Compute predictions
        preds = model(X)
        preds = preds.flatten() # convert to size [batch_size] instead of [batch_size, 1] since this is the size of y

        # Compute loss
        loss = criterion(preds, y)

        # Backpropagation
        loss.backward()
        optimizer.step()
        optimizer.zero_grad()

        # Every 50 batches, print the current loss as a message
        if batch % 10 == 0:
            print(f'Batch {batch} training loss: {loss.item()}')


# Set up a test loop that occurs once per epoch
def test_loop(dataloader, model, criterion):
    # Set to eval mode
    model.eval()
    loss = 0

    # Ensure no gradients are computed
    with torch.no_grad():
        # For each batch, get predictions, compute loss and any other metrics
        for X, y in dataloader:
            # Move data to device
            X, y = X.to(device), y.to(device)

            # Get predictions and loss
            preds = model(X)
            preds = preds.flatten() # convert to size [batch_size] instead of [batch_size, 1] since this is the size of y
            loss += criterion(preds, y).item() * len(X) # total SSE for the batch (since last batch might be less than batch size)
    
    # Print message about the test loss
    loss = loss / len(dataloader.dataset) # MSE across entire test set
    print(f'\nTest loss: {loss}\n')
    

# For each epoch
for i in range(epochs):
    print(f'===== Epoch {i} ======================================================================================')
    # Run the train loop
    train_loop(dataloader=train_dataloader, model=model, criterion=criterion, optimizer=optimizer)
    # Run the test loop
    test_loop(dataloader=test_dataloader, model=model, criterion=criterion)

print(f"Training complete\n")

# Save the model
try:
    torch.save(model, output_model_name)
    print('Model successfully saved')
except:
    print(f'Error saving model\n')
    raise