-- server/whitelist.lua — only members of the guild holding a whitelist role
-- may connect. Runs as its own deferral; spz-core's profile deferral runs in
-- parallel and the connection waits for both.
--
-- If Discord can't be reached, Config.Whitelist.failOpen decides. Identifiers in
-- Config.Whitelist.bypass always get in (so an outage can't lock admins out).

local function bypassed(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        for _, b in ipairs(Config.Whitelist.bypass) do
            if id == b then return true end
        end
    end
    return false
end

AddEventHandler('playerConnecting', function(name, _, deferrals)
    if not Config.Whitelist.enabled then return end
    local src = source
    deferrals.defer()
    Wait(0)
    deferrals.update('Checking Discord whitelist...')

    if bypassed(src) then deferrals.done(); return end

    if not Guild_Configured() then
        print('^1[spz-discord] Whitelist is enabled but the guild id or bot token is missing — '
            .. (Config.Whitelist.failOpen and 'letting everyone in.' or 'refusing everyone.') .. '^7')
        if Config.Whitelist.failOpen then deferrals.done() else deferrals.done(Config.Whitelist.messages.unavailable) end
        return
    end

    local discordId = Guild_DiscordId(src)
    if not discordId then
        deferrals.done(Config.Whitelist.messages.noDiscord)
        return
    end

    local m = Guild_GetMember(discordId, true)
    if not m.ok then
        print(('^3[spz-discord] Whitelist lookup failed for %s (%s): %s^7'):format(name, discordId, m.error))
        if Config.Whitelist.failOpen then deferrals.done() else deferrals.done(Config.Whitelist.messages.unavailable) end
        return
    end
    if not m.member then
        deferrals.done(Config.Whitelist.messages.notInGuild)
        return
    end
    if #Config.Whitelist.roles > 0 and not Guild_HasAnyRole(m, Config.Whitelist.roles) then
        deferrals.done(Config.Whitelist.messages.noRole)
        return
    end

    deferrals.done()
end)
