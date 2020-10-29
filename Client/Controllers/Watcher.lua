-- Watcher
-- ItzFoxz
-- October 15, 2020

local Watcher = {EventConnections = {}}

local WatcherService

function Watcher:Start()
    WatcherService.clientUpdate:Connect(Watcher.Update)
    WatcherService.startWatching:Connect(Watcher.Watch)
end


function Watcher:Init()
    WatcherService = self.Services.WatcherService
end

-- Watch a part for specific property changes
function Watcher.Watch(part)
    if WatcherService:IsObjectWhitelisted(part) then
        print("Watching part", part)
        local connection = part.Changed:Connect(function(property)
            WatcherService:ObjectUpdate(part, {[property] = part[property]})
        end)
        Watcher.EventConnections[#Watcher.EventConnections+1] = connection
    else
        warn("No permission to watch that object. Don't cheat, bud.")
    end
end

-- Update parts based on the change
function Watcher.Update(part, properties)
    for property, value in pairs(properties) do
        print("Updating part")
        print(part, property)
        if property == "size" then
            property = "Size"
        end
    
        part[property] = value
    end
end


return Watcher