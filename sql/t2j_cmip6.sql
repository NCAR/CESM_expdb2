-- MySQL dump 10.14  Distrib 5.5.60-MariaDB, for Linux (x86_64)
--
-- Host: localhost    Database: csegdb
-- ------------------------------------------------------
-- Server version	5.5.60-MariaDB

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
-- Table structure for table `t2j_cmip6`
--

DROP TABLE IF EXISTS `t2j_cmip6`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `t2j_cmip6` (
  `case_id` int(11) DEFAULT NULL,
  `exp_id` int(11) NOT NULL DEFAULT '0',
  `deck_id` int(11) DEFAULT NULL,
  `design_mip_id` int(11) DEFAULT NULL,
  `parentExp_id` int(11) DEFAULT NULL,
  `variant_label` varchar(20) NOT NULL DEFAULT '',
  `ensemble_num` int(11) DEFAULT NULL,
  `ensemble_size` int(11) DEFAULT NULL,
  `assign_id` int(11) DEFAULT NULL,
  `science_id` int(11) DEFAULT NULL,
  `request_date` datetime DEFAULT NULL,
  `source_type` varchar(100) DEFAULT NULL,
  `nyears` int(11) DEFAULT NULL,
  `source_id` int(11) DEFAULT '1',
  `branch_method` varchar(500) DEFAULT NULL,
  `branch_time_in_parent` varchar(100) DEFAULT NULL,
  `branch_time_in_child` varchar(100) DEFAULT NULL,
  `parentCase_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`exp_id`,`variant_label`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2019-02-20 14:57:57
