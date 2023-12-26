-- -------------------------------------------------
-- Home-away status view
-- -------------------------------------------------
-- For each game for each player, assign them a home away status
-- 0 = Game is on the road
-- 1 = Game is at home
-- -------------------------------------------------
DROP VIEW IF EXISTS home_away_status;

CREATE VIEW home_away_status AS (
	SELECT sk.player_id,
		sk.date,
		CASE WHEN sched.location = 'H' THEN 1 ELSE 0 END AS home_game_flag
	FROM skater_games sk
	LEFT JOIN schedule sched
		ON sk.team = sched.team
		AND sk.date = sched.date
);

-- Check results
-- select count(*) from skater_games; -- 125,637
-- select count(*) from home_away_status; -- 125,637
-- select home_game_flag, count(*) from home_away_status group by home_game_flag;

    