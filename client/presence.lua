-- client/presence.lua — Discord Rich Presence (was spz-rpc): what the player is
-- doing (freeroam car, queue, vote, grid, race position and lap) on their profile.

local P = Presence
local appId = GetConvar('spz_discord_appid', '')
if appId == '' then appId = P.AppId or '' end
if appId == '' then return end   -- not configured

local queueSince
local wasQueued = false

local function ordinal(n)
    local s = 'th'
    if n % 100 < 11 or n % 100 > 13 then s = ({ 'st', 'nd', 'rd' })[n % 10] or 'th' end
    return n .. s
end

local function class(c)
    return P.Classes[c] or { label = 'Racer', asset = P.Assets.logo }
end

local function vehicleName(veh)
    local model = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
    local label = GetLabelText(model)
    if label == 'NULL' or label == 'CARNOTFOUND' then return model end
    return label
end

local function update()
    local me = LocalPlayer.state
    local raceState = GlobalState.raceState or 'IDLE'
    local inRace, inQueue = me.inRace, me.inQueue

    if inQueue and not wasQueued then queueSince = GetCloudTimeAsInt()
    elseif not inQueue then queueSince = nil end
    wasQueued = inQueue and true or false

    local large, largeText = P.Assets.freeroam, 'Free roam'
    local small, smallText = P.Assets.logo, P.ServerName
    local details, state = 'In Los Santos', ''
    local since = 0

    if inRace and raceState == 'LIVE' then
        local c = class(me.raceClass)
        large, largeText, small, smallText = P.Assets.racing, 'Racing', c.asset, c.label
        details = 'Racing on ' .. (me.raceTrack or 'a track')
        if me.dnf then
            state, small, smallText = 'Did not finish', P.Assets.dnf, 'DNF'
        else
            local pos = me.racePosition or 0
            state = ('%s · Lap %d/%d'):format(pos > 0 and ordinal(pos) or '—', me.raceLap or 1, me.raceLaps or 1)
            if me.raceTime and me.raceTime > 0 then
                since = GetCloudTimeAsInt() - math.floor((GetGameTimer() - me.raceTime) / 1000)
            end
        end
    elseif inRace and (raceState == 'WAITING' or raceState == 'COUNTDOWN') then
        local c = class(me.raceClass)
        large, largeText, small, smallText = P.Assets.staging, 'On the grid', c.asset, c.label
        details = 'On the grid · ' .. (me.raceTrack or 'a track')
        state = (me.racePosition or 0) > 0 and ('%s · Grid %d'):format(c.label, me.racePosition) or c.label
    elseif raceState == 'POLLING' then
        large, largeText = P.Assets.polling, 'Voting'
        details, state = 'Voting for the next race', 'Track and class'
    elseif inQueue then
        large, largeText = P.Assets.queue, 'Ready to race'
        details = 'In the race queue'
        state = ('#%d of %d'):format(me.queuePosition or 1, GlobalState.queueCount or 1)
        since = queueSince or 0
    else
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        details = (veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped) and ('Cruising in ' .. vehicleName(veh)) or 'On foot'
        local ok, profile = pcall(function() return exports['spz-identity']:GetClientProfile() end)
        if ok and profile then
            largeText = ('Level %s · SR %s'):format(profile.level or 1, profile.sr or 0)
            state = ('%s · iR %s'):format(profile.rank or 'C-1', profile.iRating or 1000)
        else
            state = 'Free roam'
        end
    end

    SetDiscordRichPresenceAsset(large)
    SetDiscordRichPresenceAssetText(largeText)
    SetDiscordRichPresenceAssetSmall(small or '')
    SetDiscordRichPresenceAssetSmallText(smallText or '')
    SetRichPresence(state ~= '' and (details .. ' - ' .. state) or details)
    if SetDiscordRichPresenceStartTime then SetDiscordRichPresenceStartTime(since) end
end

CreateThread(function()
    SetDiscordAppId(appId)
    if P.ServerUrl and P.ServerUrl ~= '' then
        SetDiscordRichPresenceAction(0, 'Join Server', P.ServerUrl)
    end

    -- React to the moments that change the status, not just the timer.
    local myBag = 'player:' .. GetPlayerServerId(PlayerId())
    AddStateBagChangeHandler('raceState', 'global', function() SetTimeout(0, update) end)
    for _, key in ipairs({ 'inRace', 'inQueue', 'dnf' }) do
        AddStateBagChangeHandler(key, myBag, function() SetTimeout(0, update) end)
    end

    while true do
        update()
        Wait(P.UpdateIntervalMs or 15000)
    end
end)
