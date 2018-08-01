CREATE DATABASE  IF NOT EXISTS `publc_demo` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */;
USE `publc_demo`;
-- MySQL dump 10.13  Distrib 8.0.12, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: publc_demo
-- ------------------------------------------------------
-- Server version	8.0.12

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
 SET NAMES utf8 ;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Dumping routines for database 'publc_demo'
--
/*!50003 DROP PROCEDURE IF EXISTS `SP_CHECK_BALANCE_ERRORS` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `SP_CHECK_BALANCE_ERRORS`()
BEGIN

DECLARE ledgerBalance BIGINT;
DECLARE bankBalance BIGINT;
DECLARE remainingActionsInQueue BIGINT;

SELECT SUM(balance) FROM ledger INTO ledgerBalance;
SELECT balance FROM bank INTO bankBalance;
SELECT COUNT(*) FROM queue INTO remainingActionsInQueue;

SELECT remainingActionsInQueue, ledgerBalance, BankBalance, 100000000000 - (bankBalance + ledgerBalance) as err;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `SP_CREATE_DEMO` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `SP_CREATE_DEMO`()
BEGIN

DECLARE sumInitialBalance BIGINT DEFAULT 0;

DROP TABLE IF EXISTS bank;
DROP TABLE IF EXISTS ledger;
DROP TABLE IF EXISTS queue_ai;
DROP TABLE IF EXISTS queue;

-- ledger
CREATE TABLE ledger (
	hash BIGINT NOT NULL, 
    balance BIGINT NOT NULL,
    PRIMARY KEY (hash)
);
INSERT INTO ledger (hash, balance) VALUES (111, 0);
INSERT INTO ledger (hash, balance) VALUES (222, 0);
INSERT INTO ledger (hash, balance) VALUES (333, 500);

CREATE TABLE bank (
	balance BIGINT,
    PRIMARY KEY (balance)
);
SELECT sum(balance) FROM ledger INTO sumInitialBalance;
INSERT INTO bank (balance) VALUES (100000000000 - sumInitialBalance);

-- queue
CREATE TABLE queue (
	actionId BIGINT NOT NULL, 
    state TINYINT DEFAULT 0,
    ts TIMESTAMP,
    PRIMARY KEY (actionId)
);
INSERT INTO queue (actionId, ts) VALUES (1, DATE_ADD(NOW(), INTERVAL -1 HOUR));
INSERT INTO queue (actionId, ts) VALUES (2, DATE_ADD(NOW(), INTERVAL -2 HOUR));
INSERT INTO queue (actionId, ts) VALUES (3, DATE_ADD(NOW(), INTERVAL -3 HOUR));

-- queue_ai
CREATE TABLE queue_ai (
	actionId BIGINT NOT NULL,
    INDEX action_ind (actionId),
    FOREIGN KEY (actionId)
		REFERENCES queue(actionId)
        ON DELETE CASCADE,
	ben_hash BIGINT NOT NULL,
    ben_share BIGINT NOT NULL
);
INSERT INTO queue_ai (actionId, ben_hash, ben_share) VALUES (1, 111, 43);
INSERT INTO queue_ai (actionId, ben_hash, ben_share) VALUES (1, 222, 645);
INSERT INTO queue_ai (actionId, ben_hash, ben_share) VALUES (1, 333, 12);
INSERT INTO queue_ai (actionId, ben_hash, ben_share) VALUES (2, 111, 5643);
INSERT INTO queue_ai (actionId, ben_hash, ben_share) VALUES (2, 222, 4632);
INSERT INTO queue_ai (actionId, ben_hash, ben_share) VALUES (3, 111, 34234);
INSERT INTO queue_ai (actionId, ben_hash, ben_share) VALUES (3, 444, 35448);


END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `SP_PROCESS_ACTION` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `SP_PROCESS_ACTION`(
	IN currActionId BIGINT
)
BEGIN
DECLARE currBenHash BIGINT;
DECLARE currBenShare BIGINT;
DECLARE sumActionAmount BIGINT;
DECLARE curDone INT DEFAULT 0;

DECLARE cur CURSOR FOR SELECT ben_hash, ben_share FROM queue_ai WHERE actionId = currActionId;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET curDone = 1;

START TRANSACTION;

	OPEN cur;
	actionItems: LOOP
		FETCH cur INTO currBenHash, currBenShare;
		IF curDone THEN
			LEAVE actionItems;
		END IF;
        
		INSERT INTO ledger (hash, balance) VALUES (currBenHash, currBenShare) 
        ON DUPLICATE KEY UPDATE balance = balance + currBenShare;
	END LOOP;
	CLOSE cur;

	SELECT sum(ben_share) FROM queue_ai WHERE actionId = currActionId INTO sumActionAmount;
	UPDATE bank SET balance = balance - sumActionAmount WHERE balance >= 0; -- The WHERE is just because in Safe Update mode you're not allowed to perform an UPDATE without a WHERE

	-- Due to foreign key contraints, deleting the item from the queue will cascade to its action items in queue_ai
	DELETE FROM queue WHERE actionId = currActionId;

COMMIT;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `SP_PROCESS_QUEUE` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `SP_PROCESS_QUEUE`()
sp_start: BEGIN
DECLARE currActionId BIGINT;

WHILE TRUE DO
	-- Get an action to work on, lock its row for editing, mark it as being processed and quickly release the lock on its row
	START TRANSACTION;
		SELECT actionId FROM queue WHERE state != 1 ORDER BY ts DESC LIMIT 1 FOR UPDATE INTO currActionId;

		IF found_rows() = 0 THEN
			SELECT 'done' AS status;
			ROLLBACK; -- nothing to actually rollback here, just end the transaction
			LEAVE sp_start;
		END IF;
		UPDATE queue SET state = 1 WHERE actionId = currActionId;
	COMMIT;

	CALL SP_PROCESS_ACTION(currActionId);
        
END WHILE;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-08-01 13:28:49
