INSERT INTO user_vehicles (identifier, owner_name, model, plate, fakeplate, garage, fuel, engine, body, state, properties)
    SELECT 
            pv.citizenid AS identifier,
            CONCAT(JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')), ' ', JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname'))) AS owner_name,
            pv.hash AS model,
            pv.plate AS plate,
            pv.fakeplate AS fakeplate,
            pv.garage AS garage, 
            pv.fuel AS fuel,
            pv.engine AS engine,
            pv.body AS body,
            pv.state AS state,
            pv.mods AS properties
        FROM player_vehicles pv
    JOIN players p ON pv.citizenid = p.citizenid
WHERE pv.plate NOT IN (SELECT plate FROM user_vehicles);
