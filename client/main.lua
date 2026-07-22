local QBCore = exports['qb-core']:GetCoreObject()

local scoreboardOpen = false
local refreshToken = 0

local function closeScoreboard()
    if not scoreboardOpen then return end
    scoreboardOpen = false
    refreshToken = refreshToken + 1
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end

local function openScoreboard()
    if scoreboardOpen then return end
    scoreboardOpen = true
    local token = refreshToken

    QBCore.Functions.TriggerCallback('wellgame_scoreboard:server:getPlayers', function(payload)
        if not scoreboardOpen or token ~= refreshToken then return end
        SendNUIMessage({
            action = 'open',
            data = payload,
        })
    end)

    CreateThread(function()
        while scoreboardOpen and token == refreshToken do
            -- Block pause / map while holding TAB scoreboard
            DisableControlAction(0, 199, true) -- P / pause
            DisableControlAction(0, 200, true) -- ESC pause
            DisableControlAction(0, 37, true)  -- weapon wheel (TAB)
            DisableControlAction(0, 157, true)
            DisableControlAction(0, 158, true)
            DisableControlAction(0, 160, true)
            DisableControlAction(0, 164, true)
            DisableControlAction(0, 165, true)
            Wait(0)
        end
    end)

    CreateThread(function()
        local ms = Config.RefreshMs or 500
        while scoreboardOpen and token == refreshToken do
            Wait(ms)
            if not scoreboardOpen or token ~= refreshToken then break end
            QBCore.Functions.TriggerCallback('wellgame_scoreboard:server:getPlayers', function(payload)
                if not scoreboardOpen or token ~= refreshToken then return end
                SendNUIMessage({
                    action = 'update',
                    data = payload,
                })
            end)
        end
    end)
end

RegisterCommand('+wellgame_scoreboard', function()
    openScoreboard()
end, false)

RegisterCommand('-wellgame_scoreboard', function()
    closeScoreboard()
end, false)

RegisterKeyMapping('+wellgame_scoreboard', 'Wellcosta Scoreboard (hold)', 'keyboard', Config.OpenKey or 'TAB')

-- Activity heartbeat for AFK
CreateThread(function()
    local interval = Config.ActivityHeartbeatMs or 2000
    while true do
        Wait(interval)
        local ped = PlayerPedId()
        if IsPedWalking(ped) or IsPedRunning(ped) or IsPedSprinting(ped)
            or IsControlPressed(0, 32) or IsControlPressed(0, 33)
            or IsControlPressed(0, 34) or IsControlPressed(0, 35)
            or IsControlPressed(0, 21) or IsControlPressed(0, 22)
            or IsControlPressed(0, 24) or IsControlPressed(0, 25)
        then
            TriggerServerEvent('wellgame_scoreboard:server:activity')
        end
    end
end)

-- NUI scroll (wheel) — when scoreboard open, forward to NUI via message already handles wheel in browser;
-- without NUI focus, use game controls:
CreateThread(function()
    while true do
        if scoreboardOpen then
            if IsDisabledControlJustPressed(0, 14) or IsControlJustPressed(0, 14) then -- wheel down
                SendNUIMessage({ action = 'scroll', dir = 1 })
            elseif IsDisabledControlJustPressed(0, 15) or IsControlJustPressed(0, 15) then -- wheel up
                SendNUIMessage({ action = 'scroll', dir = -1 })
            end
            Wait(0)
        else
            Wait(200)
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    closeScoreboard()
end)
