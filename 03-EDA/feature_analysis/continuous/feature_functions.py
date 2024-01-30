from scipy.stats import spearmanr
import seaborn as sns
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
########################################################################
def spearman_rank(feature, target, return_pval=False):
    """Calculate spearman rank correlation coefficient between continuous or ordinal feature and target"""
    # Calculate spearman
    significance_result = spearmanr(feature, target, nan_policy='omit')

    # Check whether p-value should be returned as well
    if return_pval:
        return significance_result.statistic, significance_result.pvalue

    return significance_result.statistic
########################################################################
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
########################################################################
def density_plot(feature, target):
    target = np.array(target, dtype=str)
    # Clear any old graphic
    plt.clf()
    # Set up data
    data = pd.DataFrame({'feature':feature, 'target':target})
    num_lables = len(set(target))
    # Create plot
    if num_lables == 2:
        g = sns.kdeplot(data=data, x='feature', hue='target', common_norm=False, palette={'False':'salmon', 'True':'seagreen'})
    elif num_lables == 3:
        g = sns.kdeplot(data=data, x='feature', hue='target', common_norm=False, palette={'0':'salmon', '1':'mediumseagreen', '2+':'darkgreen'})
    else:
        g = sns.kdeplot(data=data, x='feature', hue='target', common_norm=False)

    # Other customizations
    plt.xlabel(feature.name)
    plt.show(g)
    return
########################################################################
# Function for difference in means between target levels
def diff_in_means(feature, target):
    """Calculate the difference in means of feature in target levels"""
    # Standardize feature
    x = np.array(feature)
    x_standard = (x - np.nanmean(x)) / np.nanstd(x)

    # Ensure only 2 levels, 2nd level is max 
    y_unique = np.unique(target)
    assert len(y_unique) == 2, "Target should be binary"
    assert max(y_unique) == y_unique[1], "Unique values of target are out of order"

    x_goals = x_standard[[True if elem == y_unique[1] else False for elem in target]]
    x_nogoal = x_standard[[True if elem == y_unique[0] else False for elem in target]]

    # Compute difference in mean
    diff = np.nanmean(x_goals) - np.nanmean(x_nogoal)

    return diff
########################################################################
# Function for difference in medians between target levels
def diff_in_medians(feature, target):
    """Calculate the difference in medians of feature in target levels"""
    # Standardize feature
    x = np.array(feature)
    x_standard = (x - np.nanmean(x)) / np.nanstd(x)

    # Ensure only 2 levels, 2nd level is max 
    y_unique = np.unique(target)
    assert len(set(target)) == 2, "Target should be binary"
    assert max(y_unique) == y_unique[1], "Unique values of target are out of order"

    x_goals = x_standard[[True if elem == y_unique[1] else False for elem in target]]
    x_nogoal = x_standard[[True if elem == y_unique[0] else False for elem in target]]

    # Compute difference in median
    diff = np.nanmedian(x_goals) - np.nanmedian(x_nogoal)

    return diff
########################################################################
def time_series_plot(player_df, metric_prefix, rw1='03', rw2='20'):
    # Seaborn
    sns.set(style="whitegrid", palette="muted")

    # Create a FacetGrid for S60_20 and S60_03
    g = sns.FacetGrid(player_df, col="season", hue="gt0", palette={0: 'black', 1: 'green'}, col_wrap=2, sharex=False)
    g.map(plt.scatter, "date", f"{metric_prefix}_{rw1}", alpha=0.5, s=7)
    g.map(plt.scatter, "date", f"{metric_prefix}_{rw2}", alpha=0.5, s=7)
    g.add_legend(title='At least 1 goal', labels=['No', 'Yes'])

    g.set_axis_labels("Date", metric_prefix)

    # Draw a black line connecting all points for S60_20 and S60_03
    for ax, (season, season_data) in zip(g.axes, player_df.groupby('season')):
        ax.tick_params(axis='x', rotation=20, labelsize=8)
        ax.plot(season_data['date'], season_data[f"{metric_prefix}_{rw1}"], color='black', alpha=0.5, linewidth=1, linestyle='--')
        ax.plot(season_data['date'], season_data[f"{metric_prefix}_{rw2}"], color='black', alpha=0.5, linewidth=1, linestyle='-')
        ax.set_title(f"Season: {season}")

    plt.show()
    return
########################################################################
def psi(expected, observed, bucket_type = "bins", n_bins = 10):
    """Calculate PSI for two numpy arrays. Bin strategies can be 'bins' or 'quantiles'"""
    # Set breakpoints based off bin strategy
    if bucket_type == "bins":
        breakpoints = np.histogram(expected, n_bins)[1]
    elif bucket_type == "quantiles":
        breakpoints = np.arange(0, n_bins + 1) / (n_bins) * 100
        breakpoints = np.percentile(expected, breakpoints)
    else:
        raise ValueError(f"Invalid bucket_type: {bucket_type}. Only 'bins' and 'quantiles' allowed.")

    # Find frequencies of for each bin
    expected_percents = np.histogram(expected, breakpoints)[0] / len(expected)
    observed_percents = np.histogram(observed, breakpoints)[0] / len(observed)

    # Avoid divide by 0 error
    expected_percents = np.clip(expected_percents, a_min=0.0001, a_max=None)
    observed_percents = np.clip(observed_percents, a_min=0.0001, a_max=None)

    # Calculate psi
    psi_value = (expected_percents - observed_percents) * np.log(expected_percents / observed_percents)
    psi_value = sum(psi_value)

    return psi_value
########################################################################