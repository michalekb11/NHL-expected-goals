DROP TABLE IF EXISTS test;

CREATE TABLE test (
	id VARCHAR(15),
	player_name VARCHAR(50),
	dob DATE,
	team CHAR(3),
	start_date DATE,
	end_date DATE,
	PRIMARY KEY (id, start_date, end_date)
);


-- Create or replace the stored procedure
DROP PROCEDURE IF EXISTS InsertOrUpdatePlayer;

DELIMITER //

CREATE PROCEDURE InsertOrUpdatePlayer(
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
    FROM (SELECT id, team, dob, start_date, end_date, DATEDIFF(new_date_game, start_date) AS date_diff FROM test) t1
    WHERE id = new_id AND date_diff > 0
    ORDER BY date_diff
    LIMIT 1;
    
    -- Check the next row (if exists). Allows us to handle intermediate insersions (games from past)
    SELECT team, dob, start_date, end_date
    INTO next_team, next_dob, next_start_date, next_end_date
    FROM (SELECT id, team, dob, start_date, end_date, DATEDIFF(new_date_game, start_date) AS date_diff FROM test) t1
    WHERE id = new_id AND date_diff < 0
    ORDER BY date_diff DESC
    LIMIT 1;
    
    -- Set a final date of birth if exists
    SET final_dob = COALESCE(previous_dob, next_dob);

    	
    -- Scenario 1: No previous row, no next row
    IF previous_start_date IS NULL AND next_start_date IS NULL THEN
        INSERT INTO test (id, player_name, team, start_date, end_date)
        VALUES (new_id, new_name, new_team, new_date_game, '9999-12-31');
        
   
    ELSEIF previous_start_date IS NULL THEN
     -- Scenario 2: No previous row, next row different
    	IF next_team <> new_team THEN
    		-- Just insert the new row with end date = next start date - 1
    		INSERT INTO test (id, player_name, dob, team, start_date, end_date)
          VALUES (new_id, new_name, final_dob, new_team, new_date_game, DATE_SUB(next_start_date, INTERVAL 1 DAY));
     -- Scenario 3: No previous row, next row same
     	ELSE
          -- Merge the rows be simply adjusting the old rows start date to backtrack to the new rows start date
     		UPDATE test
     		SET start_date = new_date_game
     		WHERE id = new_id AND start_date = next_start_date AND end_date = next_end_date;
     	END IF;
     	
     	
     -- Scenario 4: Previous row is different, no next row
     ELSEIF next_start_date IS NULL AND previous_team <> new_team THEN
     	-- Update end date of previous row to be new game start date - 1
     	UPDATE test
     	SET end_date = DATE_SUB(new_date_game, INTERVAL 1 DAY)
     	WHERE id = new_id AND start_date = previous_start_date AND end_date = previous_end_date;
     	
     	-- Insert new row
     	INSERT INTO test (id, player_name, dob, team, start_date, end_date)
     	VALUES (new_id, new_name, final_dob, new_team, new_date_game, '9999-12-31');
     
     
     -- Previous row is different, next row is same or different
     ELSEIF previous_team <> new_team THEN
     	-- Scenario 5: Previous row is different, next row is different
     	IF next_team <> new_team THEN
     		-- Update end date of previous row to be new game start date - 1
     		UPDATE test
     	  SET end_date = DATE_SUB(new_date_game, INTERVAL 1 DAY)
     	  WHERE id = new_id AND start_date = previous_start_date AND end_date = previous_end_date;
     	  
     	   -- Insert the new row with end date = next start date - 1
    	  INSERT INTO test (id, player_name, dob, team, start_date, end_date)
          VALUES (new_id, new_name, final_dob, new_team, new_date_game, DATE_SUB(next_start_date, INTERVAL 1 DAY));
          
       -- Scenario 6: Previous row is different, next row is same
       ELSE
       	-- Update end date of previous row to be new game start date - 1
     	  UPDATE test
     	  SET end_date = DATE_SUB(new_date_game, INTERVAL 1 DAY)
     	  WHERE id = new_id AND start_date = previous_start_date AND end_date = previous_end_date;
     	  
     	  -- "Merge" the rows be simply adjusting the old rows start date to backtrack to the new rows start date
     	  UPDATE test
     	  SET start_date = new_date_game
     	  WHERE id = new_id AND start_date = next_start_date AND end_date = next_end_date;

       END IF;
     END IF;
END //

DELIMITER ;


-- Test the procedure

-- This will throw an error if you try to insert another {id, start_date} that is already in table (duplicate key)

DELETE FROM test;

-- DET --> COL --> PIT --> ANA

CALL InsertOrUpdatePlayer ('1', 'larkin', 'DET', '2022-01-01');

CALL InsertOrUpdatePlayer ('1', 'larkin', 'COL', '2023-01-01');

CALL InsertOrUpdatePlayer ('1', 'larkin', 'PIT', '2024-01-01');

CALL InsertOrUpdatePlayer ('1', 'larkin', 'ANA', '2025-01-01');

CALL InsertOrUpdatePlayer ('1', 'larkin', 'ANA', '2024-12-01');

CALL InsertOrUpdatePlayer ('1', 'larkin', 'DET', '2020-01-01');

CALL InsertOrUpdatePlayer ('1', 'larkin', 'COL', '2022-05-01');

CALL InsertOrUpdatePlayer ('1', 'larkin', 'COL', '2019-05-01');

CALL InsertOrUpdatePlayer ('1', 'larkin', 'FLA', '2020-01-01');


SELECT * FROM test;



UPDATE test SET dob = '1999-08-15' WHERE id = '1';















CREATE PROCEDURE InsertOrUpdatePlayer(
    IN new_id INT,
    IN new_name VARCHAR(255),
    IN new_team CHAR(3),
    IN new_date_game DATE
)
BEGIN
    DECLARE current_id VARCHAR(15);
    DECLARE current_name VARCHAR(50);
    DECLARE current_team CHAR(3);
    DECLARE current_dob DATE;
    DECLARE last_update DATE;

    -- Check if the player is already in the Player table
    SELECT id, player_name, team, dob, start_date
    INTO current_id, current_name, current_team, current_dob, last_update
    FROM test
    WHERE id = new_id
    ORDER BY start_date DESC
    LIMIT 1;

    -- If the player is not in the table, insert a new row
    IF current_id IS NULL THEN
        INSERT INTO test (id, player_name, team, start_date, end_date)
        VALUES (new_id, new_name, new_team, new_date_game, '9999-01-01');

    -- If the player is in the table and the row is different, update the row and history
    ELSE
    	 IF new_date_game <= last_update THEN
    	 	SET @errorMsg = CONCAT('Error: The DATE of the game must be greater THAN the DATE of the LAST UPDATE: ', new_id, '.');
    	 	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @errorMsg;
    	 END IF;
    	 	
        IF current_team <> new_team THEN
            UPDATE test
            SET end_date = DATE_SUB(new_date_game, INTERVAL 1 DAY)
            WHERE id = new_id AND end_date = '9999-01-01';

            INSERT INTO test (id, player_name, dob, team, start_date, end_date)
            VALUES (new_id, new_name, current_dob, new_team, new_date_game, '9999-01-01');
        END IF;
    END IF;
END //


