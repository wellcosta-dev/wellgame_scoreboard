# wellgame_scoreboard

Wellcosta / Wellgame scoreboard for FiveM + QBCore.

Port of the MTA `v4_scoreboard` layout (hold **TAB**): player list with ID / Név / Szint / Ping, fill bar, scroll, admin-duty rows, AFK timer.

The MTA folder `v4_scoreboard` is **reference only** and must not be started.

## Controls

| Action | Default |
|--------|---------|
| Hold open | `TAB` |
| Scroll | Mouse wheel |

## Notes

- `qb-scoreboard` (illegal-action status) is a different resource and is left untouched.
- Admin duty: `Player(src).state.adminDuty = true`, or QBCore `optin` when `Config.OptinAsAdminDuty`.
