DELIMITER //
CREATE TRIGGER update_user_vehicles
AFTER UPDATE ON player_vehicles
FOR EACH ROW
BEGIN
    IF OLD.citizenid != NEW.citizenid THEN
        UPDATE user_vehicles
        JOIN players ON NEW.citizenid = players.identifier SET 
            user_vehicles.identifier = NEW.citizenid,
            user_vehicles.owner_name = CONCAT(JSON_UNQUOTE(JSON_EXTRACT(players.charinfo, '$.firstname')), ' ', JSON_UNQUOTE(JSON_EXTRACT(players.charinfo, '$.lastname')))
        WHERE user_vehicles.plate = OLD.plate;
    END IF;

    IF OLD.plate != NEW.plate THEN
        UPDATE user_vehicles SET 
            user_vehicles.plate = NEW.plate
        WHERE user_vehicles.plate = OLD.plate;
    END IF;

    IF OLD.mods != NEW.mods THEN
        UPDATE user_vehicles SET
            user_vehicles.properties = NEW.mods
        WHERE user_vehicles.plate = OLD.plate;
    END IF;

    IF OLD.fuel != NEW.fuel THEN
        UPDATE user_vehicles SET
            user_vehicles.fuel = NEW.fuel
        WHERE user_vehicles.plate = OLD.plate;
    END IF;

    IF OLD.engine != NEW.engine THEN
        UPDATE user_vehicles SET
            user_vehicles.engine = NEW.engine
        WHERE user_vehicles.plate = OLD.plate;
    END IF;

    IF OLD.body != NEW.body THEN
        UPDATE user_vehicles SET
            user_vehicles.body = NEW.body
        WHERE user_vehicles.plate = OLD.plate;
    END IF;

    IF OLD.garage != NEW.garage THEN
        UPDATE user_vehicles SET 
            user_vehicles.garage = NEW.garage
        WHERE user_vehicles.plate = OLD.plate;
    END IF;

    IF OLD.state != NEW.state THEN
        UPDATE user_vehicles SET 
            user_vehicles.state = NEW.state
        WHERE user_vehicles.plate = OLD.plate;
    END IF;
END //
DELIMITER ;
