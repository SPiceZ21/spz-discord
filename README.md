# spz-discord

> Discord race embeds, whitelist and role-based admin.

![version](https://img.shields.io/badge/version-1.2.0-ff6200) ![SPiceZ-Core](https://img.shields.io/badge/SPiceZ--Core-beta-18181b)

## Overview

Posts race results to Discord, can whitelist by guild role and grants admin by Discord role.

## Features

- Race result embeds
- Guild-role whitelist
- Role-based admin mode

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
ensure spz-discord
```

## Configuration

- `config.lua`

See the file for every option.

## Commands

| Command | Who | Description |
|---|---|---|
| `/dc_leaderboard` | admin | Post the leaderboard to Discord |

## Exports

| Export | Side |
|---|---|
| `IsAdminMode` | server |

```lua
exports["spz-discord"]:IsAdminMode(...)
```

---

Part of **SPiceZ-Core** — [documentation](https://github.com/SPiceZ21/Docs) · [all modules](https://github.com/SPiceZ21/Docs/blob/main/modules/README.md)
