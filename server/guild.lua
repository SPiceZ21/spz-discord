-- server/guild.lua — "which roles does this Discord user have in our guild?"
--
-- REST only (GET /guilds/{guild}/members/{user}) with the same bot token as the
-- feeds. That endpoint needs no gateway and no privileged intent; the bot just
-- has to be a member of the guild. Results are cached briefly so a reconnect
-- loop or /adminmode spam doesn't hammer Discord.

local API = 'https://discord.com/api/v10'
local cache = {}   -- [discordId] = { at = ms, result = {...} }

local function guildId()
    local g = GetConvar('spz_discord_guild', '')
    return g ~= '' and g or Config.Guild.id
end

function Guild_Configured()
    return guildId() ~= '' and GetConvar('spz_discord_token', '') ~= ''
end

--- "discord:123" → "123", or nil if the player has no Discord linked.
function Guild_DiscordId(src)
    local id = GetPlayerIdentifierByType(src, 'discord')
    if not id then return nil end
    return (id:gsub('^discord:', ''))
end

local function request(discordId)
    local p = promise.new()
    PerformHttpRequest(('%s/guilds/%s/members/%s'):format(API, guildId(), discordId),
        function(status, body, headers)
            p:resolve({ status = status, body = body, headers = headers })
        end, 'GET', '', { ['Authorization'] = 'Bot ' .. GetConvar('spz_discord_token', '') })
    return Citizen.Await(p)
end

--- Look a member up. Must be called from a thread (it awaits).
--- Returns { ok = true, member = bool, roles = {[roleId]=true}, nick = string }
---      or { ok = false, error = string }  (Discord unreachable / misconfigured)
function Guild_GetMember(discordId, fresh)
    if not discordId then return { ok = true, member = false, roles = {} } end
    if not Guild_Configured() then return { ok = false, error = 'guild or bot token not configured' } end

    local c = cache[discordId]
    if not fresh and c and GetGameTimer() - c.at < Config.Guild.cacheSeconds * 1000 then
        return c.result
    end

    local res = request(discordId)
    if res.status == 429 then
        -- Rate limited: honour retry_after once, then give up.
        local ok, data = pcall(json.decode, res.body or '')
        Wait(math.min(5000, math.floor(((ok and data and data.retry_after) or 1) * 1000)))
        res = request(discordId)
    end

    local result
    if res.status == 200 then
        local ok, data = pcall(json.decode, res.body or '')
        if ok and data then
            local roles = {}
            for _, r in ipairs(data.roles or {}) do roles[tostring(r)] = true end
            result = { ok = true, member = true, roles = roles, nick = data.nick }
        else
            result = { ok = false, error = 'bad response from Discord' }
        end
    elseif res.status == 404 then
        result = { ok = true, member = false, roles = {} }      -- not in the guild
    else
        result = { ok = false, error = ('Discord HTTP %s'):format(tostring(res.status)) }
    end

    if result.ok then cache[discordId] = { at = GetGameTimer(), result = result } end
    return result
end

--- Does the member hold ANY of the role ids in `list`?
function Guild_HasAnyRole(member, list)
    if not member or not member.roles then return false end
    for _, roleId in ipairs(list or {}) do
        if member.roles[tostring(roleId)] then return true end
    end
    return false
end

function Guild_Forget(discordId) cache[discordId] = nil end
