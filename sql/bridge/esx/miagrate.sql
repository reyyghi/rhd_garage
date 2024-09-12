INSERT INTO user_vehicles (identifier, owner_name, model, plate, garage, fuel, engine, body, properties, state)
    SELECT 
            o.owner AS identifier,
            CONCAT(u.firstname, ' ', u.lastname) AS owner_name,
            JSON_UNQUOTE(JSON_EXTRACT(o.vehicle, '$.model')) AS model, 
            o.plate AS plate, 
            o.parking AS garage, 
            JSON_UNQUOTE(JSON_EXTRACT(o.vehicle, '$.fuelLevel')) AS fuel, 
            JSON_UNQUOTE(JSON_EXTRACT(o.vehicle, '$.engineHealth')) AS engine, 
            JSON_UNQUOTE(JSON_EXTRACT(o.vehicle, '$.bodyHealth')) AS body, 
            o.vehicle AS properties,
            o.stored AS state
        FROM owned_vehicles o
    JOIN users u ON o.owner = u.identifier
WHERE o.plate NOT IN (SELECT plate FROM user_vehicles);
