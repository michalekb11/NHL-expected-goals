# Import libraries
import sys
sys.path.append('./04-modeling')
from MySQLClass import MySQL
from model import prep_for_forest
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import log_loss
import mlflow
import joblib
import pandas as pd

############# Set user/model parameters ################
########################################################
# User parameters
output_model_directory = f'./04-modeling/random_forest/models'
model_name ='NHLForest'
index_cols = ['player_id', 'team', 'opponent', 'date', 'season']
target_col = 'G_flag'
data_reset = False

# Model hyperparameters
n_estimators=200
criterion='log_loss' # 'gini'
max_depth=10
min_samples_split=10
class_weight=None #'balanced', 'balanced_subsample', {0:0.3, 1:0.7}

############# Gather features into dataset #############
########################################################
mysql = MySQL()
mysql.connect()
mysql.load_data(reset=data_reset)
train_df = mysql.train_df
val_df = mysql.val_df

print(f'Train row count: {train_df.shape[0]}')
print(f'Val row count: {val_df.shape[0]}')
assert (~train_df.isna().sum().any()) & (~val_df.isna().sum().any()), 'No missing values can be in the datasets'

# Get list of feature column names for saving inside MLflow model artifact later
feature_cols = [col for col in train_df.columns if col not in index_cols + [target_col]]

# Separate index info from features from targets (convert features and targets to tensors as well)
train_index, train_features, train_targets = prep_for_forest(train_df, index_cols=index_cols, target_col=target_col)
val_index, val_features, val_targets = prep_for_forest(val_df, index_cols=index_cols, target_col=target_col)

############# Train the model #############
########################################################
print(f'All data gathered. Beginning training...\n')

# Set ML Flow experiment
mlflow.set_tracking_uri("http://127.0.0.1:5000")
mlflow.set_experiment("random-forest")

# Log parameters and evaluation results
with mlflow.start_run() as run:
    # Log features
    with open("./04-modeling/random_forest/artifacts/features.txt", "w") as f:
        f.write(', '.join(feature_cols))
    mlflow.log_artifact("./04-modeling/random_forest/artifacts/features.txt")

    # Set up model
    rf = RandomForestClassifier(n_estimators=n_estimators,
                                criterion=criterion,
                                max_depth=max_depth,
                                min_samples_split=min_samples_split,
                                class_weight=class_weight,
                                random_state=11)
    
    # Log training parameters.
    mlflow.log_params(rf.get_params())

    # Train model
    rf.fit(train_features, train_targets)

    # Predict training and testing probabilities
    train_preds = rf.predict_proba(train_features)[:,1]
    val_preds = rf.predict_proba(val_features)[:,1]

    # Compute train and validation BCE (log loss)
    train_bce = log_loss(train_targets, train_preds)
    val_bce = log_loss(val_targets, val_preds)

    # Log BCE's
    mlflow.log_metrics({'train_BCE':train_bce, 'val_BCE':val_bce})

    # Log model
    mlflow.sklearn.log_model(sk_model=rf, artifact_path="states", registered_model_name=model_name)

# Print training results
print(f"\nTraining complete")
print(f"Training loss: {train_bce}")
print(f"Validation loss: {val_bce}\n")

# Save feature importances
feature_importances = pd.DataFrame({'feature':feature_cols, 'importance': rf.feature_importances_})
feature_importances.to_csv('./04-modeling/random_forest/artifacts/feature_importances.csv', header=True, index=False)

# Save the model
try:
    joblib.dump(rf, f'{output_model_directory}/{model_name}.pkl')
    print('Model successfully saved')
except:
    print(f'Error saving model\n')
    raise