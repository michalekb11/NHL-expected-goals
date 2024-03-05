import torch
from model import NHL_Dataset, NHLnet, prep_for_dataloader, NHLnetWide, NHLnetBinary
from torch.utils.data import DataLoader
from torchinfo import summary
from tqdm import tqdm
import mlflow
from sklearn.preprocessing import StandardScaler, MinMaxScaler, RobustScaler
from MySQLClass import MySQL
import joblib

############# Set user/model parameters ################
########################################################
# User parameters
preprocessing_dir = './04-modeling/deep_learning/preprocessing'
model_name ='NHLnetBinary' # 'NHLnetWide
output_model_directory = f'./04-modeling/deep_learning/models'
index_cols = ['player_id', 'team', 'date', 'season']
target_col = 'G_flag'
data_reset = False
model_name_dict = {
    'NHLnet':NHLnet,
    'NHLnetWide':NHLnetWide,
    'NHLnetBinary':NHLnetBinary
}

# Model hyperparameters
device = 'cuda' if torch.cuda.is_available() else 'cpu'
epochs = 30
batch_size = 64
learning_rate = 0.001
momentum = 0.9

############# Gather features into dataset #############
########################################################
mysql = MySQL()
mysql.connect()
mysql.load_data(reset=data_reset)
train_df = mysql.train_df
val_df = mysql.val_df

#print(f'Per60 row count: {per60.shape[0]}')
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
cols_to_normalize = [col for col in feature_cols if col not in ['home_game_flag', 'game_num', 'rest_days', 'games_missed']]
train_df_normalized[cols_to_normalize] = standard_scaler.fit_transform(train_df_normalized[cols_to_normalize])
val_df_normalized[cols_to_normalize] = standard_scaler.transform(val_df[cols_to_normalize])

# For rest_days, games_missed, use robust scaler due to large outliers
robust_scaler = RobustScaler()
train_df_normalized[['rest_days', 'games_missed']] = robust_scaler.fit_transform(train_df_normalized[['rest_days', 'games_missed']])
val_df_normalized[['rest_days', 'games_missed']] = robust_scaler.transform(val_df[['rest_days', 'games_missed']])

# For game_num, use min_max scaler
minmax_scaler = MinMaxScaler()
train_df_normalized['game_num'] = minmax_scaler.fit_transform(train_df_normalized[['game_num']])
val_df_normalized['game_num'] = minmax_scaler.transform(val_df[['game_num']])

# Save preprocessing objects to use in predict script
joblib.dump(standard_scaler, f'{preprocessing_dir}/standard_scaler.pkl')
joblib.dump(robust_scaler, f'{preprocessing_dir}/robust_scaler.pkl')
joblib.dump(minmax_scaler, f'{preprocessing_dir}/minmax_scaler.pkl')

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

############# Train the model #############
########################################################
# Set ML Flow experiment
mlflow.set_tracking_uri("http://127.0.0.1:5000")
mlflow.set_experiment("deep-learning")

# Set up mode, optimizer, loss function
model_class = model_name_dict[model_name]
model = model_class(n_features=train_data.n_features).to(device=device)
#optimizer = torch.optim.SGD(model.parameters(), lr=learning_rate, momentum=momentum)
optimizer = torch.optim.Adam(model.parameters(), lr=learning_rate)
#criterion = torch.nn.MSELoss()
criterion = torch.nn.BCELoss(reduction='mean')

# Set up a train loop that occurs once per epoch
global_train_step = 0
def train_loop(dataloader, model, criterion, optimizer):
    global global_train_step

    # Set to training mode
    model.train()

    progress_bar = tqdm(total=len(dataloader), unit='batch', position=0, leave=True)

    # Iterate through each batch
    for batch, (X, y) in enumerate(dataloader):
        # Move data to device
        X, y = X.to(device), y.to(device)

        # Compute predictions
        preds = model(X)
        # preds = preds.flatten() # convert to size [batch_size] instead of [batch_size, 1] since this is the size of y

        # Compute loss
        loss = criterion(preds, y.unsqueeze(1)) # unsqueeze converts y to shape (batch size, 1)

        # Backpropagation
        loss.backward()
        optimizer.step()
        optimizer.zero_grad()

        # Every N batches, print the current loss as a message
        if batch % 100 == 0:
            mlflow.log_metric("training_BCE", f"{loss.item():3f}", step=global_train_step)
            #print(f'Batch {batch} training loss: {loss.item()}')

        progress_bar.set_description(f"Batch {batch}, training loss: {loss.item():.3f}")
        progress_bar.update()

        global_train_step += 1

# Set up a test loop that occurs once per epoch
global_test_step = 0
def test_loop(dataloader, model, criterion):
    global global_test_step
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
            #preds = preds.flatten() # convert to size [batch_size] instead of [batch_size, 1] since this is the size of y
            loss += criterion(preds, y.unsqueeze(1)).item() * len(X) # total SSE for the batch (since last batch might be less than batch size)
    
    # Print message about the test loss
    loss = loss / len(dataloader.dataset) # MSE across entire test set
    mlflow.log_metric("validation_BCE", f"{loss:3f}", step=global_test_step) # What happens if there is no step?
    print(f'\nValidation loss: {loss}\n')
    global_test_step += 1
    
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