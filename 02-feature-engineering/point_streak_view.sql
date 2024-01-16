-- -------------------------------------------------------------
-- Point streak view
-- -------------------------------------------------------------
-- Calculate the point streak for each player using each game that they have played so far in
-- that season. If it is the first game of the season, the point streak is 0. If a player
-- has gone 5 games without recording a point, the point streak is -5. 
-- -------------------------------------------------------------
DROP VIEW IF EXISTS point_streak;

CREATE VIEW point_streak AS (
	WITH starter AS (
		SELECT sk.player_id,
			sk.date,
			sched.season,
			sk.game_num,
			sk.P,
			CASE WHEN sk.P > 0 THEN 1 ELSE -1 END AS P_flag
		FROM skater_game sk
		LEFT JOIN schedule sched
			ON sk.team = sched.team
			AND sk.date = sched.date
	),

	lagged AS (
		SELECT *,
			COALESCE(LAG(P_flag, 1) OVER(PARTITION BY player_id, season ORDER BY game_num), 0) AS P_lag1,
			COALESCE(LAG(P_flag, 2) OVER(PARTITION BY player_id, season ORDER BY game_num), 0) AS P_lag2
		FROM starter
	),

	streak_change AS (
		SELECT *,
			CASE WHEN P_lag1 <> P_lag2 THEN 1 ELSE 0 END AS streak_changed
		FROM lagged 
	),

	streak_identifier AS (
		SELECT *,
			SUM(streak_changed) OVER(PARTITION BY player_id, season ORDER BY game_num) AS streak_identifier
		FROM streak_change
	),

	streak_length AS (
		SELECT *,
			ROW_NUMBER() OVER(PARTITION BY player_id, season, streak_identifier ORDER BY game_num) AS streak_length
		FROM streak_identifier
	)

	SELECT player_id,
		date,
		P_lag1 * CAST(streak_length AS SIGNED) AS point_streak
	FROM streak_length
);

-- Check results
-- select count(*) from skater_game; -- 125,637
-- select count(*) from point_streak; -- 125,637
-- select * from point_streak limit 100;
-- select * from point_streak where player_id = '/g/gudasra01';


