-- MySQL Workbench Forward Engineering
SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema nhl
-- -----------------------------------------------------
DROP SCHEMA IF EXISTS `nhl` ;

-- -----------------------------------------------------
-- Schema nhl
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `nhl` DEFAULT CHARACTER SET utf8 ;
USE `nhl` ;

-- -----------------------------------------------------
-- Table `nhl`.`game_id`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `nhl`.`game_id` ;

CREATE TABLE IF NOT EXISTS `nhl`.`game_id` (
  `game_id` VARCHAR(25) NOT NULL,
  `team` CHAR(3) NOT NULL,
  `date` DATE NOT NULL,
  PRIMARY KEY (`game_id`),
  CONSTRAINT `unq_game_id` UNIQUE (`team`, `date`))
ENGINE = INNODB;

-- -----------------------------------------------------
-- Table `nhl`.`schedule`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `nhl`.`schedule` ;

CREATE TABLE IF NOT EXISTS `nhl`.`schedule` (
  `team` CHAR(3) NOT NULL,
  `date` DATE NOT NULL,
  `season` INT NULL,
  `location` CHAR(1) NULL,
  `G` SMALLINT UNSIGNED NULL,
  `OT_status` CHAR(2) NULL,
  `win_flag` TINYINT NULL,
  PRIMARY KEY (`team`, `date`),
  INDEX `fk_schedule_game_id1_idx` (`team` ASC, `date` ASC) VISIBLE,
  CONSTRAINT `fk_schedule_game_id1`
    FOREIGN KEY (`team` , `date`)
    REFERENCES `nhl`.`game_id` (`team` , `date`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE)
ENGINE = INNODB;

-- -----------------------------------------------------
-- Trigger: Upon insert into game_id, cascade into schedule
-- -----------------------------------------------------
-- DROP TRIGGER IF EXISTS after_game_id_insert;

-- CREATE TRIGGER after_game_id_insert 
-- 	AFTER INSERT ON game_id 
--   FOR EACH ROW 
-- 	INSERT INTO schedule (team, date) 
-- 	VALUES (NEW.team, NEW.date);

-- -----------------------------------------------------
-- Table `nhl`.`player_history`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `nhl`.`player_history` ;

CREATE TABLE IF NOT EXISTS `nhl`.`player_history` (
  `player_id` VARCHAR(50) NOT NULL,
  `start_date` DATE NOT NULL,
  `end_date` DATE NOT NULL,
  `name` VARCHAR(75) NULL,
  `dob` DATE NULL,
  `team` CHAR(3) NULL,
  PRIMARY KEY (`player_id`, `start_date`),
  CONSTRAINT `fk_player_history_schedule1`
    FOREIGN KEY (`team`)
    REFERENCES `nhl`.`schedule` (`team`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE
)
ENGINE = INNODB;

-- -----------------------------------------------------
-- Table `nhl`.`ml_odds`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `nhl`.`ml_odds` ;

CREATE TABLE IF NOT EXISTS `nhl`.`ml_odds` (
  `team` CHAR(3) NOT NULL,
  `date_recorded` DATE NOT NULL,
  `time_recorded` TIME NOT NULL,
  `date_game` DATE NOT NULL,
  `time_game` TIME NULL,
  `odds` INT NULL,
  PRIMARY KEY (`team`, `date_recorded`, `time_recorded`),
  INDEX `fk_ml_odds_schedule1_idx` (`team` ASC, `date_game` ASC) VISIBLE,
  CONSTRAINT `fk_ml_odds_schedule1`
    FOREIGN KEY (`team` , `date_game`)
    REFERENCES `nhl`.`schedule` (`team` , `date`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE)
ENGINE = INNODB;

-- -----------------------------------------------------
-- Table `nhl`.`pl_odds`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `nhl`.`pl_odds` ;

CREATE TABLE IF NOT EXISTS `nhl`.`pl_odds` (
  `team` CHAR(3) NOT NULL,
  `date_recorded` DATE NOT NULL,
  `time_recorded` TIME NOT NULL,
  `date_game` DATE NOT NULL,
  `time_game` TIME NULL,
  `line` FLOAT NULL,
  `odds` INT NULL,
  PRIMARY KEY (`team`, `date_recorded`, `time_recorded`),
  INDEX `fk_pl_odds_schedule1_idx` (`team` ASC, `date_game` ASC) VISIBLE,
  CONSTRAINT `fk_pl_odds_schedule1`
    FOREIGN KEY (`team` , `date_game`)
    REFERENCES `nhl`.`schedule` (`team` , `date`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE)
ENGINE = INNODB;

-- -----------------------------------------------------
-- Table `nhl`.`total_odds`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `nhl`.`total_odds` ;

CREATE TABLE IF NOT EXISTS `nhl`.`total_odds` (
  `home` CHAR(3) NOT NULL,
  `away` CHAR(3) NOT NULL,
  `date_recorded` DATE NOT NULL,
  `time_recorded` TIME NOT NULL,
  `date_game` DATE NOT NULL,
  `time_game` TIME NULL,
  `bet_type` CHAR(1) NOT NULL,
  `line` FLOAT NULL,
  `odds` INT NULL,
  PRIMARY KEY (`bet_type`, `home`, `away`, `date_recorded`, `time_recorded`),
  INDEX `fk_total_odds_schedule1_idx` (`home` ASC, `away` ASC, `date_game` ASC) VISIBLE,
  CONSTRAINT `fk_total_odds_schedule1`
    FOREIGN KEY (`home` , `date_game`)
    REFERENCES `nhl`.`schedule` (`team` , `date`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE,
  CONSTRAINT `fk_total_odds_schedule2`
    FOREIGN KEY (`away`)
    REFERENCES `nhl`.`schedule` (`team`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE)
ENGINE = INNODB;

-- -----------------------------------------------------
-- Table `nhl`.`regulation_odds`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `nhl`.`regulation_odds` ;

CREATE TABLE IF NOT EXISTS `nhl`.`regulation_odds` (
  `home` CHAR(3) NOT NULL,
  `away` CHAR(3) NOT NULL,
  `date_recorded` DATE NOT NULL,
  `time_recorded` TIME NOT NULL,
  `date_game` DATE NOT NULL,
  `bet_type` VARCHAR(10) NOT NULL,
  `odds` INT NULL,
  PRIMARY KEY (`bet_type`, `home`, `away`, `date_recorded`, `time_recorded`),
  INDEX `fk_regulation_odds_schedule1_idx` (`home` ASC, `away` ASC, `date_game` ASC) VISIBLE,
  CONSTRAINT `fk_regulation_odds_schedule1`
    FOREIGN KEY (`home` , `date_game`)
    REFERENCES `nhl`.`schedule` (`team` , `date`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE,
  CONSTRAINT `fk_regulation_odds_schedule2`
    FOREIGN KEY (`away`)
    REFERENCES `nhl`.`schedule` (`team`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE)
ENGINE = INNODB;

-- -----------------------------------------------------
-- Table `nhl`.`goalscorer_odds`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `nhl`.`goalscorer_odds` ;

CREATE TABLE IF NOT EXISTS `nhl`.`goalscorer_odds`  (
  `player_id` VARCHAR(50) NOT NULL,
  `date_recorded` DATE NOT NULL,
  `time_recorded` TIME NOT NULL,
  `date_game` DATE NOT NULL,
  `home` CHAR(3) NULL,
  `away` CHAR(3) NULL,
  `odds` INT,
  PRIMARY KEY (`player_id`, `date_recorded`, `time_recorded`),
  -- Left off index for foreign key since not expecting many joins to schedule
  CONSTRAINT `fk_goalscorer_player_history1`
    FOREIGN KEY (`player_id`)
    REFERENCES `nhl`.`player_history` (`player_id`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE,
  CONSTRAINT `fk_goalscorer_odds_schedule1`
    FOREIGN KEY (`home` , `date_game`)
    REFERENCES `nhl`.`schedule` (`team` , `date`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE,
  CONSTRAINT `fk_goalscorer_odds_schedule2`
    FOREIGN KEY (`away`)
    REFERENCES `nhl`.`schedule` (`team`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE)
ENGINE = INNODB;

-- -----------------------------------------------------
-- Table `nhl`.`injury`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `nhl`.`injury` ;

CREATE TABLE IF NOT EXISTS `nhl`.`injury` (
  `player_id` VARCHAR(50) NOT NULL,
  `date_recorded` DATE NOT NULL,
  `time_recorded` TIME NOT NULL,
  `team` CHAR(3) NULL,
  `type` VARCHAR(75) NULL,
  `status` VARCHAR(10) NULL,
  PRIMARY KEY (`player_id`, `date_recorded`, `time_recorded`),
  CONSTRAINT `fk_injury_player_history1`
    FOREIGN KEY (`team`)
    REFERENCES `nhl`.`player_history` (`team`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE
)
ENGINE = INNODB;

-- -----------------------------------------------------
-- Table `nhl`.`skater_game`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `nhl`.`skater_game` ;

CREATE TABLE IF NOT EXISTS `nhl`.`skater_game` (
  `player_id` VARCHAR(50) NOT NULL,
  `team` CHAR(3) NOT NULL,
  `game_num` INT NULL,
  `date` DATE NOT NULL,
  `opponent` CHAR(3) NULL,
  `G` SMALLINT UNSIGNED NULL,
  `A` SMALLINT UNSIGNED NULL,
  `P` SMALLINT UNSIGNED NULL,
  `rating` SMALLINT NULL,
  `PIM` SMALLINT UNSIGNED NULL,
  `EVG` SMALLINT UNSIGNED NULL,
  `PPG` SMALLINT UNSIGNED NULL,
  `SHG` SMALLINT UNSIGNED NULL,
  `GWG` SMALLINT UNSIGNED NULL,
  `EVA` SMALLINT UNSIGNED NULL,
  `PPA` SMALLINT UNSIGNED NULL,
  `SHA` SMALLINT UNSIGNED NULL,
  `S` SMALLINT UNSIGNED NULL,
  `S_pct` FLOAT NULL,
  `shifts` INT UNSIGNED NULL,
  `TOI` FLOAT NULL,
  `HIT` INT UNSIGNED NULL,
  `BLK` INT UNSIGNED NULL,
  `FOW` INT UNSIGNED NULL,
  `FOL` INT UNSIGNED NULL,
  `FOW_pct` FLOAT NULL,
  PRIMARY KEY (`player_id`, `team`, `date`),
  INDEX `fk_skater_game_schedule1_idx` (`team` ASC, `date` ASC) VISIBLE,
  CONSTRAINT `fk_skater_game_schedule1`
    FOREIGN KEY (`team` , `date`)
    REFERENCES `nhl`.`schedule` (`team` , `date`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE)
ENGINE = INNODB;

-- -----------------------------------------------------
-- Table `nhl`.`goalie_game`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `nhl`.`goalie_game` ;

CREATE TABLE IF NOT EXISTS `nhl`.`goalie_game` (
  `player_id` VARCHAR(50) NOT NULL,
  `team` CHAR(3) NOT NULL,
  `game_num` INT NULL,
  `date` DATE NOT NULL,
  `opponent` CHAR(3) NULL,
  `decision` CHAR(1) NULL,
  `GA` INT UNSIGNED NULL,
  `SA` INT UNSIGNED NULL,
  `SV` INT UNSIGNED NULL,
  `SV_pct` FLOAT NULL,
  `shutout` TINYINT UNSIGNED NULL,
  `PIM` INT UNSIGNED NULL,
  `TOI` FLOAT NULL,
  PRIMARY KEY (`player_id`, `team`, `date`),
  INDEX `fk_goalie_game_schedule1_idx` (`team` ASC, `date` ASC) VISIBLE,
  CONSTRAINT `fk_goalie_game_schedule1`
    FOREIGN KEY (`team` , `date`)
    REFERENCES `nhl`.`schedule` (`team` , `date`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE)
ENGINE = INNODB;

-- -----------------------------------------------------
-- Table `nhl`.`projected_goalie`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `nhl`.`projected_goalie` ;

CREATE TABLE IF NOT EXISTS `nhl`.`projected_goalie` (
  `player_id` VARCHAR(50) NOT NULL,
  `date_recorded` DATE NOT NULL,
  `time_recorded` TIME NOT NULL,
  `date_game` DATE NOT NULL,
  `team` CHAR(3) NULL,
  `status` CHAR(1) NULL,
  PRIMARY KEY (`player_id`, `date_recorded`, `time_recorded`),
  CONSTRAINT `fk_projected_goalie_player_history1`
    FOREIGN KEY (`player_id`)
    REFERENCES `nhl`.`player_history` (`player_id`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE,
  INDEX `fk_projected_goalie_schedule1_idx` (`team` ASC, `date_game` ASC) VISIBLE,
  CONSTRAINT `fk_projected_goalie_schedule1_idx`
    FOREIGN KEY (`team` , `date_game`)
    REFERENCES `nhl`.`schedule` (`team` , `date`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE)
ENGINE = INNODB;

-- -----------------------------------------------------
-- Table `nhl`.`projected_lineup`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `nhl`.`projected_lineup` ;

CREATE TABLE IF NOT EXISTS `nhl`.`projected_lineup` (
  `player_id` VARCHAR(50) NOT NULL,
  `date_recorded` DATE NOT NULL,
  `time_recorded` TIME NOT NULL,
  `team` CHAR(3) NULL,
  `position` VARCHAR(5) NULL,
  `depth_chart_rank` SMALLINT UNSIGNED NULL,
  `injury_status` VARCHAR(10) NULL,
  `pp1_position` SMALLINT UNSIGNED NULL,
  `pp2_position` SMALLINT UNSIGNED NULL,
  `pk1_position` SMALLINT UNSIGNED NULL,
  `pk2_position` SMALLINT UNSIGNED NULL,
  PRIMARY KEY (`player_id`, `date_recorded`, `time_recorded`),
  CONSTRAINT `fk_projected_lineup_player_history1`
    FOREIGN KEY (`player_id`)
    REFERENCES `nhl`.`player_history` (`player_id`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE,
  CONSTRAINT `fk_projected_lineup_schedule1_idx`
    FOREIGN KEY (`team`)
    REFERENCES `nhl`.`schedule` (`team`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE)
ENGINE = INNODB;

-- -----------------------------------------------------
SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
-- -----------------------------------------------------
