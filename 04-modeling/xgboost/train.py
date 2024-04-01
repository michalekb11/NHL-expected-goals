# Import libraries
import sys
sys.path.append('./04-modeling')
from MySQLClass import MySQL
from model import prep_for_boosting
from xgboost import XGBClassifier
from sklearn.metrics import log_loss
import mlflow
import joblib
import pandas as pd

############# Set user/model parameters ################
########################################################
# User parameters
output_model_directory = f'./04-modeling/xgboost/models'
model_name ='NHLXGBoost'
index_cols = ['player_id', 'team', 'opponent', 'date', 'season']
target_col = 'G_flag'
data_reset = False

# Model hyperparameters
n_estimators = 250
learning_rate = 0.1
min_split_loss = 0.1 # min loss reduction required to make another split
max_depth = 4
max_delta_step = 1 # typically 1-10, used for logistic regression problems with class imbalance, sets limit to the change in predicted scores for leaf nodes
subsample = 0.08 # if you want to sample only some of the data before each boosting iteration
colsample_bytree = 1.0
reg_lambda = 1.0 # L2 regularization on weights
scale_pos_weight = 1.3 # useful for class imbalance, something around sum(negative class) / sum(positive class)
objective = 'binary:logistic'

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
train_index, train_features, train_targets = prep_for_boosting(train_df, index_cols=index_cols, target_col=target_col)
val_index, val_features, val_targets = prep_for_boosting(val_df, index_cols=index_cols, target_col=target_col)

############# Train the model #############
########################################################
print(f'All data gathered. Beginning training...\n')

# Set ML Flow experiment
mlflow.set_tracking_uri("http://127.0.0.1:5000")
mlflow.set_experiment("xgboost")

# Log parameters and evaluation results
with mlflow.start_run() as run:
    # Log features
    with open("./04-modeling/xgboost/artifacts/features.txt", "w") as f:
        f.write(', '.join(feature_cols))
    mlflow.log_artifact("./04-modeling/xgboost/artifacts/features.txt")

    # Set up model
    xgb = XGBClassifier(n_estimators=n_estimators,
                        learning_rate=learning_rate,
                        min_split_loss=min_split_loss,
                        max_depth=max_depth,
                        subsample=subsample,
                        colsample_bytree=colsample_bytree,
                        reg_lambda=reg_lambda,
                        scale_pos_weight=scale_pos_weight,
                        objective=objective,
                        random_state=11)
    
    # Log training parameters.
    mlflow.log_params(xgb.get_params())

    # Train model
    xgb.fit(train_features, train_targets)

    # Predict training and testing probabilities
    train_preds = xgb.predict_proba(train_features)[:,1]
    val_preds = xgb.predict_proba(val_features)[:,1]

    # Compute train and validation BCE (log loss)
    train_bce = log_loss(train_targets, train_preds)
    val_bce = log_loss(val_targets, val_preds)

    # Log BCE's
    mlflow.log_metrics({'train_BCE':train_bce, 'val_BCE':val_bce})

    # Log model
    mlflow.sklearn.log_model(sk_model=xgb, artifact_path="states", registered_model_name=model_name)

# Print training results
print(f"\nTraining complete")
print(f"Training loss: {train_bce}")
print(f"Validation loss: {val_bce}\n")

# Save feature importances
feature_importances = pd.DataFrame({'feature':feature_cols, 'importance': xgb.feature_importances_})
feature_importances.to_csv('./04-modeling/xgboost/artifacts/feature_importances.csv', header=True, index=False)

# Save the model
try:
    joblib.dump(xgb, f'{output_model_directory}/{model_name}.pkl')
    print('Model successfully saved')
except:
    print(f'Error saving model\n')
    raise