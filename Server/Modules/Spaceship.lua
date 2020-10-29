-- Spaceship
-- ItzFoxz
-- October 8, 2020

--[[
    Class handles the creation and management of each player's spaceship on the server. 
]]

local Spaceship = {}
Spaceship.__index = Spaceship

local HUM_SOUND_ID = "rbxasset://sounds/spaceship_hum.ogg"
local THRUST_SOUND_ID = "rbxasset://sounds/spaceship_thrust.ogg"

local HttpService 
local MotorUtil
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
    local self = {}
    setmetatable(self, Spaceship)

    self.ID = HttpService:GenerateGUID()
    -- Find ship model based on name
    self.Model = getShipModel(modelName)
    self.Owner = Owner
    self.Config = {
        Acceleration = 5,
        Speed = 5,
        TurnSpeed = 5,
        ThrusterColor = Color3.new(143, 231, 255)
    }
    self.Colors = {}
    self.ThrustersCreated = false
    self.Seat = self.Model:FindFirstChildWhichIsA("Seat", true)

    if not self.Seat then
        error("Could not find a seat in the specified spaceship model. Ensure there is a seat part somewhere inside the model. The ship will not function until this error is resolved.")
    end

    -- Event fires when a pilot sits on a seat
    self.pilotSeated = self.Seat:GetPropertyChangedSignal("Occupant")
    self.pilotExited = Signal.new()

    -- Create maid
    self.Maid = Maid.new()
    self.Maid:GiveTask(self.pilotSeated)
    self.Maid:GiveTask(self.pilotExited)

    -- When a player enters the cockpit, give them network ownership, and notify the FlightController to begin controlling the ship
    local lastPilot
    self.pilotSeated:Connect(function()
        if self.Seat.Occupant then
            --lastPilot = game.Players[self.Seat.Occupant.Parent.Name]
            self:Activate(game.Players[self.Seat.Occupant.Parent.Name])
        end
    end)

    -- Register the new spaceship with the SpaceshipService
    SpaceshipService:RegisterShip(self)
    self:GetConfig()
    self:LoadSound()

    return self
end

-- Get Config from the configuration folder inside of model
function Spaceship:GetConfig()
    local config = self.Model:FindFirstChildWhichIsA("Configuration", true)
    if config then
        for _, item in pairs(config:GetChildren()) do
            if self.Config[item.Name] then
                self.Config[item.Name] = item.Value
            end
        end
    else
        warn("Could not locate ship's configuration. Using default Config.")
    end
end

function Spaceship:Init()
    MotorUtil = self.Shared.MotorUtil
    Signal = self.Shared.Signal
    Maid = self.Shared.Maid
    SpaceshipService = self.Services.SpaceshipService
    HttpService = game:GetService("HttpService")
end

-- Activates the spaceship for flight
function Spaceship:Activate(player)
    if not self.ThrustersCreated then
        self:CreateThrustParts(player)
        self.ThrustersCreated = true
    end
    -- Notify the FlightController to begin controlling the ship
    SpaceshipService:GainControls(player, self)
end

function Spaceship:Spawn(cframe)
    MotorUtil.MotorModel(self.Model)
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
            local particles = script:FindFirstChild("Particles"):Clone()
            MotorUtil.MotorTo(particles, part)
            -- Get diameter of thruster effect from the value inside of ThrustRootPart
            local diameter = part.Diameter.Value
            particles.ParticleEmitter.Color = ColorSequence.new(self.Config.ThrusterColor)
            -- Set ParticleEmitter size based on diameter
            particles.ParticleEmitter.Size = NumberSequence.new{NumberSequenceKeypoint.new(0, diameter / 2.5), NumberSequenceKeypoint.new(1, diameter / 5)}
            particles.Position = part.Position
            particles.Parent = part
            -- Create corresponding parts
            for i = 1, 4 do
                local cone = script:FindFirstChild("Cone"):Clone()
                -- Thrust cones closer to the center are smaller and vice versa
                local Diameter = diameter - (0.5 * (4 - i))
                cone.Size = Vector3.new(Diameter, cone.Size.Y, Diameter)

                cone.Color = self.Config.ThrusterColor
                cone.Transparency = 1
                cone.Name = string.format("%s%i", cone.Name, i)

                local motor = MotorUtil.MotorTo(cone, part)
                motor.C0 = motor.Part0.CFrame:Inverse() * (motor.Part0.CFrame * CFrame.Angles(math.rad(90), 0, 0)) 

                cone.Parent = model
            end
        end
    end
end

function Spaceship:LoadSound()
    -- Hum sound layer
    local humSound = Instance.new("Sound", self.Seat)
    local pitchShift = Instance.new("PitchShiftSoundEffect", humSound)
    humSound.Name = "hum"
    humSound.SoundId = HUM_SOUND_ID
    humSound.Looped = true
    humSound.Volume = 0
    pitchShift.Octave = 0.5

    -- Thrust sound layer
    local thrustSound = Instance.new("Sound", self.Seat)
    local audioEQ = Instance.new("EqualizerSoundEffect", thrustSound)
    thrustSound.Name = "thrust"
    thrustSound.SoundId = THRUST_SOUND_ID
    thrustSound.Looped = true
    thrustSound.Volume = 0
    audioEQ.HighGain = -80
    audioEQ.MidGain = -80
    audioEQ.LowGain = -80
end

function Spaceship:Destroy()
    self.Maid:DoCleaning()
    self.Model:Destroy()
end

return Spaceship
