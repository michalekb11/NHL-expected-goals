-- ---------------------------------------------------------
-- Rolling Per60 View(s) - Demean version
-- ---------------------------------------------------------
-- De-mean the per60 statistics. The goal is to see whether there
-- is additional information in the residuals of these statistics
-- that is predictive of goals scored.

-- To do this, do the following:
    -- For each season, calculate the following
        -- Average of that per 60 statistic over the course of the entire season
        -- Count of the number of game that were included in this calculation
        -- Total ice time that was included in this calculation
        -- If the ice time is low or number of games is low, 
        -- coalesce the per60 value to the average of all players for that season
        -- (for now), potentially placing small weight on their actual value for S60

    -- Take the current value of the per 60 stat over the rolling window
    -- Tack on the season from schedule table.
    -- Join the player averages on rolling SEASON == average SEASON - 1
    -- Subtract the mean from the current value from the per 60 stat
    -- to get the corrected version / excess / residual per 60 value

-- ---------------------------------------------------------
-- Residual rolling 3
-- ---------------------------------------------------------
DROP VIEW IF EXISTS skater_per60_resid_rolling03;

CREATE VIEW skater_per60_resid_rolling03 AS (
    WITH all_players_average AS (
        SELECT sch.season + 1 AS season_plus_one, 
            60 * (SUM(sk.G) / SUM(sk.TOI)) AS G60,
            60 * (SUM(sk.A) / SUM(sk.TOI)) AS A60,
            60 * (SUM(sk.P) / SUM(sk.TOI)) AS P60,
            60 * (SUM(sk.rating) / SUM(sk.TOI)) AS rating60,
            60 * (SUM(sk.PIM) / SUM(sk.TOI)) AS PIM60,
            60 * (SUM(sk.EVG) / SUM(sk.TOI)) AS EVG60,
            60 * (SUM(sk.PPG) / SUM(sk.TOI)) AS PPG60,
            60 * (SUM(sk.SHG) / SUM(sk.TOI)) AS SHG60,
            60 * (SUM(sk.GWG) / SUM(sk.TOI)) AS GWG60,
            60 * (SUM(sk.EVA) / SUM(sk.TOI)) AS EVA60,
            60 * (SUM(sk.PPA) / SUM(sk.TOI)) AS PPA60,
            60 * (SUM(sk.SHA) / SUM(sk.TOI)) AS SHA60,
            60 * (SUM(sk.S) / SUM(sk.TOI)) AS S60,
            60 * (SUM(sk.shifts) / SUM(sk.TOI)) AS shifts60,
            (SUM(sk.TOI) / COUNT(*)) AS avg_TOI,
            60 * (SUM(sk.HIT) / SUM(sk.TOI)) AS HIT60,
            60 * (SUM(sk.BLK) / SUM(sk.TOI)) AS BLK60,
            60 * (SUM(sk.FOW) / SUM(sk.TOI)) AS FOW60,
            60 * (SUM(sk.FOL) / SUM(sk.TOI)) AS FOL60
        FROM skater_game sk
        LEFT JOIN schedule sch
            ON sk.date = sch.date
            AND sk.team = sch.team
        GROUP BY sch.season 

    ),

    player_totals_per_season AS (
        SELECT sk.player_id,
            sch.season + 1 AS season_plus_one, -- set to next season to make join easier in next query
            COUNT(*) AS n_games,
            SUM(sk.TOI) AS TOI_tot,
			SUM(sk.G) AS G_tot,
			SUM(sk.A) AS A_tot,
			SUM(sk.P) AS P_tot,
			SUM(sk.rating) AS rating_tot,
			SUM(sk.PIM) AS PIM_tot,
			SUM(sk.EVG) AS EVG_tot,
			SUM(sk.PPG) AS PPG_tot,
			SUM(sk.SHG) AS SHG_tot,
			SUM(sk.GWG) AS GWG_tot,
			SUM(sk.EVA) AS EVA_tot,
			SUM(sk.PPA) AS PPA_tot,
			SUM(sk.SHA) AS SHA_tot,
			SUM(sk.S) AS S_tot,
			SUM(sk.shifts) AS shifts_tot,
			SUM(sk.HIT) AS HIT_tot,
			SUM(sk.BLK) AS BLK_tot,
			SUM(sk.FOW) AS FOW_tot,
			SUM(sk.FOL) AS FOL_tot
        FROM skater_game sk
        LEFT JOIN schedule sch
            ON sk.date = sch.date
            AND sk.team = sch.team
        GROUP BY sk.player_id,
            sch.season
    ),

    combined_rolling_and_average AS (
        SELECT sk_roll.player_id,
            sk_roll.date,
            sch.season,
            sk_roll.G60_03,
		    sk_roll.A60_03,
            sk_roll.P60_03,
            sk_roll.rating60_03,
            sk_roll.PIM60_03,
            sk_roll.EVG60_03,
            sk_roll.PPG60_03,
            sk_roll.SHG60_03,
            sk_roll.GWG60_03,
            sk_roll.EVA60_03,
            sk_roll.PPA60_03,
            sk_roll.SHA60_03,
            sk_roll.S60_03,
            sk_roll.shifts60_03,
            sk_roll.HIT60_03,
            sk_roll.BLK60_03,
            sk_roll.FOW60_03,
            sk_roll.FOL60_03,
            sk_roll.avgTOI_03,
            -- player_tot.n_games,
            -- player_tot.TOI_tot,
            -- player_tot.S_tot,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.avg_TOI
                ELSE (player_tot.TOI_tot / player_tot.n_games)
            END AS avgTOI_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.G60
                ELSE 60 * (player_tot.G_tot / player_tot.TOI_tot)
            END AS G60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.A60
                ELSE 60 * (player_tot.A_tot / player_tot.TOI_tot)
            END AS A60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.P60
                ELSE 60 * (player_tot.P_tot / player_tot.TOI_tot)
            END AS P60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.rating60
                ELSE 60 * (player_tot.rating_tot / player_tot.TOI_tot)
            END AS rating60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.PIM60
                ELSE 60 * (player_tot.PIM_tot / player_tot.TOI_tot)
            END AS PIM60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.EVG60
                ELSE 60 * (player_tot.EVG_tot / player_tot.TOI_tot)
            END AS EVG60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.PPG60
                ELSE 60 * (player_tot.PPG_tot / player_tot.TOI_tot)
            END AS PPG60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.SHG60
                ELSE 60 * (player_tot.SHG_tot / player_tot.TOI_tot)
            END AS SHG60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.GWG60
                ELSE 60 * (player_tot.GWG_tot / player_tot.TOI_tot)
            END AS GWG60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.EVA60
                ELSE 60 * (player_tot.EVA_tot / player_tot.TOI_tot)
            END AS EVA60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.PPA60
                ELSE 60 * (player_tot.PPA_tot / player_tot.TOI_tot)
            END AS PPA60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.SHA60
                ELSE 60 * (player_tot.SHA_tot / player_tot.TOI_tot)
            END AS SHA60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.S60
                ELSE 60 * (player_tot.S_tot / player_tot.TOI_tot)
            END AS S60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.shifts60
                ELSE 60 * (player_tot.shifts_tot / player_tot.TOI_tot)
            END AS shifts60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.HIT60
                ELSE 60 * (player_tot.HIT_tot / player_tot.TOI_tot)
            END AS HIT60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.BLK60
                ELSE 60 * (player_tot.BLK_tot / player_tot.TOI_tot)
            END AS BLK60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.FOW60
                ELSE 60 * (player_tot.FOW_tot / player_tot.TOI_tot)
            END AS FOW60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.FOL60
                ELSE 60 * (player_tot.FOL_tot / player_tot.TOI_tot)
            END AS FOL60_last_season

        FROM skater_per60_rolling03 sk_roll
        LEFT JOIN skater_game sk
            ON sk_roll.player_id = sk.player_id
            AND sk_roll.date = sk.date
        LEFT JOIN SCHEDULE sch
            ON sk_roll.date = sch.date
            AND sk.team = sch.team
        INNER JOIN player_totals_per_season player_tot
            ON sk.player_id = player_tot.player_id
            AND sch.season  = player_tot.season_plus_one
        LEFT JOIN all_players_average all_player
            ON sch.season = all_player.season_plus_one
    )

    SELECT player_id,
        date,
        G60_03 - G60_last_season AS resid_G60_03,
        A60_03 - A60_last_season AS resid_A60_03,
        P60_03 - P60_last_season AS resid_P60_03,
        rating60_03 - rating60_last_season AS resid_rating60_03,
        PIM60_03 - PIM60_last_season AS resid_PIM60_03,
        EVG60_03 - EVG60_last_season AS resid_EVG60_03,
        PPG60_03 - PPG60_last_season AS resid_PPG60_03,
        SHG60_03 - SHG60_last_season AS resid_SHG60_03,
        GWG60_03 - GWG60_last_season AS resid_GWG60_03,
        EVA60_03 - EVA60_last_season AS resid_EVA60_03,
        PPA60_03 - PPA60_last_season AS resid_PPA60_03,
        SHA60_03 - SHA60_last_season AS resid_SHA60_03,
        S60_03 - S60_last_season AS resid_S60_03,
        shifts60_03 - shifts60_last_season AS resid_shifts60_03,
        HIT60_03 - HIT60_last_season AS resid_HIT60_03,
        BLK60_03 - BLK60_last_season AS resid_BLK60_03,
        FOW60_03 - FOW60_last_season AS resid_FOW60_03,
        FOL60_03 - FOL60_last_season AS resid_FOL60_03,
        avgTOI_03 - avgTOI_last_season AS resid_avgTOI_03
    FROM combined_rolling_and_average
);

-- ---------------------------------------------------------
-- Residual rolling 5
-- ---------------------------------------------------------
DROP VIEW IF EXISTS skater_per60_resid_rolling05;

CREATE VIEW skater_per60_resid_rolling05 AS (
    WITH all_players_average AS (
        SELECT sch.season + 1 AS season_plus_one, 
            60 * (SUM(sk.G) / SUM(sk.TOI)) AS G60,
            60 * (SUM(sk.A) / SUM(sk.TOI)) AS A60,
            60 * (SUM(sk.P) / SUM(sk.TOI)) AS P60,
            60 * (SUM(sk.rating) / SUM(sk.TOI)) AS rating60,
            60 * (SUM(sk.PIM) / SUM(sk.TOI)) AS PIM60,
            60 * (SUM(sk.EVG) / SUM(sk.TOI)) AS EVG60,
            60 * (SUM(sk.PPG) / SUM(sk.TOI)) AS PPG60,
            60 * (SUM(sk.SHG) / SUM(sk.TOI)) AS SHG60,
            60 * (SUM(sk.GWG) / SUM(sk.TOI)) AS GWG60,
            60 * (SUM(sk.EVA) / SUM(sk.TOI)) AS EVA60,
            60 * (SUM(sk.PPA) / SUM(sk.TOI)) AS PPA60,
            60 * (SUM(sk.SHA) / SUM(sk.TOI)) AS SHA60,
            60 * (SUM(sk.S) / SUM(sk.TOI)) AS S60,
            60 * (SUM(sk.shifts) / SUM(sk.TOI)) AS shifts60,
            (SUM(sk.TOI) / COUNT(*)) AS avg_TOI,
            60 * (SUM(sk.HIT) / SUM(sk.TOI)) AS HIT60,
            60 * (SUM(sk.BLK) / SUM(sk.TOI)) AS BLK60,
            60 * (SUM(sk.FOW) / SUM(sk.TOI)) AS FOW60,
            60 * (SUM(sk.FOL) / SUM(sk.TOI)) AS FOL60
        FROM skater_game sk
        LEFT JOIN schedule sch
            ON sk.date = sch.date
            AND sk.team = sch.team
        GROUP BY sch.season 

    ),

    player_totals_per_season AS (
        SELECT sk.player_id,
            sch.season + 1 AS season_plus_one, -- set to next season to make join easier in next query
            COUNT(*) AS n_games,
            SUM(sk.TOI) AS TOI_tot,
			SUM(sk.G) AS G_tot,
			SUM(sk.A) AS A_tot,
			SUM(sk.P) AS P_tot,
			SUM(sk.rating) AS rating_tot,
			SUM(sk.PIM) AS PIM_tot,
			SUM(sk.EVG) AS EVG_tot,
			SUM(sk.PPG) AS PPG_tot,
			SUM(sk.SHG) AS SHG_tot,
			SUM(sk.GWG) AS GWG_tot,
			SUM(sk.EVA) AS EVA_tot,
			SUM(sk.PPA) AS PPA_tot,
			SUM(sk.SHA) AS SHA_tot,
			SUM(sk.S) AS S_tot,
			SUM(sk.shifts) AS shifts_tot,
			SUM(sk.HIT) AS HIT_tot,
			SUM(sk.BLK) AS BLK_tot,
			SUM(sk.FOW) AS FOW_tot,
			SUM(sk.FOL) AS FOL_tot
        FROM skater_game sk
        LEFT JOIN schedule sch
            ON sk.date = sch.date
            AND sk.team = sch.team
        GROUP BY sk.player_id,
            sch.season
    ),

    combined_rolling_and_average AS (
        SELECT sk_roll.player_id,
            sk_roll.date,
            sch.season,
            sk_roll.G60_05,
		    sk_roll.A60_05,
            sk_roll.P60_05,
            sk_roll.rating60_05,
            sk_roll.PIM60_05,
            sk_roll.EVG60_05,
            sk_roll.PPG60_05,
            sk_roll.SHG60_05,
            sk_roll.GWG60_05,
            sk_roll.EVA60_05,
            sk_roll.PPA60_05,
            sk_roll.SHA60_05,
            sk_roll.S60_05,
            sk_roll.shifts60_05,
            sk_roll.HIT60_05,
            sk_roll.BLK60_05,
            sk_roll.FOW60_05,
            sk_roll.FOL60_05,
            sk_roll.avgTOI_05,
            -- player_tot.n_games,
            -- player_tot.TOI_tot,
            -- player_tot.S_tot,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.avg_TOI
                ELSE (player_tot.TOI_tot / player_tot.n_games)
            END AS avgTOI_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.G60
                ELSE 60 * (player_tot.G_tot / player_tot.TOI_tot)
            END AS G60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.A60
                ELSE 60 * (player_tot.A_tot / player_tot.TOI_tot)
            END AS A60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.P60
                ELSE 60 * (player_tot.P_tot / player_tot.TOI_tot)
            END AS P60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.rating60
                ELSE 60 * (player_tot.rating_tot / player_tot.TOI_tot)
            END AS rating60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.PIM60
                ELSE 60 * (player_tot.PIM_tot / player_tot.TOI_tot)
            END AS PIM60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.EVG60
                ELSE 60 * (player_tot.EVG_tot / player_tot.TOI_tot)
            END AS EVG60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.PPG60
                ELSE 60 * (player_tot.PPG_tot / player_tot.TOI_tot)
            END AS PPG60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.SHG60
                ELSE 60 * (player_tot.SHG_tot / player_tot.TOI_tot)
            END AS SHG60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.GWG60
                ELSE 60 * (player_tot.GWG_tot / player_tot.TOI_tot)
            END AS GWG60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.EVA60
                ELSE 60 * (player_tot.EVA_tot / player_tot.TOI_tot)
            END AS EVA60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.PPA60
                ELSE 60 * (player_tot.PPA_tot / player_tot.TOI_tot)
            END AS PPA60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.SHA60
                ELSE 60 * (player_tot.SHA_tot / player_tot.TOI_tot)
            END AS SHA60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.S60
                ELSE 60 * (player_tot.S_tot / player_tot.TOI_tot)
            END AS S60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.shifts60
                ELSE 60 * (player_tot.shifts_tot / player_tot.TOI_tot)
            END AS shifts60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.HIT60
                ELSE 60 * (player_tot.HIT_tot / player_tot.TOI_tot)
            END AS HIT60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.BLK60
                ELSE 60 * (player_tot.BLK_tot / player_tot.TOI_tot)
            END AS BLK60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.FOW60
                ELSE 60 * (player_tot.FOW_tot / player_tot.TOI_tot)
            END AS FOW60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.FOL60
                ELSE 60 * (player_tot.FOL_tot / player_tot.TOI_tot)
            END AS FOL60_last_season

        FROM skater_per60_rolling05 sk_roll
        LEFT JOIN skater_game sk
            ON sk_roll.player_id = sk.player_id
            AND sk_roll.date = sk.date
        LEFT JOIN SCHEDULE sch
            ON sk_roll.date = sch.date
            AND sk.team = sch.team
        INNER JOIN player_totals_per_season player_tot
            ON sk.player_id = player_tot.player_id
            AND sch.season  = player_tot.season_plus_one
        LEFT JOIN all_players_average all_player
            ON sch.season = all_player.season_plus_one
    )

    SELECT player_id,
        date,
        G60_05 - G60_last_season AS resid_G60_05,
        A60_05 - A60_last_season AS resid_A60_05,
        P60_05 - P60_last_season AS resid_P60_05,
        rating60_05 - rating60_last_season AS resid_rating60_05,
        PIM60_05 - PIM60_last_season AS resid_PIM60_05,
        EVG60_05 - EVG60_last_season AS resid_EVG60_05,
        PPG60_05 - PPG60_last_season AS resid_PPG60_05,
        SHG60_05 - SHG60_last_season AS resid_SHG60_05,
        GWG60_05 - GWG60_last_season AS resid_GWG60_05,
        EVA60_05 - EVA60_last_season AS resid_EVA60_05,
        PPA60_05 - PPA60_last_season AS resid_PPA60_05,
        SHA60_05 - SHA60_last_season AS resid_SHA60_05,
        S60_05 - S60_last_season AS resid_S60_05,
        shifts60_05 - shifts60_last_season AS resid_shifts60_05,
        HIT60_05 - HIT60_last_season AS resid_HIT60_05,
        BLK60_05 - BLK60_last_season AS resid_BLK60_05,
        FOW60_05 - FOW60_last_season AS resid_FOW60_05,
        FOL60_05 - FOL60_last_season AS resid_FOL60_05,
        avgTOI_05 - avgTOI_last_season AS resid_avgTOI_05
    FROM combined_rolling_and_average
);

-- ---------------------------------------------------------
-- Residual rolling 10
-- ---------------------------------------------------------
DROP VIEW IF EXISTS skater_per60_resid_rolling10;

CREATE VIEW skater_per60_resid_rolling10 AS (
    WITH all_players_average AS (
        SELECT sch.season + 1 AS season_plus_one, 
            60 * (SUM(sk.G) / SUM(sk.TOI)) AS G60,
            60 * (SUM(sk.A) / SUM(sk.TOI)) AS A60,
            60 * (SUM(sk.P) / SUM(sk.TOI)) AS P60,
            60 * (SUM(sk.rating) / SUM(sk.TOI)) AS rating60,
            60 * (SUM(sk.PIM) / SUM(sk.TOI)) AS PIM60,
            60 * (SUM(sk.EVG) / SUM(sk.TOI)) AS EVG60,
            60 * (SUM(sk.PPG) / SUM(sk.TOI)) AS PPG60,
            60 * (SUM(sk.SHG) / SUM(sk.TOI)) AS SHG60,
            60 * (SUM(sk.GWG) / SUM(sk.TOI)) AS GWG60,
            60 * (SUM(sk.EVA) / SUM(sk.TOI)) AS EVA60,
            60 * (SUM(sk.PPA) / SUM(sk.TOI)) AS PPA60,
            60 * (SUM(sk.SHA) / SUM(sk.TOI)) AS SHA60,
            60 * (SUM(sk.S) / SUM(sk.TOI)) AS S60,
            60 * (SUM(sk.shifts) / SUM(sk.TOI)) AS shifts60,
            (SUM(sk.TOI) / COUNT(*)) AS avg_TOI,
            60 * (SUM(sk.HIT) / SUM(sk.TOI)) AS HIT60,
            60 * (SUM(sk.BLK) / SUM(sk.TOI)) AS BLK60,
            60 * (SUM(sk.FOW) / SUM(sk.TOI)) AS FOW60,
            60 * (SUM(sk.FOL) / SUM(sk.TOI)) AS FOL60
        FROM skater_game sk
        LEFT JOIN schedule sch
            ON sk.date = sch.date
            AND sk.team = sch.team
        GROUP BY sch.season 

    ),

    player_totals_per_season AS (
        SELECT sk.player_id,
            sch.season + 1 AS season_plus_one, -- set to next season to make join easier in next query
            COUNT(*) AS n_games,
            SUM(sk.TOI) AS TOI_tot,
			SUM(sk.G) AS G_tot,
			SUM(sk.A) AS A_tot,
			SUM(sk.P) AS P_tot,
			SUM(sk.rating) AS rating_tot,
			SUM(sk.PIM) AS PIM_tot,
			SUM(sk.EVG) AS EVG_tot,
			SUM(sk.PPG) AS PPG_tot,
			SUM(sk.SHG) AS SHG_tot,
			SUM(sk.GWG) AS GWG_tot,
			SUM(sk.EVA) AS EVA_tot,
			SUM(sk.PPA) AS PPA_tot,
			SUM(sk.SHA) AS SHA_tot,
			SUM(sk.S) AS S_tot,
			SUM(sk.shifts) AS shifts_tot,
			SUM(sk.HIT) AS HIT_tot,
			SUM(sk.BLK) AS BLK_tot,
			SUM(sk.FOW) AS FOW_tot,
			SUM(sk.FOL) AS FOL_tot
        FROM skater_game sk
        LEFT JOIN schedule sch
            ON sk.date = sch.date
            AND sk.team = sch.team
        GROUP BY sk.player_id,
            sch.season
    ),

    combined_rolling_and_average AS (
        SELECT sk_roll.player_id,
            sk_roll.date,
            sch.season,
            sk_roll.G60_10,
		    sk_roll.A60_10,
            sk_roll.P60_10,
            sk_roll.rating60_10,
            sk_roll.PIM60_10,
            sk_roll.EVG60_10,
            sk_roll.PPG60_10,
            sk_roll.SHG60_10,
            sk_roll.GWG60_10,
            sk_roll.EVA60_10,
            sk_roll.PPA60_10,
            sk_roll.SHA60_10,
            sk_roll.S60_10,
            sk_roll.shifts60_10,
            sk_roll.HIT60_10,
            sk_roll.BLK60_10,
            sk_roll.FOW60_10,
            sk_roll.FOL60_10,
            sk_roll.avgTOI_10,
            -- player_tot.n_games,
            -- player_tot.TOI_tot,
            -- player_tot.S_tot,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.avg_TOI
                ELSE (player_tot.TOI_tot / player_tot.n_games)
            END AS avgTOI_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.G60
                ELSE 60 * (player_tot.G_tot / player_tot.TOI_tot)
            END AS G60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.A60
                ELSE 60 * (player_tot.A_tot / player_tot.TOI_tot)
            END AS A60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.P60
                ELSE 60 * (player_tot.P_tot / player_tot.TOI_tot)
            END AS P60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.rating60
                ELSE 60 * (player_tot.rating_tot / player_tot.TOI_tot)
            END AS rating60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.PIM60
                ELSE 60 * (player_tot.PIM_tot / player_tot.TOI_tot)
            END AS PIM60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.EVG60
                ELSE 60 * (player_tot.EVG_tot / player_tot.TOI_tot)
            END AS EVG60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.PPG60
                ELSE 60 * (player_tot.PPG_tot / player_tot.TOI_tot)
            END AS PPG60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.SHG60
                ELSE 60 * (player_tot.SHG_tot / player_tot.TOI_tot)
            END AS SHG60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.GWG60
                ELSE 60 * (player_tot.GWG_tot / player_tot.TOI_tot)
            END AS GWG60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.EVA60
                ELSE 60 * (player_tot.EVA_tot / player_tot.TOI_tot)
            END AS EVA60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.PPA60
                ELSE 60 * (player_tot.PPA_tot / player_tot.TOI_tot)
            END AS PPA60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.SHA60
                ELSE 60 * (player_tot.SHA_tot / player_tot.TOI_tot)
            END AS SHA60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.S60
                ELSE 60 * (player_tot.S_tot / player_tot.TOI_tot)
            END AS S60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.shifts60
                ELSE 60 * (player_tot.shifts_tot / player_tot.TOI_tot)
            END AS shifts60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.HIT60
                ELSE 60 * (player_tot.HIT_tot / player_tot.TOI_tot)
            END AS HIT60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.BLK60
                ELSE 60 * (player_tot.BLK_tot / player_tot.TOI_tot)
            END AS BLK60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.FOW60
                ELSE 60 * (player_tot.FOW_tot / player_tot.TOI_tot)
            END AS FOW60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.FOL60
                ELSE 60 * (player_tot.FOL_tot / player_tot.TOI_tot)
            END AS FOL60_last_season

        FROM skater_per60_rolling10 sk_roll
        LEFT JOIN skater_game sk
            ON sk_roll.player_id = sk.player_id
            AND sk_roll.date = sk.date
        LEFT JOIN SCHEDULE sch
            ON sk_roll.date = sch.date
            AND sk.team = sch.team
        INNER JOIN player_totals_per_season player_tot
            ON sk.player_id = player_tot.player_id
            AND sch.season  = player_tot.season_plus_one
        LEFT JOIN all_players_average all_player
            ON sch.season = all_player.season_plus_one
    )

    SELECT player_id,
        date,
        G60_10 - G60_last_season AS resid_G60_10,
        A60_10 - A60_last_season AS resid_A60_10,
        P60_10 - P60_last_season AS resid_P60_10,
        rating60_10 - rating60_last_season AS resid_rating60_10,
        PIM60_10 - PIM60_last_season AS resid_PIM60_10,
        EVG60_10 - EVG60_last_season AS resid_EVG60_10,
        PPG60_10 - PPG60_last_season AS resid_PPG60_10,
        SHG60_10 - SHG60_last_season AS resid_SHG60_10,
        GWG60_10 - GWG60_last_season AS resid_GWG60_10,
        EVA60_10 - EVA60_last_season AS resid_EVA60_10,
        PPA60_10 - PPA60_last_season AS resid_PPA60_10,
        SHA60_10 - SHA60_last_season AS resid_SHA60_10,
        S60_10 - S60_last_season AS resid_S60_10,
        shifts60_10 - shifts60_last_season AS resid_shifts60_10,
        HIT60_10 - HIT60_last_season AS resid_HIT60_10,
        BLK60_10 - BLK60_last_season AS resid_BLK60_10,
        FOW60_10 - FOW60_last_season AS resid_FOW60_10,
        FOL60_10 - FOL60_last_season AS resid_FOL60_10,
        avgTOI_10 - avgTOI_last_season AS resid_avgTOI_10
    FROM combined_rolling_and_average
);

-- ---------------------------------------------------------
-- Residual rolling 15
-- ---------------------------------------------------------
DROP VIEW IF EXISTS skater_per60_resid_rolling15;

CREATE VIEW skater_per60_resid_rolling15 AS (
    WITH all_players_average AS (
        SELECT sch.season + 1 AS season_plus_one, 
            60 * (SUM(sk.G) / SUM(sk.TOI)) AS G60,
            60 * (SUM(sk.A) / SUM(sk.TOI)) AS A60,
            60 * (SUM(sk.P) / SUM(sk.TOI)) AS P60,
            60 * (SUM(sk.rating) / SUM(sk.TOI)) AS rating60,
            60 * (SUM(sk.PIM) / SUM(sk.TOI)) AS PIM60,
            60 * (SUM(sk.EVG) / SUM(sk.TOI)) AS EVG60,
            60 * (SUM(sk.PPG) / SUM(sk.TOI)) AS PPG60,
            60 * (SUM(sk.SHG) / SUM(sk.TOI)) AS SHG60,
            60 * (SUM(sk.GWG) / SUM(sk.TOI)) AS GWG60,
            60 * (SUM(sk.EVA) / SUM(sk.TOI)) AS EVA60,
            60 * (SUM(sk.PPA) / SUM(sk.TOI)) AS PPA60,
            60 * (SUM(sk.SHA) / SUM(sk.TOI)) AS SHA60,
            60 * (SUM(sk.S) / SUM(sk.TOI)) AS S60,
            60 * (SUM(sk.shifts) / SUM(sk.TOI)) AS shifts60,
            (SUM(sk.TOI) / COUNT(*)) AS avg_TOI,
            60 * (SUM(sk.HIT) / SUM(sk.TOI)) AS HIT60,
            60 * (SUM(sk.BLK) / SUM(sk.TOI)) AS BLK60,
            60 * (SUM(sk.FOW) / SUM(sk.TOI)) AS FOW60,
            60 * (SUM(sk.FOL) / SUM(sk.TOI)) AS FOL60
        FROM skater_game sk
        LEFT JOIN schedule sch
            ON sk.date = sch.date
            AND sk.team = sch.team
        GROUP BY sch.season 

    ),

    player_totals_per_season AS (
        SELECT sk.player_id,
            sch.season + 1 AS season_plus_one, -- set to next season to make join easier in next query
            COUNT(*) AS n_games,
            SUM(sk.TOI) AS TOI_tot,
			SUM(sk.G) AS G_tot,
			SUM(sk.A) AS A_tot,
			SUM(sk.P) AS P_tot,
			SUM(sk.rating) AS rating_tot,
			SUM(sk.PIM) AS PIM_tot,
			SUM(sk.EVG) AS EVG_tot,
			SUM(sk.PPG) AS PPG_tot,
			SUM(sk.SHG) AS SHG_tot,
			SUM(sk.GWG) AS GWG_tot,
			SUM(sk.EVA) AS EVA_tot,
			SUM(sk.PPA) AS PPA_tot,
			SUM(sk.SHA) AS SHA_tot,
			SUM(sk.S) AS S_tot,
			SUM(sk.shifts) AS shifts_tot,
			SUM(sk.HIT) AS HIT_tot,
			SUM(sk.BLK) AS BLK_tot,
			SUM(sk.FOW) AS FOW_tot,
			SUM(sk.FOL) AS FOL_tot
        FROM skater_game sk
        LEFT JOIN schedule sch
            ON sk.date = sch.date
            AND sk.team = sch.team
        GROUP BY sk.player_id,
            sch.season
    ),

    combined_rolling_and_average AS (
        SELECT sk_roll.player_id,
            sk_roll.date,
            sch.season,
            sk_roll.G60_15,
		    sk_roll.A60_15,
            sk_roll.P60_15,
            sk_roll.rating60_15,
            sk_roll.PIM60_15,
            sk_roll.EVG60_15,
            sk_roll.PPG60_15,
            sk_roll.SHG60_15,
            sk_roll.GWG60_15,
            sk_roll.EVA60_15,
            sk_roll.PPA60_15,
            sk_roll.SHA60_15,
            sk_roll.S60_15,
            sk_roll.shifts60_15,
            sk_roll.HIT60_15,
            sk_roll.BLK60_15,
            sk_roll.FOW60_15,
            sk_roll.FOL60_15,
            sk_roll.avgTOI_15,
            -- player_tot.n_games,
            -- player_tot.TOI_tot,
            -- player_tot.S_tot,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.avg_TOI
                ELSE (player_tot.TOI_tot / player_tot.n_games)
            END AS avgTOI_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.G60
                ELSE 60 * (player_tot.G_tot / player_tot.TOI_tot)
            END AS G60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.A60
                ELSE 60 * (player_tot.A_tot / player_tot.TOI_tot)
            END AS A60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.P60
                ELSE 60 * (player_tot.P_tot / player_tot.TOI_tot)
            END AS P60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.rating60
                ELSE 60 * (player_tot.rating_tot / player_tot.TOI_tot)
            END AS rating60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.PIM60
                ELSE 60 * (player_tot.PIM_tot / player_tot.TOI_tot)
            END AS PIM60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.EVG60
                ELSE 60 * (player_tot.EVG_tot / player_tot.TOI_tot)
            END AS EVG60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.PPG60
                ELSE 60 * (player_tot.PPG_tot / player_tot.TOI_tot)
            END AS PPG60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.SHG60
                ELSE 60 * (player_tot.SHG_tot / player_tot.TOI_tot)
            END AS SHG60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.GWG60
                ELSE 60 * (player_tot.GWG_tot / player_tot.TOI_tot)
            END AS GWG60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.EVA60
                ELSE 60 * (player_tot.EVA_tot / player_tot.TOI_tot)
            END AS EVA60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.PPA60
                ELSE 60 * (player_tot.PPA_tot / player_tot.TOI_tot)
            END AS PPA60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.SHA60
                ELSE 60 * (player_tot.SHA_tot / player_tot.TOI_tot)
            END AS SHA60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.S60
                ELSE 60 * (player_tot.S_tot / player_tot.TOI_tot)
            END AS S60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.shifts60
                ELSE 60 * (player_tot.shifts_tot / player_tot.TOI_tot)
            END AS shifts60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.HIT60
                ELSE 60 * (player_tot.HIT_tot / player_tot.TOI_tot)
            END AS HIT60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.BLK60
                ELSE 60 * (player_tot.BLK_tot / player_tot.TOI_tot)
            END AS BLK60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.FOW60
                ELSE 60 * (player_tot.FOW_tot / player_tot.TOI_tot)
            END AS FOW60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.FOL60
                ELSE 60 * (player_tot.FOL_tot / player_tot.TOI_tot)
            END AS FOL60_last_season

        FROM skater_per60_rolling15 sk_roll
        LEFT JOIN skater_game sk
            ON sk_roll.player_id = sk.player_id
            AND sk_roll.date = sk.date
        LEFT JOIN SCHEDULE sch
            ON sk_roll.date = sch.date
            AND sk.team = sch.team
        INNER JOIN player_totals_per_season player_tot
            ON sk.player_id = player_tot.player_id
            AND sch.season  = player_tot.season_plus_one
        LEFT JOIN all_players_average all_player
            ON sch.season = all_player.season_plus_one
    )

    SELECT player_id,
        date,
        G60_15 - G60_last_season AS resid_G60_15,
        A60_15 - A60_last_season AS resid_A60_15,
        P60_15 - P60_last_season AS resid_P60_15,
        rating60_15 - rating60_last_season AS resid_rating60_15,
        PIM60_15 - PIM60_last_season AS resid_PIM60_15,
        EVG60_15 - EVG60_last_season AS resid_EVG60_15,
        PPG60_15 - PPG60_last_season AS resid_PPG60_15,
        SHG60_15 - SHG60_last_season AS resid_SHG60_15,
        GWG60_15 - GWG60_last_season AS resid_GWG60_15,
        EVA60_15 - EVA60_last_season AS resid_EVA60_15,
        PPA60_15 - PPA60_last_season AS resid_PPA60_15,
        SHA60_15 - SHA60_last_season AS resid_SHA60_15,
        S60_15 - S60_last_season AS resid_S60_15,
        shifts60_15 - shifts60_last_season AS resid_shifts60_15,
        HIT60_15 - HIT60_last_season AS resid_HIT60_15,
        BLK60_15 - BLK60_last_season AS resid_BLK60_15,
        FOW60_15 - FOW60_last_season AS resid_FOW60_15,
        FOL60_15 - FOL60_last_season AS resid_FOL60_15,
        avgTOI_15 - avgTOI_last_season AS resid_avgTOI_15
    FROM combined_rolling_and_average
);

-- ---------------------------------------------------------
-- Residual rolling 20
-- ---------------------------------------------------------
DROP VIEW IF EXISTS skater_per60_resid_rolling20;

CREATE VIEW skater_per60_resid_rolling20 AS (
    WITH all_players_average AS (
        SELECT sch.season + 1 AS season_plus_one, 
            60 * (SUM(sk.G) / SUM(sk.TOI)) AS G60,
            60 * (SUM(sk.A) / SUM(sk.TOI)) AS A60,
            60 * (SUM(sk.P) / SUM(sk.TOI)) AS P60,
            60 * (SUM(sk.rating) / SUM(sk.TOI)) AS rating60,
            60 * (SUM(sk.PIM) / SUM(sk.TOI)) AS PIM60,
            60 * (SUM(sk.EVG) / SUM(sk.TOI)) AS EVG60,
            60 * (SUM(sk.PPG) / SUM(sk.TOI)) AS PPG60,
            60 * (SUM(sk.SHG) / SUM(sk.TOI)) AS SHG60,
            60 * (SUM(sk.GWG) / SUM(sk.TOI)) AS GWG60,
            60 * (SUM(sk.EVA) / SUM(sk.TOI)) AS EVA60,
            60 * (SUM(sk.PPA) / SUM(sk.TOI)) AS PPA60,
            60 * (SUM(sk.SHA) / SUM(sk.TOI)) AS SHA60,
            60 * (SUM(sk.S) / SUM(sk.TOI)) AS S60,
            60 * (SUM(sk.shifts) / SUM(sk.TOI)) AS shifts60,
            (SUM(sk.TOI) / COUNT(*)) AS avg_TOI,
            60 * (SUM(sk.HIT) / SUM(sk.TOI)) AS HIT60,
            60 * (SUM(sk.BLK) / SUM(sk.TOI)) AS BLK60,
            60 * (SUM(sk.FOW) / SUM(sk.TOI)) AS FOW60,
            60 * (SUM(sk.FOL) / SUM(sk.TOI)) AS FOL60
        FROM skater_game sk
        LEFT JOIN schedule sch
            ON sk.date = sch.date
            AND sk.team = sch.team
        GROUP BY sch.season 

    ),

    player_totals_per_season AS (
        SELECT sk.player_id,
            sch.season + 1 AS season_plus_one, -- set to next season to make join easier in next query
            COUNT(*) AS n_games,
            SUM(sk.TOI) AS TOI_tot,
			SUM(sk.G) AS G_tot,
			SUM(sk.A) AS A_tot,
			SUM(sk.P) AS P_tot,
			SUM(sk.rating) AS rating_tot,
			SUM(sk.PIM) AS PIM_tot,
			SUM(sk.EVG) AS EVG_tot,
			SUM(sk.PPG) AS PPG_tot,
			SUM(sk.SHG) AS SHG_tot,
			SUM(sk.GWG) AS GWG_tot,
			SUM(sk.EVA) AS EVA_tot,
			SUM(sk.PPA) AS PPA_tot,
			SUM(sk.SHA) AS SHA_tot,
			SUM(sk.S) AS S_tot,
			SUM(sk.shifts) AS shifts_tot,
			SUM(sk.HIT) AS HIT_tot,
			SUM(sk.BLK) AS BLK_tot,
			SUM(sk.FOW) AS FOW_tot,
			SUM(sk.FOL) AS FOL_tot
        FROM skater_game sk
        LEFT JOIN schedule sch
            ON sk.date = sch.date
            AND sk.team = sch.team
        GROUP BY sk.player_id,
            sch.season
    ),

    combined_rolling_and_average AS (
        SELECT sk_roll.player_id,
            sk_roll.date,
            sch.season,
            sk_roll.G60_20,
		    sk_roll.A60_20,
            sk_roll.P60_20,
            sk_roll.rating60_20,
            sk_roll.PIM60_20,
            sk_roll.EVG60_20,
            sk_roll.PPG60_20,
            sk_roll.SHG60_20,
            sk_roll.GWG60_20,
            sk_roll.EVA60_20,
            sk_roll.PPA60_20,
            sk_roll.SHA60_20,
            sk_roll.S60_20,
            sk_roll.shifts60_20,
            sk_roll.HIT60_20,
            sk_roll.BLK60_20,
            sk_roll.FOW60_20,
            sk_roll.FOL60_20,
            sk_roll.avgTOI_20,
            -- player_tot.n_games,
            -- player_tot.TOI_tot,
            -- player_tot.S_tot,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.avg_TOI
                ELSE (player_tot.TOI_tot / player_tot.n_games)
            END AS avgTOI_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.G60
                ELSE 60 * (player_tot.G_tot / player_tot.TOI_tot)
            END AS G60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.A60
                ELSE 60 * (player_tot.A_tot / player_tot.TOI_tot)
            END AS A60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.P60
                ELSE 60 * (player_tot.P_tot / player_tot.TOI_tot)
            END AS P60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.rating60
                ELSE 60 * (player_tot.rating_tot / player_tot.TOI_tot)
            END AS rating60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.PIM60
                ELSE 60 * (player_tot.PIM_tot / player_tot.TOI_tot)
            END AS PIM60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.EVG60
                ELSE 60 * (player_tot.EVG_tot / player_tot.TOI_tot)
            END AS EVG60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.PPG60
                ELSE 60 * (player_tot.PPG_tot / player_tot.TOI_tot)
            END AS PPG60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.SHG60
                ELSE 60 * (player_tot.SHG_tot / player_tot.TOI_tot)
            END AS SHG60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.GWG60
                ELSE 60 * (player_tot.GWG_tot / player_tot.TOI_tot)
            END AS GWG60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.EVA60
                ELSE 60 * (player_tot.EVA_tot / player_tot.TOI_tot)
            END AS EVA60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.PPA60
                ELSE 60 * (player_tot.PPA_tot / player_tot.TOI_tot)
            END AS PPA60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.SHA60
                ELSE 60 * (player_tot.SHA_tot / player_tot.TOI_tot)
            END AS SHA60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.S60
                ELSE 60 * (player_tot.S_tot / player_tot.TOI_tot)
            END AS S60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.shifts60
                ELSE 60 * (player_tot.shifts_tot / player_tot.TOI_tot)
            END AS shifts60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.HIT60
                ELSE 60 * (player_tot.HIT_tot / player_tot.TOI_tot)
            END AS HIT60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.BLK60
                ELSE 60 * (player_tot.BLK_tot / player_tot.TOI_tot)
            END AS BLK60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.FOW60
                ELSE 60 * (player_tot.FOW_tot / player_tot.TOI_tot)
            END AS FOW60_last_season,

            CASE
                WHEN player_tot.n_games IS NULL OR player_tot.n_games <= 5 OR player_tot.TOI_tot IS NULL OR player_tot.TOI_tot <= 50 THEN all_player.FOL60
                ELSE 60 * (player_tot.FOL_tot / player_tot.TOI_tot)
            END AS FOL60_last_season

        FROM skater_per60_rolling20 sk_roll
        LEFT JOIN skater_game sk
            ON sk_roll.player_id = sk.player_id
            AND sk_roll.date = sk.date
        LEFT JOIN SCHEDULE sch
            ON sk_roll.date = sch.date
            AND sk.team = sch.team
        INNER JOIN player_totals_per_season player_tot
            ON sk.player_id = player_tot.player_id
            AND sch.season  = player_tot.season_plus_one
        LEFT JOIN all_players_average all_player
            ON sch.season = all_player.season_plus_one
    )

    SELECT player_id,
        `date`,
        G60_20 - G60_last_season AS resid_G60_20,
        A60_20 - A60_last_season AS resid_A60_20,
        P60_20 - P60_last_season AS resid_P60_20,
        rating60_20 - rating60_last_season AS resid_rating60_20,
        PIM60_20 - PIM60_last_season AS resid_PIM60_20,
        EVG60_20 - EVG60_last_season AS resid_EVG60_20,
        PPG60_20 - PPG60_last_season AS resid_PPG60_20,
        SHG60_20 - SHG60_last_season AS resid_SHG60_20,
        GWG60_20 - GWG60_last_season AS resid_GWG60_20,
        EVA60_20 - EVA60_last_season AS resid_EVA60_20,
        PPA60_20 - PPA60_last_season AS resid_PPA60_20,
        SHA60_20 - SHA60_last_season AS resid_SHA60_20,
        S60_20 - S60_last_season AS resid_S60_20,
        shifts60_20 - shifts60_last_season AS resid_shifts60_20,
        HIT60_20 - HIT60_last_season AS resid_HIT60_20,
        BLK60_20 - BLK60_last_season AS resid_BLK60_20,
        FOW60_20 - FOW60_last_season AS resid_FOW60_20,
        FOL60_20 - FOL60_last_season AS resid_FOL60_20,
        avgTOI_20 - avgTOI_last_season AS resid_avgTOI_20
    FROM combined_rolling_and_average
);