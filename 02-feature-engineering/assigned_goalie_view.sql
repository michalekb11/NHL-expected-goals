-- ------------------------------------------------------
-- Assigned goalie view
-- ------------------------------------------------------
-- Each game in the past needs an assigned goalie. We do not always know
-- who started the game since a goalie could get injuried or pulled 
-- during the game. Additionally, for the purposes of training a model,
-- we can only assume that one goalie will play in a given game.

-- So how should we assign one goalie to each game in cases where multiple played?
-- We don't know which one started the game just based on time on ice, etc.

-- For training purposes, we want to associate the goalie statistics with the
-- likelihood of scoring a goal. As a result we propose choosing the goalie 
-- according to the following criteria:

    -- 1. Choose the goalie that gave up the most goals (this is the association we want to learn)
    -- 2. Choose the goalie that faced the most shots (most "action" or events that could have resulted in a goal)
    -- 3. Choose the goalie that had the most time on ice (second version of most "action")
    -- 4. Choose the goalie that received decision (gave up game winner or got the win)
-- ------------------------------------------------------
DROP VIEW IF EXISTS assigned_goalie;

CREATE VIEW assigned_goalie AS (
    WITH ordered AS (
        SELECT player_id,
            date,
            ROW_NUMBER() OVER (PARTITION BY team, date ORDER BY GA DESC, SA DESC, TOI DESC, decision DESC) AS goalie_priority
		FROM goalie_games
    )

    SELECT player_id,
        date
    FROM ordered
    WHERE goalie_priority = 1
);
