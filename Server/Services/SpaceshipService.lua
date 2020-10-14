-- Spaceship Service
-- ItzFoxz
-- October 9, 2020



local SpaceshipService = {Client = {}}

local Spaceships = {}

local CLIENT_GAIN_CONTROLS = "gainControls"
local CLIENT_REMOVE_CONTROLS = "removeControls"

function SpaceshipService:Start()
	
end

function SpaceshipService:Init()
    SpaceshipService:RegisterClientEvent(CLIENT_GAIN_CONTROLS)
end

-- Register a spaceship by pushing it to the global spaceships table
function SpaceshipService:RegisterShip(spaceship)
    if spaceship then
        Spaceships[#Spaceships+1] = spaceship
    end
end

function SpaceshipService:GainControls(player, spaceship)
    -- Give the pilot network ownership
    spaceship.Model.PrimaryPart:SetNetworkOwner(player)
    -- Hand the controls of a spaceship over to the client controller
    SpaceshipService:FireClient(CLIENT_GAIN_CONTROLS, player, spaceship)
end

function SpaceshipService:RemoveControls(player, spaceship)
    -- Remove a client's control of a spaceship
    SpaceshipService:FireClient(CLIENT_REMOVE_CONTROLS, player, spaceship)
end

return SpaceshipService