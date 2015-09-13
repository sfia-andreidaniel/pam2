-- MySQL dump 10.13  Distrib 5.5.44, for debian-linux-gnu (x86_64)
--
-- Host: 127.0.0.1    Database: pam
-- ------------------------------------------------------
-- Server version	5.5.44-0ubuntu0.14.04.1

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
-- Table structure for table `group`
--

DROP TABLE IF EXISTS `group`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `group` (
  `group_id` int(11) NOT NULL AUTO_INCREMENT,
  `group_name` char(30) NOT NULL,
  `group_enabled` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`group_id`),
  UNIQUE KEY `group_name_UNIQUE` (`group_name`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `group`
--

LOCK TABLES `group` WRITE;
/*!40000 ALTER TABLE `group` DISABLE KEYS */;
INSERT INTO `group` VALUES (1,'administrators',1),(2,'powerusers',1),(3,'users',1);
/*!40000 ALTER TABLE `group` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `group_users`
--

DROP TABLE IF EXISTS `group_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `group_users` (
  `group_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  PRIMARY KEY (`group_id`,`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `group_users`
--

LOCK TABLES `group_users` WRITE;
/*!40000 ALTER TABLE `group_users` DISABLE KEYS */;
/*!40000 ALTER TABLE `group_users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `host`
--

DROP TABLE IF EXISTS `host`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `host` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` char(64) DEFAULT NULL,
  `default` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name_UNIQUE` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `host`
--

LOCK TABLES `host` WRITE;
/*!40000 ALTER TABLE `host` DISABLE KEYS */;
INSERT INTO `host` VALUES (1,'localhost',1),(2,'virtualubuntu',0);
/*!40000 ALTER TABLE `host` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `host_services`
--

DROP TABLE IF EXISTS `host_services`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `host_services` (
  `host_id` int(11) NOT NULL,
  `service_id` int(11) NOT NULL,
  PRIMARY KEY (`host_id`,`service_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `host_services`
--

LOCK TABLES `host_services` WRITE;
/*!40000 ALTER TABLE `host_services` DISABLE KEYS */;
/*!40000 ALTER TABLE `host_services` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `service`
--

DROP TABLE IF EXISTS `service`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `service` (
  `service_id` int(11) NOT NULL AUTO_INCREMENT,
  `service_name` char(16) NOT NULL,
  PRIMARY KEY (`service_id`),
  UNIQUE KEY `service_name_UNIQUE` (`service_name`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `service`
--

LOCK TABLES `service` WRITE;
/*!40000 ALTER TABLE `service` DISABLE KEYS */;
INSERT INTO `service` VALUES (1,'pam');
/*!40000 ALTER TABLE `service` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `service_host_group_options`
--

DROP TABLE IF EXISTS `service_host_group_options`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `service_host_group_options` (
  `service_id` int(11) NOT NULL,
  `host_id` int(11) NOT NULL,
  `group_id` int(11) NOT NULL,
  `option_name` char(45) NOT NULL,
  `option_value` char(255) DEFAULT NULL,
  PRIMARY KEY (`service_id`,`host_id`,`group_id`,`option_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `service_host_group_options`
--

LOCK TABLES `service_host_group_options` WRITE;
/*!40000 ALTER TABLE `service_host_group_options` DISABLE KEYS */;
/*!40000 ALTER TABLE `service_host_group_options` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `service_host_groups`
--

DROP TABLE IF EXISTS `service_host_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `service_host_groups` (
  `service_id` int(11) NOT NULL,
  `host_id` int(11) NOT NULL,
  `group_id` int(11) NOT NULL,
  `allow` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`service_id`,`host_id`,`group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `service_host_groups`
--

LOCK TABLES `service_host_groups` WRITE;
/*!40000 ALTER TABLE `service_host_groups` DISABLE KEYS */;
/*!40000 ALTER TABLE `service_host_groups` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `service_host_options`
--

DROP TABLE IF EXISTS `service_host_options`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `service_host_options` (
  `service_id` int(11) NOT NULL,
  `host_id` int(11) NOT NULL,
  `option_name` char(48) NOT NULL,
  `option_value` char(255) DEFAULT NULL,
  PRIMARY KEY (`service_id`,`host_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `service_host_options`
--

LOCK TABLES `service_host_options` WRITE;
/*!40000 ALTER TABLE `service_host_options` DISABLE KEYS */;
/*!40000 ALTER TABLE `service_host_options` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `service_host_user_options`
--

DROP TABLE IF EXISTS `service_host_user_options`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `service_host_user_options` (
  `service_id` int(11) NOT NULL,
  `host_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `option_name` char(45) NOT NULL,
  `option_value` char(255) DEFAULT NULL,
  PRIMARY KEY (`service_id`,`host_id`,`user_id`,`option_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `service_host_user_options`
--

LOCK TABLES `service_host_user_options` WRITE;
/*!40000 ALTER TABLE `service_host_user_options` DISABLE KEYS */;
/*!40000 ALTER TABLE `service_host_user_options` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `service_host_users`
--

DROP TABLE IF EXISTS `service_host_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `service_host_users` (
  `service_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `host_id` int(11) NOT NULL,
  `allow` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`service_id`,`user_id`,`host_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `service_host_users`
--

LOCK TABLES `service_host_users` WRITE;
/*!40000 ALTER TABLE `service_host_users` DISABLE KEYS */;
/*!40000 ALTER TABLE `service_host_users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `service_options`
--

DROP TABLE IF EXISTS `service_options`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `service_options` (
  `service_id` int(11) NOT NULL,
  `option_name` char(45) NOT NULL,
  `default_value` char(255) DEFAULT NULL,
  PRIMARY KEY (`service_id`,`option_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `service_options`
--

LOCK TABLES `service_options` WRITE;
/*!40000 ALTER TABLE `service_options` DISABLE KEYS */;
/*!40000 ALTER TABLE `service_options` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `service_user_password`
--

DROP TABLE IF EXISTS `service_user_password`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `service_user_password` (
  `service_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `service_password` char(48) NOT NULL,
  `service_password_encryption` enum('PLAIN','MD5','CRYPT','PASSWORD') NOT NULL DEFAULT 'PLAIN',
  PRIMARY KEY (`service_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `service_user_password`
--

LOCK TABLES `service_user_password` WRITE;
/*!40000 ALTER TABLE `service_user_password` DISABLE KEYS */;
/*!40000 ALTER TABLE `service_user_password` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user` (
  `user_id` int(11) NOT NULL AUTO_INCREMENT,
  `login_name` char(16) NOT NULL,
  `real_name` char(64) DEFAULT NULL,
  `email` char(96) NOT NULL,
  `user_enabled` tinyint(1) NOT NULL DEFAULT '0',
  `is_admin` tinyint(1) NOT NULL DEFAULT '0',
  `password` varchar(32) NOT NULL,
  PRIMARY KEY (`user_id`),
  KEY `user_id` (`user_id`),
  KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user`
--

LOCK TABLES `user` WRITE;
/*!40000 ALTER TABLE `user` DISABLE KEYS */;
INSERT INTO `user` VALUES (1,'admin','The Boss','boss@business.com',1,1,'21232f297a57a5a743894a0e4a801fc3'),(2,'joe','John Doe','joe@business.com',1,0,'8ff32489f92f33416694be8fdc2d4c22');
/*!40000 ALTER TABLE `user` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2015-09-14  1:17:17
