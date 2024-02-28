import torch
from MySQLClass import MySQL
import joblib
from model import prep_for_dataloader, NHL_Dataset
from torch.utils.data import DataLoader
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt

############# Set user/model parameters ################
########################################################
# Define device
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
# Paths
model_name = 'NHLnetBinary'
model_path = f'./04-modeling/deep_learning/models/{model_name}.pth'
preprocessing_dir = './04-modeling/deep_learning/preprocessing'
output_dir = './04-modeling/predictions'
# Column information
index_cols = ['player_id', 'team', 'date', 'season']
target_col = 'G_flag'
# For dataloader
batch_size = 64

############# Gather test dataset ######################
########################################################
mysql = MySQL()
mysql.connect()
mysql.load_data()
test_df = mysql.test_df
print(f'Test row count: {test_df.shape[0]}')
assert (~test_df.isna().sum().any()), 'No missing values can be in the dataset'

# Get list of feature column names for saving inside MLflow model artifact later
feature_cols = [col for col in test_df.columns if col not in index_cols + [target_col]]

# Preprocess / normalize inputs
test_df_normalized = test_df.copy()

# Load scalers from training
standard_scaler = joblib.load(f'{preprocessing_dir}/standard_scaler.pkl')
minmax_scaler = joblib.load(f'{preprocessing_dir}/minmax_scaler.pkl')

# Scale features
cols_to_normalize = [col for col in feature_cols if col not in ['home_game_flag', 'game_num']]
test_df_normalized[cols_to_normalize] = standard_scaler.transform(test_df_normalized[cols_to_normalize])
test_df_normalized['game_num'] = minmax_scaler.transform(test_df[['game_num']])

# Separate index info from features from targets (convert features and targets to tensors as well)
test_index, test_features, test_targets = prep_for_dataloader(test_df_normalized, index_cols=index_cols, target_col=target_col)

# Set custom dataset class
test_data = NHL_Dataset(features=test_features, targets=test_targets)

# Set up the data loader
test_dataloader = DataLoader(dataset=test_data, batch_size=batch_size, shuffle=False)

############# Load model + predict ######################
########################################################
# Load model
model = torch.load(model_path)
model.to(device)

# Set criterion
#criterion = torch.nn.MSELoss()
criterion = torch.nn.BCELoss(reduction='mean')

# Make predictions (and compute loss)
model.eval()
loss = 0
predictions = []
with torch.no_grad():
    # For each batch, get predictions, compute loss and any other metrics
    for X, y in test_dataloader:
        # Move data to device
        X, y = X.to(device), y.to(device)

        # Get predictions and loss
        preds = model(X)
        #preds = preds.flatten() 
        predictions.extend(preds.flatten()) # convert to size [batch_size] instead of [batch_size, 1]
        loss += criterion(preds, y.unsqueeze(1)).item() * len(X) # total SSE for the batch (since last batch might be less than batch size)

# Print message about the test loss
loss = loss / len(test_dataloader.dataset) # MSE across entire test set
print(f'Test loss: {loss}\n')

############# Gather predcitions #######################
########################################################
df_preds = test_index.drop(columns='season').copy()
assert len(predictions) == df_preds.shape[0], "Predictions must be same length as index data frame."
df_preds['prob'] = np.array(predictions) 
df_preds['G_flag'] = test_targets

######## Generate/save plot/distribution info ##########
########################################################
# Create a figure and axes
fig, axs = plt.subplots(nrows=3, ncols=1, figsize=(8, 10))
sns.histplot(data=df_preds, x="prob", bins=20, kde=True, ax=axs[0])
sns.histplot(data=df_preds[df_preds['player_id'] == 'mcdavco01'], x="prob", bins=20, kde=True, ax=axs[1])
sns.histplot(data=df_preds[df_preds['player_id'] == 'seidemo01'], x="prob", bins=20, kde=True, ax=axs[2])
plt.tight_layout()

# Distribution info
with open(f"{output_dir}/{model_name}_info.txt", 'w') as f:
    f.write(df_preds['prob'].describe().to_string())

# Save the plot to a PDF file
plt.savefig(f"{output_dir}/{model_name}_plots.pdf")

######## Save predictions ##########
########################################################
# Save predictions for bet optimization and final test
df_preds.to_csv(f'{output_dir}/{model_name}_predictions.csv', header=True, index=False)