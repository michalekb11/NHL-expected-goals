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
		name,
		team,
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

SELECT COUNT(*) FROM skater_per60_rolling5; -- 112,219
SELECT COUNT(*) FROM skater_games WHERE game_num > 5; -- 112,219
