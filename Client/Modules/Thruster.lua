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

local function offsetWeld(weld, offset)
	return weld.Part0.CFrame:Inverse() * (weld.Part0.CFrame * CFrame.new(0, 0, offset)) * CFrame.Angles(math.rad(90), 0, 0)
end

-- local function resizeWeldedPart(part, newSize, minOffset)
-- 	local weld = part:FindFirstChildWhichIsA("Weld")
-- 	local sizeDeltas = Vector3.new(newSize.X - part.Size.X, newSize.Y - part.Size.Y, newSize.Z - part.Size.Z)
-- 	print(sizeDeltas)
-- 	local offsetX, offsetY, offsetZ = minOffset
-- 	if sizeDeltas.X ~= 0 then
-- 		offsetX = part.Size.X / 2
-- 		offsetX = offsetX > minOffset.X and offsetX or minOffset.X
-- 	end
-- 	if sizeDeltas.Y ~= 0 then
-- 		offsetY = part.Size.Y / 2
-- 		offsetY = offsetY > minOffset.Y and offsetY or minOffset.Y
-- 	end
-- 	if sizeDeltas.Z ~= 0 then
-- 		offsetZ = part.Size.Z / 2
-- 		offsetX = offsetX > minOffset.X and offsetX or minOffset.X
-- 	end
-- 	-- local offset = Vector3.new(part.Size.X / 2, part.Size.Y / 2, part.Size.Z / 2)
-- 	part.Size = newSize
-- 	print(offsetX, offsetY, offsetZ)
-- 	weld.C0 = weld.Part0.CFrame:Inverse() * (weld.Part0.CFrame * CFrame.new(0, 0, offsetY) * CFrame.Angles(math.rad(90), 0, 0))
-- end

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
				local newThruster = Thruster.new(rootPart, rootPart.Diameter.Value, rootPart.MaxHeight.Value, speed, rootPart.ThrustColor.Value)
				group[#group+1] = newThruster
			else
				error("Failed to create thruster group. No thrust root part found.")
			end 
		end
	end

	return group
end

function Thruster.new(rootPart, diameter, maxHeight, maxSpeed, color)
	local self = {}
    setmetatable(self, Thruster)
	
	self.RootPart = rootPart
	self.Diameter = diameter or 5
	self.MaxHeight = maxHeight or 3
	self.Color = color or Color3.fromRGB(111, 255, 224)
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
	coroutine.wrap(function()
		-- Count index only on cone parts
		local i = 1
		for _, part in pairs(self.RootPart.Parent:GetChildren()) do
			if part:IsA("MeshPart") and string.find(part.Name, "Cone") then
				self.Parts[#self.Parts+1] = part
				self:UpdatePart(part, i)
				--self:InitPart(i, part)
	
				i += 1
			end
		end
		self:FadeIn(1)
	end)()
end

-- Sets the parts color, position, and transparency. This is affected by the index of the part in self.Parts
function Thruster:InitPart(index, part)
	local weld = part:FindFirstChildWhichIsA("Weld")
	weld:Destroy()
	weld = Instance.new("Weld", part)
	weld.Part0 = self.RootPart
	weld.Part1 = part
	
	-- Thrust cones closer to the center are smaller and vice versa
	local Diameter = self.Diameter - (0.5 * (4 - index))
	part.Size = Vector3.new(Diameter, part.Size.Y, Diameter)

	part.Color = self.Color
	part.Transparency = 1
	part.Name = string.format("%s%i", part.Name, index)

	self:UpdatePart(part, index)
	
	return part
end

-- Updates part depending on speed 
function Thruster:UpdatePart(part, index)
	-- How fast the ship is moving relative to its maximum speed
	local speedRatio = self.CurrentSpeed / self.MaxSpeed
	-- Each part's height will be PART_OFFSET smaller than the next and less than self.MaxHeight
	local height = (speedRatio * self.MaxHeight) - (PART_OFFSET * (#self.Parts - index))
	-- Minimum height of 0.5 studs
	height = height > 0.5 and height or 0.5
	--resizeWeldedPart(part, Vector3.new(part.Size.X, height, part.Size.Z), Vector3.new(0.1, 0.1, 0.1))
	part.Size = Vector3.new(part.Size.X, height, part.Size.Z)

	-- Makes the inner-most cone glow and increase Diameter as speed increases
	if index == 1 then
		local Diameter = math.clamp(speedRatio, 0.5, 0.65) * self.Diameter
		part.Size = Vector3.new(Diameter, part.Size.Y, Diameter)
	end

	-- As the thrust effect increases in height, it will need to move back a bit
	local zOffset = part.Size.Y / 2
	zOffset = zOffset < 0.05 and 0.05 or zOffset
	
	local weld = part:FindFirstChildWhichIsA("Weld")
	--Offset weld 
	weld.C0 = offsetWeld(weld, zOffset)
end

function Thruster:Flicker(offset)
	local part = self.Parts[3]
	coroutine.wrap(function()
		local weld = part:FindFirstChildWhichIsA("Weld")
		local zOffset = (part.Size.Y / 2) + (offset / 2)
		zOffset = zOffset < 0.05 and 0.05 or zOffset
		part.Size = part.Size + Vector3.new(0, offset, 0)
		-- Offset weld 
		--weld.C0 = offsetWeld(weld, zOffset)
		wait(0.1)
		part.Size = part.Size - Vector3.new(0, offset, 0)
		weld.C0 = offsetWeld(weld, zOffset)
	end)()
end

function Thruster:FadeIn(time)
	local timesToRepeat = (time / 0.01) / 4
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
	local timesToRepeat = (time / 0.01) / 4
	coroutine.wrap(function()
		for _, part in pairs(self.Parts) do
			local increment = (1 - part.Transparency) / timesToRepeat
			repeat
				part.Transparency = part.Transparency + increment
				wait(0.01)
			until part.Transparency >= 1
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

	--self:Flicker(0.3)
end

function Thruster:Stop()
	self:FadeOut(0.5)
	self:InitializeParts()
end

return Thruster
