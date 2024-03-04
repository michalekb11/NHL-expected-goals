-- ---------------------------------------------------------
-- Rolling Per60 View(s)
-- ---------------------------------------------------------
-- Create a View that will give the per60 player statistics over various rolling windows
-- Ex: could be the previous 3 games, previous 5 games, etc. 
-- Rows should only be returned if the player has played the required number of games
-- specified by the rolling window. All of the previous games should be part of the same season.

-- Future improvement: If the games are outdated (say a player just recovered from a 4 month injury),
-- either scrap those games, or place a lower weight on those games.

-- Note: These views are not the most optimized. The filtering occurs after the view query has been run.

-- ---------------------------------------------------------
-- View for last 3 games
DROP VIEW IF EXISTS skater_per60_rolling03;

CREATE VIEW skater_per60_rolling03 AS (
	WITH rows_not_null AS (
		SELECT *
		FROM skater_game
		WHERE G IS NOT NULL
			AND A IS NOT NULL
			AND P IS NOT NULL
			AND rating IS NOT NULL
			AND PIM IS NOT NULL
			AND EVG IS NOT NULL
			AND PPG IS NOT NULL
			AND SHG IS NOT NULL
			AND GWG IS NOT NULL
			AND EVA IS NOT NULL
			AND PPA IS NOT NULL
			AND SHA IS NOT NULL
			AND S IS NOT NULL
			AND TOI IS NOT NULL
			AND HIT IS NOT NULL
			AND BLK IS NOT NULL
			AND FOW IS NOT NULL
			AND FOL IS NOT NULL
	),
	
	stat_totals AS (
		SELECT sk.player_id,
			sk.team,
			sk.date,
            sk.game_num,
			COUNT(*) OVER (PARTITION BY sk.player_id, sched.season ORDER BY sk.date) AS n_not_null,
			-- COUNT(*) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) AS n,
			SUM(sk.TOI) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) AS TOI_tot,
			SUM(sk.G) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) AS G_tot,
			SUM(sk.A) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) AS A_tot,
			SUM(sk.P) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) AS P_tot,
			SUM(sk.rating) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) AS rating_tot,
			SUM(sk.PIM) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) AS PIM_tot,
			SUM(sk.EVG) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) AS EVG_tot,
			SUM(sk.PPG) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) AS PPG_tot,
			SUM(sk.SHG) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) AS SHG_tot,
			SUM(sk.GWG) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) AS GWG_tot,
			SUM(sk.EVA) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) AS EVA_tot,
			SUM(sk.PPA) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) AS PPA_tot,
			SUM(sk.SHA) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) AS SHA_tot,
			SUM(sk.S) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) AS S_tot,
			SUM(sk.shifts) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) AS shifts_tot,
			SUM(sk.HIT) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) AS HIT_tot,
			SUM(sk.BLK) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) AS BLK_tot,
			SUM(sk.FOW) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) AS FOW_tot,
			SUM(sk.FOL) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) AS FOL_tot
		FROM rows_not_null sk
        LEFT JOIN SCHEDULE sched
			ON sk.team = sched.team
            AND sk.date = sched.date
	)

	SELECT player_id,
		`date`,
		60 * (G_tot / TOI_tot) AS G60_03,
		60 * (A_tot / TOI_tot) AS A60_03,
		60 * (P_tot / TOI_tot) AS P60_03,
		60 * (rating_tot / TOI_tot) AS rating60_03,
		60 * (PIM_tot / TOI_tot) AS PIM60_03,
		60 * (EVG_tot / TOI_tot) AS EVG60_03,
		60 * (PPG_tot / TOI_tot) AS PPG60_03,
		60 * (SHG_tot / TOI_tot) AS SHG60_03,
		60 * (GWG_tot / TOI_tot) AS GWG60_03,
		60 * (EVA_tot / TOI_tot) AS EVA60_03,
		60 * (PPA_tot / TOI_tot) AS PPA60_03,
		60 * (SHA_tot / TOI_tot) AS SHA60_03,
		60 * (S_tot / TOI_tot) AS S60_03,
		60 * (shifts_tot / TOI_tot) AS shifts60_03,
		60 * (HIT_tot / TOI_tot) AS HIT60_03,
		60 * (BLK_tot / TOI_tot) AS BLK60_03,
		60 * (FOW_tot / TOI_tot) AS FOW60_03,
		60 * (FOL_tot / TOI_tot) AS FOL60_03,
		TOI_tot / 3 AS avgTOI_03
	FROM stat_totals
	WHERE n_not_null > 3
);

-- Check results
-- SELECT * FROM skater_per60_rolling03 LIMIT 100;
-- SELECT count(*) FROM skater_per60_rolling03; -- 117,367
-- SELECT count(*) FROM skater_game WHERE game_num > 3; -- 117,367

-- ---------------------------------------------------------
-- View for last 5 games
DROP VIEW IF EXISTS skater_per60_rolling05;

CREATE VIEW skater_per60_rolling05 AS (
	WITH rows_not_null AS (
		SELECT *
		FROM skater_game
		WHERE G IS NOT NULL
			AND A IS NOT NULL
			AND P IS NOT NULL
			AND rating IS NOT NULL
			AND PIM IS NOT NULL
			AND EVG IS NOT NULL
			AND PPG IS NOT NULL
			AND SHG IS NOT NULL
			AND GWG IS NOT NULL
			AND EVA IS NOT NULL
			AND PPA IS NOT NULL
			AND SHA IS NOT NULL
			AND S IS NOT NULL
			AND TOI IS NOT NULL
			AND HIT IS NOT NULL
			AND BLK IS NOT NULL
			AND FOW IS NOT NULL
			AND FOL IS NOT NULL
	),
	
	stat_totals AS (
		SELECT sk.player_id,
			sk.team,
			sk.date,
            sk.game_num,
			COUNT(*) OVER (PARTITION BY sk.player_id, sched.season ORDER BY sk.date) AS n_not_null,
			-- COUNT(*) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING) AS n,
			SUM(sk.TOI) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING) AS TOI_tot,
			SUM(sk.G) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING) AS G_tot,
			SUM(sk.A) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING) AS A_tot,
			SUM(sk.P) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING) AS P_tot,
			SUM(sk.rating) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING) AS rating_tot,
			SUM(sk.PIM) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING) AS PIM_tot,
			SUM(sk.EVG) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING) AS EVG_tot,
			SUM(sk.PPG) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING) AS PPG_tot,
			SUM(sk.SHG) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING) AS SHG_tot,
			SUM(sk.GWG) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING) AS GWG_tot,
			SUM(sk.EVA) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING) AS EVA_tot,
			SUM(sk.PPA) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING) AS PPA_tot,
			SUM(sk.SHA) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING) AS SHA_tot,
			SUM(sk.S) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING) AS S_tot,
			SUM(sk.shifts) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING) AS shifts_tot,
			SUM(sk.HIT) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING) AS HIT_tot,
			SUM(sk.BLK) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING) AS BLK_tot,
			SUM(sk.FOW) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING) AS FOW_tot,
			SUM(sk.FOL) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING) AS FOL_tot
		FROM rows_not_null sk
        LEFT JOIN SCHEDULE sched
			ON sk.team = sched.team
            AND sk.date = sched.date
	)

	SELECT player_id,
		`date`,
		60 * (G_tot / TOI_tot) AS G60_05,
		60 * (A_tot / TOI_tot) AS A60_05,
		60 * (P_tot / TOI_tot) AS P60_05,
		60 * (rating_tot / TOI_tot) AS rating60_05,
		60 * (PIM_tot / TOI_tot) AS PIM60_05,
		60 * (EVG_tot / TOI_tot) AS EVG60_05,
		60 * (PPG_tot / TOI_tot) AS PPG60_05,
		60 * (SHG_tot / TOI_tot) AS SHG60_05,
		60 * (GWG_tot / TOI_tot) AS GWG60_05,
		60 * (EVA_tot / TOI_tot) AS EVA60_05,
		60 * (PPA_tot / TOI_tot) AS PPA60_05,
		60 * (SHA_tot / TOI_tot) AS SHA60_05,
		60 * (S_tot / TOI_tot) AS S60_05,
		60 * (shifts_tot / TOI_tot) AS shifts60_05,
		60 * (HIT_tot / TOI_tot) AS HIT60_05,
		60 * (BLK_tot / TOI_tot) AS BLK60_05,
		60 * (FOW_tot / TOI_tot) AS FOW60_05,
		60 * (FOL_tot / TOI_tot) AS FOL60_05,
		TOI_tot / 5 AS avgTOI_05
	FROM stat_totals
	WHERE n_not_null > 5
);

-- Check results
-- SELECT * FROM skater_per60_rolling05 LIMIT 100;
-- SELECT count(*) FROM skater_per60_rolling05; -- 112,219
-- SELECT count(*) FROM skater_game WHERE game_num > 5; -- 112,219

-- ---------------------------------------------------------
-- View for last 10 games
DROP VIEW IF EXISTS skater_per60_rolling10;

CREATE VIEW skater_per60_rolling05 AS (
	WITH rows_not_null AS (
		SELECT *
		FROM skater_game
		WHERE G IS NOT NULL
			AND A IS NOT NULL
			AND P IS NOT NULL
			AND rating IS NOT NULL
			AND PIM IS NOT NULL
			AND EVG IS NOT NULL
			AND PPG IS NOT NULL
			AND SHG IS NOT NULL
			AND GWG IS NOT NULL
			AND EVA IS NOT NULL
			AND PPA IS NOT NULL
			AND SHA IS NOT NULL
			AND S IS NOT NULL
			AND TOI IS NOT NULL
			AND HIT IS NOT NULL
			AND BLK IS NOT NULL
			AND FOW IS NOT NULL
			AND FOL IS NOT NULL
	),
	
	stat_totals AS (
		SELECT sk.player_id,
			sk.team,
			sk.date,
            sk.game_num,
			COUNT(*) OVER (PARTITION BY sk.player_id, sched.season ORDER BY sk.date) AS n_not_null,
			-- COUNT(*) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING) AS n,
			SUM(sk.TOI) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING) AS TOI_tot,
			SUM(sk.G) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING) AS G_tot,
			SUM(sk.A) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING) AS A_tot,
			SUM(sk.P) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING) AS P_tot,
			SUM(sk.rating) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING) AS rating_tot,
			SUM(sk.PIM) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING) AS PIM_tot,
			SUM(sk.EVG) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING) AS EVG_tot,
			SUM(sk.PPG) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING) AS PPG_tot,
			SUM(sk.SHG) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING) AS SHG_tot,
			SUM(sk.GWG) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING) AS GWG_tot,
			SUM(sk.EVA) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING) AS EVA_tot,
			SUM(sk.PPA) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING) AS PPA_tot,
			SUM(sk.SHA) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING) AS SHA_tot,
			SUM(sk.S) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING) AS S_tot,
			SUM(sk.shifts) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING) AS shifts_tot,
			SUM(sk.HIT) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING) AS HIT_tot,
			SUM(sk.BLK) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING) AS BLK_tot,
			SUM(sk.FOW) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING) AS FOW_tot,
			SUM(sk.FOL) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING) AS FOL_tot
		FROM rows_not_null sk
        LEFT JOIN SCHEDULE sched
			ON sk.team = sched.team
            AND sk.date = sched.date
	)

	SELECT player_id,
		`date`,
		60 * (G_tot / TOI_tot) AS G60_10,
		60 * (A_tot / TOI_tot) AS A60_10,
		60 * (P_tot / TOI_tot) AS P60_10,
		60 * (rating_tot / TOI_tot) AS rating60_10,
		60 * (PIM_tot / TOI_tot) AS PIM60_10,
		60 * (EVG_tot / TOI_tot) AS EVG60_10,
		60 * (PPG_tot / TOI_tot) AS PPG60_10,
		60 * (SHG_tot / TOI_tot) AS SHG60_10,
		60 * (GWG_tot / TOI_tot) AS GWG60_10,
		60 * (EVA_tot / TOI_tot) AS EVA60_10,
		60 * (PPA_tot / TOI_tot) AS PPA60_10,
		60 * (SHA_tot / TOI_tot) AS SHA60_10,
		60 * (S_tot / TOI_tot) AS S60_10,
		60 * (shifts_tot / TOI_tot) AS shifts60_10,
		60 * (HIT_tot / TOI_tot) AS HIT60_10,
		60 * (BLK_tot / TOI_tot) AS BLK60_10,
		60 * (FOW_tot / TOI_tot) AS FOW60_10,
		60 * (FOL_tot / TOI_tot) AS FOL60_10,
		TOI_tot / 10 AS avgTOI_10
	FROM stat_totals
	WHERE n_not_null > 10
);

-- Check results
-- SELECT * FROM skater_per60_rolling10 LIMIT 100;
-- SELECT count(*) FROM skater_per60_rolling10; -- 100,207
-- SELECT count(*) FROM skater_game WHERE game_num > 10; -- 100,207

-- ---------------------------------------------------------
-- View for last 15 games
DROP VIEW IF EXISTS skater_per60_rolling15;

CREATE VIEW skater_per60_rolling15 AS (
	WITH rows_not_null AS (
		SELECT *
		FROM skater_game
		WHERE G IS NOT NULL
			AND A IS NOT NULL
			AND P IS NOT NULL
			AND rating IS NOT NULL
			AND PIM IS NOT NULL
			AND EVG IS NOT NULL
			AND PPG IS NOT NULL
			AND SHG IS NOT NULL
			AND GWG IS NOT NULL
			AND EVA IS NOT NULL
			AND PPA IS NOT NULL
			AND SHA IS NOT NULL
			AND S IS NOT NULL
			AND TOI IS NOT NULL
			AND HIT IS NOT NULL
			AND BLK IS NOT NULL
			AND FOW IS NOT NULL
			AND FOL IS NOT NULL
	),
	
	stat_totals AS (
		SELECT sk.player_id,
			sk.team,
			sk.date,
            sk.game_num,
			COUNT(*) OVER (PARTITION BY sk.player_id, sched.season ORDER BY sk.date) AS n_not_null,
			-- COUNT(*) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 15 PRECEDING AND 1 PRECEDING) AS n,
			SUM(sk.TOI) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 15 PRECEDING AND 1 PRECEDING) AS TOI_tot,
			SUM(sk.G) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 15 PRECEDING AND 1 PRECEDING) AS G_tot,
			SUM(sk.A) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 15 PRECEDING AND 1 PRECEDING) AS A_tot,
			SUM(sk.P) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 15 PRECEDING AND 1 PRECEDING) AS P_tot,
			SUM(sk.rating) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 15 PRECEDING AND 1 PRECEDING) AS rating_tot,
			SUM(sk.PIM) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 15 PRECEDING AND 1 PRECEDING) AS PIM_tot,
			SUM(sk.EVG) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 15 PRECEDING AND 1 PRECEDING) AS EVG_tot,
			SUM(sk.PPG) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 15 PRECEDING AND 1 PRECEDING) AS PPG_tot,
			SUM(sk.SHG) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 15 PRECEDING AND 1 PRECEDING) AS SHG_tot,
			SUM(sk.GWG) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 15 PRECEDING AND 1 PRECEDING) AS GWG_tot,
			SUM(sk.EVA) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 15 PRECEDING AND 1 PRECEDING) AS EVA_tot,
			SUM(sk.PPA) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 15 PRECEDING AND 1 PRECEDING) AS PPA_tot,
			SUM(sk.SHA) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 15 PRECEDING AND 1 PRECEDING) AS SHA_tot,
			SUM(sk.S) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 15 PRECEDING AND 1 PRECEDING) AS S_tot,
			SUM(sk.shifts) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 15 PRECEDING AND 1 PRECEDING) AS shifts_tot,
			SUM(sk.HIT) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 15 PRECEDING AND 1 PRECEDING) AS HIT_tot,
			SUM(sk.BLK) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 15 PRECEDING AND 1 PRECEDING) AS BLK_tot,
			SUM(sk.FOW) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 15 PRECEDING AND 1 PRECEDING) AS FOW_tot,
			SUM(sk.FOL) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 15 PRECEDING AND 1 PRECEDING) AS FOL_tot
		FROM rows_not_null sk
        LEFT JOIN SCHEDULE sched
			ON sk.team = sched.team
            AND sk.date = sched.date
	)

	SELECT player_id,
		`date`,
		60 * (G_tot / TOI_tot) AS G60_15,
		60 * (A_tot / TOI_tot) AS A60_15,
		60 * (P_tot / TOI_tot) AS P60_15,
		60 * (rating_tot / TOI_tot) AS rating60_15,
		60 * (PIM_tot / TOI_tot) AS PIM60_15,
		60 * (EVG_tot / TOI_tot) AS EVG60_15,
		60 * (PPG_tot / TOI_tot) AS PPG60_15,
		60 * (SHG_tot / TOI_tot) AS SHG60_15,
		60 * (GWG_tot / TOI_tot) AS GWG60_15,
		60 * (EVA_tot / TOI_tot) AS EVA60_15,
		60 * (PPA_tot / TOI_tot) AS PPA60_15,
		60 * (SHA_tot / TOI_tot) AS SHA60_15,
		60 * (S_tot / TOI_tot) AS S60_15,
		60 * (shifts_tot / TOI_tot) AS shifts60_15,
		60 * (HIT_tot / TOI_tot) AS HIT60_15,
		60 * (BLK_tot / TOI_tot) AS BLK60_15,
		60 * (FOW_tot / TOI_tot) AS FOW60_15,
		60 * (FOL_tot / TOI_tot) AS FOL60_15,
		TOI_tot / 15 AS avgTOI_15
	FROM stat_totals
	WHERE n_not_null > 15
);

-- Check results
-- SELECT * FROM skater_per60_rolling15 LIMIT 100;
-- SELECT count(*) FROM skater_per60_rolling15; -- 89,104
-- SELECT count(*) FROM skater_game WHERE game_num > 15; -- 89,104

-- ---------------------------------------------------------
-- View for last 20 games
DROP VIEW IF EXISTS skater_per60_rolling20;

CREATE VIEW skater_per60_rolling20 AS (
	WITH rows_not_null AS (
		SELECT *
		FROM skater_game
		WHERE G IS NOT NULL
			AND A IS NOT NULL
			AND P IS NOT NULL
			AND rating IS NOT NULL
			AND PIM IS NOT NULL
			AND EVG IS NOT NULL
			AND PPG IS NOT NULL
			AND SHG IS NOT NULL
			AND GWG IS NOT NULL
			AND EVA IS NOT NULL
			AND PPA IS NOT NULL
			AND SHA IS NOT NULL
			AND S IS NOT NULL
			AND TOI IS NOT NULL
			AND HIT IS NOT NULL
			AND BLK IS NOT NULL
			AND FOW IS NOT NULL
			AND FOL IS NOT NULL
	),
	
	stat_totals AS (
		SELECT sk.player_id,
			sk.team,
			sk.date,
            sk.game_num,
			COUNT(*) OVER (PARTITION BY sk.player_id, sched.season ORDER BY sk.date) AS n_not_null,
			-- COUNT(*) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 20 PRECEDING AND 1 PRECEDING) AS n,
			SUM(sk.TOI) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 20 PRECEDING AND 1 PRECEDING) AS TOI_tot,
			SUM(sk.G) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 20 PRECEDING AND 1 PRECEDING) AS G_tot,
			SUM(sk.A) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 20 PRECEDING AND 1 PRECEDING) AS A_tot,
			SUM(sk.P) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 20 PRECEDING AND 1 PRECEDING) AS P_tot,
			SUM(sk.rating) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 20 PRECEDING AND 1 PRECEDING) AS rating_tot,
			SUM(sk.PIM) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 20 PRECEDING AND 1 PRECEDING) AS PIM_tot,
			SUM(sk.EVG) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 20 PRECEDING AND 1 PRECEDING) AS EVG_tot,
			SUM(sk.PPG) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 20 PRECEDING AND 1 PRECEDING) AS PPG_tot,
			SUM(sk.SHG) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 20 PRECEDING AND 1 PRECEDING) AS SHG_tot,
			SUM(sk.GWG) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 20 PRECEDING AND 1 PRECEDING) AS GWG_tot,
			SUM(sk.EVA) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 20 PRECEDING AND 1 PRECEDING) AS EVA_tot,
			SUM(sk.PPA) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 20 PRECEDING AND 1 PRECEDING) AS PPA_tot,
			SUM(sk.SHA) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 20 PRECEDING AND 1 PRECEDING) AS SHA_tot,
			SUM(sk.S) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 20 PRECEDING AND 1 PRECEDING) AS S_tot,
			SUM(sk.shifts) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 20 PRECEDING AND 1 PRECEDING) AS shifts_tot,
			SUM(sk.HIT) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 20 PRECEDING AND 1 PRECEDING) AS HIT_tot,
			SUM(sk.BLK) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 20 PRECEDING AND 1 PRECEDING) AS BLK_tot,
			SUM(sk.FOW) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 20 PRECEDING AND 1 PRECEDING) AS FOW_tot,
			SUM(sk.FOL) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.date ROWS BETWEEN 20 PRECEDING AND 1 PRECEDING) AS FOL_tot
		FROM rows_not_null sk
        LEFT JOIN SCHEDULE sched
			ON sk.team = sched.team
            AND sk.date = sched.date
	)

	SELECT player_id,
		`date`,
		60 * (G_tot / TOI_tot) AS G60_20,
		60 * (A_tot / TOI_tot) AS A60_20,
		60 * (P_tot / TOI_tot) AS P60_20,
		60 * (rating_tot / TOI_tot) AS rating60_20,
		60 * (PIM_tot / TOI_tot) AS PIM60_20,
		60 * (EVG_tot / TOI_tot) AS EVG60_20,
		60 * (PPG_tot / TOI_tot) AS PPG60_20,
		60 * (SHG_tot / TOI_tot) AS SHG60_20,
		60 * (GWG_tot / TOI_tot) AS GWG60_20,
		60 * (EVA_tot / TOI_tot) AS EVA60_20,
		60 * (PPA_tot / TOI_tot) AS PPA60_20,
		60 * (SHA_tot / TOI_tot) AS SHA60_20,
		60 * (S_tot / TOI_tot) AS S60_20,
		60 * (shifts_tot / TOI_tot) AS shifts60_20,
		60 * (HIT_tot / TOI_tot) AS HIT60_20,
		60 * (BLK_tot / TOI_tot) AS BLK60_20,
		60 * (FOW_tot / TOI_tot) AS FOW60_20,
		60 * (FOL_tot / TOI_tot) AS FOL60_20,
		TOI_tot / 20 AS avgTOI_20
	FROM stat_totals
	WHERE n_not_null > 20
);

-- Check results
-- select * from skater_per60_rolling20 limit 100;
-- select count(*) from skater_per60_rolling20; -- 78,580
-- select count(*) from skater_game where game_num > 20; -- 78,580
