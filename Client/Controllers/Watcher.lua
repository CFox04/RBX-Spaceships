-- Watcher
-- ItzFoxz
-- October 15, 2020



local Watcher = {EventConnections = {}}

local STOP_WATCHING_EVENT = "stopWatching"
local SpaceshipService

function Watcher:Start()
    SpaceshipService.watchSpaceship:Connect(function(spaceship)
        self:Watch(spaceship)
    end)

    SpaceshipService.onSpaceshipChange:Connect(function(part, property, value)
        self:HandleChange(part, property, value)
    end)

    self:ConnectEvent(STOP_WATCHING_EVENT, function()
        self:StopWatching()
    end)
end


function Watcher:Init()
    SpaceshipService = self.Services.SpaceshipService
    Watcher:RegisterEvent(STOP_WATCHING_EVENT)
end

-- Watch an instance for changes and notify other clients of that change
function Watcher:Watch(instance)
    for _, part in pairs(instance:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Weld") then
            local connection = part.Changed:Connect(function(property)
                SpaceshipService:RegisterChange(part, property, part[property])
            end)
            self.EventConnections[#self.EventConnections+1] = connection
        end
    end
end

function Watcher:StopWatching()
    for _, connection in pairs(self.EventConnections) do
        connection:Disconnect()
    end
end

-- Update parts based on the change
function Watcher:HandleChange(part, property, value)
    if property == "size" then
        property = "Size"
    end

    part[property] = value
end


return Watcher