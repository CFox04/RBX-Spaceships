-- Thrust Effect
-- ItzFoxz
-- October 10, 2020

--[[

This class handles the thrust effects for spaceships.

The thrust effect is created by cloning neon cone meshes and incrementally changing
each mesh's size based on the current power of the thrust.
	
--]]

local Thruster = {}
Thruster.__index = Thruster

local PART_OFFSET = 0.2
local SpaceshipService
local RunService

-- Thrusts an array of thrusters 
function Thruster.ThrustAll(thrustGroup, speed)
	coroutine.wrap(function()
		for _, thruster in pairs(thrustGroup) do
			thruster:Thrust(speed)
		end
	end)()
end

-- Stops thrusting an array of thrusters
function Thruster.StopAll(thrustGroup)
	for _, thruster in pairs(thrustGroup) do
		thruster:Stop()
	end
end

-- Create a group of thrusters from a spaceship model
function Thruster.CreateThrusterGroup(model, speed)
	local group = {}
	-- Find thrust root parts
	for _, item in pairs(model:GetDescendants()) do
		if item.Name == "Thruster" then
			local rootPart = item:FindFirstChild("ThrustRootPart")
			if rootPart then
				local newThruster = Thruster.new(rootPart, rootPart.Diameter.Value, rootPart.MaxHeight.Value, speed)
				group[#group+1] = newThruster
			else
				error("Failed to create thruster group. No thrust root part found.")
			end 
		end
	end

	return group
end

function Thruster.new(rootPart, diameter, maxHeight, maxSpeed)
	local self = {}
    setmetatable(self, Thruster)
	
	self.RootPart = rootPart
	self.Diameter = diameter or 5
	self.MaxHeight = maxHeight or 3
	self.MaxSpeed = maxSpeed
	
	self.Parts = {}
	self.CurrentSpeed = 0

	self:InitializeParts()
	
	return self
end

-- AeroGameFramework initialization
function Thruster:Init()
	SpaceshipService = self.Services.SpaceshipService
	RunService = game:GetService("RunService")
end

-- Initial setup for the mesh parts
function Thruster:InitializeParts()
	print("initializing")
	coroutine.wrap(function()
		-- Count index only on cone parts
		for _, part in pairs(self.RootPart.Parent:GetChildren()) do
			if part:IsA("MeshPart") and string.find(part.Name, "Cone") then
				self.Parts[#self.Parts+1] = part
				self:UpdatePart(part, #self.Parts+1)
			end
		end
		self:FadeIn(1)
	end)()
end

-- Updates part depending on speed 
function Thruster:UpdatePart(part, index)
	-- How fast the ship is moving relative to its maximum speed
	local speedRatio = self.CurrentSpeed / self.MaxSpeed
	-- Each part's height will be PART_OFFSET smaller than the next and less than self.MaxHeight
	local height = (speedRatio * self.MaxHeight) - (PART_OFFSET * (#self.Parts - index))
	-- Minimum height of 0.5 studs
	height = height > 0.5 and height or 0.5
	part.Size = Vector3.new(part.Size.X, height, part.Size.Z)

	-- Makes the inner-most cone glow and increase Diameter as speed increases
	if index == 1 then
		local Diameter = math.clamp(speedRatio, 0.5, 0.65) * self.Diameter
		part.Size = Vector3.new(Diameter, part.Size.Y, Diameter)
	end

	-- As the thrust effect increases in height, it will need to move back a bit
	local motor = part:FindFirstChildWhichIsA("Motor6D")
	motor.Transform = motor.Part0.CFrame:Inverse() * (motor.Part0.CFrame * CFrame.new(0, part.Size.Y / 2, 0))

	local particles = self.RootPart.Parent:FindFirstChild("Particles")
	particles.ParticleEmitter.Acceleration = Vector3.new(0, 0, (speedRatio * 100) * (self.Diameter / 4))
	particles.ParticleEmitter.Speed = NumberRange.new(speedRatio * 10)
end

function Thruster:Flicker(offset)
	local part = self.Parts[#self.Parts]
	coroutine.wrap(function()
		local motor = part:FindFirstChildWhichIsA("Motor6D")
		part.Size = part.Size + Vector3.new(0, offset, 0)
		motor.Transform = motor.Part0.CFrame:Inverse() * (motor.Part0.CFrame * CFrame.new(0, part.Size.Y / 2, 0))
		wait(0.1)
		part.Size = part.Size - Vector3.new(0, offset, 0)
		motor.Transform = motor.Part0.CFrame:Inverse() * (motor.Part0.CFrame * CFrame.new(0, part.Size.Y / 2, 0))
	end)()
end

function Thruster:FadeIn(time)
	local timesToRepeat = (time / 0.01) / #self.Parts
	coroutine.wrap(function()
		for i, part in pairs(self.Parts) do
			local goal = (i / #self.Parts) 
			local increment = (1 - goal) / timesToRepeat
			coroutine.wrap(function()
				repeat
					if part.Transparency > goal then
						part.Transparency = part.Transparency - increment
					end
					wait(0.01)
				until part.Transparency <= goal 
			end)()
		end
	end)()
end

function Thruster:FadeOut(time)
	local timesToRepeat = (time / 0.01) / #self.Parts
	coroutine.wrap(function()
		for _, part in pairs(self.Parts) do
			local increment = (1 - part.Transparency) / timesToRepeat
			coroutine.wrap(function()
				repeat
					part.Transparency = part.Transparency + increment
					wait(0.01)
				until part.Transparency >= 1
			end)()
		end
	end)()
end

function Thruster:Thrust(speed)
	if speed ~= self.CurrentSpeed then
		self.CurrentSpeed = speed

		--Update each cone part
		for i, part in pairs(self.Parts) do
			self:UpdatePart(part, i)
		end
	end
end

function Thruster:Stop()
	local model = self.RootPart.Parent
	model:ClearAllChildren()
	model:Destroy()
	self:FadeOut(1)
	self.RootPart = nil
	self.Parts = {}
	self = nil
end

return Thruster
