#%%
import torch
import pandas as pd
from model import NHL_Dataset, NHLnet, prep_for_dataloader
from torch.utils.data import DataLoader
from torchinfo import summary
from tqdm import tqdm
import sqlalchemy
import mlflow
from sklearn.preprocessing import StandardScaler, MinMaxScaler

############# Set user/model parameters ################
########################################################
# User parameters
model_name ='NHLnet'
output_model_directory = f'./04-modeling/deep_learning/models'
index_cols = ['player_id', 'team', 'date', 'season']
target_col = 'G'

# Model hyperparameters
device = 'cuda' if torch.cuda.is_available() else 'cpu'
epochs = 10
batch_size = 32
learning_rate = 0.015
momentum = 0.9
#%%
############# Gather features into dataset #############
########################################################
# MySQL connection
engine = sqlalchemy.create_engine('mysql+mysqlconnector://root:rootdata@localhost/nhl')

# Set up SQL queries to gather features
print("Gathering data from MySQL...")
skater = pd.read_sql("""
    SELECT a.player_id,
        a.team,
        a.date,
        a.game_num,
        a.G,
        b.season
    FROM skater_game a
    INNER JOIN schedule b
        ON a.team = b.team
        AND a.date = b.date
    WHERE b.season IN (2021, 2022, 2023)
""", con=engine)
home_away = pd.read_sql("SELECT * FROM home_away_status;", con=engine)
point_streak = pd.read_sql("SELECT * FROM point_streak;", con=engine)
per60 = pd.read_sql("""
    SELECT player_id,
        date,
        G60_last_season,
        resid_G60_10,
        P60_last_season,
        resid_P60_10,
        S60_last_season,
        resid_S60_10,
        BLK60_last_season,
        resid_BLK60_10,
        HIT60_last_season,
        resid_HIT60_10,
        avgTOI_last_season,
        resid_avgTOI_10
    FROM skater_per60_resid_rolling10
""", con=engine)

# Merge features to create pandas DF
train_df = skater.loc[skater['season'].isin([2021, 2022]), :].merge(per60, how='inner', on=['player_id', 'date']
    ).merge(home_away, how='inner', on=['player_id', 'date']
    ).merge(point_streak, how='inner', on=['player_id', 'date'])

val_df = skater.loc[skater['season'] == 2023, :].merge(per60, how='inner', on=['player_id', 'date']
    ).merge(home_away, how='inner', on=['player_id', 'date']
    ).merge(point_streak, how='inner', on=['player_id', 'date'])

print(f'Per60 row count: {per60.shape[0]}')
print(f'Train row count: {train_df.shape[0]}')
print(f'Val row count: {val_df.shape[0]}')
#print(f'Training dataset information: {train_df.info()}\n')
assert (~train_df.isna().sum().any()) & (~val_df.isna().sum().any()), 'No missing values can be in the datasets'

# Get list of feature column names for saving inside MLflow model artifact later
feature_cols = [col for col in train_df.columns if col not in index_cols + [target_col]]

# Preprocess / normalize inputs
train_df_normalized = train_df.copy()
val_df_normalized = val_df.copy()

# For most columns, use standardization
standard_scaler = StandardScaler()
cols_to_normalize = [col for col in feature_cols if col not in ['home_game_flag', 'game_num']]
train_df_normalized[cols_to_normalize] = standard_scaler.fit_transform(train_df_normalized[cols_to_normalize])
val_df_normalized[cols_to_normalize] = standard_scaler.transform(val_df[cols_to_normalize])

# For game_num, use min_max scaler
minmax_scaler = MinMaxScaler()
train_df_normalized['game_num'] = minmax_scaler.fit_transform(train_df_normalized[['game_num']])
val_df_normalized['game_num'] = minmax_scaler.transform(val_df[['game_num']])

#print(train_df_normalized.head())

# Separate index info from features from targets (convert features and targets to tensors as well)
train_index, train_features, train_targets = prep_for_dataloader(train_df_normalized, index_cols=index_cols, target_col=target_col)
val_index, val_features, val_targets = prep_for_dataloader(val_df_normalized, index_cols=index_cols, target_col=target_col)

# Set custom dataset class
train_data = NHL_Dataset(features=train_features, targets=train_targets)
val_data = NHL_Dataset(features=val_features, targets=val_targets)

# Set up the data loader
train_dataloader = DataLoader(dataset=train_data, batch_size=batch_size, shuffle=True)
test_dataloader = DataLoader(dataset=val_data, batch_size=batch_size, shuffle=False)
#%%
############# Train the model #############
########################################################
# Set ML Flow experiment
mlflow.set_tracking_uri("http://127.0.0.1:5000")
mlflow.set_experiment("deep-learning")

# Set up mode, optimizer, loss function
model = NHLnet(n_features=train_data.n_features).to(device=device)
optimizer = torch.optim.SGD(model.parameters(), lr=learning_rate, momentum=momentum)
criterion = torch.nn.MSELoss()

# Set up a train loop that occurs once per epoch
def train_loop(dataloader, model, criterion, optimizer):
    # Set to training mode
    model.train()

    progress_bar = tqdm(total=len(dataloader), unit='batch', position=0, leave=True)

    # Iterate through each batch
    for batch, (X, y) in enumerate(dataloader):
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
        if batch % 100 == 0:
            mlflow.log_metric("training_mse", f"{loss.item():3f}", step=int(batch))
            #print(f'Batch {batch} training loss: {loss.item()}')

        progress_bar.set_description(f"Batch {batch}, training loss: {loss.item():.3f}")
        progress_bar.update()

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
    mlflow.log_metric("validation_mse", f"{loss:3f}") # What happens if there is no step?
    print(f'\nValidation loss: {loss}\n')
    
with mlflow.start_run() as run:
    params = {
        "epochs": epochs,
        "learning_rate": learning_rate,
        "batch_size": batch_size,
        "criterion": criterion.__class__.__name__,
        "optimizer": optimizer.__class__.__name__
    }
    # Log training parameters.
    mlflow.log_params(params)

    # Log model summary and feature list
    with open("./04-modeling/deep_learning/artifacts/model_summary.txt", "w") as f:
        f.write(str(summary(model)))
    with open("./04-modeling/deep_learning/artifacts/features.txt", "w") as f:
        f.write(', '.join(feature_cols))
    mlflow.log_artifacts("./artifacts", artifact_path="states")

    # For each epoch
    for i in range(epochs):
        print(f'===== Epoch {i} ======================================================================================')
        # Run the train loop
        train_loop(dataloader=train_dataloader, model=model, criterion=criterion, optimizer=optimizer)
        # Run the test loop
        test_loop(dataloader=test_dataloader, model=model, criterion=criterion)

    # Save the trained model to MLflow.
    mlflow.pytorch.log_model(pytorch_model=model, artifact_path="states", registered_model_name=model_name)

print(f"Training complete\n")

# Save the model
try:
    torch.save(model, f'{output_model_directory}/{model_name}.pth')
    print('Model successfully saved')
except:
    print(f'Error saving model\n')
    raise
#%%