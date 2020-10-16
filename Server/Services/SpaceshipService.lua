-- Spaceship Service
-- ItzFoxz
-- October 9, 2020



local SpaceshipService = {Client = {}}

local Spaceships = {}

local CLIENT_GAIN_CONTROLS = "gainControls"
local CLIENT_REMOVE_CONTROLS = "removeControls"
local CLIENT_WATCH_SPACESHIP = "watchSpaceship"
local CLIENT_SPACESHIP_CHANGE = "onSpaceshipChange"

function SpaceshipService:Start()
	
end

function SpaceshipService:Init()
    SpaceshipService:RegisterClientEvent(CLIENT_GAIN_CONTROLS)
    SpaceshipService:RegisterClientEvent(CLIENT_REMOVE_CONTROLS)
    SpaceshipService:RegisterClientEvent(CLIENT_WATCH_SPACESHIP)
    SpaceshipService:RegisterClientEvent(CLIENT_SPACESHIP_CHANGE)
end

-- Register a spaceship by pushing it to the global spaceships table
function SpaceshipService:RegisterShip(spaceship)
    if spaceship then
        Spaceships[spaceship.Owner] = spaceship
    end
end

function SpaceshipService:GainControls(player, spaceship)
    -- Give the pilot network ownership
    spaceship.Model.PrimaryPart:SetNetworkOwner(player)
    -- Hand the controls of a spaceship over to the client controller
    SpaceshipService:FireClient(CLIENT_GAIN_CONTROLS, player, spaceship)
    SpaceshipService:FireClient(CLIENT_WATCH_SPACESHIP, player, spaceship.Model)
end

function SpaceshipService:RemoveControls(player, spaceship)
    -- Remove a client's control of a spaceship
    SpaceshipService:FireClient(CLIENT_REMOVE_CONTROLS, player, spaceship)
end

function SpaceshipService.Client:RegisterChange(player, part, property, value)
    SpaceshipService:FireOtherClients(CLIENT_SPACESHIP_CHANGE, player, part, property, value)
end

function SpaceshipService.Client:GetSpaceshipFromPlayer(player)
    local spaceship = Spaceships[player]
    if spaceship then
        return spaceship
    end
end

return SpaceshipService