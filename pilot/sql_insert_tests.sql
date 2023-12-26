-- ---------------------------------------------
-- ---------------------------------------------

-- If there are actual data in the following tables, DON'T
-- run this script. Only using this at the beginning to test 
-- the database structure/relationships.

-- ---------------------------------------------
-- ---------------------------------------------

-- Set DB
USE nhl;

-- Test game id insert
INSERT INTO game_ids 
VALUES ('DET', '2023-08-15', 2);

SELECT * FROM game_ids;

-- Inserting into schedule is no longer necessary. I have set up a trigger after insert into game_id, 
-- the corresponding team/date will insert into schedule with nulls for remaining columns)
SELECT * FROM schedule;

-- Test schedule foreign key constraint. This should throw an error since the team/date is not in game id table.
INSERT INTO schedule (team, date, G, win_flag)
VALUES ('PIT', '2023-08-15', 2, 0);

-- Test skater_games insert
INSERT INTO skater_games (player_id, name, age, team, date, G, S)
VALUES ('/d/dawgb01', 'Big Dawg', 24, 'DET', '2023-08-15', 100, 101);

SELECT * FROM skater_games;

-- Test goalie_games insert
INSERT INTO goalie_games (player_id, name, age, team, date, GA, SV_pct)
VALUES ('/d/dawgb01', 'Big Dawg', 24, 'DET', '2023-08-15', 0, 1.0);

SELECT * FROM goalie_games;

-- Test moneyline insert
INSERT INTO ml_odds (team, date_game, time_game, odds)
VALUES ('DET', '2023-08-15', '18:00:00', 165);

SELECT * FROM ml_odds;
SELECT team, HOUR(time_game) FROM ml_odds;

-- Test puckline insert
INSERT INTO pl_odds (team, date_game, time_game, line, odds)
VALUES ('DET', '2023-08-15', '18:00:00', -1.5, -110);

SELECT * FROM pl_odds;

-- Test total odds insert
	-- Should fail because PIT is not in schedule or game ID yet
INSERT INTO total_odds (home, away, date_game, time_game, bet_type, line, odds)
VALUES ('DET', 'PIT', '2023-08-15', '18:00:00', 'O', 6.5, 105);

	-- Insert into game id and schedule (I have set up a trigger after insert into game_id, the corresponding team/date will insert into schedule with nulls for remaining columns)
INSERT INTO game_ids
VALUES ('PIT', '2023-08-15', 2);

	-- Now this insert should work
INSERT INTO total_odds (home, away, date_game, time_game, bet_type, line, odds)
VALUES ('DET', 'PIT', '2023-08-15', '18:00:00', 'O', 6.5, 105);

SELECT * FROM total_odds;

-- Test game id update + all cascades downstream
UPDATE game_ids
SET team = 'DEG'
WHERE team = 'DET';

SELECT * FROM game_ids;
SELECT * FROM schedule;
SELECT * FROM skater_games;
SELECT * FROM goalie_games;
SELECT * FROM ml_odds;
SELECT * FROM pl_odds;
SELECT * FROM total_odds;

-- These should not work due to FK constraints. Only the game_id table can be updated with respect to team and date.
UPDATE schedule
SET team = 'PIG'
WHERE team = 'PIT';

-- Remove all information when ready to insert real data
SET SQL_SAFE_UPDATES = 0;

DELETE FROM pl_odds;
DELETE FROM ml_odds;
DELETE FROM total_odds;
DELETE FROM skater_games;
DELETE FROM goalie_games;
DELETE FROM schedule;
DELETE FROM game_ids;

SET SQL_SAFE_UPDATES = 1;



