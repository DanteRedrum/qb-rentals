local QBCore = exports['qb-core']:GetCoreObject()
local RentedVehicles = {}

RegisterServerEvent('qb-rentals:server:SetVehicleRented')
AddEventHandler('qb-rentals:server:SetVehicleRented', function(plate, bool, vehicleData)
    local src = source
    local ply = QBCore.Functions.GetPlayer(src)
    local plyCid = ply.PlayerData.citizenid

    if bool then
        if ply.PlayerData.money.cash >= vehicleData.price then
            ply.Functions.RemoveMoney('cash', vehicleData.price, "vehicle-rentail-bail") 
            RentedVehicles[plyCid] = plate
            TriggerClientEvent('QBCore:Notify', src, 'You have paid the deposit of '..vehicleData.price..' in cash.', 'success', 3500)
            TriggerClientEvent('qb-rentals:server:SpawnRentedVehicle', src, plate, vehicleData) 
        elseif ply.PlayerData.money.bank >= vehicleData.price then 
            ply.Functions.RemoveMoney('bank', vehicleData.price, "vehicle-rentail-bail") 
            RentedVehicles[plyCid] = plate
            TriggerClientEvent('QBCore:Notify', src, 'You have paid the deposit of '..vehicleData.price..' paid through the bank.', 'success', 3500)
            TriggerClientEvent('qb-rentals:server:SpawnRentedVehicle', src, plate, vehicleData) 
        else
            TriggerClientEvent('QBCore:Notify', src, 'You do not have enough money.', 'error', 3500)
        end
        return
    end
    TriggerClientEvent('QBCore:Notify', src, 'You have received your deposit of '..vehicleData.price..' Back.', 'success', 3500)
    ply.Functions.AddMoney('cash', vehicleData.price, "vehicle-rentail-bail")
    RentedVehicles[plyCid] = nil
end)




