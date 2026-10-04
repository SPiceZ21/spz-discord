-- server/adminmode.lua — Discord roles → ACE groups, behind an on/off toggle.
--
-- Holding a role in Config.AdminMode.roles makes you ELIGIBLE. /adminmode turns
-- the matching groups on for your server id (add_principal player.<id> <group>)
-- and off again. Everything that already checks ACEs (spz.admin via group.admin,
-- spz-core HasPermission, spz-admin's F1 menu) just follows.
--
-- Grants are runtime-only and per server id. They are removed on disconnect —
-- server ids are reused, so a leaked grant would hand the next joiner admin —
-- and when this resource stops. Roles are re-read from Discord on every toggle,
-- so removing someone's role in Discord takes effect at their next /adminmode.

local granted = {}   -- [src] = { group, group, ... }

local function notify(src, msg, t)
    TriggerClientEvent('ox_lib:notify', src, { title = 'Admin mode', description = msg, type = t or 'inform' })
end

--- Groups this member is eligible for, from their Discord roles.
local function eligibleGroups(member)
    local groups, seen = {}, {}
    for roleId, group in pairs(Config.AdminMode.roles) do
        if member.roles[tostring(roleId)] and not seen[group] then
            seen[group] = true
            groups[#groups + 1] = group
        end
    end
    table.sort(groups)
    return groups
end

local function revoke(src)
    local list = granted[src]
    if not list then return end
    for _, group in ipairs(list) do
        ExecuteCommand(('remove_principal player.%d %s'):format(src, group))
    end
    granted[src] = nil
    if GetPlayerName(src) then Player(src).state:set('spz:adminMode', false, true) end
end

-- Runtime add_principal/remove_principal need the resource to hold
-- command.add_principal / command.remove_principal (see README). Without them
-- ExecuteCommand fails silently, so check once and say so loudly.
CreateThread(function()
    local res = 'resource.' .. GetCurrentResourceName()
    if not IsPrincipalAceAllowed(res, 'command.add_principal') or not IsPrincipalAceAllowed(res, 'command.remove_principal') then
        print(('^1[spz-discord] Admin mode cannot grant roles. Add to server.cfg:^7'))
        print(('    add_ace %s command.add_principal allow'):format(res))
        print(('    add_ace %s command.remove_principal allow'):format(res))
    end
end)

local function grant(src, groups)
    revoke(src)
    for _, group in ipairs(groups) do
        ExecuteCommand(('add_principal player.%d %s'):format(src, group))
    end
    granted[src] = groups
    Player(src).state:set('spz:adminMode', true, true)
end

local function log(src, on, groups)
    local line = ('%s (%s) admin mode %s%s'):format(GetPlayerName(src) or '?', Guild_DiscordId(src) or 'no discord',
        on and 'ON' or 'OFF', on and (' [' .. table.concat(groups, ', ') .. ']') or '')
    print('^5[spz-discord]^7 ' .. line)
    if GetResourceState('spz-analytics') == 'started' then
        pcall(function() exports['spz-analytics']:AdminAction(src, on and 'adminmode_on' or 'adminmode_off', line) end)
    end
    if GetResourceState('spz-log') == 'started' then
        pcall(function() exports['spz-log']:Log('admin', 'Admin mode', line, on and 'warning' or 'info') end)
    end
end

--- Turn on (on=true), off (false) or flip (nil). Runs in a thread (awaits Discord).
local function setMode(src, on)
    if on == nil then on = granted[src] == nil end
    if not on then
        if granted[src] then revoke(src); log(src, false); notify(src, 'Admin mode OFF.', 'inform') end
        return
    end

    local m = Guild_GetMember(Guild_DiscordId(src), true)
    if not m.ok then notify(src, "Couldn't reach Discord: " .. m.error, 'error'); return end
    local groups = m.member and eligibleGroups(m) or {}
    if #groups == 0 then
        revoke(src)
        notify(src, 'You have no admin role in the Discord server.', 'error')
        return
    end
    grant(src, groups)
    log(src, true, groups)
    notify(src, ('Admin mode ON (%s).'):format(table.concat(groups, ', ')), 'success')
end

RegisterCommand(Config.AdminMode.command, function(src, args)
    if src == 0 then return end
    local arg = args[1] and args[1]:lower()
    local want = nil                       -- no argument: toggle
    if arg == 'on' then want = true elseif arg == 'off' then want = false end
    CreateThread(function() setMode(src, want) end)
end, false)

-- Optionally switch eligible staff on as they join.
AddEventHandler('playerJoining', function()
    if not Config.AdminMode.autoOnJoin then return end
    local src = source
    CreateThread(function()
        local m = Guild_GetMember(Guild_DiscordId(src))
        if m.ok and m.member and #eligibleGroups(m) > 0 then setMode(src, true) end
    end)
end)

AddEventHandler('playerDropped', function()
    revoke(source)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for src in pairs(granted) do revoke(src) end
end)

exports('IsAdminMode', function(src) return granted[tonumber(src)] ~= nil end)
