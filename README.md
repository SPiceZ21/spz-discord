# spz-discord

> Everything Discord: race feeds, logs, rich presence, guild-role whitelist and role-based admin.

![version](https://img.shields.io/badge/version-2.0.0-ff6200) ![SPiceZ-Core](https://img.shields.io/badge/SPiceZ--Core-beta-18181b)

## Overview

One resource for everything that talks to Discord. It posts the live race, results and a standing leaderboard, sends server logs into channels, shows each player's status on their Discord profile, admits players by guild role, and grants admin by Discord role.

It uses one bot token and the Discord REST API only: no gateway, nothing extra to host.

spz-log and spz-rpc are part of it now (they were separate resources before 2.0.0).

## Features

- **Race feeds.** A live race embed edited as it runs, recent results, and a leaderboard edited in place.
- **Logs.** `exports['spz-discord']:Log(...)` from any resource; each category goes to its own channel (or several share one), with a webhook fallback and a local `logs.txt`.
- **Rich presence.** Freeroam car, queue position, vote, grid, race position and lap, with class badges.
- **Whitelist.** Only guild members with a whitelist role can connect.
- **Admin mode.** Discord roles map to ACE groups, switched on with `/adminmode`.

## Requirements

| Resource | Type |
|---|---|
| `spz-core` | SPiceZ module |
| `spz-races` | SPiceZ module |
| `oxmysql` | third-party |

## Installation

Included in the [txAdmin recipe](https://github.com/SPiceZ21/spz-txrecipe). Manual install:

1. Download `spz-discord` from GitHub (latest release, or the repository) into your `resources` folder.
2. Add to `server.cfg`, after its requirements:

```cfg
set  spz_discord_token "..."   # bot token, private: never setr
set  spz_discord_guild "..."   # guild id (whitelist, admin mode)
setr spz_discord_appid "..."   # Discord app id for rich presence (public)
ensure spz-discord
```

Coming from spz-log / spz-rpc: remove `ensure spz-log` and `ensure spz-rpc`, delete both folders, and move your channel ids, webhooks and app id into the places below.

## Configuration

| File | What |
|---|---|
| `config.lua` | feed channels, leaderboard, guild, whitelist, admin mode, `Config.Logs` |
| `config_presence.lua` | rich presence: app id fallback, server name, Join button, art asset names, class badges |

### Logs

`Config.Logs.Channels` maps a category to a channel id. A category without one uses `default`; with no channel at all, the log goes to the category's webhook.

| Category | Sent by |
|---|---|
| `race` | track records (spz-raceline), rivals (spz-progression) |
| `duel` | ghost duels (spz-races) |
| `minigame` | minigame results |
| `admin` | spz-admin actions, `/adminmode` |
| `system` | `/testlog` |

`Config.Logs.Webhooks.race` is also where overtake clips are uploaded (screenshot-basic can only post to a webhook). `ShowIp` adds the player's IP to the player block (off by default). Logs sent from the client are off until you list categories in `ClientCategories`, and each player is limited to one per `ClientCooldownMs`.

## Commands

| Command | Who | Description |
|---|---|---|
| `/dc_leaderboard` | admin | Post the leaderboard to Discord |
| `/adminmode [on\|off]` | staff with a mapped role | Switch your admin groups on or off |
| `testlog` | server console | Send a test log |

## Exports

| Export | Side | Purpose |
|---|---|---|
| `Log(category, title, message, type, fields, src, thumbnail)` | server | post a log; `type` is `info`, `success`, `warning` or `error` |
| `Info` / `Success` / `Warning` / `Error(category, title, message, fields, src, thumbnail)` | server | the same, with the type set |
| `GetWebhook(category)` | server | the category's webhook URL |
| `Log` / `Info` / `Success` / `Warning` / `Error` | client | client logs (see `ClientCategories`) |
| `IsAdminMode(src)` | server | is this player in admin mode |

```lua
exports['spz-discord']:Log('race', 'Track Record', 'SPiceZ set 1:12.408 on Vinewood Loop', 'warning')
```

---

Part of **SPiceZ-Core** — [documentation](https://github.com/SPiceZ21/Docs) · [all modules](https://github.com/SPiceZ21/Docs/blob/main/modules/README.md)
