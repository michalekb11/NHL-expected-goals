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
-- Table `nhl`.`game_ids`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `nhl`.`game_ids` ;

CREATE TABLE IF NOT EXISTS `nhl`.`game_ids` (
  `team` CHAR(3) NOT NULL,
  `date` DATE NOT NULL,
  `game_id` VARCHAR(25) NULL,
  PRIMARY KEY (`team`, `date`))
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
  INDEX `fk_schedule_game_ids1_idx` (`team` ASC, `date` ASC) VISIBLE,
  CONSTRAINT `fk_schedule_game_ids1`
    FOREIGN KEY (`team` , `date`)
    REFERENCES `nhl`.`game_ids` (`team` , `date`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE)
ENGINE = INNODB;

-- -----------------------------------------------------
-- Trigger: Upon insert into game_ids, cascade into schedule
-- -----------------------------------------------------
DROP TRIGGER IF EXISTS after_game_id_insert;

CREATE TRIGGER after_game_id_insert 
	AFTER INSERT ON game_ids FOR EACH ROW 
	INSERT INTO SCHEDULE (team, DATE) 
	VALUES (NEW.team, NEW.date);

-- -----------------------------------------------------
-- Table `nhl`.`skater_games`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `nhl`.`skater_games` ;

CREATE TABLE IF NOT EXISTS `nhl`.`skater_games` (
  `player_id` VARCHAR(50) NOT NULL,
  `name` VARCHAR(75) NULL,
  `age` SMALLINT UNSIGNED NULL,
  `team` CHAR(3) NOT NULL,
  -- `season` INT NULL,
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
  INDEX `fk_skater_games_schedule1_idx` (`team` ASC, `date` ASC) VISIBLE,
  CONSTRAINT `fk_skater_games_schedule1`
    FOREIGN KEY (`team` , `date`)
    REFERENCES `nhl`.`schedule` (`team` , `date`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE)
ENGINE = INNODB;


-- -----------------------------------------------------
-- Table `nhl`.`ml_odds`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `nhl`.`ml_odds` ;

CREATE TABLE IF NOT EXISTS `nhl`.`ml_odds` (
  `team` CHAR(3) NOT NULL,
  `date_recorded` DATE NULL,
  `time_recorded` TIME NULL,
  `date_game` DATE NOT NULL,
  `time_game` TIME NULL,
  `odds` INT NULL,
  PRIMARY KEY (`team`, `date_game`),
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
  `date_recorded` DATE NULL,
  `time_recorded` TIME NULL,
  `date_game` DATE NOT NULL,
  `time_game` TIME NULL,
  `line` FLOAT NULL,
  `odds` INT NULL,
  PRIMARY KEY (`team`, `date_game`),
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
  `date_recorded` DATE NULL,
  `time_recorded` TIME NULL,
  `date_game` DATE NOT NULL,
  `time_game` TIME NULL,
  `bet_type` CHAR(1) NOT NULL,
  `line` FLOAT NULL,
  `odds` INT NULL,
  PRIMARY KEY (`bet_type`, `home`, `away`, `date_game`),
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
  `date_recorded` DATE NULL,
  `time_recorded` TIME NULL,
  `date_game` DATE NOT NULL,
  `bet_type` VARCHAR(10) NOT NULL,
  `odds` INT NULL,
  PRIMARY KEY (`bet_type`, `home`, `away`, `date_game`),
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
-- Table `nhl`.`goalie_games`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `nhl`.`goalie_games` ;

CREATE TABLE IF NOT EXISTS `nhl`.`goalie_games` (
  `player_id` VARCHAR(50) NOT NULL,
  `name` VARCHAR(75) NULL,
  `age` SMALLINT NULL,
  `team` CHAR(3) NOT NULL,
  -- `season` INT NULL,
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
  INDEX `fk_goalie_games_schedule1_idx` (`team` ASC, `date` ASC) VISIBLE,
  CONSTRAINT `fk_goalie_games_schedule1`
    FOREIGN KEY (`team` , `date`)
    REFERENCES `nhl`.`schedule` (`team` , `date`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE)
ENGINE = INNODB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
