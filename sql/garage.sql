CREATE TABLE IF NOT EXISTS `user_vehicles` (
  `identifier` varchar(46) DEFAULT NULL,
  `owner_name` longtext DEFAULT NULL,
  `label` longtext DEFAULT NULL,
  `model` varchar(50) NOT NULL DEFAULT '',
  `plate` longtext NOT NULL,
  `fakeplate` longtext DEFAULT NULL,
  `garage` longtext DEFAULT 'Motel Parking',
  `state` int(11) DEFAULT 0,
  `fuel` float DEFAULT 100,
  `engine` float DEFAULT 1000,
  `body` float DEFAULT 1000,
  `properties` longtext NOT NULL,
  `deformation` longtext DEFAULT NULL,
  UNIQUE KEY `Index 2` (`plate`(100)),
  KEY `Index 1` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;