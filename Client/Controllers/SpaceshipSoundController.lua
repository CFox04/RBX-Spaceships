-- Spaceship Sound Controller
-- ItzFoxz
-- October 27, 2020



local SpaceshipSoundController = {}

local MAX_OCTAVE = 1.5
local MAX_MID_GAIN = -20
local MAX_LOW_GAIN = 10
local MAX_HUM_VOLUME = 0.7
local MAX_THRUST_VOLUME = 3
local MAX_THRUST_SPEED = 4

local started = false

local HumSound
local ThrustSound
local PitchShift
local AudioEQ


function SpaceshipSoundController:Start()
end


function SpaceshipSoundController:Init()
end

-- Engine startup sound
function SpaceshipSoundController:StartSound(hum, thrust, time)
    if hum:IsA("Sound") and thrust:IsA("Sound") then
        HumSound = hum
        ThrustSound = thrust
        PitchShift = hum:FindFirstChild("PitchShiftSoundEffect")
        AudioEQ = thrust:FindFirstChild("EqualizerSoundEffect")
        HumSound.Volume = MAX_HUM_VOLUME
        HumSound.Playing = true
        ThrustSound.Playing = true
        local steps = time / 0.1
        local octaveGoal = 0.7
        coroutine.wrap(function()
            repeat
                PitchShift.Octave = PitchShift.Octave + (octaveGoal / steps)
                wait(0.1)
            until PitchShift.Octave >= octaveGoal
            started = true
        end)()
    else
        error("Invalid spaceship sound")
    end
end

-- Engine stop sound
function SpaceshipSoundController:StopSound(time)
    local steps = time / 0.1
    local midIncrement = AudioEQ.MidGain / steps
    local lowIncrement = AudioEQ.LowGain / steps
    local humIncrement = HumSound.Volume / steps
    local octaveIncrement = PitchShift.Octave / steps
    coroutine.wrap(function()
        repeat
            AudioEQ.MidGain = AudioEQ.MidGain - midIncrement
            AudioEQ.LowGain = AudioEQ.LowGain - lowIncrement
            HumSound.Volume = HumSound.Volume - humIncrement
            PitchShift.Octave = PitchShift.Octave - octaveIncrement
            wait(0.1)
        until PitchShift.Octave <= 0.5 and HumSound.Volume <= 0 and ThrustSound.Volume <= 0
        started = false
        HumSound.Playing = false
        ThrustSound.Playing = false
    end)()
end

function SpaceshipSoundController:UpdateSound(speedRatio)
    if HumSound and ThrustSound and started then
        PitchShift.Octave = (speedRatio * MAX_OCTAVE) + 0.7
        ThrustSound.Volume = speedRatio * MAX_THRUST_VOLUME
        ThrustSound.PlaybackSpeed = speedRatio * MAX_THRUST_SPEED
        AudioEQ.MidGain = speedRatio * MAX_MID_GAIN
        AudioEQ.LowGain = speedRatio * MAX_LOW_GAIN
    end
end


return SpaceshipSoundController