-- Flight Controller
-- ItzFoxz
-- October 9, 2020

local FlightController = {}

local KEYBINDS = {
    ACCELERATE = Enum.KeyCode.W,
    DECELERATE = Enum.KeyCode.S,
    ROLL_LEFT = Enum.KeyCode.A,
    ROLL_RIGHT = Enum.KeyCode.D,
    FREE_LOOK = Enum.KeyCode.LeftAlt
}

local CAMERA_OFFSET = CFrame.new(0, 13, 25) * CFrame.fromEulerAnglesXYZ(math.rad(-10), 0, 0)

local SpaceshipService
local UserInputService
local RunService
local Thruster

local Spaceship
local PrimaryPart
local BodyVelocity
local BodyGyro
local ShipStats
local Camera = workspace.CurrentCamera

local CurrentSpeed = 0 
local IsFlying = false
local mouseActive = false
local RotX = 0
local RotY = 0
local ThrusterGroup = {}
local SteppedEvent
local SeatEvent

local xAngle = 0
local yAngle = 0

function FlightController:Start()
    -- Gain controls of the spaceship the client has entered
    SpaceshipService.gainControls:Connect(function(spaceship)
        Spaceship = spaceship
        PrimaryPart = Spaceship.Model.PrimaryPart
        ShipStats = spaceship.Stats
        BodyVelocity = nil
        BodyGyro = nil

        if not IsFlying then
            self:StartFlight()
        end
    end)
end


function FlightController:Init()
    SpaceshipService = self.Services.SpaceshipService
    Thruster = self.Modules.Thruster
    UserInputService = game:GetService("UserInputService")
    RunService = game:GetService("RunService")
end

function FlightController:StartFlight()
    if Spaceship then
        -- Set up the BodyGyro and BodyVelocity objects
        local seat = Spaceship.Model:FindFirstChildWhichIsA("Seat", true)

        -- Stop flight if player exits seat
        SeatEvent = seat:GetPropertyChangedSignal("Occupant"):Connect(function()
            if not seat.Occupant then
                self:EndFlight()
                SeatEvent:Disconnect()
            end
        end)

        -- Create a thruster group
        ThrusterGroup = Thruster.CreateThrusterGroup(Spaceship.Model, ShipStats.Speed) 

        if not seat:FindFirstChild("BodyGyro") then
            BodyGyro = Instance.new("BodyGyro", seat)
            -- BodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            BodyGyro.MaxTorque = Vector3.new(40000, 40000, 40000)
            BodyGyro.D = 300
            BodyGyro.P = 3000
        else
            BodyGyro = seat:FindFirstChild("BodyGyro")
        end

        if not seat:FindFirstChild("BodyVelocity") then
            BodyVelocity = Instance.new("BodyVelocity", seat)
            BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            BodyVelocity.P = 1250
            BodyVelocity.Velocity = Vector3.new()
        else
            BodyVelocity = seat:FindFirstChild("BodyVelocity")
        end

        workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable

        UserInputService.MouseIconEnabled = false
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

        -- Fly function will be called on every frame
        SteppedEvent = RunService.Stepped:Connect(function(_, dt)
            self:Fly(dt)
            Thruster.ThrustAll(ThrusterGroup, CurrentSpeed / 30)
        end)

        IsFlying = true
    end
end

-- Undos everything done in StartFlight()
function FlightController:EndFlight()
    -- Disconnect the Stepped event 
    SteppedEvent:Disconnect()
    workspace.CurrentCamera.CameraType = Enum.CameraType.Follow
    UserInputService.MouseIconEnabled = true
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    IsFlying = false
end

function FlightController:Fly(dt)
    local mouse = self.Player:GetMouse()

    if mouseActive then
        BodyVelocity.Velocity = mouse.Hit.LookVector * CurrentSpeed
    end

    if RotX ~= 0 then
        BodyGyro.CFrame = BodyGyro.CFrame * CFrame.fromEulerAnglesXYZ(0, RotX, RotX / 3)
    end
    
    if RotY ~= 0 then
        BodyGyro.CFrame = BodyGyro.CFrame * CFrame.fromEulerAnglesXYZ(RotY, 0, 0) 
    end

    self:UpdateCamera(dt)
    self:HandleInput()
end

-- Called each frame to handle user input
function FlightController:HandleInput()
    local MaxSpeed = ShipStats.Speed * 30
    local Acceleration = ShipStats.Acceleration / 3

	-- Acceleration
	if UserInputService:IsKeyDown(KEYBINDS.ACCELERATE) then
		CurrentSpeed = math.clamp(CurrentSpeed + Acceleration, 0, MaxSpeed)
    end
    -- Deceleration
	if UserInputService:IsKeyDown(KEYBINDS.DECELERATE) then
		CurrentSpeed = math.clamp(CurrentSpeed - Acceleration, 0, MaxSpeed)
	end

	-- Banking with A and D
	local bankSpeed = math.clamp(CurrentSpeed / 4000, 0.01, 0.04)
	
	if UserInputService:IsKeyDown(KEYBINDS.ROLL_LEFT) then
		BodyGyro.CFrame = BodyGyro.CFrame * CFrame.fromEulerAnglesXYZ(0, 0, bankSpeed)
	end 
	if  UserInputService:IsKeyDown(KEYBINDS.ROLL_RIGHT) then
		BodyGyro.CFrame = BodyGyro.CFrame * CFrame.fromEulerAnglesXYZ(0, 0, -bankSpeed)
    end
    
    self:GetRotationFromMouse()
end

-- Determine rotation of the ship based on the user's mouse detla and turn speed
function FlightController:GetRotationFromMouse()
    if UserInputService:IsMouseButtonPressed(1) and not UserInputService:IsKeyDown(KEYBINDS.FREE_LOOK) then
		local mouseDelta = UserInputService:GetMouseDelta()
		mouseDelta = Vector2.new(math.clamp(mouseDelta.X, -7, 7), math.clamp(mouseDelta.Y, -7, 7))
		
		-- Turn speed will speed up as the ship speeds up and vice versa:
        local turnSpeed = -math.clamp(ShipStats.TurnSpeed * (CurrentSpeed / 10) / 10000, 0.00005, ShipStats.TurnSpeed / 10000)
		
		-- Drag based on mouse delta
		local dragX = math.abs(mouseDelta.X / 10)
		local dragY = math.abs(mouseDelta.Y / 10)
		
		RotX = math.clamp(RotX + (mouseDelta.X * turnSpeed * dragX), -0.03, 0.03)
		RotY = math.clamp(RotY + (mouseDelta.Y * turnSpeed * dragY), -0.03, 0.03)
	else
		RotX = 0
		RotY = 0
	end
end

function FlightController:UpdateCamera(dt)

    local alpha = math.clamp(0.5 * 20 * dt, 0, 1)
    local goal = PrimaryPart.CFrame * CAMERA_OFFSET

    if not UserInputService:IsKeyDown(KEYBINDS.FREE_LOOK) then
        mouseActive = true
        --local lerped = Camera.CFrame:Lerp(goal, alpha)
        --Camera.CFrame = CFrame.new(Vector3.new(lerped.Position.X, lerped.Position.Y, PrimaryPart.Position.Z)) * CFrame.Angles(lerped:ToEulerAnglesXYZ())
        Camera.CFrame = Camera.CFrame:Lerp(goal, alpha)
        xAngle = 0
        yAngle = 0
    else
        mouseActive = false
        self:FreeLook(alpha)
    end
end

function FlightController:FreeLook(alpha)
    local mouseDelta = UserInputService:GetMouseDelta()
    xAngle = xAngle - mouseDelta.X * 0.4
    --Clamp the vertical axis so it doesn't go upside down or glitch.
    yAngle = math.clamp(yAngle - mouseDelta.Y * 0.4, -80, 80)

    local goal = PrimaryPart.CFrame * CFrame.Angles(0, math.rad(xAngle), 0) * CFrame.Angles(math.rad(yAngle), 0, 0)
    goal = goal * CAMERA_OFFSET

    Camera.CFrame = Camera.CFrame:Lerp(goal, alpha) 
end

return FlightController