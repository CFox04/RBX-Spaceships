-- Spaceship
-- ItzFoxz
-- October 8, 2020

local Spaceship = {}
Spaceship.__index = Spaceship

local WeldUtil
local Signal
local Maid
local SpaceshipService

-- Clones a ship model asset from its name
local function getShipModel(name)
    local ServerStorage = game:GetService("ServerStorage")
    local shipModels = ServerStorage:FindFirstChild("ShipModels")
    local model = shipModels:FindFirstChild(name)

    if model then
        return model:Clone()
    else
        return false
    end
end

-- Instantiate Spaceship object
function Spaceship.new(modelName, Owner)
    local self = {
        -- Find ship model based on name
        Model = getShipModel(modelName),
        Owner = Owner,
        Stats = {
            Acceleration = 5,
            Speed = 5,
            TurnSpeed = 5
        },
        Colors = {},
        Thrusters = {}
    }

    local seat = self.Model:FindFirstChildWhichIsA("Seat", true)

    if not seat then
        error("Could not find a seat in the specified spaceship model. Ensure there is a seat part somewhere inside the model. The ship will not function until this error is resolved.")
    end

    -- Event fires when a pilot sits on a seat
    self.pilotSeated = seat:GetPropertyChangedSignal("Occupant")
    self.pilotExited = Signal.new()

    -- Create maid
    self.Maid = Maid.new()
    self.Maid:GiveTask(self.pilotSeated)
    self.Maid:GiveTask(self.pilotExited)

    -- When a player enters the cockpit, give them network ownership, and notify the FlightController to begin controlling the ship
    local lastPilot
    self.pilotSeated:Connect(function()
        if seat.Occupant then
            lastPilot = game.Players[seat.Occupant.Parent.Name]
            self:CreateThrustParts(lastPilot)
            -- Notify the FlightController to begin controlling the ship
            SpaceshipService:GainControls(lastPilot, self)
        end
    end)

    setmetatable(self, Spaceship)

    -- Register the new spaceship with the SpaceshipService
    SpaceshipService:RegisterShip(self)
    self:GetStatsFromConfig()

    return self
end

-- Get stats from the configuration folder inside of model
function Spaceship:GetStatsFromConfig()
    local config = self.Model:FindFirstChildWhichIsA("Configuration", true)
    if config then
        for _, item in pairs(config:GetChildren()) do
            if self.Stats[item.Name] then
                self.Stats[item.Name] = item.Value
            end
        end
    else
        warn("Could not locate ship's configuration. Using default stats.")
    end
end

function Spaceship:Init()
    WeldUtil = self.Shared.WeldUtil
    Signal = self.Shared.Signal
    Maid = self.Shared.Maid
    SpaceshipService = self.Services.SpaceshipService
end

function Spaceship:Spawn(cframe)
    WeldUtil.WeldModel(self.Model)
    self.Model.Name = string.format("%s-%s", self.Model.Name, self.Owner.Name)
    self.Model.Parent = workspace
    self.Model:SetPrimaryPartCFrame(cframe)
end

-- Creates the required meshparts for the thrust effect
function Spaceship:CreateThrustParts(player)
    -- Find thrust root parts
    for _, part in pairs(self.Model:GetDescendants()) do
        if part:IsA("BasePart") and part.Name == "ThrustRootPart" then
            local model = Instance.new("Model", part.Parent)
            model.Name = "Thruster"
            part.Parent = model
            model.PrimaryPart = part
            -- model.PrimaryPart:SetNetworkOwner(player)
            local diameter = part.Diameter.Value
            local color = part.ThrustColor.Value
            -- Create corresponding parts
            for i = 1, 4 do
                local cone = script:FindFirstChild("Cone"):Clone()
                local weld = Instance.new("Weld", cone)
                weld.Part0 = part
                weld.Part1 = cone
                
                -- Thrust cones closer to the center are smaller and vice versa
                local Diameter = diameter - (0.5 * (4 - i))
                cone.Size = Vector3.new(Diameter, cone.Size.Y, Diameter)

                cone.Color = color
                cone.Transparency = 1
                cone.Name = string.format("%s%i", cone.Name, i)
                cone.Parent = model
            end
        end
    end
end

function Spaceship:Destroy()
    self.Maid:Destroy()
    self.Model:Destroy()
end

return Spaceship
