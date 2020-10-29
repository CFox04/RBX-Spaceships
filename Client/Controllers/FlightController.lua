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

local CAMERA_OFFSET = CFrame.new(0, 13, 30) * CFrame.fromEulerAnglesXYZ(math.rad(-10), 0, 0)
local SPEED_SCALE = 30
local MAX_BANK_SPEED = 1.5

local SpaceshipSoundController
local SpaceshipService
local UserInputService
local TweenService
local RunService
local Thruster

local Spaceship
local PrimaryPart
local BodyVelocity
local BodyGyro
local ShipConfig
local HumSound
local ThrustSound
local Camera = workspace.CurrentCamera

local CurrentSpeed = 0
local IsFlying = false
local mouseActive = false
local RotX = 0
local RotY = 0
local ThrusterGroup = {}
local ThrusterCreated = false
local SteppedEvent
local SeatEvent
local lastCFrame

local xAngle = 0
local yAngle = 0

function FlightController:Start()
    -- Gain controls of the spaceship the client has entered
    SpaceshipService.gainControls:Connect(function(spaceship)
        Spaceship = spaceship
        PrimaryPart = Spaceship.Model.PrimaryPart
        ShipConfig = spaceship.Config
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
    SpaceshipSoundController = self.Controllers.SpaceshipSoundController
    UserInputService = game:GetService("UserInputService")
    RunService = game:GetService("RunService")
    TweenService = game:GetService("TweenService")
end

function FlightController:StartFlight()
    if Spaceship then
        if not ThrusterCreated then
            -- Create a thruster group
            ThrusterGroup = Thruster.CreateThrusterGroup(Spaceship.Model, ShipConfig.Speed, Spaceship.ID)
            ThrusterCreated = true
        end

        Thruster.ActivateAll(ThrusterGroup)
        
        -- Set up the BodyGyro and BodyVelocity objects
        local seat = Spaceship.Model:FindFirstChildWhichIsA("Seat", true)

        HumSound = seat:FindFirstChild("hum")
        ThrustSound = seat:FindFirstChild("thrust")

        -- Play sound
        SpaceshipSoundController:StartSound(HumSound, ThrustSound, 5)

        -- Stop flight if player exits seat
        SeatEvent = seat:GetPropertyChangedSignal("Occupant"):Connect(function()
            if not seat.Occupant then
                self:EndFlight()
            end
        end)

        if not seat:FindFirstChild("BodyGyro") then
            BodyGyro = Instance.new("BodyGyro", seat)
            BodyGyro.MaxTorque = Vector3.new(40000, 40000, 40000)
            BodyGyro.D = 300
            BodyGyro.P = 3000
        else
            BodyGyro = seat:FindFirstChild("BodyGyro")
        end

        if not seat:FindFirstChild("BodyVelocity") then
            BodyVelocity = Instance.new("BodyVelocity", seat)
            BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            BodyVelocity.Velocity = Vector3.new()
        else
            BodyVelocity = seat:FindFirstChild("BodyVelocity")
        end

        workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable

        UserInputService.MouseIconEnabled = false
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

        -- Relock mouse when window is focused
        UserInputService.WindowFocused:Connect(function()
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        end)

        -- Fly function will be called on every frame
        SteppedEvent = RunService.Stepped:Connect(function(_, dt)
            self:ValidateCFrame()
            self:Fly(dt)
            SpaceshipSoundController:UpdateSound(CurrentSpeed / ShipConfig.Speed)
            Thruster.ThrustAll(ThrusterGroup, CurrentSpeed)
        end)

        IsFlying = true
    end
end

function FlightController:EndFlight()
    -- Disconnect events
    SeatEvent:Disconnect()
    SteppedEvent:Disconnect()
    -- Stop thrusters
    Thruster.DeactivateAll(ThrusterGroup)
    -- Restore camera
    workspace.CurrentCamera.CameraType = Enum.CameraType.Follow
    UserInputService.MouseIconEnabled = true
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default

    SpaceshipSoundController:StopSound(3)

    IsFlying = false

    self:FadeVelocity()
end

function FlightController:Fly(dt)
    local mouse = self.Player:GetMouse()
    local newVelocity = mouse.Hit.LookVector * (CurrentSpeed * SPEED_SCALE)

    -- Only update velocity when it has changed
    if BodyVelocity.Velocity ~= newVelocity and mouseActive then
        BodyVelocity.Velocity = newVelocity
    end

    self:UpdateCamera(dt)
    self:HandleInput()
end

-- Anti exploit: Ensures the ship's velocity does not change more than it should (DOESNT WORK)
function FlightController:ValidateCFrame()
    if lastCFrame then
        --print((PrimaryPart.Position - lastCFrame.Position).Magnitude)
    end
    -- if math.floor(PrimaryPart.Velocity.Magnitude) > math.floor(BodyVelocity.Velocity.Magnitude) * 1.5 then
    --     print(math.floor(PrimaryPart.Velocity.Magnitude), math.floor(BodyVelocity.Velocity.Magnitude) * 1.5)
    --     print("cheating")
    --     Spaceship.Model:SetPrimaryPartCFrame(lastCFrame)
    -- end
    lastCFrame = PrimaryPart.CFrame
end

-- Slowly stop the ship
function FlightController:FadeVelocity()
    local speedRatio = CurrentSpeed / ShipConfig.Speed
    local time = speedRatio * 5
    local Tween = TweenService:Create(BodyVelocity, TweenInfo.new(time), {
        Velocity = Vector3.new(0, 0, 0)
    })
    Tween:Play()
end

-- Called each frame to handle user input
function FlightController:HandleInput()
    local speedRatio = CurrentSpeed / ShipConfig.Speed
    local maxSpeed = ShipConfig.Speed 
    local acceleration = ShipConfig.Acceleration / 100

	-- Acceleration
	if UserInputService:IsKeyDown(KEYBINDS.ACCELERATE) then
		CurrentSpeed = math.clamp(CurrentSpeed + acceleration, 0, maxSpeed)
    end
    -- Deceleration
	if UserInputService:IsKeyDown(KEYBINDS.DECELERATE) then
		CurrentSpeed = math.clamp(CurrentSpeed - acceleration, 0, maxSpeed)
	end

	-- Banking with A and D
	local bankSpeed = (speedRatio * MAX_BANK_SPEED) + 0.5
	
	if UserInputService:IsKeyDown(KEYBINDS.ROLL_LEFT) then
		BodyGyro.CFrame = BodyGyro.CFrame * CFrame.fromEulerAnglesXYZ(0, 0, math.rad(bankSpeed))
	end 
	if  UserInputService:IsKeyDown(KEYBINDS.ROLL_RIGHT) then
		BodyGyro.CFrame = BodyGyro.CFrame * CFrame.fromEulerAnglesXYZ(0, 0, math.rad(-bankSpeed))
    end
    
    self:GetRotationFromMouse()
end

-- Determine rotation of the ship based on the user's mouse detla and turn speed
function FlightController:GetRotationFromMouse()
    if UserInputService:IsMouseButtonPressed(1) and not UserInputService:IsKeyDown(KEYBINDS.FREE_LOOK) then
		local mouseDelta = UserInputService:GetMouseDelta()
		mouseDelta = Vector2.new(math.clamp(mouseDelta.X, -7, 7), math.clamp(mouseDelta.Y, -7, 7))
		
		-- Turn speed will speed up as the ship speeds up and vice versa:
        local turnSpeed = -math.clamp(ShipConfig.TurnSpeed * (CurrentSpeed / 10) / 10000, 0.00005, ShipConfig.TurnSpeed / 10000)
		
		-- Drag based on mouse delta
		local dragX = math.abs(mouseDelta.X / 10)
		local dragY = math.abs(mouseDelta.Y / 10)
		
		RotX = math.clamp(RotX + (mouseDelta.X * turnSpeed * dragX), -0.03, 0.03)
        RotY = math.clamp(RotY + (mouseDelta.Y * turnSpeed * dragY), -0.03, 0.03)
        
        BodyGyro.CFrame = BodyGyro.CFrame * CFrame.fromEulerAnglesXYZ(0, RotX, RotX / 3)
        BodyGyro.CFrame = BodyGyro.CFrame * CFrame.fromEulerAnglesXYZ(RotY, 0, 0) 
	else
		RotX = 0
		RotY = 0
	end
end

function FlightController:UpdateCamera(dt)
    local alpha = math.clamp(10 * dt, 0, 1)
    local goal = PrimaryPart.CFrame * CAMERA_OFFSET

    if not UserInputService:IsKeyDown(KEYBINDS.FREE_LOOK) then
        mouseActive = true
        Camera.CFrame = Camera.CFrame:Lerp(goal, alpha)
        xAngle = 0
        yAngle = 0
    else
        mouseActive = false
        self:FreeLook(dt)
    end
end

function FlightController:FreeLook(dt)
    local mouseDelta = UserInputService:GetMouseDelta()
    xAngle = xAngle - mouseDelta.X * 0.4
    --Clamp the vertical axis so it doesn't go upside down or glitch.
    yAngle = math.clamp(yAngle - mouseDelta.Y * 0.4, -80, 80)

    local goal = PrimaryPart.CFrame * (CFrame.Angles(0, math.rad(xAngle), 0) * CFrame.Angles(math.rad(yAngle), 0, 0))
    goal = goal * CAMERA_OFFSET

    local alpha = math.clamp(CAMERA_OFFSET.Position.Z * dt, 0, 1)
    Camera.CFrame = Camera.CFrame:Lerp(goal, alpha)
end

return FlightController