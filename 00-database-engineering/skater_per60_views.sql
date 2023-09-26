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
DROP VIEW IF EXISTS skater_per60_rolling3;

CREATE VIEW skater_per60_rolling3 AS (
	WITH stat_totals AS (
		SELECT sk.player_id,
			sk.name,
			sk.team,
			sk.date,
            sk.game_num,
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
		FROM skater_games sk
        LEFT JOIN schedule sched
			ON sk.team = sched.team
            AND sk.date = sched.date
	)

	SELECT player_id,
		date,
		60 * (G_tot / TOI_tot) AS G60_3,
		60 * (A_tot / TOI_tot) AS A60_3,
		60 * (P_tot / TOI_tot) AS P60_3,
		60 * (rating_tot / TOI_tot) AS rating60_3,
		60 * (PIM_tot / TOI_tot) AS PIM60_3,
		60 * (EVG_tot / TOI_tot) AS EVG60_3,
		60 * (PPG_tot / TOI_tot) AS PPG60_3,
		60 * (SHG_tot / TOI_tot) AS SHG60_3,
		60 * (GWG_tot / TOI_tot) AS GWG60_3,
		60 * (EVA_tot / TOI_tot) AS EVA60_3,
		60 * (PPA_tot / TOI_tot) AS PPA60_3,
		60 * (SHA_tot / TOI_tot) AS SHA60_3,
		60 * (S_tot / TOI_tot) AS S60_3,
		60 * (shifts_tot / TOI_tot) AS shifts60_3,
		60 * (HIT_tot / TOI_tot) AS HIT60_3,
		60 * (BLK_tot / TOI_tot) AS BLK60_3,
		60 * (FOW_tot / TOI_tot) AS FOW60_3,
		60 * (FOL_tot / TOI_tot) AS FOL60_3,
		TOI_tot / 3 AS avgTOI_3
	FROM stat_totals
	WHERE game_num > 3
);

-- Check results
select * from skater_per60_rolling3 limit 100;
select count(*) from skater_per60_rolling3; -- 117,367
select count(*) from skater_games where game_num > 3; -- 117,367

-- ---------------------------------------------------------
-- View for last 5 games
DROP VIEW IF EXISTS skater_per60_rolling5;

CREATE VIEW skater_per60_rolling5 AS (
	WITH stat_totals AS (
		SELECT sk.player_id,
			sk.name,
			sk.team,
			sk.date,
            sk.game_num,
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
		FROM skater_games sk
        LEFT JOIN schedule sched
			ON sk.team = sched.team
            AND sk.date = sched.date
	)

	SELECT player_id,
		date,
		60 * (G_tot / TOI_tot) AS G60_5,
		60 * (A_tot / TOI_tot) AS A60_5,
		60 * (P_tot / TOI_tot) AS P60_5,
		60 * (rating_tot / TOI_tot) AS rating60_5,
		60 * (PIM_tot / TOI_tot) AS PIM60_5,
		60 * (EVG_tot / TOI_tot) AS EVG60_5,
		60 * (PPG_tot / TOI_tot) AS PPG60_5,
		60 * (SHG_tot / TOI_tot) AS SHG60_5,
		60 * (GWG_tot / TOI_tot) AS GWG60_5,
		60 * (EVA_tot / TOI_tot) AS EVA60_5,
		60 * (PPA_tot / TOI_tot) AS PPA60_5,
		60 * (SHA_tot / TOI_tot) AS SHA60_5,
		60 * (S_tot / TOI_tot) AS S60_5,
		60 * (shifts_tot / TOI_tot) AS shifts60_5,
		60 * (HIT_tot / TOI_tot) AS HIT60_5,
		60 * (BLK_tot / TOI_tot) AS BLK60_5,
		60 * (FOW_tot / TOI_tot) AS FOW60_5,
		60 * (FOL_tot / TOI_tot) AS FOL60_5,
		TOI_tot / 5 AS avgTOI_5
	FROM stat_totals
	WHERE game_num > 5
);

-- Check results
select * from skater_per60_rolling5 limit 100;
select count(*) from skater_per60_rolling5; -- 112,219
select count(*) from skater_games where game_num > 5; -- 112,219

-- ---------------------------------------------------------
-- View for last 10 games
DROP VIEW IF EXISTS skater_per60_rolling10;

CREATE VIEW skater_per60_rolling10 AS (
	WITH stat_totals AS (
		SELECT sk.player_id,
			sk.name,
			sk.team,
			sk.date,
            sk.game_num,
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
		FROM skater_games sk
        LEFT JOIN schedule sched
			ON sk.team = sched.team
            AND sk.date = sched.date
	)

	SELECT player_id,
		date,
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
	WHERE game_num > 10
);

-- Check results
select * from skater_per60_rolling10 limit 100;
select count(*) from skater_per60_rolling10; -- 100,207
select count(*) from skater_games where game_num > 10; -- 100,207

-- ---------------------------------------------------------
-- View for last 15 games
DROP VIEW IF EXISTS skater_per60_rolling15;

CREATE VIEW skater_per60_rolling15 AS (
	WITH stat_totals AS (
		SELECT sk.player_id,
			sk.name,
			sk.team,
			sk.date,
            sk.game_num,
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
		FROM skater_games sk
        LEFT JOIN schedule sched
			ON sk.team = sched.team
            AND sk.date = sched.date
	)

	SELECT player_id,
		date,
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
	WHERE game_num > 15
);

-- Check results
select * from skater_per60_rolling15 limit 100;
select count(*) from skater_per60_rolling15; -- 89,104
select count(*) from skater_games where game_num > 15; -- 89,104

-- ---------------------------------------------------------
-- View for last 20 games
DROP VIEW IF EXISTS skater_per60_rolling20;

CREATE VIEW skater_per60_rolling20 AS (
	WITH stat_totals AS (
		SELECT sk.player_id,
			sk.name,
			sk.team,
			sk.date,
            sk.game_num,
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
		FROM skater_games sk
        LEFT JOIN schedule sched
			ON sk.team = sched.team
            AND sk.date = sched.date
	)

	SELECT player_id,
		date,
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
	WHERE game_num > 20
);

-- Check results
select * from skater_per60_rolling20 limit 100;
select count(*) from skater_per60_rolling20; -- 78,580
select count(*) from skater_games where game_num > 20; -- 78,580
