local QBCore = exports['qb-core']:GetCoreObject()

local lastActivity = {} -- [src] = os.time()

local function touchActivity(src)
    lastActivity[src] = os.time()
end

AddEventHandler('playerJoining', function()
    touchActivity(source)
end)

AddEventHandler('playerDropped', function()
    lastActivity[source] = nil
end)

RegisterNetEvent('wellgame_scoreboard:server:activity', function()
    touchActivity(source)
end)

local function resolveAdminRank(src)
    for i = 1, #Config.AdminRanks do
        local rank = Config.AdminRanks[i]
        if IsPlayerAceAllowed(src, rank.ace) then
            return rank
        end
    end
    return nil
end

local function isHelper(src)
    if not Config.HelperAce or Config.HelperAce == '' then return false end
    return IsPlayerAceAllowed(src, Config.HelperAce)
end

local function getCharName(qbPlayer)
    local ci = qbPlayer.PlayerData.charinfo
    if not ci then return GetPlayerName(qbPlayer.PlayerData.source) or 'Ismeretlen' end
    local name = ((ci.firstname or '') .. ' ' .. (ci.lastname or '')):gsub('^%s+', ''):gsub('%s+$', '')
    if name == '' then return GetPlayerName(qbPlayer.PlayerData.source) or 'Ismeretlen' end
    return name
end

local function getLevel(qbPlayer)
    local meta = qbPlayer.PlayerData.metadata or {}
    local level = meta.level
    if type(level) ~= 'number' then level = 1 end
    return level
end

local function getAfkSeconds(src)
    local t = lastActivity[src]
    if not t then return 0 end
    return math.max(0, os.time() - t)
end

QBCore.Functions.CreateCallback('wellgame_scoreboard:server:getPlayers', function(source, cb)
    local rows = {}
    local myId = source

    for _, playerId in ipairs(QBCore.Functions.GetPlayers()) do
        local src = tonumber(playerId)
        local qbPlayer = QBCore.Functions.GetPlayer(src)
        local ping = GetPlayerPing(src)
        if not ping or ping < 0 then ping = 0 end

        local entry = {
            id = src,
            name = GetPlayerName(src) or ('ID ' .. tostring(src)),
            level = false,
            ping = false,
            loggedIn = false,
            isSelf = (src == myId),
            isHelper = false,
            adminDuty = false,
            adminLabel = nil,
            adminColor = nil,
            adminLevel = nil,
            afkSeconds = getAfkSeconds(src),
        }

        if qbPlayer then
            entry.loggedIn = true
            entry.name = getCharName(qbPlayer)
            entry.level = getLevel(qbPlayer)
            entry.ping = ping
            entry.isHelper = isHelper(src)

            local onDuty = false
            local stateNick, stateTitle, stateLevel, stateColor
            pcall(function()
                local st = Player(src).state
                onDuty = st.adminDuty == true
                stateNick = st.adminNick
                stateTitle = st.adminTitle
                stateLevel = st.adminLevel
            end)

            if not onDuty and Config.OptinAsAdminDuty then
                local rank = resolveAdminRank(src)
                if rank and qbPlayer.PlayerData.optin == true then
                    onDuty = true
                    stateTitle = rank.label
                    stateColor = rank.color
                    stateLevel = rank.level
                end
            end

            if onDuty then
                entry.adminDuty = true
                entry.ping = false

                if type(stateNick) == 'string' and stateNick ~= '' then
                    entry.name = stateNick
                else
                    local adminNick = qbPlayer.PlayerData.metadata and qbPlayer.PlayerData.metadata.adminNick
                    if type(adminNick) == 'string' and adminNick ~= '' then
                        entry.name = adminNick
                    end
                end

                local level = tonumber(stateLevel)
                if not level then
                    level = (qbPlayer.PlayerData.metadata and qbPlayer.PlayerData.metadata.adminLevel) or nil
                end
                if not level then
                    local rank = resolveAdminRank(src)
                    if rank then
                        level = rank.level
                        stateColor = rank.color
                        if not stateTitle then stateTitle = rank.label end
                    end
                end

                if GetResourceState('wellgame_admin') == 'started' and level then
                    local label = exports['wellgame_admin']:GetAdminTitle(level)
                    local color = exports['wellgame_admin']:GetAdminTitleColor(level)
                    entry.adminLabel = stateTitle or label
                    entry.adminColor = stateColor or color or '#06b6d4'
                    entry.adminLevel = level
                else
                    local rank = resolveAdminRank(src)
                    entry.adminLabel = stateTitle or (rank and rank.label) or 'Admin'
                    entry.adminColor = stateColor or (rank and rank.color) or '#06b6d4'
                    entry.adminLevel = level or (rank and rank.level)
                end
            end
        end

        rows[#rows + 1] = entry
    end

    table.sort(rows, function(a, b)
        if a.isSelf ~= b.isSelf then
            return a.isSelf and not b.isSelf
        end
        return a.id < b.id
    end)

    cb({
        players = rows,
        maxPlayers = Config.MaxPlayers or GetConvarInt('sv_maxclients', 48),
        brand = Config.Brand,
        title = Config.Title,
        columns = Config.Columns,
        afkThreshold = Config.AfkThresholdSec or 60,
    })
end)
