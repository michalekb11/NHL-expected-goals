from scipy.stats import spearmanr
import seaborn as sns
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd

def spearman_rank(feature, target, return_pval=False):
    """Calculate spearman rank correlation coefficient between continuous or ordinal feature and target"""
    # Calculate spearman
    significance_result = spearmanr(feature, target, nan_policy='omit')

    # Check whether p-value should be returned as well
    if return_pval:
        return significance_result.statistic, significance_result.pvalue

    return significance_result.statistic

def boxplot(feature, target, ax=None):
    # Clear any old graphic
    plt.clf()
    # Set up data
    data = pd.DataFrame({'feature':feature, 'target':target})
    num_lables = len(set(target))
    # Create plot
    if num_lables == 2:
        g = sns.boxplot(data=data, x='target', y='feature', palette=['salmon', 'seagreen'])
    elif num_lables == 3:
        g = sns.boxplot(data=data, x='target', y='feature', palette=['salmon', 'mediumseagreen', 'seagreen'])
    else:
        g = sns.boxplot(data=data, x='target', y='feature')
    # Other customizaitons
    plt.ylabel(feature.name)
    plt.xlabel(target.name)
    plt.show(g)
    return

def density_plot(feature, target):
    # Clear any old graphic
    plt.clf()
    # Set up data
    data = pd.DataFrame({'feature':feature, 'target':target})
    num_lables = len(set(target))
    # Create plot
    if num_lables == 2:
        g = sns.kdeplot(data=data, x='feature', hue='target', common_norm=False, palette=['salmon', 'seagreen'])
    elif num_lables == 3:
        g = sns.kdeplot(data=data, x='feature', hue='target', common_norm=False, palette=['salmon', 'mediumseagreen', 'darkgreen'])
    else:
        g = sns.kdeplot(data=data, x='feature', hue='target', common_norm=False)
    # Other customizaitons
    plt.xlabel(feature.name)
    plt.legend(title=target.name)
    plt.show(g)
    return

# Function for difference in means between target levels
def diff_in_means(feature, target):
    """Calculate the difference in means of feature in target levels"""
    # Standardize feature
    x = np.array(feature)
    x_standard = (x - np.mean(x)) / np.std(x)

    # Ensure only 2 levels, 2nd level is max 
    y_unique = np.unique(target)
    assert len(set(target)) == 2, "Target should be binary"
    assert max(y_unique) == y_unique[1], "Unique values of target are out of order"

    # Compute difference in mean
    diff = x_standard[target == y_unique[1]].mean() - x_standard[target == y_unique[0]].mean()

    return diff

# Function for difference in means between target levels
def diff_in_medians(feature, target):
    """Calculate the difference in means of feature in target levels"""
    # Standardize feature
    x = np.array(feature)
    x_standard = (x - np.mean(x)) / np.std(x)

    # Ensure only 2 levels, 2nd level is max 
    y_unique = np.unique(target)
    assert len(set(target)) == 2, "Target should be binary"
    assert max(y_unique) == y_unique[1], "Unique values of target are out of order"

    # Compute difference in mean
    diff = np.median(x_standard[target == y_unique[1]]) - np.median(x_standard[target == y_unique[0]])

    return diff