-- ------------------------------------------------------
-- Switched teams view
-- ------------------------------------------------------
-- If a player has switched teams in the last X number of games
-- we want to flag these rows. Often times, a player switching 
-- to a new team induces a change in performance (sometimes good
-- and sometimes bad).

-- Assume that at the start of a season or for a player's first few games, 
-- the player has not "changed teams" even if they may have been traded 
-- or signed during the offseason.
-- ------------------------------------------------------
DROP VIEW IF EXISTS team_change5;

CREATE VIEW team_change5 AS (
	WITH team_lag AS (
		SELECT sk.player_id,
			sk.team,
			sk.date,
			sched.season,
			sk.game_num,
			LAG(sk.team, 1) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.game_num) AS team_lag1,
			LAG(sk.team, 2) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.game_num) AS team_lag2,
			LAG(sk.team, 3) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.game_num) AS team_lag3,
			LAG(sk.team, 4) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.game_num) AS team_lag4,
			LAG(sk.team, 5) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.game_num) AS team_lag5
		FROM skater_games sk
		LEFT JOIN schedule sched
			ON sk.team = sched.team
			AND sk.date = sched.date
	)

	SELECT player_id,
		date,
		CASE 
			WHEN (team <> team_lag1 
				OR team <> team_lag2 
				OR team <> team_lag3
				OR team <> team_lag4
				OR team <> team_lag5) 
			THEN 1 
			ELSE 0 
		END AS team_change5_flag
	 FROM team_lag
 );
 
 -- Check results
 -- select count(*) from skater_games; -- 125,637
 -- select count(*) from team_change5; -- 125,637
 -- select team_change5_flag, count(*) from team_change5 group by team_change5_flag;
 -- select * from team_change5 limit 1000;
 -- select * from team_change5 where player_id = '/p/pacioma01';
 -- select * from team_change5 where player_id = '/b/barrity01';
 
 -- ------------------------------------------------------
 -- Same thing but for the last 10 games instead of only the last 5
 DROP VIEW IF EXISTS team_change10;

CREATE VIEW team_change10 AS (
	WITH team_lag AS (
		SELECT sk.player_id,
			sk.team,
			sk.date,
			sched.season,
			sk.game_num,
			LAG(sk.team, 1) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.game_num) AS team_lag1,
			LAG(sk.team, 2) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.game_num) AS team_lag2,
			LAG(sk.team, 3) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.game_num) AS team_lag3,
			LAG(sk.team, 4) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.game_num) AS team_lag4,
			LAG(sk.team, 5) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.game_num) AS team_lag5,
            LAG(sk.team, 6) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.game_num) AS team_lag6,
            LAG(sk.team, 7) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.game_num) AS team_lag7,
            LAG(sk.team, 8) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.game_num) AS team_lag8,
            LAG(sk.team, 9) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.game_num) AS team_lag9,
            LAG(sk.team, 10) OVER(PARTITION BY sk.player_id, sched.season ORDER BY sk.game_num) AS team_lag10
		FROM skater_games sk
		LEFT JOIN schedule sched
			ON sk.team = sched.team
			AND sk.date = sched.date
	)

	SELECT player_id,
		date,
		CASE 
			WHEN (team <> team_lag1 
				OR team <> team_lag2 
				OR team <> team_lag3
				OR team <> team_lag4
				OR team <> team_lag5
                OR team <> team_lag6
                OR team <> team_lag7
                OR team <> team_lag8
                OR team <> team_lag9
                OR team <> team_lag10) 
			THEN 1 
			ELSE 0 
		END AS team_change10_flag
	 FROM team_lag
 );
 
 -- Check results
 -- select count(*) from skater_games; -- 125,637
 -- select count(*) from team_change10; -- 125,637
 -- select team_change10_flag, count(*) from team_change10 group by team_change10_flag;
 -- select * from team_change10 limit 1000;
 -- select * from team_change10 where player_id = '/p/pacioma01';
 -- select * from team_change10 where player_id = '/b/barrity01';
 