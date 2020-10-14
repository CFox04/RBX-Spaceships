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

function Thruster.ThrustAll(thrustGroup, speed)
	coroutine.wrap(function()
		for _, thruster in pairs(thrustGroup) do
			thruster:Thrust(speed)
		end
	end)()
end

-- Create a group of thrusters from a spaceship model
function Thruster.CreateThrusterGroup(model, speed)
	local group = {}
	-- Find thrust root parts
	for _, item in pairs(model:GetDescendants()) do
		if item.Name == "Thruster" then
			local rootPart = item:FindFirstChild("ThrustRootPart")
			if rootPart then
				local newThruster = Thruster.new(rootPart, rootPart.Radius.Value, rootPart.MaxHeight.Value, speed, rootPart.ThrustColor.Value)
				-- newThruster:Activate()
				group[#group+1] = newThruster
			else
				error("Failed to create thruster group. No thrust root part found.")
			end 
		end
	end

	return group
end

function Thruster.new(rootPart, radius, maxHeight, maxSpeed, color)
	local self = {}
    setmetatable(self, Thruster)
	
	self.RootPart = rootPart
	self.Radius = radius or 5
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
		self:FadeIn(0.3)
	end)()
end

-- Sets the parts color, position, and transparency. This is affected by the index of the part in self.Parts
function Thruster:InitPart(index, part)
	-- local weld = part:FindFirstChildWhichIsA("WeldConstraint")
	-- weld:Destroy()
	-- weld = Instance.new("WeldConstraint", part)
	-- weld.Part0 = self.RootPart
	-- weld.Part1 = part


	part.Color = self.Color
	-- part.CFrame = self.RootPart.CFrame * CFrame.new(0, 0, 0.15) * CFrame.Angles(math.rad(90), 0, 0)
	part.Position = self.RootPart.Position
	part.Transparency = 1
	
	local darkColor = GetDarkColorShade(self.Color)
	
	-- Thrust cones closer to the center are smaller and vice versa
	local radius = self.Radius - (0.5 * (4 - index))
	part.Size = Vector3.new(radius, 0.05, radius)

	if index == 1 or index == 4 then
		part.Color = darkColor
	end
	
	return part
end

function Thruster:FadeIn(time)
	local timesToRepeat = (time / 0.01) / 4
	coroutine.wrap(function()
		for i, part in pairs(self.Parts) do
			local goal = (i / #self.Parts)
			local increment = (1 - goal) / timesToRepeat
			repeat
				part.Transparency = part.Transparency - increment
				wait(0.01)
			until part.Transparency <= goal
		end
	end)()
end

function Thruster:FadeOut(time)
	local timesToRepeat = (time / 0.01) / 4
	coroutine.wrap(function()
		for i, part in pairs(self.Parts) do
			local increment = (1 - part.Transparency) / timesToRepeat
			repeat
				part.Transparency = part.Transparency + increment
				wait(0.01)
			until part.Transparency >= 1
		end
	end)()
end

function Thruster:UpdatePart(part, index)
	-- How fast the ship is moving relative to its maximum speed
	local speedRatio = self.CurrentSpeed / self.MaxSpeed
	-- Each part's height will be PART_OFFSET smaller than the next and less than self.MaxHeight
	local height = (speedRatio * self.MaxHeight) - (PART_OFFSET * (#self.Parts - index))
	part.Size = Vector3.new(part.Size.X, height, part.Size.Z)
	-- part.CFrame = 
	--part.Position = Vector3.new(0, 0, height / 2)

	-- Makes the inner-most cone glow and increase radius as speed increases
	if index == 1 then
		local radius = math.clamp(speedRatio, 0.5, 0.65) * self.Radius
		part.Size = Vector3.new(radius, part.Size.Y, radius)
		
		local R = math.clamp(part.Color.R + 0.01, 0, self.Color.R) 
		local G = math.clamp(part.Color.G + 0.01, 0, self.Color.G)
		
		part.Color = Color3.new(R, G, self.Color.B)
	end

	-- As the thrust effect increases in height, it will need to move back a bit
	local zOffset = part.Size.Y / 2
	zOffset = zOffset < 0.15 and 0.15 or zOffset

	part.Position = self.RootPart.Position + Vector3.new(0, 0, zOffset)

	-- part.CFrame = self.RootPart.CFrame * CFrame.new(0, 0, zOffset) * CFrame.Angles(math.rad(90), 0, 0)
	
	-- local weld = part:FindFirstChildWhichIsA("WeldConstraint") 
	-- if weld then
	-- 	weld.Enabled = false
	-- 	part.Position = self.RootPart.Position + Vector3.new(0, 0, zOffset)
	-- 	weld.Enabled = true
	-- end
end

function Thruster:Thrust(speed)
	self.CurrentSpeed = speed

	--Update each cone part
	for i, part in pairs(self.Parts) do
		self:UpdatePart(part, i)
	end
end

function Thruster:Stop()
	self:FadeOut(0.5)
	self:InitializeParts()
end

return Thruster
