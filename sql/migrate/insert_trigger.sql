DELIMITER //
CREATE TRIGGER auto_added_to_user_vehicles
AFTER INSERT ON owned_vehicles
FOR EACH ROW
BEGIN
    INSERT INTO user_vehicles (
        identifier,
        owner_name,
        model,
        plate,
        garage,
        fuel,
        engine,
        body,
        properties,
        state
    )
    SELECT 
        NEW.owner AS identifier,
        CONCAT(u.firstname, ' ', u.lastname) AS owner_name,
        JSON_UNQUOTE(JSON_EXTRACT(NEW.vehicle, '$.model')) AS model, 
        NEW.plate AS plate, 
        NEW.parking AS garage, 
        JSON_UNQUOTE(JSON_EXTRACT(NEW.vehicle, '$.fuelLevel')) AS fuel, 
        JSON_UNQUOTE(JSON_EXTRACT(NEW.vehicle, '$.engineHealth')) AS engine, 
        JSON_UNQUOTE(JSON_EXTRACT(NEW.vehicle, '$.bodyHealth')) AS body, 
        NEW.vehicle AS properties,
        NEW.stored AS state
    FROM owned_vehicles o JOIN users u ON NEW.owner = u.identifier WHERE o.plate = NEW.plate;
END//
DELIMITER ;