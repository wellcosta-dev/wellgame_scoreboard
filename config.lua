Config = {}

-- Hold key (v4 TAB). FiveM keymapping default.
Config.OpenKey = 'TAB'
Config.MaxPlayers = GetConvarInt('sv_maxclients', 48)
Config.Brand = 'WELLCOSTA'
Config.Title = 'SCOREBOARD'

-- Refresh while open (ms) — ping / AFK
Config.RefreshMs = 500

-- AFK: no activity heartbeat for this long → show AFK timer
Config.AfkThresholdSec = 60
Config.ActivityHeartbeatMs = 2000

-- Treat qb-core optin admins as "admin duty" (colored staff row, no ping)
-- Prefer Player(src).state.adminDuty = true from your admin script.
Config.OptinAsAdminDuty = false

--[[
  Admin rank display (highest matching ace wins).
  Mirrors v4 adminLevel labels; mapped to QBCore ace permissions.
]]
Config.AdminRanks = {
    { ace = 'god',   level = 11, label = 'Fejlesztő',   color = '#3b82f6' },
    { ace = 'admin', level = 9,  label = 'Admin',       color = '#06b6d4' },
    { ace = 'mod',   level = 6,  label = 'Moderator',   color = '#f59e0b' },
}

-- Optional helper ace (v4 helperLevel) — tinted name, still shows Lvl + ping
Config.HelperAce = nil -- e.g. 'helper'

-- Column labels (Hungarian like v4)
Config.Columns = {
    id = 'ID',
    name = 'Név',
    level = 'Szint',
    ping = 'Ping',
}
