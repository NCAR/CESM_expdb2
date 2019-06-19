-- MySQL dump 10.14  Distrib 5.5.56-MariaDB, for Linux (x86_64)
--
-- Host: localhost    Database: csegdb
-- ------------------------------------------------------
-- Server version	5.5.56-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `t2v_cmip6_status`
--
use csegdb;

DROP TABLE IF EXISTS `t2v_cmip6_status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `t2v_cmip6_status` (
  `case_id` int(11) DEFAULT NULL,
  `casename` VARCHAR(128) DEFAULT NULL,
  `cmip6_exp_uid` varchar(200) DEFAULT NULL,
  `conform_code` varchar(20) DEFAULT NULL,
  `conform_color` varchar(7) DEFAULT NULL,
  `conform_disk_usage` varchar(20) DEFAULT NULL,
  `conform_last_update` varchar(25) DEFAULT NULL,
  `conform_model_date` varchar(150) DEFAULT NULL,
  `conform_percent_complete` float(7,2) DEFAULT NULL,
  `conform_process_time` varchar(50) DEFAULT NULL,
  `expName` varchar(40) DEFAULT NULL,
  `pub_code` varchar(20) DEFAULT NULL,
  `pub_color` varchar(7) DEFAULT NULL,
  `pub_last_update` varchar(25) DEFAULT NULL,
  `run_archive_method` varchar(20) DEFAULT NULL,
  `run_code` varchar(20) DEFAULT NULL, 
  `run_color` varchar(7) DEFAULT NULL,
  `run_disk_usage` varchar(20) DEFAULT NULL,
  `run_last_update` varchar(25) DEFAULT NULL,
  `run_model_cost` varchar(50) DEFAULT NULL,
  `run_model_date` varchar(150) DEFAULT NULL,
  `run_model_throughput` varchar(50) DEFAULT NULL,
  `run_percent_complete` float(7,2) DEFAULT NULL, 
  `sta_archive_method` varchar(20) DEFAULT NULL,
  `sta_code` varchar(20) DEFAULT NULL, 
  `sta_color` varchar(7) DEFAULT NULL,
  `sta_disk_usage` varchar(20) DEFAULT NULL, 
  `sta_last_update` varchar(25) DEFAULT NULL, 
  `sta_model_date` varchar(150) DEFAULT NULL,
  `sta_percent_complete` float(7,2) DEFAULT NULL,  
  `total_disk_usage` varchar(20) DEFAULT NULL,  
  `ts_code` varchar(20) DEFAULT NULL,  
  `ts_color` varchar(7) DEFAULT NULL,
  `ts_disk_usage` varchar(20) DEFAULT NULL,  
  `ts_last_update` varchar(25) DEFAULT NULL,  
  `ts_model_date` varchar(150) DEFAULT NULL, 
  `ts_percent_complete` float(7,2) DEFAULT NULL,   
  `ts_process_time` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

