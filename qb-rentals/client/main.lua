QBCore = exports['qb-core']:GetCoreObject()

local isLoggedIn = false
local RentedVehiclePlate = nil
local CurrentRentalPoint = nil
local RentedVehicleData = nil

RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    isLoggedIn = true
end)

function DrawText3Ds(x, y, z, text)
	SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

Citizen.CreateThread(function()
    while true do
        local inRange = false
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        
        if isLoggedIn then
            for k, v in pairs(Config.RentalPoints) do
                local dist = GetDistanceBetweenCoords(pos.x, pos.y, pos.z, Config.RentalPoints[k]["coords"][1]["x"], Config.RentalPoints[k]["coords"][1]["y"], Config.RentalPoints[k]["coords"][1]["z"])

                if dist < 30 then
                    inRange = true
                    DrawMarker(2, Config.RentalPoints[k]["coords"][1]["x"], Config.RentalPoints[k]["coords"][1]["y"], Config.RentalPoints[k]["coords"][1]["z"], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.2, 155, 22, 22, 155, 0, 0, 0, 1, 0, 0, 0)

                    if dist < 1 then
                        DrawText3Ds(Config.RentalPoints[k]["coords"][1]["x"], Config.RentalPoints[k]["coords"][1]["y"], Config.RentalPoints[k]["coords"][1]["z"] + 0.35, '~g~E~w~ - To rent vehicle')
                        if IsControlJustPressed(0, 38) then
                            RentalMenu()
                            Menu.hidden = not Menu.hidden
                            CurrentRentalPoint = k
                        end
                        Menu.renderGUI()
                    end

                    if dist > 1.5 then
                        CloseMenu()
                    end
                end
            end

            for k, v in pairs(Config.DeliveryPoints) do
                local dist = GetDistanceBetweenCoords(pos.x, pos.y, pos.z, Config.DeliveryPoints[k]["coords"]["x"], Config.DeliveryPoints[k]["coords"]["y"], Config.DeliveryPoints[k]["coords"]["z"])

                if dist < 30 then
                    inRange = true
                    DrawMarker(2, Config.DeliveryPoints[k]["coords"]["x"], Config.DeliveryPoints[k]["coords"]["y"], Config.DeliveryPoints[k]["coords"]["z"], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.6, 0.6, 0.4, 155, 22, 22, 255, 0, 0, 0, 1, 0, 0, 0)

                    if dist < 1 then
                        DrawText3Ds(Config.DeliveryPoints[k]["coords"]["x"], Config.DeliveryPoints[k]["coords"]["y"], Config.DeliveryPoints[k]["coords"]["z"] + 0.35, '~g~E~w~ - Return the vehicle')
                        if IsControlJustPressed(0, 38) then
                            ReturnVehicle()
                            Menu.hidden = not Menu.hidden
                            CurrentRentalPoint = k
                        end
                        Menu.renderGUI()
                    end

                    if dist > 1.5 then
                        CloseMenu()
                    end
                end
            end
        end
      
        if not inRange then
            Citizen.Wait(1500)
        end

        Citizen.Wait(3)
    end
end)

Citizen.CreateThread(function()
    for k, v in pairs(Config.RentalPoints) do
        RentalPoints = AddBlipForCoord(v["coords"][1]["x"], v["coords"][1]["y"], v["coords"][1]["z"])

        SetBlipSprite (RentalPoints, 372)
        SetBlipDisplay(RentalPoints, 4)
        SetBlipScale  (RentalPoints, 0.65)
        SetBlipAsShortRange(RentalPoints, true)
        SetBlipColour(RentalPoints, 3)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName("Jet Ski Rental - Pick up ")
        EndTextCommandSetBlipName(RentalPoints)
    end

    for k, v in pairs(Config.DeliveryPoints) do
        DeliveryPoints = AddBlipForCoord(v["coords"]["x"], v["coords"]["y"], v["coords"]["z"])

        SetBlipSprite (DeliveryPoints, 379)
        SetBlipDisplay(DeliveryPoints, 4)
        SetBlipScale  (DeliveryPoints, 0.65)
        SetBlipAsShortRange(DeliveryPoints, true)
        SetBlipColour(DeliveryPoints, 3)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName("Jet Ski Rental - Drop off")
        EndTextCommandSetBlipName(DeliveryPoints)
    end
end)

RentVehicleMenu = function()
    ClearMenu()
    for k, v in pairs(Config.RentalVehicles) do
        Menu.addButton(Config.RentalVehicles[k]["label"].." - Deposit Costs: €"..Config.RentalVehicles[k]["price"], "RentVehicle", k)
    end
    Menu.addButton("Terug", "RentalMenu", nil) 
end

RentVehicle = function(selectedVehicle)
    local ped = PlayerPedId()

    if IsPedInAnyVehicle(ped) then
        QBCore.Functions.Notify('this can only when not in a vehicle..', 'error')
        return
    end

    local vehiclePlate = "QBR"..math.random(1, 100)
    TriggerServerEvent('qb-rentals:server:SetVehicleRented', vehiclePlate, true, Config.RentalVehicles[selectedVehicle])

    RentedVehicleData = selectedVehicle
end

RegisterNetEvent('qb-rentals:server:SpawnRentedVehicle')
AddEventHandler('qb-rentals:server:SpawnRentedVehicle', function(vehiclePlate, vehicleData)
    local ped = PlayerPedId()
    local coords = {
        x = Config.RentalPoints[CurrentRentalPoint]["coords"][2]["x"],
        y = Config.RentalPoints[CurrentRentalPoint]["coords"][2]["y"],
        z = Config.RentalPoints[CurrentRentalPoint]["coords"][2]["z"],
    }

    local isnetworked = isnetworked ~= nil and isnetworked or true

    local model = GetHashKey(vehicleData["model"])

    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(10)
    end

    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, coords.a, isnetworked, false)
    local netid = NetworkGetNetworkIdFromEntity(veh)

    SetVehicleHasBeenOwnedByPlayer(vehicle,  true)
    SetNetworkIdCanMigrate(netid, true)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehRadioStation(veh, "OFF")

    SetVehicleNumberPlateText(veh, vehiclePlate)
    TaskWarpPedIntoVehicle(ped, veh, -1)
    exports['LegacyFuel']:SetFuel(veh, 100)
    SetVehicleEngineOn(veh, true, true)
    RentedVehiclePlate = vehiclePlate
    TriggerEvent("vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(veh))

    SetModelAsNoLongerNeeded(model)
    RentalMenu()
end)

ReturnVehicle = function()
    if RentedVehiclePlate ~= nil then
        Menu.addButton("Confirm", "AcceptReturn", nil)
        Menu.addButton("Back", "RentalMenu", nil) 
        return
    end
    QBCore.Functions.Notify('You do not have a deposit open..', 'error')
end

AcceptReturn = function()
    local Ped = PlayerPedId()
    local CurrentVehicle = GetVehiclePedIsIn(Ped)
    local VehiclePlate = GetVehicleNumberPlateText(CurrentVehicle)
    if noSpace(VehiclePlate) ~= noSpace(RentedVehiclePlate) then
        QBCore.Functions.Notify('This is not a rental vehicle..', 'error')
    else
        TriggerServerEvent('qb-rentals:server:SetVehicleRented', RentedVehiclePlate, false, Config.RentalVehicles[RentedVehicleData])
        QBCore.Functions.DeleteVehicle(CurrentVehicle)
        RentedVehiclePlate = nil
        RentedVehicleData = nil
    end
    RentalMenu()
end

RentalMenu = function()
    ClearMenu()
    Menu.addButton("Rent vehicle", "RentVehicleMenu", nil)
    Menu.addButton("Close Menu", "CloseMenu", nil) 
end

CloseMenu = function()
    Menu.hidden = true
    currentGarage = nil
    ClearMenu()
end

ClearMenu = function()
	Menu.GUI = {}
	Menu.buttonCount = 0
	Menu.selection = 0
end

function noSpace(str)
    local normalisedString = string.gsub(str, "%s+", "")
    return normalisedString
end