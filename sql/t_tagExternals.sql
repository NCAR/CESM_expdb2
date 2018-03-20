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
-- Table structure for table `t_tagExternals`
--

DROP TABLE IF EXISTS `t_tagExternals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `t_tagExternals` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(20) DEFAULT NULL,
  `path` varchar(50) DEFAULT NULL,
  `svnURL` mediumtext,
  `gatekeeper1_id` int(11) DEFAULT NULL,
  `gatekeeper2_id` int(11) DEFAULT NULL,
  `tagFirst_id` int(11) DEFAULT NULL,
  `ordering` int(11) DEFAULT NULL,
  `tagLast_id` int(11) DEFAULT NULL,
  `isStub` tinyint(1) DEFAULT NULL,
  `isDead` tinyint(1) DEFAULT NULL,
  `subExternals_file` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=62 DEFAULT CHARSET=latin1 COMMENT='table including all the externals that makeup a tag (e.g. sc';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_tagExternals`
--

LOCK TABLES `t_tagExternals` WRITE;
/*!40000 ALTER TABLE `t_tagExternals` DISABLE KEYS */;
INSERT INTO `t_tagExternals` VALUES 
(1,'scripts','scripts','https://svn-ccsm-models.cgd.ucar.edu/scripts/trunk_tags/scripts[version]',32,50,1,1,308,0,0,NULL),
(2,'Machines','scripts/ccsm_utils/Machines','https://svn-ccsm-models.cgd.ucar.edu/Machines/trunk_tags/Machines[version]',32,NULL,1,2,308,0,0,NULL),
(3,'mapping','tools/mapping','https://svn-ccsm-models.cgd.ucar.edu/tools/mapping/trunk_tags/mapping[version]',351,NULL,1,4,308,0,0,NULL),
(4,'drv','models/drv','https://svn-ccsm-models.cgd.ucar.edu/drv/seq_mct/trunk_tags/drvseq[version]',73,NULL,1,5,308,0,0,NULL),
(5,'csm_share','models/csm_share','https://svn-ccsm-models.cgd.ucar.edu/csm_share/trunk_tags/share[version]',73,NULL,1,6,308,0,0,NULL),
(6,'cam','models/atm/cam','https://svn-ccsm-models.cgd.ucar.edu/cam1/branch_tags/bldnml_tags/bldnml??_cam?_?_??/models/atm/cam',19,50,1,10,308,0,0,NULL),
(7,'wrf','models/atm/wrf','https://svn-ccsm-models.cgd.ucar.edu/wrf/trunk_tags/wrf[version]',50,NULL,1,10,235,0,0,NULL),
(8,'clm','models/lnd/clm','https://svn-ccsm-models.cgd.ucar.edu/clm2/trunk_tags/clm?_?_??/models/lnd/clm',20,NULL,1,10,308,0,0,NULL),
(9,'cice','models/ice/cice','https://svn-ccsm-models.cgd.ucar.edu/cice/trunk_tags/cice[version]',14,NULL,1,10,308,0,0,NULL),
(10,'cism','models/glc/cism','https://svn-ccsm-models.cgd.ucar.edu/glc/trunk_tags/cism[version]',105,NULL,1,10,308,0,0,NULL),
(11,'pop2','models/ocn/pop2','https://svn-ccsm-models.cgd.ucar.edu/pop2/trunk_tags/cesm_pop_[version]',351,NULL,1,10,308,0,0,NULL),
(12,'datm','models/atm/datm','https://svn-ccsm-models.cgd.ucar.edu/datm7/trunk_tags/datm[version]',73,NULL,1,10,308,0,0,NULL),
(13,'dlnd','models/lnd/dlnd','https://svn-ccsm-models.cgd.ucar.edu/dlnd7/trunk_tags/dlnd[version]',73,NULL,1,10,308,0,0,NULL),
(14,'dice','models/ice/dice','https://svn-ccsm-models.cgd.ucar.edu/dice7/trunk_tags/dice[version]',73,NULL,1,10,308,0,0,NULL),
(15,'docn','models/ocn/docn','https://svn-ccsm-models.cgd.ucar.edu/docn7/trunk_tags/docn[version]',73,NULL,1,10,308,0,0,NULL),
(16,'xatm','models/atm/xatm','https://svn-ccsm-models.cgd.ucar.edu/dead7/trunk_tags/dead[version]/xatm',73,NULL,1,10,308,0,1,NULL),
(17,'xlnd','models/lnd/xlnd','https://svn-ccsm-models.cgd.ucar.edu/dead7/trunk_tags/dead[version]/xlnd',73,NULL,1,10,308,0,1,NULL),
(18,'xice','models/ice/xice','https://svn-ccsm-models.cgd.ucar.edu/dead7/trunk_tags/dead[version]/xice',73,NULL,1,10,308,0,1,NULL),
(19,'xocn','models/ocn/xocn','https://svn-ccsm-models.cgd.ucar.edu/dead7/trunk_tags/dead[version]/xocn',73,NULL,1,10,308,0,1,NULL),
(20,'xglc','models/glc/xglc','https://svn-ccsm-models.cgd.ucar.edu/dead7/trunk_tags/dead[version]/xglc',73,NULL,1,10,308,0,1,NULL),
(21,'dead_share','models/dead_share','https://svn-ccsm-models.cgd.ucar.edu/dead7/trunk_tags/dead[version]/dead_share',73,NULL,1,10,308,0,1,NULL),
(22,'satm','models/atm/satm','https://svn-ccsm-models.cgd.ucar.edu/stubs/trunk_tags/stubs[version]/satm',73,NULL,1,10,308,1,0,NULL),
(23,'slnd','models/lnd/slnd','https://svn-ccsm-models.cgd.ucar.edu/stubs/trunk_tags/stubs[version]/slnd',73,NULL,1,10,308,1,0,NULL),
(24,'sice','models/ice/sice','https://svn-ccsm-models.cgd.ucar.edu/stubs/trunk_tags/stubs[version]/sice',73,NULL,1,10,308,1,0,NULL),
(25,'socn','models/ocn/socn','https://svn-ccsm-models.cgd.ucar.edu/stubs/trunk_tags/stubs[version]/socn',73,NULL,1,10,308,1,0,NULL),
(26,'sglc','models/glc/sglc','https://svn-ccsm-models.cgd.ucar.edu/stubs/trunk_tags/stubs[version]/sglc',73,NULL,1,10,308,1,0,NULL),
(27,'timing','models/utils/timing','https://svn-ccsm-models.cgd.ucar.edu/timing/trunk_tags/timing_[version]',32,NULL,1,10,308,0,0,NULL),
(28,'esmf_wrf_timemgr','models/utils/esmf_wrf_timemgr','https://svn-ccsm-models.cgd.ucar.edu/esmf_wrf_timemgr/trunk_tags/esmf_wrf_timemgr_[version]',73,NULL,1,10,308,0,0,NULL),
(29,'mct','models/utils/mct','https://github.com/MCSclimate/MCT/tags/MCT[version]',32,NULL,1,10,308,0,0,NULL),
(30,'pio','models/utils/pio','http://parallelio.googlecode.com/svn/trunk_tags/pio[version]/pio',32,NULL,1,10,308,0,0,NULL),
(31,'rtm','models/rof/rtm','https://svn-ccsm-models.cgd.ucar.edu/rivrtm/trunk_tags/rtm1_[version]',73,50,1,10,308,0,0,NULL),
(32,'drof','models/rof/drof','https://svn-ccsm-models.cgd.ucar.edu/drof/trunk_tags/drof[version]',73,NULL,1,10,308,0,0,NULL),
(33,'xrof','models/rof/xrof','https://svn-ccsm-models.cgd.ucar.edu/dead7/trunk_tags/dead7_7_04/xrof',73,NULL,1,10,308,0,1,NULL),
(34,'srof','models/rof/srof','https://svn-ccsm-models.cgd.ucar.edu/stubs/trunk_tags/stubs1_4_01/srof',73,NULL,1,10,308,1,0,NULL),
(35,'cprnc','tools/cprnc','https://svn-ccsm-models.cgd.ucar.edu/tools/cprnc/trunk_tags/cprnc_[version]',32,NULL,177,3,308,0,0,NULL),
(36,'ww3','models/wav/ww3','https://svn-ccsm-models.cgd.ucar.edu/ww3/trunk_tags/ww3_[version]',73,NULL,180,10,308,0,0,NULL),
(37,'xwav','models/wav/xwav','https://svn-ccsm-models.cgd.ucar.edu/dead7/trunk_tags/dead[version]/xwav',73,NULL,180,10,308,0,1,NULL),
(38,'swav','models/wav/swav','https://svn-ccsm-models.cgd.ucar.edu/stubs/trunk_tags/stubs[version]/swav',73,NULL,180,10,308,1,0,NULL),
(39,'dwav','models/wav/dwav','https://svn-ccsm-models.cgd.ucar.edu/dwav/trunk_tags/dwav[version]',73,NULL,308,10,308,0,0,NULL),
(40,'aquap','models/ocn/aquap','https://svn-ccsm-models.cgd.ucar.edu/aquap/trunk_tags/aquap_130430',32,NULL,187,10,308,0,0,NULL),
(41,'genf90','models/utils/bin',' http://parallelio.googlecode.com/svn/genf90/trunk_tags/genf90_130402',32,NULL,206,10,206,0,0,NULL),
(42,'validation_testing','scripts/validation_testing','https://svn-ccsm-models.cgd.ucar.edu/validation_testing/trunk_tags/validation_[version]/run_CESM/',351,354,234,7,308,0,0,NULL),
(43,'doc','scripts/doc','https://svn-ccsm-models.cgd.ucar.edu/doc/',334,354,250,10,308,0,0,NULL),
(44,'unit_testing','tools/unit_testing','https://svn-ccsm-models.cgd.ucar.edu/unit_testing/ ',165,NULL,255,10,308,0,0,NULL),
(45,'CMake','scripts/ccsm_utils/CMake','https://github.com/quantheory/CMake_Fortran_utils',165,32,256,10,308,0,0,NULL),
(46,'stubs models','models/[comp]/[stub_model]','https://svn-ccsm-models.cgd.ucar.edu/stubs/trunk_tags/stubs[version]/[stub_model]',73,32,261,11,308,1,0,NULL),
(47,'dead models','models/[comp]/[dead_model]','https://svn-ccsm-models.cgd.ucar.edu/dead7/trunk_tags/dead[version]/[dead_model]',73,32,261,11,308,0,1,NULL),
(48,'pyReshaper','tools/pyReshaper','https://proxy.subversion.ucar.edu/pubasap/pyReshaper/trunk',679,334,281,10,308,0,0,NULL),
(49,'load_balancing_tool','tools/load_balancing_tool','https://svn-ccsm-models.cgd.ucar.edu/tools/load_balancing_tool/trunk/',190,334,281,10,308,0,0,NULL),
(50,'cime','cime','https://github.com/CESM-Development/cime',32,50,309,1,NULL,0,0,NULL),
(51,'cam','components/cam','https://svn-ccsm-models.cgd.ucar.edu/cam1',32,50,309,2,NULL,0,0,NULL),
(52,'clm','components/clm','https://svn-ccsm-models.cgd.ucar.edu/clm2',32,50,309,3,448,0,0,NULL),
(53,'cice','components/cice','https://svn-ccsm-models.cgd.ucar.edu/cice',32,50,309,4,NULL,0,0,NULL),
(54,'pop','components/pop','https://svn-ccsm-models.cgd.ucar.edu/pop',32,50,309,5,NULL,0,0,'Externals_POP.cfg'),
(55,'aquap','components/aquap','https://svn-ccsm-models.cgd.ucar.edu/aquap',32,50,309,7,433,0,0,NULL),
(56,'rtm','components/rtm','https://svn-ccsm-models.cgd.ucar.edu/rivrtm',32,50,309,8,448,0,0,NULL),
(57,'ww3','components/ww3','https://svn-ccsm-models.cgd.ucar.edu/ww3',32,50,309,9,NULL,0,0,NULL),
(58,'cism','components/cism','https://svn-ccsm-models.cgd.ucar.edu/glc',32,50,309,6,448,0,0,NULL),
(59,'mosart','components/mosart','https://svn-ccsm-models.cgd.ucar.edu/mosart',32,50,353,12,448,0,0,NULL),
(60,'cime_config','cime/cime_config/cesm/allactive','https://github.com/CESM-Development/cime_config/tags/cime_config0.0.1.alpha.02/allactive',32,50,423,1,425,0,0,NULL),
(61,'cime_config','cime_config','https://github.com/CESM-Development/cime_config',32,50,426,1,NULL,0,0,NULL),
STARTHERE.....
(62,'clm','components/clm','https://github.com/ESCOMP/ctsm',32,50,449,3,NULL,0,0,'Externals_CLM.cfg'),
(63,'cism','components/cism','https://github.com/ESCOMP/cism-wrapper',32,50,449,6,448,0,0,'Externals_CISM.cfg');
/*!40000 ALTER TABLE `t_tagExternals` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-01-22 17:07:58
