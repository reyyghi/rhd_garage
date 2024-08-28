DELIMITER //
CREATE TRIGGER update_user_vehicles
AFTER UPDATE ON owned_vehicles
FOR EACH ROW
BEGIN
    IF OLD.owner != NEW.owner THEN
        UPDATE user_vehicles
        JOIN users ON NEW.owner = users.identifier SET 
            user_vehicles.identifier = NEW.owner,
            user_vehicles.owner_name = CONCAT(users.firstname, ' ', users.lastname)
        WHERE user_vehicles.plate = OLD.plate;
    END IF;

    IF OLD.plate != NEW.plate THEN
        UPDATE user_vehicles SET 
            user_vehicles.plate = NEW.plate
        WHERE user_vehicles.plate = OLD.plate;
    END IF;

    IF OLD.vehicle != NEW.vehicle THEN
        UPDATE user_vehicles SET 
            user_vehicles.fuel = JSON_UNQUOTE(JSON_EXTRACT(NEW.vehicle, '$.fuelLevel')),
            user_vehicles.engine = JSON_UNQUOTE(JSON_EXTRACT(NEW.vehicle, '$.engineHealth')),
            user_vehicles.body = JSON_UNQUOTE(JSON_EXTRACT(NEW.vehicle, '$.bodyHealth')),
            user_vehicles.properties = NEW.vehicle
        WHERE user_vehicles.plate = OLD.plate;
    END IF;

    IF OLD.parking != NEW.parking THEN
        UPDATE user_vehicles SET 
            user_vehicles.garage = NEW.parking
        WHERE user_vehicles.plate = OLD.plate;
    END IF;

    IF OLD.stored != NEW.stored THEN
        UPDATE user_vehicles SET 
            user_vehicles.state = NEW.stored
        WHERE user_vehicles.plate = OLD.plate;
    END IF;
END //
DELIMITER ;
