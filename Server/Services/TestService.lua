-- Test Service
-- ItzFoxz
-- October 8, 2020

-- Driver code for testing modules

local TestService = {Client = {}}

function TestService:Start()
    local Spaceship = TestService.Modules.Spaceship
    local players = game:GetService("Players")

    players.PlayerAdded:Connect(
        function(player)
            -- Wait for character
            local character = player.Character or player.CharacterAdded:wait()
            -- Spawn a new spaceship at the player's location
            local newSpaceship = Spaceship.new("Test", player)
            newSpaceship:Spawn(character.HumanoidRootPart.CFrame)
        end
    )
end

function TestService:Init()
end

return TestService
