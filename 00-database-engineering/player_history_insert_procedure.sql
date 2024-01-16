-- ------------------------------------------------
-- Insert or update player history

-- Goal: Be able to keep track of player history changes
-- (Ex: changes in team, etc.). Will include the current state
-- of the player. All tables with player ID should reference
-- this player history table, meaning that it needs to stay up
-- to date with all possible players in injuries, projected lineups,
-- projected goalies, and all players who indeed played in a game.
-- 
-- This table should also serve as a place to match player names 
-- (from lineup, injury, projected goalie, goalscorer scrapes, etc.)
-- to the correct player ID before insertion into those respective tables.
-- 
-- As a result, a standard insertion procedure will not be effective enough.
-- This procedure performs the insert in situations such as a new player, new
-- change in their history... it performs updates to old history rows upon new
-- inserts, etc.
-- 
-- Improvements: IF ELSE logic is long, complicated, and likely not the most 
-- efficient solution. Additionally, investigate whether a BEFORE INSERT TRIGGER
-- is possible.
-- ------------------------------------------------

-- Create or replace the stored procedure
DROP PROCEDURE IF EXISTS InsertOrUpdatePlayerHistory;

DELIMITER //

CREATE PROCEDURE InsertOrUpdatePlayerHistory(
    IN new_id VARCHAR(15),
    IN new_name VARCHAR(255),
    IN new_team CHAR(3),
    IN new_date_game DATE
)
BEGIN
    DECLARE previous_team CHAR(3);
    DECLARE previous_dob DATE;
    DECLARE previous_start_date DATE;
    DECLARE previous_end_date DATE;
    
    DECLARE next_team CHAR(3);
    DECLARE next_dob DATE;
    DECLARE next_start_date DATE;
    DECLARE next_end_date DATE;
    
    DECLARE final_dob DATE;
    
    -- Check the previous row (if exists). Allows us to handle intermediate insersions (games from past)
    SELECT team, dob, start_date, end_date
    INTO previous_team, previous_dob, previous_start_date, previous_end_date
    FROM (SELECT player_id, team, dob, start_date, end_date, DATEDIFF(new_date_game, start_date) AS date_diff FROM player_history) t1
    WHERE player_id = new_id AND date_diff > 0
    ORDER BY date_diff
    LIMIT 1;
    
    -- Check the next row (if exists). Allows us to handle intermediate insersions (games from past)
    SELECT team, dob, start_date, end_date
    INTO next_team, next_dob, next_start_date, next_end_date
    FROM (SELECT player_id, team, dob, start_date, end_date, DATEDIFF(new_date_game, start_date) AS date_diff FROM player_history) t1
    WHERE player_id = new_id AND date_diff < 0
    ORDER BY date_diff DESC
    LIMIT 1;
    
    -- Set a final date of birth if exists
    SET final_dob = COALESCE(previous_dob, next_dob);

    	
    -- Scenario 1: No previous row, no next row
    IF previous_start_date IS NULL AND next_start_date IS NULL THEN
        INSERT INTO player_history (player_id, name, team, start_date, end_date)
        VALUES (new_id, new_name, new_team, new_date_game, '9999-12-31');
        
   
    ELSEIF previous_start_date IS NULL THEN
     -- Scenario 2: No previous row, next row different
    	IF next_team <> new_team THEN
    		-- Just insert the new row with end date = next start date - 1
    		INSERT INTO player_history (player_id, name, dob, team, start_date, end_date)
          VALUES (new_id, new_name, final_dob, new_team, new_date_game, DATE_SUB(next_start_date, INTERVAL 1 DAY));
     -- Scenario 3: No previous row, next row same
     	ELSE
          -- Merge the rows be simply adjusting the old rows start date to backtrack to the new rows start date
     		UPDATE player_history
     		SET start_date = new_date_game
     		WHERE player_id = new_id AND start_date = next_start_date AND end_date = next_end_date;
     	END IF;
     	
     	
     -- Scenario 4: Previous row is different, no next row
     ELSEIF next_start_date IS NULL AND previous_team <> new_team THEN
     	-- Update end date of previous row to be new game start date - 1
     	UPDATE player_history
     	SET end_date = DATE_SUB(new_date_game, INTERVAL 1 DAY)
     	WHERE player_id = new_id AND start_date = previous_start_date AND end_date = previous_end_date;
     	
     	-- Insert new row
     	INSERT INTO player_history (player_id, name, dob, team, start_date, end_date)
     	VALUES (new_id, new_name, final_dob, new_team, new_date_game, '9999-12-31');
     
     
     -- Previous row is different, next row is same or different
     ELSEIF previous_team <> new_team THEN
     	-- Scenario 5: Previous row is different, next row is different
     	IF next_team <> new_team THEN
     		-- Update end date of previous row to be new game start date - 1
     		UPDATE player_history
     	  SET end_date = DATE_SUB(new_date_game, INTERVAL 1 DAY)
     	  WHERE player_id = new_id AND start_date = previous_start_date AND end_date = previous_end_date;
     	  
     	   -- Insert the new row with end date = next start date - 1
    	  INSERT INTO player_history (player_id, name, dob, team, start_date, end_date)
          VALUES (new_id, new_name, final_dob, new_team, new_date_game, DATE_SUB(next_start_date, INTERVAL 1 DAY));
          
       -- Scenario 6: Previous row is different, next row is same
       ELSE
       	-- Update end date of previous row to be new game start date - 1
     	  UPDATE player_history
     	  SET end_date = DATE_SUB(new_date_game, INTERVAL 1 DAY)
     	  WHERE player_id = new_id AND start_date = previous_start_date AND end_date = previous_end_date;
     	  
     	  -- "Merge" the rows be simply adjusting the old rows start date to backtrack to the new rows start date
     	  UPDATE player_history
     	  SET start_date = new_date_game
     	  WHERE player_id = new_id AND start_date = next_start_date AND end_date = next_end_date;

       END IF;
     END IF;
END //

DELIMITER ;
