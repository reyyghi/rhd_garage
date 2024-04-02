CREATE TABLE `owned_vehicles` (
	`owner` VARCHAR(60) NOT NULL,
	`plate` varchar(12) NOT NULL,
	`vehicle` longtext,
    `vehicle_name` longtext DEFAULT NULL,
	`type` VARCHAR(20) NOT NULL DEFAULT 'car',
	`job` VARCHAR(20) NULL DEFAULT NULL,
	`stored` INT(1) NOT NULL DEFAULT '0',
    `garage` longtext,
    `fuel` INT(11) NULL DEFAULT 100,
    `engine` FLOAT NULL DEFAULT 1000,
    `body` FLOAT NULL DEFAULT 1000,
    `deformation` longtext,

	PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DELIMITER //
CREATE TRIGGER rhd_garage_update_impound_plate
AFTER UPDATE ON owned_vehicles
FOR EACH ROW
BEGIN
    UPDATE police_impound
    SET plate = NEW.plate
    WHERE plate = OLD.plate;
END;

CREATE TRIGGER rhd_garage_delete_from_impound
AFTER DELETE ON owned_vehicles
FOR EACH ROW
BEGIN
    DELETE FROM police_impound
    WHERE plate = OLD.plate;
END;

CREATE TRIGGER rhd_garage_state_update
AFTER UPDATE ON owned_vehicles
FOR EACH ROW
BEGIN
    IF NEW.stored <> 2 THEN
        DELETE FROM police_impound
        WHERE plate = OLD.plate;
    END IF;
END;
//
DELIMITER ;