-- Before insert trigger to set NULL end date to '9999-12-31'

DELIMITER //

CREATE TRIGGER end_date_check 
BEFORE INSERT ON player_history
FOR EACH ROW
BEGIN
	IF NEW.end_date IS NULL THEN
		SET NEW.end_date = '9999-12-31';
	END IF;
END;//

DELIMITER ;