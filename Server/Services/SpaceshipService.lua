-- Spaceship Service
-- ItzFoxz
-- October 9, 2020

--[[
    Manages and stores each player's spaceship(s) in the server.
]]

local SpaceshipService = {Client = {}}

local WatcherService

local Spaceships = {}

local CLIENT_GAIN_CONTROLS = "gainControls"
local CLIENT_REMOVE_CONTROLS = "removeControls"
local CLIENT_THRUSTER_UPDATE_EVENT = "onThrusterUpdate"

function SpaceshipService:Start()
    self:ConnectClientEvent(CLIENT_THRUSTER_UPDATE_EVENT, function(player, eventScript)
        self:ReplicateThruster(player, eventScript)
    end)
end

function SpaceshipService:Init()
    SpaceshipService:RegisterClientEvent(CLIENT_GAIN_CONTROLS)
    SpaceshipService:RegisterClientEvent(CLIENT_REMOVE_CONTROLS)
    SpaceshipService:RegisterClientEvent(CLIENT_THRUSTER_UPDATE_EVENT)

    WatcherService = self.Services.WatcherService
end

-- Register a spaceship by pushing it to the global spaceships table
function SpaceshipService:RegisterShip(spaceship)
    if spaceship then
        Spaceships[spaceship.ID] = spaceship
    end

    -- Destroy the spaceship when the player leaves and remove it from the spaceships table
    game.Players.PlayerRemoving:Connect(function(player)
        if player == spaceship.Owner then
            spaceship = self:GetSpaceshipFromPlayer(player)
            if spaceship then
                spaceship:Destroy()
                spaceship = nil
            else
                error("Failed to destroy spaceship. Could not locate spaceship associated with player.")
            end
        end
    end)
end

function SpaceshipService:GainControls(player, spaceship)
    -- Give the pilot network ownership
    spaceship.Model.PrimaryPart:SetNetworkOwner(player)
    -- Hand the controls of a spaceship over to the client controller
    SpaceshipService:FireClient(CLIENT_GAIN_CONTROLS, player, spaceship)
    SpaceshipService.WatchShip(player, spaceship)
end

function SpaceshipService:RemoveControls(player, spaceship)
    -- Remove the pilot network ownership
    spaceship.Model.PrimaryPart:SetNetworkOwner()
    -- Remove a client's control of a spaceship
    SpaceshipService:FireClient(CLIENT_REMOVE_CONTROLS, player, spaceship)
end

function SpaceshipService:GetSpaceshipFromPlayer(player)
    for _, spaceship in pairs(Spaceships) do
        if spaceship.Owner == player then
            return spaceship
        end
    end
end

function SpaceshipService.WatchShip(player, spaceship)
    for _, part in pairs(spaceship.Model:GetDescendants()) do
        if string.find(part.Name, "Cone") or part:IsA("ParticleEmitter") or part:IsA("Sound") or part:IsA("SoundEffect") then
            WatcherService:StartWatching(player, part)
        end
    end
end

return SpaceshipService