Config = {}

-- Configuration settings
Config.FuelScript = 'rhd_fuel' --- Specifies the fuel script to use: 'rhd_fuel', 'ox_fuel', 'LegacyFuel', 'ps-fuel', 'cdn-fuel'
Config.changeNamePrice = 15000 --- Price for changing the name of the vehicle in the garage
Config.SpawnInVehicle = true --- Set to true if the player should immediately enter the vehicle when taken out of the garage

Config.interact = {
    target = 'interact',--- Specifies the interactions system to use: 'ox', 'qb', 'interact (https://github.com/darktrovx/interact)'
    radialMenu = 'ox' --- Specifies the radial menu system to use: 'ox', 'qb', 'rhd'
}

-- Additional settings (Requires ox_target or qb-target resource)
Config.UseJobVechileShop = true --- Set to false if you do not want to use the work vehicle shop system from rhd
Config.UsePoliceImpound = true --- Set to false if you do not want to use the police impound system from rhd

Config.InDevelopment = true --- Set to false when you have finished setting up this garage

Config.ChangeVehicleName = {
    enable = true,
    price = 10
}

-- Vehicle transfer settings
Config.TransferVehicle = {
    enable = true,  --- Enable or disable vehicle transfer functionality
    price = 100     --- Price for transferring a vehicle
}

-- Garage swap settings
Config.SwapGarage = {
    enable = true,  --- Enable or disable garage swapping functionality
    price = 500     --- Price for swapping garages
}
