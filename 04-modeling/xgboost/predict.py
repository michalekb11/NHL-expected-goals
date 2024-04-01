import sys
sys.path.append('./04-modeling')
from MySQLClass import MySQL
from model import prep_for_boosting
import joblib
from sklearn.metrics import log_loss
import seaborn as sns
import matplotlib.pyplot as plt

############# Set user parameters ######################
########################################################
# Paths
model_name = 'NHLXGBoost'
model_path = f'./04-modeling/xgboost/models/{model_name}.pkl'
output_dir = './04-modeling/predictions'
# Column information
index_cols = ['player_id', 'team', 'opponent', 'date', 'season']
target_col = 'G_flag'

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

# Separate index info from features from targets (convert features and targets to arrays as well)
test_index, test_features, test_targets = prep_for_boosting(test_df, index_cols=index_cols, target_col=target_col)

############# Load model + predict ######################
########################################################
# Load model
xgb = joblib.load(model_path)

# Make predictions on test set
test_preds = xgb.predict_proba(test_features)[:,1]

# Compute test BCE (log loss)
test_bce = log_loss(test_targets, test_preds)

# Print loss
print(f"Validation loss: {test_bce}\n")

############# Gather predcitions #######################
########################################################
df_preds = test_index.drop(columns='season').copy()
assert len(test_preds) == df_preds.shape[0], "Predictions must be same length as index data frame."
df_preds['prob'] = test_preds 
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