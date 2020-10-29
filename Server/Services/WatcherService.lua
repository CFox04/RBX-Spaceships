-- Watcher Service
-- ItzFoxz
-- October 27, 2020


local WatcherService = {Client = {}, Whitelist = {}}

local CLIENT_UPDATE_EVENT = "clientUpdate"
local CLIENT_WATCH_EVENT = "startWatching"
local CLIENT_UNWATCH_EVENT = "stopWatching"

function WatcherService:Start()
end


function WatcherService:Init()
    WatcherService:RegisterClientEvent(CLIENT_UPDATE_EVENT)
    WatcherService:RegisterClientEvent(CLIENT_WATCH_EVENT)
    WatcherService:RegisterClientEvent(CLIENT_UNWATCH_EVENT)
end

function WatcherService:StartWatching(player, object)
    -- Add to whitelist
    WatcherService.Whitelist[#WatcherService.Whitelist+1] = object
    -- Start watching
    WatcherService:FireClient(CLIENT_WATCH_EVENT, player, object)
end

function WatcherService.Client:IsObjectWhitelisted(player, object)
    for _, wlObject in pairs(WatcherService.Whitelist) do
        if wlObject == object then
            return true
        end
    end
    return false
end

function WatcherService.Client:ObjectUpdate(player, object, properties)
    if self:IsObjectWhitelisted(_, object) then
        WatcherService:FireOtherClients(CLIENT_UPDATE_EVENT, player, object, properties)
    else
        warn("Could not update object. Object is not whitelisted.")
    end
end


return WatcherService