-- MySQL dump 10.13  Distrib 8.0.46, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: lab_agent
-- ------------------------------------------------------
-- Server version	8.0.46

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
-- Table structure for table `equipments`
--

DROP TABLE IF EXISTS `equipments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `equipments` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `lab_id` int NOT NULL COMMENT '所属实验室',
  `name` varchar(50) COLLATE utf8mb3_unicode_ci NOT NULL COMMENT '设备名称',
  `description` varchar(500) COLLATE utf8mb3_unicode_ci DEFAULT NULL COMMENT '说明',
  `img` varchar(200) COLLATE utf8mb3_unicode_ci DEFAULT NULL COMMENT '图片',
  `spec` varchar(100) COLLATE utf8mb3_unicode_ci DEFAULT NULL COMMENT '型号规格',
  `quantity` int NOT NULL COMMENT '数量',
  `status` int NOT NULL COMMENT '状态：0-维修，1-正常',
  `create_time` datetime NOT NULL COMMENT '创建时间',
  `update_time` datetime NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `lab_id` (`lab_id`),
  CONSTRAINT `equipments_ibfk_1` FOREIGN KEY (`lab_id`) REFERENCES `labs` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=33 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci COMMENT='实验室设备表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `equipments`
--

LOCK TABLES `equipments` WRITE;
/*!40000 ALTER TABLE `equipments` DISABLE KEYS */;
INSERT INTO `equipments` VALUES (1,1,'RTX4090','深度学习训练显卡',NULL,'24G 显存',2,1,'2026-10-09 15:50:16','2026-10-09 15:50:16'),(2,1,'开发主机','学生上机编程',NULL,'i7 / 32G / 1T SSD',20,1,'2026-10-09 15:50:16','2026-10-09 15:50:16'),(3,1,'投影仪','讲课演示',NULL,'1080P',1,1,'2026-10-09 15:50:16','2026-10-09 15:50:16'),(4,1,'千兆交换机','机房组网',NULL,'24 口',1,1,'2026-10-09 15:50:16','2026-10-09 15:50:16'),(5,2,'示波器','电路波形观测',NULL,'100MHz 双通道',8,1,'2026-10-09 15:50:16','2026-10-09 15:50:16'),(6,2,'信号发生器','信号源实验',NULL,'DDS 60MHz',6,1,'2026-10-09 15:50:16','2026-10-09 15:50:16'),(7,2,'数字万用表','电子测量',NULL,'4 位半',10,0,'2026-10-09 15:50:16','2026-10-09 15:50:16'),(8,2,'直流稳压电源','电路供电',NULL,'30V 5A',8,1,'2026-10-09 15:50:16','2026-10-09 15:50:16'),(9,3,'光学实验台','几何光学实验',NULL,'1.2m 隔振台',4,1,'2026-10-09 15:50:16','2026-10-09 15:50:16'),(10,3,'氦氖激光器','干涉衍射实验',NULL,'632.8nm',2,1,'2026-10-09 15:50:16','2026-10-09 15:50:16'),(11,3,'力学轨道','牛顿定律实验',NULL,'气垫导轨 1.5m',3,1,'2026-10-09 15:50:16','2026-10-09 15:50:16'),(12,3,'分光计','光谱测量',NULL,'0.1° 精度',4,1,'2026-10-09 15:50:16','2026-10-09 15:50:16'),(13,4,'电子天平','试剂称量',NULL,'0.1mg',6,1,'2026-10-09 15:50:16','2026-10-09 15:50:16'),(14,4,'离心机','样品分离',NULL,'4000rpm',2,1,'2026-10-09 15:50:16','2026-10-09 15:50:16'),(15,4,'通风橱','有机实验',NULL,'1.5m',3,1,'2026-10-09 15:50:16','2026-10-09 15:50:16'),(16,4,'pH 计','溶液酸碱度',NULL,'0.01pH',4,1,'2026-10-09 15:50:16','2026-10-09 15:50:16'),(17,5,'显微镜','细胞观察',NULL,'1000x 光学',10,1,'2026-10-09 15:50:16','2026-10-09 15:50:16'),(18,5,'恒温培养箱','菌种培养',NULL,'室温 ~ 60℃',2,1,'2026-10-09 15:50:16','2026-10-09 15:50:16'),(19,5,'移液器','微量取样',NULL,'0.5-10μL',20,1,'2026-10-09 15:50:16','2026-10-09 15:50:16'),(20,5,'PCR 仪','基因扩增',NULL,'96 孔',1,0,'2026-10-09 15:50:16','2026-10-09 15:50:16'),(21,6,'GPU 训练服务器','大模型微调',NULL,'2 * RTX4090 / 128G',1,1,'2026-10-09 15:50:16','2026-10-09 15:50:16'),(22,6,'RTX4090','深度学习训练显卡',NULL,'24G 显存',4,1,'2026-10-09 15:50:16','2026-10-09 15:50:16'),(23,6,'深度相机','视觉数据采集',NULL,'RealSense D435i',3,1,'2026-10-09 15:50:16','2026-10-09 15:50:16'),(24,6,'标注工作站','数据集标注',NULL,'i9 / 64G',6,1,'2026-10-09 15:50:16','2026-10-09 15:50:16'),(25,7,'UR5 机械臂','工业机械臂教学',NULL,'负载 5kg',2,1,'2026-10-09 15:50:16','2026-10-09 15:50:16'),(26,7,'Livox 激光雷达','SLAM 建图',NULL,'Mid-360',3,1,'2026-10-09 15:50:16','2026-10-09 15:50:16'),(27,7,'RealSense 深度相机','视觉抓取',NULL,'D435i',4,1,'2026-10-09 15:50:16','2026-10-09 15:50:16'),(28,7,'Jetson Orin','边缘计算',NULL,'32G',4,1,'2026-10-09 15:50:16','2026-10-09 15:50:16'),(29,8,'开发主机','项目实训',NULL,'i7 / 32G / 1T SSD',40,1,'2026-10-09 15:50:16','2026-10-09 15:50:16'),(30,8,'显示器','双屏开发',NULL,'27 寸 2K',40,1,'2026-10-09 15:50:16','2026-10-09 15:50:16'),(31,8,'投影仪','答辩演示',NULL,'1080P',2,1,'2026-10-09 15:50:16','2026-10-09 15:50:16'),(32,8,'代码服务器','Git 与 CI',NULL,'8 核 / 32G',1,1,'2026-10-09 15:50:16','2026-10-09 15:50:16');
/*!40000 ALTER TABLE `equipments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `labs`
--

DROP TABLE IF EXISTS `labs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `labs` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `name` varchar(50) COLLATE utf8mb3_unicode_ci NOT NULL COMMENT '名称',
  `description` varchar(500) COLLATE utf8mb3_unicode_ci DEFAULT NULL COMMENT '简介',
  `img` varchar(100) COLLATE utf8mb3_unicode_ci DEFAULT NULL COMMENT '封面',
  `location` varchar(100) COLLATE utf8mb3_unicode_ci DEFAULT NULL COMMENT '位置',
  `capacity` int NOT NULL COMMENT '容量',
  `open_time` varchar(20) COLLATE utf8mb3_unicode_ci DEFAULT NULL COMMENT '开放开始时间',
  `close_time` varchar(20) COLLATE utf8mb3_unicode_ci DEFAULT NULL COMMENT '开放结束时间',
  `status` int NOT NULL COMMENT '状态，0-关闭，1-开放',
  `create_time` datetime NOT NULL COMMENT '创建时间',
  `update_time` datetime NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci COMMENT='实验室信息';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `labs`
--

LOCK TABLES `labs` WRITE;
/*!40000 ALTER TABLE `labs` DISABLE KEYS */;
INSERT INTO `labs` VALUES (1,'物理实验室','物理实验室','/uploads/1792055367259_a454e5a7.jpg','综合实验楼101',20,'08:00','18:00',1,'2026-10-09 15:50:06','2026-10-15 17:09:28'),(2,'电子实验室','电子实验室','/uploads/1792055363630_b6de5a51.jpg','综合实验楼102',20,'08:00','18:00',1,'2026-10-09 15:50:06','2026-10-15 17:09:24'),(3,'计算机实验室','计算机实验室','/uploads/1792055359730_0d669e4c.jpg','综合实验楼201',20,'09:00','18:00',1,'2026-10-09 15:50:06','2026-10-15 17:09:20'),(4,'化学实验室','化学实验室','/uploads/1792055356061_89ed270b.jpg','综合实验楼301',20,'08:00','18:00',1,'2026-10-09 15:50:06','2026-10-15 17:09:17'),(5,'生物实验室','生物实验室','/uploads/1792055352247_ea0a08b8.jpg','综合实验楼302',20,'08:00','18:00',1,'2026-10-09 15:50:06','2026-10-15 17:09:13'),(6,'人工智能实验室','人工智能实验室','/uploads/1792055347801_5e372db0.jpg','综合实验楼401',30,'08:00','18:00',1,'2026-10-09 15:50:06','2026-10-15 17:09:08'),(7,'机器人实验室','机器人实验室','/uploads/1792055342962_d0396e0f.jpg','综合实验楼402',20,'09:00','18:00',1,'2026-10-09 15:50:06','2026-10-15 17:09:04'),(8,'软件工程实验室','软件工程实验室','/uploads/1792055337866_e5560799.jpg','综合实验楼501',40,'08:00','20:00',1,'2026-10-09 15:50:06','2026-10-15 17:08:59');
/*!40000 ALTER TABLE `labs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `reservations`
--

DROP TABLE IF EXISTS `reservations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reservations` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` int NOT NULL COMMENT '预约人',
  `lab_id` int NOT NULL COMMENT '实验室',
  `equipment_id` int DEFAULT NULL COMMENT '设备，空表示预约实验室',
  `date` varchar(20) COLLATE utf8mb3_unicode_ci NOT NULL COMMENT '预约日期',
  `start_time` varchar(20) COLLATE utf8mb3_unicode_ci NOT NULL COMMENT '开始时间',
  `end_time` varchar(20) COLLATE utf8mb3_unicode_ci NOT NULL COMMENT '结束时间',
  `remark` varchar(255) COLLATE utf8mb3_unicode_ci DEFAULT NULL COMMENT '备注',
  `status` int NOT NULL COMMENT '预约状态 0待审核，1已通过，2已拒绝，3已取消',
  `create_time` datetime NOT NULL COMMENT '创建时间',
  `update_time` datetime NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `lab_id` (`lab_id`),
  KEY `equipment_id` (`equipment_id`),
  CONSTRAINT `reservations_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `reservations_ibfk_2` FOREIGN KEY (`lab_id`) REFERENCES `labs` (`id`),
  CONSTRAINT `reservations_ibfk_3` FOREIGN KEY (`equipment_id`) REFERENCES `equipments` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci COMMENT='预约信息';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reservations`
--

LOCK TABLES `reservations` WRITE;
/*!40000 ALTER TABLE `reservations` DISABLE KEYS */;
INSERT INTO `reservations` VALUES (1,3,8,32,'2026-10-10','09:00','12:00','',3,'2026-10-09 23:16:21','2026-10-11 00:04:25'),(2,3,8,32,'2026-10-10','12:00','13:00','',3,'2026-10-09 23:17:03','2026-10-11 00:04:23'),(3,3,8,32,'2026-10-13','09:00','18:00','',1,'2026-10-11 00:06:05','2026-10-11 00:07:43'),(4,3,8,NULL,'2026-10-11','10:09','10:11','',3,'2026-10-11 10:08:30','2026-10-11 10:11:08'),(5,3,2,5,'2026-10-15','09:00','11:00',NULL,3,'2026-10-14 00:03:31','2026-10-14 20:23:56'),(6,3,2,NULL,'2026-10-15','08:00','09:00',NULL,3,'2026-10-14 00:08:50','2026-10-14 20:23:59'),(7,3,3,12,'2026-10-15','14:00','16:00',NULL,1,'2026-10-14 20:23:49','2026-10-14 20:33:01'),(8,1,3,NULL,'2026-10-15','14:00','16:00',NULL,2,'2026-10-14 20:32:44','2026-10-14 20:32:54'),(9,3,3,NULL,'2026-10-16','09:00','11:00',NULL,3,'2026-10-15 00:37:28','2026-10-15 10:29:33'),(10,3,3,NULL,'2026-10-16','16:00','17:00',NULL,3,'2026-10-15 10:00:55','2026-10-15 10:29:32'),(11,3,3,NULL,'2026-10-15','16:00','17:00',NULL,3,'2026-10-15 10:01:33','2026-10-15 10:02:39'),(12,3,3,NULL,'2026-10-15','14:00','15:00',NULL,3,'2026-10-15 10:03:13','2026-10-15 10:29:30'),(13,3,3,NULL,'2026-10-15','12:00','13:00',NULL,3,'2026-10-15 10:05:37','2026-10-15 10:29:28'),(14,3,5,NULL,'2026-10-15','15:00','16:00',NULL,3,'2026-10-15 10:29:20','2026-10-15 10:43:25'),(15,3,3,NULL,'2026-10-15','14:00','15:00',NULL,3,'2026-10-15 10:42:29','2026-10-15 13:41:13'),(16,3,5,NULL,'2026-10-16','13:00','15:00',NULL,3,'2026-10-15 11:10:03','2026-10-15 13:41:12'),(17,3,2,NULL,'2026-10-16','14:00','16:00',NULL,3,'2026-10-15 11:54:30','2026-10-15 13:41:11'),(18,3,5,NULL,'2026-10-15','14:00','16:00',NULL,3,'2026-10-15 12:08:29','2026-10-15 13:41:09'),(19,3,3,NULL,'2026-10-16','11:00','13:00',NULL,3,'2026-10-15 13:45:33','2026-10-15 14:52:16'),(20,3,3,NULL,'2026-10-15','15:00','16:00',NULL,3,'2026-10-15 14:26:05','2026-10-15 14:52:14'),(21,3,5,NULL,'2026-10-16','14:00','15:00',NULL,3,'2026-10-15 14:30:31','2026-10-15 14:52:15'),(22,3,5,NULL,'2026-10-16','09:00','11:00',NULL,0,'2026-10-15 14:51:41','2026-10-15 14:51:41');
/*!40000 ALTER TABLE `reservations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `username` varchar(50) COLLATE utf8mb3_unicode_ci NOT NULL COMMENT '账号',
  `password` varchar(255) COLLATE utf8mb3_unicode_ci NOT NULL COMMENT '密码',
  `name` varchar(50) COLLATE utf8mb3_unicode_ci NOT NULL COMMENT '名称',
  `role` varchar(50) COLLATE utf8mb3_unicode_ci NOT NULL COMMENT '角色：student-学生，admin-管理员',
  `email` varchar(50) COLLATE utf8mb3_unicode_ci DEFAULT NULL COMMENT '邮箱',
  `phone` varchar(50) COLLATE utf8mb3_unicode_ci DEFAULT NULL COMMENT '手机号',
  `avatar` varchar(50) COLLATE utf8mb3_unicode_ci DEFAULT NULL COMMENT '头像',
  `status` int NOT NULL COMMENT '状态：0-禁用，1-正常',
  `create_time` datetime NOT NULL COMMENT '创建时间',
  `update_time` datetime NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci COMMENT='用户信息表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'admin','$2a$10$wRrMag9x2f1qw0w3AhDnu.yHX3hx5vOssc3zhP55.qWGIRBhEd.i.','管理员','admin',NULL,NULL,NULL,1,'2026-10-06 16:56:35','2026-10-06 16:56:37'),(2,'bbb','$2b$12$NipUXf4SioiD83UgTdSIQOMF6laSCis3wrukLp6YMhdYJk6.ibS/2','bbb','student',NULL,NULL,NULL,1,'2026-10-06 16:53:04','2026-10-06 16:53:04'),(3,'aaa','$2b$12$Bi9Qn4HAihg1UB.xw9RNHeYbKB5/6kNDrwlCXIKMr4X28Uvsy0ST6','zsy','student','2503347001@qq.com','18923496608','/uploads/1791350082611_17f7100f.png',1,'2026-10-05 15:09:27','2026-10-07 18:00:42');
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

-- Dump completed on 2026-10-15 17:55:10
