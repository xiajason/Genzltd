-- MySQL dump 10.13  Distrib 8.0.43, for Linux (aarch64)
--
-- Host: localhost    Database: dao_migration
-- ------------------------------------------------------
-- Server version	8.0.43

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `companies`
--

DROP TABLE IF EXISTS `companies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `companies` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `industry` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `size` enum('startup','small','medium','large','enterprise') COLLATE utf8mb4_unicode_ci DEFAULT 'medium',
  `location` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `website` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `logo_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `is_verified` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_name` (`name`),
  KEY `idx_industry` (`industry`),
  KEY `idx_size` (`size`),
  KEY `idx_is_verified` (`is_verified`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `companies`
--

LOCK TABLES `companies` WRITE;
/*!40000 ALTER TABLE `companies` DISABLE KEYS */;
INSERT INTO `companies` VALUES (1,'DAO Tech','Technology','startup','Beijing, China',NULL,NULL,'ä¸“æ³¨äºŽDAOæŠ€æœ¯çš„åˆ›æ–°å…¬å¸',1,'2025-10-01 01:45:31','2025-10-01 01:45:31'),(2,'Blockchain Inc','Blockchain','medium','Shanghai, China',NULL,NULL,'åŒºå—é“¾æŠ€æœ¯è§£å†³æ–¹æ¡ˆæä¾›å•†',1,'2025-10-01 01:45:31','2025-10-01 01:45:31'),(3,'Web3 Solutions','Web3','small','Shenzhen, China',NULL,NULL,'Web3ç”Ÿæ€ç³»ç»Ÿå»ºè®¾è€…',0,'2025-10-01 01:45:31','2025-10-01 01:45:31');
/*!40000 ALTER TABLE `companies` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dao_activity_log`
--

DROP TABLE IF EXISTS `dao_activity_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dao_activity_log` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `activity_type` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `activity_description` text COLLATE utf8mb4_unicode_ci,
  `metadata` json DEFAULT NULL,
  `timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dao_activity_log`
--

LOCK TABLES `dao_activity_log` WRITE;
/*!40000 ALTER TABLE `dao_activity_log` DISABLE KEYS */;
INSERT INTO `dao_activity_log` VALUES (1,'user-uuid-001','login','ç”¨æˆ·ç™»å½•ç³»ç»Ÿ','{\"ip\": \"127.0.0.1\", \"user_agent\": \"Mozilla/5.0\"}','2025-10-01 01:45:31'),(2,'user-uuid-002','proposal_create','åˆ›å»ºæŠ€æœ¯ææ¡ˆ','{\"title\": \"æŠ€æœ¯æž¶æž„å‡çº§ææ¡ˆ\", \"proposal_id\": \"prop-002\"}','2025-10-01 01:45:31'),(3,'user-uuid-003','vote','å‚ä¸Žæ²»ç†æŠ•ç¥¨','{\"vote\": \"against\", \"proposal_id\": \"prop-001\"}','2025-10-01 01:45:31');
/*!40000 ALTER TABLE `dao_activity_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dao_members`
--

DROP TABLE IF EXISTS `dao_members`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dao_members` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `wallet_address` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reputation_score` int DEFAULT '0',
  `contribution_points` int DEFAULT '0',
  `join_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `status` enum('active','inactive','suspended') COLLATE utf8mb4_unicode_ci DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dao_members`
--

LOCK TABLES `dao_members` WRITE;
/*!40000 ALTER TABLE `dao_members` DISABLE KEYS */;
INSERT INTO `dao_members` VALUES (1,'user-uuid-001','0x1234567890abcdef1234567890abcdef12345678',100,50,'2025-10-01 01:45:31','active','2025-10-01 01:45:31','2025-10-01 01:45:31'),(2,'user-uuid-002','0xabcdef1234567890abcdef1234567890abcdef12',85,35,'2025-10-01 01:45:31','active','2025-10-01 01:45:31','2025-10-01 01:45:31'),(3,'user-uuid-003','0x9876543210fedcba9876543210fedcba98765432',120,75,'2025-10-01 01:45:31','active','2025-10-01 01:45:31','2025-10-01 01:45:31');
/*!40000 ALTER TABLE `dao_members` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dao_proposals`
--

DROP TABLE IF EXISTS `dao_proposals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dao_proposals` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `proposal_id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `proposer_id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `proposal_type` enum('governance','funding','technical','policy') COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('draft','active','passed','rejected','executed') COLLATE utf8mb4_unicode_ci DEFAULT 'draft',
  `start_time` timestamp NULL DEFAULT NULL,
  `end_time` timestamp NULL DEFAULT NULL,
  `votes_for` int DEFAULT '0',
  `votes_against` int DEFAULT '0',
  `total_votes` int DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `proposal_id` (`proposal_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dao_proposals`
--

LOCK TABLES `dao_proposals` WRITE;
/*!40000 ALTER TABLE `dao_proposals` DISABLE KEYS */;
INSERT INTO `dao_proposals` VALUES (1,'prop-001','DAOæ²»ç†æœºåˆ¶ä¼˜åŒ–ææ¡ˆ','å»ºè®®ä¼˜åŒ–DAOæ²»ç†æœºåˆ¶ï¼Œæé«˜å†³ç­–æ•ˆçŽ‡','user-uuid-001','governance','active',NULL,NULL,0,0,0,'2025-10-01 01:45:31','2025-10-01 01:45:31'),(2,'prop-002','æŠ€æœ¯æž¶æž„å‡çº§ææ¡ˆ','å»ºè®®å‡çº§ç³»ç»ŸæŠ€æœ¯æž¶æž„ï¼Œæé«˜æ€§èƒ½','user-uuid-002','technical','draft',NULL,NULL,0,0,0,'2025-10-01 01:45:31','2025-10-01 01:45:31'),(3,'prop-003','ç¤¾åŒºæ¿€åŠ±è®¡åˆ’ææ¡ˆ','åˆ¶å®šç¤¾åŒºè´¡çŒ®è€…æ¿€åŠ±è®¡åˆ’','user-uuid-003','funding','active',NULL,NULL,0,0,0,'2025-10-01 01:45:31','2025-10-01 01:45:31');
/*!40000 ALTER TABLE `dao_proposals` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dao_rewards`
--

DROP TABLE IF EXISTS `dao_rewards`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dao_rewards` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `recipient_id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `reward_type` enum('contribution','voting','proposal','governance') COLLATE utf8mb4_unicode_ci NOT NULL,
  `amount` decimal(18,8) NOT NULL,
  `currency` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT 'DAO',
  `description` text COLLATE utf8mb4_unicode_ci,
  `status` enum('pending','approved','distributed') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `distributed_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dao_rewards`
--

LOCK TABLES `dao_rewards` WRITE;
/*!40000 ALTER TABLE `dao_rewards` DISABLE KEYS */;
INSERT INTO `dao_rewards` VALUES (1,'user-uuid-001','contribution',100.00000000,'DAO','ç³»ç»Ÿç®¡ç†è´¡çŒ®å¥–åŠ±','distributed','2025-10-01 01:45:31',NULL),(2,'user-uuid-002','proposal',50.00000000,'DAO','æŠ€æœ¯ææ¡ˆå¥–åŠ±','approved','2025-10-01 01:45:31',NULL),(3,'user-uuid-003','governance',75.00000000,'DAO','æ²»ç†å‚ä¸Žå¥–åŠ±','pending','2025-10-01 01:45:31',NULL);
/*!40000 ALTER TABLE `dao_rewards` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dao_votes`
--

DROP TABLE IF EXISTS `dao_votes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dao_votes` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `proposal_id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `voter_id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `vote_choice` enum('for','against','abstain') COLLATE utf8mb4_unicode_ci NOT NULL,
  `voting_power` int NOT NULL,
  `vote_timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_vote` (`proposal_id`,`voter_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dao_votes`
--

LOCK TABLES `dao_votes` WRITE;
/*!40000 ALTER TABLE `dao_votes` DISABLE KEYS */;
INSERT INTO `dao_votes` VALUES (1,'prop-001','user-uuid-001','for',100,'2025-10-01 01:45:31'),(2,'prop-001','user-uuid-002','for',85,'2025-10-01 01:45:31'),(3,'prop-001','user-uuid-003','against',120,'2025-10-01 01:45:31');
/*!40000 ALTER TABLE `dao_votes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `positions`
--

DROP TABLE IF EXISTS `positions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `positions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `category` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `level` enum('entry','junior','mid','senior','lead','executive') COLLATE utf8mb4_unicode_ci DEFAULT 'mid',
  `description` text COLLATE utf8mb4_unicode_ci,
  `requirements` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_title` (`title`),
  KEY `idx_category` (`category`),
  KEY `idx_level` (`level`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `positions`
--

LOCK TABLES `positions` WRITE;
/*!40000 ALTER TABLE `positions` DISABLE KEYS */;
INSERT INTO `positions` VALUES (1,'Go Developer','Development','senior','è´Ÿè´£åŽç«¯æœåŠ¡å¼€å‘',NULL,'2025-10-01 01:45:31','2025-10-01 01:45:31'),(2,'Frontend Developer','Development','mid','è´Ÿè´£å‰ç«¯ç•Œé¢å¼€å‘',NULL,'2025-10-01 01:45:31','2025-10-01 01:45:31'),(3,'DevOps Engineer','Operations','senior','è´Ÿè´£ç³»ç»Ÿè¿ç»´å’Œéƒ¨ç½²',NULL,'2025-10-01 01:45:31','2025-10-01 01:45:31'),(4,'Product Manager','Product','senior','è´Ÿè´£äº§å“è§„åˆ’å’Œè®¾è®¡',NULL,'2025-10-01 01:45:31','2025-10-01 01:45:31'),(5,'Community Manager','Marketing','mid','è´Ÿè´£ç¤¾åŒºè¿è¥å’Œç®¡ç†',NULL,'2025-10-01 01:45:31','2025-10-01 01:45:31');
/*!40000 ALTER TABLE `positions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `resumes`
--

DROP TABLE IF EXISTS `resumes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `resumes` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` bigint unsigned NOT NULL,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `slug` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `summary` text COLLATE utf8mb4_unicode_ci,
  `template_id` bigint unsigned DEFAULT NULL,
  `content` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `content_vector` json DEFAULT NULL,
  `status` enum('draft','published','archived') COLLATE utf8mb4_unicode_ci DEFAULT 'draft',
  `visibility` enum('public','friends','private') COLLATE utf8mb4_unicode_ci DEFAULT 'private',
  `can_comment` tinyint(1) DEFAULT '1',
  `view_count` int unsigned DEFAULT '0',
  `download_count` int unsigned DEFAULT '0',
  `share_count` int unsigned DEFAULT '0',
  `comment_count` int unsigned DEFAULT '0',
  `like_count` int unsigned DEFAULT '0',
  `is_default` tinyint(1) DEFAULT '0',
  `published_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uuid` (`uuid`),
  UNIQUE KEY `slug` (`slug`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_template_id` (`template_id`),
  KEY `idx_status` (`status`),
  KEY `idx_visibility` (`visibility`),
  KEY `idx_slug` (`slug`),
  KEY `idx_published_at` (`published_at`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `resumes_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `resumes`
--

LOCK TABLES `resumes` WRITE;
/*!40000 ALTER TABLE `resumes` DISABLE KEYS */;
INSERT INTO `resumes` VALUES (1,'resume-uuid-001',1,'DAOç³»ç»Ÿç®¡ç†å‘˜ç®€åŽ†','dao-admin-resume','èµ„æ·±ç³»ç»Ÿç®¡ç†å‘˜ï¼Œä¸“æ³¨DAOæŠ€æœ¯',NULL,'# DAOç³»ç»Ÿç®¡ç†å‘˜ç®€åŽ†\n\n## æŠ€èƒ½\n- ç³»ç»Ÿç®¡ç†\n- åŒºå—é“¾æŠ€æœ¯\n- DAOæ²»ç†',NULL,'published','public',1,0,0,0,0,0,0,NULL,'2025-10-01 01:45:31','2025-10-01 01:45:31',NULL),(2,'resume-uuid-002',2,'DAOå¼€å‘è€…ç®€åŽ†','dao-developer-resume','å…¨æ ˆå¼€å‘è€…ï¼Œä¸“æ³¨DAOåº”ç”¨å¼€å‘',NULL,'# DAOå¼€å‘è€…ç®€åŽ†\n\n## æŠ€èƒ½\n- Goå¼€å‘\n- Reactå¼€å‘\n- åŒºå—é“¾åº”ç”¨',NULL,'published','public',1,0,0,0,0,0,0,NULL,'2025-10-01 01:45:31','2025-10-01 01:45:31',NULL),(3,'resume-uuid-003',3,'DAOç¤¾åŒºè¿è¥ç®€åŽ†','dao-community-resume','ç¤¾åŒºè¿è¥ä¸“å®¶ï¼Œä¸“æ³¨DAOç”Ÿæ€å»ºè®¾',NULL,'# DAOç¤¾åŒºè¿è¥ç®€åŽ†\n\n## æŠ€èƒ½\n- ç¤¾åŒºè¿è¥\n- è¥é”€æŽ¨å¹¿\n- ç”Ÿæ€å»ºè®¾',NULL,'draft','private',1,0,0,0,0,0,0,NULL,'2025-10-01 01:45:31','2025-10-01 01:45:31',NULL);
/*!40000 ALTER TABLE `resumes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `skills`
--

DROP TABLE IF EXISTS `skills`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `skills` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `category` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `icon` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_popular` tinyint(1) DEFAULT '0',
  `search_count` int unsigned DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `idx_category` (`category`),
  KEY `idx_is_popular` (`is_popular`),
  KEY `idx_search_count` (`search_count`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `skills`
--

LOCK TABLES `skills` WRITE;
/*!40000 ALTER TABLE `skills` DISABLE KEYS */;
INSERT INTO `skills` VALUES (1,'Go','Programming','Goç¼–ç¨‹è¯­è¨€',NULL,1,0,'2025-10-01 01:45:31','2025-10-01 01:45:31'),(2,'Python','Programming','Pythonç¼–ç¨‹è¯­è¨€',NULL,1,0,'2025-10-01 01:45:31','2025-10-01 01:45:31'),(3,'JavaScript','Programming','JavaScriptç¼–ç¨‹è¯­è¨€',NULL,1,0,'2025-10-01 01:45:31','2025-10-01 01:45:31'),(4,'React','Frontend','Reactå‰ç«¯æ¡†æž¶',NULL,1,0,'2025-10-01 01:45:31','2025-10-01 01:45:31'),(5,'Vue.js','Frontend','Vue.jså‰ç«¯æ¡†æž¶',NULL,1,0,'2025-10-01 01:45:31','2025-10-01 01:45:31'),(6,'MySQL','Database','MySQLæ•°æ®åº“',NULL,1,0,'2025-10-01 01:45:31','2025-10-01 01:45:31'),(7,'PostgreSQL','Database','PostgreSQLæ•°æ®åº“',NULL,1,0,'2025-10-01 01:45:31','2025-10-01 01:45:31'),(8,'Redis','Database','Redisç¼“å­˜æ•°æ®åº“',NULL,1,0,'2025-10-01 01:45:31','2025-10-01 01:45:31'),(9,'Docker','DevOps','Dockerå®¹å™¨æŠ€æœ¯',NULL,1,0,'2025-10-01 01:45:31','2025-10-01 01:45:31'),(10,'Kubernetes','DevOps','Kuberneteså®¹å™¨ç¼–æŽ’',NULL,1,0,'2025-10-01 01:45:31','2025-10-01 01:45:31');
/*!40000 ALTER TABLE `skills` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_profiles`
--

DROP TABLE IF EXISTS `user_profiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_profiles` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `bio` text COLLATE utf8mb4_unicode_ci,
  `location` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `website` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `linkedin_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `github_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `twitter_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `date_of_birth` date DEFAULT NULL,
  `gender` enum('male','female','other','prefer_not_to_say') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `nationality` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `languages` json DEFAULT NULL,
  `skills` json DEFAULT NULL,
  `interests` json DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  CONSTRAINT `user_profiles_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_profiles`
--

LOCK TABLES `user_profiles` WRITE;
/*!40000 ALTER TABLE `user_profiles` DISABLE KEYS */;
INSERT INTO `user_profiles` VALUES (1,1,'DAOç³»ç»Ÿç®¡ç†å‘˜','Beijing, China',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'[\"ä¸­æ–‡\", \"è‹±æ–‡\"]','[\"ç³»ç»Ÿç®¡ç†\", \"åŒºå—é“¾\", \"DAOæ²»ç†\"]',NULL,'2025-10-01 01:45:31','2025-10-01 01:45:31'),(2,2,'DAOç¤¾åŒºæˆå‘˜','Shanghai, China',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'[\"ä¸­æ–‡\", \"è‹±æ–‡\"]','[\"å¼€å‘\", \"è®¾è®¡\", \"äº§å“\"]',NULL,'2025-10-01 01:45:31','2025-10-01 01:45:31'),(3,3,'DAOè´¡çŒ®è€…','Shenzhen, China',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'[\"ä¸­æ–‡\"]','[\"è¥é”€\", \"è¿è¥\", \"ç¤¾åŒº\"]',NULL,'2025-10-01 01:45:31','2025-10-01 01:45:31');
/*!40000 ALTER TABLE `user_profiles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `username` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `first_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `last_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `avatar_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('active','inactive','suspended') COLLATE utf8mb4_unicode_ci DEFAULT 'active',
  `email_verified` tinyint(1) DEFAULT '0',
  `phone_verified` tinyint(1) DEFAULT '0',
  `last_login_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uuid` (`uuid`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `username` (`username`),
  KEY `idx_email` (`email`),
  KEY `idx_username` (`username`),
  KEY `idx_status` (`status`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'user-uuid-001','admin@dao.com','dao_admin','hashed_password_001','DAO','Admin',NULL,NULL,'active',0,0,NULL,'2025-10-01 01:45:31','2025-10-01 01:45:31',NULL),(2,'user-uuid-002','user1@dao.com','dao_user1','hashed_password_002','DAO','User1',NULL,NULL,'active',0,0,NULL,'2025-10-01 01:45:31','2025-10-01 01:45:31',NULL),(3,'user-uuid-003','user2@dao.com','dao_user2','hashed_password_003','DAO','User2',NULL,NULL,'active',0,0,NULL,'2025-10-01 01:45:31','2025-10-01 01:45:31',NULL);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-10-01  1:47:08
