DELIMITER //
CREATE TRIGGER auto_added_to_user_vehicles
AFTER INSERT ON player_vehicles
FOR EACH ROW
BEGIN
    INSERT INTO user_vehicles (
        identifier,
        owner_name,
        model,
        plate,
        fakeplate,
        garage,
        fuel,
        engine,
        body,
        properties,
        state
    )
    SELECT 
        NEW.citizenid AS identifier,
        CONCAT(JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')), ' ', JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname'))) AS owner_name,
        NEW.hash AS model, 
        NEW.plate AS plate,
        NEW.fakeplate AS fakeplate,
        NEW.garage AS garage, 
        NEW.fuel AS fuel, 
        NEW.engine AS engine, 
        NEW.body AS body, 
        NEW.mods AS properties,
        NEW.state AS state
    FROM player_vehicles pv JOIN players p ON NEW.citizenid = p.citizenid WHERE pv.plate = NEW.plate;
END//
DELIMITER ;