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

local SpaceshipService

local PARTICLES_TRANSPARENCY = NumberSequence.new{
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.3, 0.6),
	NumberSequenceKeypoint.new(0.5, 0.75),
	NumberSequenceKeypoint.new(1, 1),
}

-- Thrusts an array of thrusters 
function Thruster.ThrustAll(thrustGroup, speed)
	coroutine.wrap(function()
		for _, thruster in pairs(thrustGroup) do
			thruster:Thrust(speed)
		end
	end)()
end

-- Activates table of thrusters
function Thruster.ActivateAll(thrustGroup)
	for _, thruster in pairs(thrustGroup) do
		thruster:Activate()
	end
end

-- Deactivates table of thrusters
function Thruster.DeactivateAll(thrustGroup)
	for _, thruster in pairs(thrustGroup) do
		thruster:Deactivate()
	end
end

-- Create a group of thrusters from a spaceship model
function Thruster.CreateThrusterGroup(model, speed, ID)
	local group = {}
	-- Find thrust root parts
	for _, item in pairs(model:GetDescendants()) do
		if item.Name == "Thruster" then
			local rootPart = item:FindFirstChild("ThrustRootPart")
			if rootPart then
				local newThruster = Thruster.new(rootPart, rootPart.Diameter.Value, speed, ID)
				group[#group+1] = newThruster
			else
				error("Failed to create thruster group. No thrust root part found.")
			end 
		end
	end

	return group
end

function Thruster.new(rootPart, diameter, maxSpeed, maxHeight, spaceshipID)
	local self = {}
    setmetatable(self, Thruster)
	
	self.RootPart = rootPart
	self.Diameter = diameter or 5
	self.MaxHeight = maxHeight or 1.5
	self.MaxSpeed = maxSpeed
	self.spaceshipID = spaceshipID
	
	self.Parts = {}
	self.CurrentSpeed = 0
	self.Particles = self.RootPart.Particles.ParticleEmitter
	self.Activated = false

	if not self.Particles then
		error("Unable to locate thruster particles. Ensure there is a part named 'Particles' with a ParticleEmitter inside of it within each ThrustRootPart.")
	end

	self:InitializeParts()
	
	return self
end

-- AeroGameFramework initialization
function Thruster:Init()
	SpaceshipService = self.Services.SpaceshipService
end

-- Initial setup for the mesh parts
function Thruster:InitializeParts()
	coroutine.wrap(function()
		-- Count index only on cone parts
		for _, part in pairs(self.RootPart.Parent:GetChildren()) do
			if part:IsA("MeshPart") and string.find(part.Name, "Cone") then
				self.Parts[#self.Parts+1] = part
			end
		end
	end)()
end

-- Updates particles depending on speed
function Thruster:UpdateParticles()
	-- How fast the ship is moving relative to its maximum speed
	local speedRatio = self.CurrentSpeed / self.MaxSpeed

	-- Adjust particles setting based on speed and size of thruster
	self.Particles.Acceleration = Vector3.new(0, 0, (speedRatio * 100) * (self.Diameter / 4))
	self.Particles.Speed = NumberRange.new(speedRatio * 10)

end

function Thruster:FadeIn(time)
	local timesToRepeat = (time / 0.01) / #self.Parts
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
	self.Particles.Transparency = PARTICLES_TRANSPARENCY
end

function Thruster:FadeOut(time)
	local timesToRepeat = (time / 0.01) / #self.Parts
	self.Particles.Transparency = NumberSequence.new(1)
	for _, part in pairs(self.Parts) do
		local increment = (1 - part.Transparency) / timesToRepeat
		coroutine.wrap(function()
			repeat
				part.Transparency = part.Transparency + increment
				wait(0.01)
			until part.Transparency >= 1
		end)()
	end
end

function Thruster:Thrust(speed)
	if speed ~= self.CurrentSpeed and self.Activated then
		self.CurrentSpeed = speed
		self:UpdateParticles()
	end
end

function Thruster:Activate()
	self:FadeIn(3)
	self.Activated = true
end

-- Make it keep old parts and update them instead
function Thruster:Deactivate()
	self:FadeOut(3)
	self.Activated = false
end

return Thruster
