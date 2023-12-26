from scipy.stats import spearmanr
import pandas as pd
import matplotlib.pyplot as plt


def spearman_rank(feature, target, return_pval=False):
    """Calculate spearman rank correlation coefficient between continuous or ordinal feature and target"""
    # Calculate spearman
    significance_result = spearmanr(feature, target, nan_policy='omit')

    # Check whether p-value should be returned as well
    if return_pval:
        return significance_result.statistic, significance_result.pvalue

    return significance_result.statistic


def barplot(feature, target):
    """Make barplot of proportion of distribution of target variable among each level of feature"""
    # Create df to plot
    df = pd.crosstab(feature, target, margins=False, normalize=False)
    # Normalize along the correct axis
    df = df.div(df.sum(axis=1), axis=0)

    # create stacked bar chart for monthly temperatures
    df.plot(kind='bar', stacked=True, color=['salmon', 'mediumseagreen', 'seagreen'])
    
    # labels for x & y axis
    plt.xlabel(f'{feature.name}')
    plt.ylabel('Proportion')
    
    return