-- Animation Controller
-- Username
-- October 15, 2020



local Watcher = {}

local SpaceshipService 

function Watcher:Start()
    SpaceshipService.watchSpaceship:Connect(function(spaceship)
        self:Watch(spaceship)
    end)

    SpaceshipService.onSpaceshipChange:Connect(function(part, property, value)
        self:HandleChange(part, property, value)
    end)
end


function Watcher:Init()
	SpaceshipService = self.Services.SpaceshipService
end

function Watcher:Watch(instance)
    print("Watching instance: ", instance.Name)
    -- Find thrust root parts
    for _, part in pairs(instance:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Weld") then
            part.Changed:Connect(function(property)
                SpaceshipService:RegisterChange(part, property, part[property])
            end)
        end
    end
end

function Watcher:HandleChange(part, property, value)
    if property == "size" then
        property = "Size"
    end

    part[property] = value
end


return Watcher