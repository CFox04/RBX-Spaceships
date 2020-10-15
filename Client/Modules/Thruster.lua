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
local RunService 

-- Gets a darker color shade of specified color
local function GetDarkColorShade(color)
	local R = (color.R * 255) / 1.5
	local G = (color.G * 255) / 2
	local B = color.B * 255 
	local darkColor = Color3.fromRGB(R, G, B)
	
	return darkColor
end

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
	RunService = game:GetService("RunService")
end

-- Initial setup for the mesh parts
function Thruster:InitializeParts()
	coroutine.wrap(function()
		-- Count index only on cone parts
		local i = 1
		for _, part in pairs(self.RootPart.Parent:GetChildren()) do
			if part:IsA("MeshPart") and part.Name == "Cone" then
				self.Parts[#self.Parts+1] = part
				self:InitPart(i, part)
	
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
	weld.C0 = weld.Part0.CFrame:Inverse() * (self.RootPart.CFrame * CFrame.Angles(math.rad(90), 0, 0))
	
	-- Thrust cones closer to the center are smaller and vice versa
	local Diameter = self.Diameter - (0.5 * (4 - index))
	local height = 1 - (0.1 * (4 - index))
	part.Size = Vector3.new(Diameter, height, Diameter)

	part.Color = self.Color
	weld.C0 = weld.C0 + Vector3.new(0, 0, height / 2)
	part.Transparency = 1
	
	return part
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
	local zOffset = part.Size.Y / 2
	zOffset = zOffset < 0.05 and 0.05 or zOffset
	
	local weld = part:FindFirstChildWhichIsA("Weld")
	-- Offset weld 
	weld.C0 = weld.Part0.CFrame:Inverse() * (self.RootPart.CFrame * CFrame.new(0, 0, zOffset)) * CFrame.Angles(math.rad(90), 0, 0)
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
	self:FadeOut(0.5)
	self:InitializeParts()
end

return Thruster
