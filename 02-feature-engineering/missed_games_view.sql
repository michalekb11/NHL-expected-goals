-- -------------------------------------------------------------
-- Missed game(s) view
-- -------------------------------------------------------------
-- How many games has a player missed? Could be due to injury,
-- send down to minors, etc. In fact, this could be a proxy for an injury
-- feature for the past few years where I don't have data on injuries data.

-- When a player has a large number of rest days, we'd like to know if this 
-- is due to the team having 12 days off at all start break, or whether the player
-- is injured, etc. On average, I would expect injured players to have 
-- middle sized rest days and a few games missed. I would expect guys sent to the 
-- minors to have large number of rest days (potentially hundreds) and large number
-- of games missed.

-- This code should handle situations where the last game played was from the previous 
-- season. Here, we only backtrack to the start of a season. A player cannot miss more 
-- than ~81 games.

-- Undecided what to do when players make their season debut. One argument is 
-- to set to NULL. The reason for this is because some players make their NHL debut 
-- late in the season(Luke Hughes example), and they technically have not missed any of that
-- team's previous games... they were never on the team. This is their game #1. 
-- Another argument is to allow them to miss everything prior in the season, since if
-- a player is still recovering from injury, they are in fact missing those games (since
-- they would normally be playing).

-- For now, season debuts are set to players having missed those games. If I am including
-- per60 stats, these rows will drop out anyways...

-- Additional problem, when a player switches teams, it is hard to define if they "miss"
-- games, since we don't know the exact moment they switched teams. There could be a situation
-- where a player gets traded from DET (game num 50) to PIT (game num 47), so the games missed is -4.
-- In these situations, I am capping the feature at 0 for clarity. Know that this could happen in 
-- the opposite order, thus giving an innacurate estimate (>0 when he never technically missed a game).
-- Best I can do for now...
----------------------------------------------------------------
DROP VIEW IF EXISTS games_missed;

CREATE VIEW games_missed AS (
    WITH team_game_num as (
        SELECT team, 
            date,
            season,
        ROW_NUMBER() OVER (PARTITION BY team, season ORDER BY date) AS team_game_num 
        FROM schedule
    ),

    lagged AS (
        SELECT sk.player_id, 
            sk.team,
            sk.date,
            tgn.season,
            tgn.team_game_num,
            COALESCE(LAG(tgn.team_game_num) OVER (PARTITION BY tgn.season, sk.player_id ORDER BY sk.date), 0) AS prev_team_game_num
        FROM skater_game sk
        LEFT JOIN team_game_num tgn
            ON sk.team = tgn.team
            AND sk.date = tgn.date
    )
    
    SELECT player_id,
        `date`,
        CASE WHEN team_game_num - prev_team_game_num - 1  < 0 THEN 0 
             ELSE team_game_num - prev_team_game_num - 1
        END AS games_missed
    FROM lagged
);

-- SELECT COUNT(*) FROM games_missed; -- 280932
-- SELECT * FROM games_missed LIMIT 100;
-- SELECT * FROM games_missed ORDER BY games_missed DESC LIMIT 100;
-- SELECT * FROM games_missed WHERE player_id = 'dorofpa01' ORDER BY `date`;