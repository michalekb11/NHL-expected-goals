-- -------------------------------------------------------------
-- Rest days view
-- -------------------------------------------------------------
-- Calculate the number of rest days each player has had before the 
-- upcoming game of interest. Should act within each season, player_id.
-- A player making their season debut should have rest days = NULL for now.

-- Other scenarios to keep in mind:
    -- A player returning from injury will have high number of rest days
    -- (but hopfully we've noted that they've been injured)

    -- A player that comes up and down from the minors will have high
    -- number of rest days. This is technicall innaccurate (but is there
    -- a way to know this information and reset the value to the median/mean?)

-- The idea is that players may have a sweet spot of 2-4 rest days for peak 
-- performance. Potential improvement could be made dealing with players
-- coming up from the minors (perhaps if rest days is >= 20 and they have no
-- sign of injury, reset to median??)
----------------------------------------------------------------
DROP VIEW IF EXISTS rest_days;

CREATE VIEW rest_days AS (
    SELECT player_id,
        date,
        DATEDIFF(date, LAG(date) OVER (PARTITION BY season, player_id ORDER BY date)) - 1 AS rest_days
    FROM skater_games
);

-- NOTE: This code has not been tested due to issues with MySQL. Test to make sure it works as intended.