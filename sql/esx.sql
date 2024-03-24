ALTER TABLE owned_vehicles CHANGE COLUMN stored stored INT(11) NOT NULL DEFAULT 0;
ALTER TABLE owned_vehicles ADD COLUMN garage LONGTEXT NULL AFTER stored;
ALTER TABLE owned_vehicles ADD COLUMN deformation LONGTEXT NULL AFTER garage;

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
//
DELIMITER ;