-- ---------------------------------------------------------
-- Rolling Per60 View(s)
-- ---------------------------------------------------------
-- Create a View that will give the per60 goalie statistics over various rolling windows
-- Ex: could be the previous 3 games, previous 5 games, etc. 
-- Rows should only be returned if the player has played the required number of games
-- specified by the rolling window. All of the previous games should be part of the same season.

-- Future improvement: If the games are outdated (say a player just recovered from a 4 month injury),
-- either scrap those games, or place a lower weight on those games.

-- Note: These views are not the most optimized. The filtering occurs after the view query has been run.

-- ---------------------------------------------------------
-- View for last 3 games
DROP VIEW IF EXISTS goalie_per60_rolling3;

CREATE VIEW goalie_per60_rolling3 AS (
	WITH stat_totals AS (
		SELECT gg.player_id,
			gg.name,
			gg.team,
			gg.date,
            gg.game_num,
			-- COUNT(*) OVER(PARTITION BY gg.player_id, sched.season ORDER BY gg.date ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) AS n,
			SUM(gg.TOI) OVER(PARTITION BY gg.player_id, sched.season ORDER BY gg.date ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) AS TOI_tot,
			SUM(gg.GA) OVER(PARTITION BY gg.player_id, sched.season ORDER BY gg.date ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) AS GA_tot,
			SUM(gg.SA) OVER(PARTITION BY gg.player_id, sched.season ORDER BY gg.date ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) AS SA_tot,
			SUM(gg.SV) OVER(PARTITION BY gg.player_id, sched.season ORDER BY gg.date ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) AS SV_tot
		FROM goalie_games gg
        LEFT JOIN schedule sched
			ON gg.team = sched.team
            AND gg.date = sched.date
	)

	SELECT player_id,
		name,
		team,
		date,
		60 * (GA_tot / TOI_tot) AS GA60_3,
		60 * (SA_tot / TOI_tot) AS SA60_3,
		60 * (SV_tot / TOI_tot) AS SV60_3,
        CAST(SV_tot AS FLOAT) / SA_tot AS SVpct_3,
		TOI_tot / 3 AS avgTOI_3
	FROM stat_totals
	WHERE game_num > 3
);

-- Check results
select * from goalie_per60_rolling3 limit 100;
select count(*) from goalie_per60_rolling3; -- 6,556
select count(*) from goalie_games where game_num > 3; -- 6,556

-- ---------------------------------------------------------
-- View for last 5 games
DROP VIEW IF EXISTS goalie_per60_rolling5;

CREATE VIEW goalie_per60_rolling5 AS (
	WITH stat_totals AS (
		SELECT gg.player_id,
			gg.name,
			gg.team,
			gg.date,
            gg.game_num,
			-- COUNT(*) OVER(PARTITION BY gg.player_id, sched.season ORDER BY gg.date ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING) AS n,
			SUM(gg.TOI) OVER(PARTITION BY gg.player_id, sched.season ORDER BY gg.date ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING) AS TOI_tot,
			SUM(gg.GA) OVER(PARTITION BY gg.player_id, sched.season ORDER BY gg.date ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING) AS GA_tot,
			SUM(gg.SA) OVER(PARTITION BY gg.player_id, sched.season ORDER BY gg.date ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING) AS SA_tot,
			SUM(gg.SV) OVER(PARTITION BY gg.player_id, sched.season ORDER BY gg.date ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING) AS SV_tot
		FROM goalie_games gg
        LEFT JOIN schedule sched
			ON gg.team = sched.team
            AND gg.date = sched.date
	)

	SELECT player_id,
		name,
		team,
		date,
		60 * (GA_tot / TOI_tot) AS GA60_5,
		60 * (SA_tot / TOI_tot) AS SA60_5,
		60 * (SV_tot / TOI_tot) AS SV60_5,
        CAST(SV_tot AS FLOAT) / SA_tot AS SVpct_5,
		TOI_tot / 5 AS avgTOI_5
	FROM stat_totals
	WHERE game_num > 5
);

-- Check results
select * from goalie_per60_rolling5 limit 100;
select count(*) from goalie_per60_rolling5; -- 6,041
select count(*) from goalie_games where game_num > 5; -- 6,041

-- ---------------------------------------------------------
-- View for last 10 games
DROP VIEW IF EXISTS goalie_per60_rolling10;

CREATE VIEW goalie_per60_rolling10 AS (
	WITH stat_totals AS (
		SELECT gg.player_id,
			gg.name,
			gg.team,
			gg.date,
            gg.game_num,
			-- COUNT(*) OVER(PARTITION BY gg.player_id, sched.season ORDER BY gg.date ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING) AS n,
			SUM(gg.TOI) OVER(PARTITION BY gg.player_id, sched.season ORDER BY gg.date ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING) AS TOI_tot,
			SUM(gg.GA) OVER(PARTITION BY gg.player_id, sched.season ORDER BY gg.date ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING) AS GA_tot,
			SUM(gg.SA) OVER(PARTITION BY gg.player_id, sched.season ORDER BY gg.date ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING) AS SA_tot,
			SUM(gg.SV) OVER(PARTITION BY gg.player_id, sched.season ORDER BY gg.date ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING) AS SV_tot
		FROM goalie_games gg
        LEFT JOIN schedule sched
			ON gg.team = sched.team
            AND gg.date = sched.date
	)

	SELECT player_id,
		name,
		team,
		date,
		60 * (GA_tot / TOI_tot) AS GA60_10,
		60 * (SA_tot / TOI_tot) AS SA60_10,
		60 * (SV_tot / TOI_tot) AS SV60_10,
        CAST(SV_tot AS FLOAT) / SA_tot AS SVpct_10,
		TOI_tot / 10 AS avgTOI_10
	FROM stat_totals
	WHERE game_num > 10
);

-- Check results
select * from goalie_per60_rolling10 limit 100;
select count(*) from goalie_per60_rolling10; -- 4,891
select count(*) from goalie_games where game_num > 10; -- 4,891

-- ---------------------------------------------------------
-- View for last 15 games
DROP VIEW IF EXISTS goalie_per60_rolling15;

CREATE VIEW goalie_per60_rolling15 AS (
	WITH stat_totals AS (
		SELECT gg.player_id,
			gg.name,
			gg.team,
			gg.date,
            gg.game_num,
			-- COUNT(*) OVER(PARTITION BY gg.player_id, sched.season ORDER BY gg.date ROWS BETWEEN 15 PRECEDING AND 1 PRECEDING) AS n,
			SUM(gg.TOI) OVER(PARTITION BY gg.player_id, sched.season ORDER BY gg.date ROWS BETWEEN 15 PRECEDING AND 1 PRECEDING) AS TOI_tot,
			SUM(gg.GA) OVER(PARTITION BY gg.player_id, sched.season ORDER BY gg.date ROWS BETWEEN 15 PRECEDING AND 1 PRECEDING) AS GA_tot,
			SUM(gg.SA) OVER(PARTITION BY gg.player_id, sched.season ORDER BY gg.date ROWS BETWEEN 15 PRECEDING AND 1 PRECEDING) AS SA_tot,
			SUM(gg.SV) OVER(PARTITION BY gg.player_id, sched.season ORDER BY gg.date ROWS BETWEEN 15 PRECEDING AND 1 PRECEDING) AS SV_tot
		FROM goalie_games gg
        LEFT JOIN schedule sched
			ON gg.team = sched.team
            AND gg.date = sched.date
	)

	SELECT player_id,
		name,
		team,
		date,
		60 * (GA_tot / TOI_tot) AS GA60_15,
		60 * (SA_tot / TOI_tot) AS SA60_15,
		60 * (SV_tot / TOI_tot) AS SV60_15,
        CAST(SV_tot AS FLOAT) / SA_tot AS SVpct_15,
		TOI_tot / 15 AS avgTOI_15
	FROM stat_totals
	WHERE game_num > 15
);

-- Check results
select * from goalie_per60_rolling15 limit 100;
select count(*) from goalie_per60_rolling15; -- 3,855
select count(*) from goalie_games where game_num > 15; -- 3,855

-- ---------------------------------------------------------
-- View for last 20 games
DROP VIEW IF EXISTS goalie_per60_rolling20;

CREATE VIEW goalie_per60_rolling20 AS (
	WITH stat_totals AS (
		SELECT gg.player_id,
			gg.name,
			gg.team,
			gg.date,
            gg.game_num,
			-- COUNT(*) OVER(PARTITION BY gg.player_id, sched.season ORDER BY gg.date ROWS BETWEEN 20 PRECEDING AND 1 PRECEDING) AS n,
			SUM(gg.TOI) OVER(PARTITION BY gg.player_id, sched.season ORDER BY gg.date ROWS BETWEEN 20 PRECEDING AND 1 PRECEDING) AS TOI_tot,
			SUM(gg.GA) OVER(PARTITION BY gg.player_id, sched.season ORDER BY gg.date ROWS BETWEEN 20 PRECEDING AND 1 PRECEDING) AS GA_tot,
			SUM(gg.SA) OVER(PARTITION BY gg.player_id, sched.season ORDER BY gg.date ROWS BETWEEN 20 PRECEDING AND 1 PRECEDING) AS SA_tot,
			SUM(gg.SV) OVER(PARTITION BY gg.player_id, sched.season ORDER BY gg.date ROWS BETWEEN 20 PRECEDING AND 1 PRECEDING) AS SV_tot
		FROM goalie_games gg
        LEFT JOIN schedule sched
			ON gg.team = sched.team
            AND gg.date = sched.date
	)

	SELECT player_id,
		name,
		team,
		date,
		60 * (GA_tot / TOI_tot) AS GA60_20,
		60 * (SA_tot / TOI_tot) AS SA60_20,
		60 * (SV_tot / TOI_tot) AS SV60_20,
        CAST(SV_tot AS FLOAT) / SA_tot AS SVpct_20,
		TOI_tot / 20 AS avgTOI_20
	FROM stat_totals
	WHERE game_num > 20
);

-- Check results
select * from goalie_per60_rolling20 limit 100;
select count(*) from goalie_per60_rolling20; -- 2,927
select count(*) from goalie_games where game_num > 20; -- 2,927