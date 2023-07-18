# Reyghita Hafizh Firmanda

# Note 
- Jika anda menggunakan framework ESX, anda merubah database owned_vehicles anda seperti ini:
| CREATE TABLE IF NOT EXISTS `owned_vehicles` (
  `owner` varchar(60) NOT NULL,
  `plate` varchar(50) NOT NULL DEFAULT '',
  `vehicle` longtext DEFAULT NULL,
  `type` varchar(20) NOT NULL DEFAULT 'car',
  `job` varchar(20) DEFAULT NULL,
  `stored` bigint(20) NOT NULL DEFAULT 0,
  `garage` longtext DEFAULT NULL,
  `glovebox` longtext DEFAULT NULL,
  `trunk` longtext DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;|
|----|
