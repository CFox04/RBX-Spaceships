-- Weld Util
-- ItzFoxz
-- October 8, 2020

--[[ Quick way to weld models ]]
local WeldUtil = {}

function WeldUtil.WeldModel(model)
    local primaryPart = model.PrimaryPart

    -- Loop through model's part recursively
    for _, part in pairs(model:GetDescendants()) do
        -- If it is indeed a part and not the primaryPart
        if (part:IsA("BasePart") and part ~= primaryPart) then
            -- Weld the part to the model's primary part
            local Weld = Instance.new("WeldConstraint")
            Weld.Name = "MainWeld"
            Weld.Part0 = primaryPart
            Weld.Part1 = part
            Weld.Parent = part
            
            part.Anchored = false
        end

        primaryPart.Anchored = false
    end
end

return WeldUtil
