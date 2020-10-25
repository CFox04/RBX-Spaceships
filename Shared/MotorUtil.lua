-- Motor Util
-- ItzFoxz
-- October 8, 2020

--[[ Quick way to attach Motor6D joints to models ]]
local MotorUtil = {}

function MotorUtil.MotorModel(model)
    local primaryPart = model.PrimaryPart

    -- Loop through model's part recursively
    for _, part in pairs(model:GetDescendants()) do
        -- If it is indeed a part and not the primaryPart
        if (part:IsA("BasePart") and part ~= primaryPart) then
            -- Motor the part to the model's primary part
            local Motor = Instance.new("Motor6D")
            Motor.Name = "MainMotor"
            Motor.Part0 = primaryPart
            Motor.Part1 = part
            Motor.C0 = primaryPart.CFrame:inverse()
		    Motor.C1 = part.CFrame:inverse()
            Motor.Parent = part
            
            part.Anchored = false
        end

        primaryPart.Anchored = false
    end
end

return MotorUtil
