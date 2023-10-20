lib.addCommand(locale("rhd_garage:command.admin.CreateGarage"), {
    help = locale("rhd_garage:command.admin.CreateGarageHelp"),
    restricted = 'group.admin'
}, function(source, args, raw)
    TriggerClientEvent("rhd_garage:client:createGarage", source)
end)
lib.addCommand(locale("rhd_garage:command.admin.listgarage"), {
    help = locale("rhd_garage:command.admin.listgarageHelp"),
    restricted = 'group.admin'
}, function(source, args, raw)
    TriggerClientEvent("rhd_garage:client:createGarage", source)
end)