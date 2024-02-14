from scipy.stats import poisson
import pandas as pd
#######################################################
def odds_to_profit(odds):
    """Convert odds (ex: -125, +200) to a profit in units assuming bet wins"""
    odds = int(odds)
    if odds > 0:
        profit = (odds / 100) # + 1 if you want odds to payout
    else:
        profit = (100 / abs(odds)) # + 1
    return profit
#######################################################
def bet_EV(odds, prob):
    """Get the expected value of bet"""
    profit = odds_to_profit(odds)
    return (prob) * (profit) - (1 - prob)
#######################################################
# def determine_bet_profit(odds, place_bet_flag, win_flag):
#     if place_bet_flag == 0:
#         return 0
#     elif win_flag == 0:
#         return -1
#     else:
#         return odds_to_profit(odds)
#######################################################
def poisson_goalscorer(xG):
    """Assuming G is poisson distributed, find probability of scoring >= 1 goals"""
    return (1 -  poisson.cdf(k=1, mu=xG))
#######################################################
def poisson_moneyline(xgA, xgB):
    """Get probability of team A winning using xG of team A and team B"""
    # Assume that  NHL teams score between 0 and 25 goals per game
    num_goals = [n for n in range(25)]

    # Get probabilities of scoring 0-20 from poisson distribution with mean xGoals
    pois_probsA = poisson.pmf(k = num_goals, mu = xgA)
    pois_probsB = poisson.pmf(k = num_goals, mu = xgB)

    # Set up df to store probabilities
    poisA = pd.DataFrame(zip(num_goals, pois_probsA), columns = ['goalsA', 'probA'])
    #poisA['temp_key'] = 1

    poisB = pd.DataFrame(zip(num_goals, pois_probsB), columns = ['goalsB', 'probB'])
    #poisB['temp_key'] = 1

    # Join on temporary key to get cross join
    all_outcomes = pd.merge(poisA, poisB, how = 'cross')

    # Calculate probability of each possible outcome
    all_outcomes['outcome_prob'] = all_outcomes['probA'] * all_outcomes['probB']

    # Get probability that team A wins. Pr(A win) = SUM(A > B) + 0.5 * SUM(A = B)
    prob_A_win = all_outcomes.loc[all_outcomes['goalsA'] > all_outcomes['goalsB'], 'outcome_prob'].sum() + 0.5 * all_outcomes.loc[all_outcomes['goalsA'] == all_outcomes['goalsB'], 'outcome_prob'].sum()

    return prob_A_win
#######################################################
# def poisson_moneyline(df_group):
#     # Gather the expected goals for each team in the group
#     xg = df_group['xg'].tolist()
#     xgA = xg[0]
#     xgB = xg[1]

#     # Assume that  NHL teams score between 0 and 25 goals per game
#     num_goals = [n for n in range(25)]

#     # Get probabilities of scoring 0-20 from poisson distribution with mean xGoals
#     pois_probsA = poisson.pmf(k = num_goals, mu = xgA)
#     pois_probsB = poisson.pmf(k = num_goals, mu = xgB)

#     # Set up df to store probabilities
#     poisA = pd.DataFrame(zip(num_goals, pois_probsA), columns = ['goalsA', 'probA'])
#     #poisA['temp_key'] = 1

#     poisB = pd.DataFrame(zip(num_goals, pois_probsB), columns = ['goalsB', 'probB'])
#     #poisB['temp_key'] = 1

#     # Join on temporary key to get cross join
#     all_outcomes = pd.merge(poisA, poisB, how = 'cross')
                            
#     # Calculate probability of each possible outcome
#     all_outcomes['outcome_prob'] = all_outcomes['probA'] * all_outcomes['probB']

    # # Get probability that team A wins. Pr(A win) = SUM(A > B) + 0.5 * SUM(A = B)
    # prob_A_win = all_outcomes.loc[all_outcomes['goalsA'] > all_outcomes['goalsB'], 'outcome_prob'].sum() + 0.5 * all_outcomes.loc[all_outcomes['goalsA'] == all_outcomes['goalsB'], 'outcome_prob'].sum()

    # # Get probability that team B wins
    # prob_B_win = 1-prob_A_win

    # # Assign these probabilities to a new column in the data frame
    # df_group['prob'] = [prob_A_win, prob_B_win]
 
    # # Return the result for each group
    # return df_group