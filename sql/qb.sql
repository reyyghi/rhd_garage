ALTER TABLE player_vehicles ADD COLUMN vehicle_name LONGTEXT NULL AFTER vehicle;
ALTER TABLE player_vehicles ADD COLUMN deformation LONGTEXT NULL AFTER garage;

DELIMITER //
CREATE TRIGGER rhd_garage_update_impound_plate
AFTER UPDATE ON player_vehicles
FOR EACH ROW
BEGIN
    UPDATE police_impound
    SET plate = NEW.plate
    WHERE plate = OLD.plate;
END;

CREATE TRIGGER rhd_garage_delete_from_impound
AFTER DELETE ON player_vehicles
FOR EACH ROW
BEGIN
    DELETE FROM police_impound
    WHERE plate = OLD.plate;
END;

CREATE TRIGGER rhd_garage_state_update
AFTER UPDATE ON player_vehicles
FOR EACH ROW
BEGIN
    IF NEW.state <> 2 THEN
        DELETE FROM police_impound
        WHERE plate = OLD.plate;
    END IF;
END;
//
DELIMITER ;