# Troubleshooting and known limitations

If something fails, record your selected **playstyle**, F8 achievement total, Archipelago **room/server address without its password**, and the **error text shown in the PowerShell bridge**. Do not publish passwords or private save files.

## F8 says 41/33/39 but Archipelago's tracker says something else

This is usually an **old generated room** or wrong YAML during generation. Check:

1. You installed `archipelago/project_zomboid.apworld` from **this** release using Archipelago Launcher's **Install APWorld**.
2. You restarted the Launcher afterwards.
3. The `Players` folder contained the desired playstyle's **`ZomboidPlayer.yaml`** when you clicked **Generate**.
4. You uploaded the **newly generated multiworld ZIP**, not an older output file and not the `.apworld`.
5. You are connected to the matching **new room**.

Expected tracker totals: **Base Building 41**, **Local Exploration 33**, **Road Trip 39**. Old 50- or 51-location rooms were generated with older world definitions and cannot be retroactively updated.

## F8 has an old achievement list

Project Zomboid may be loading a duplicate/older `ZomboidAPCheckTracker` mod, or your save was created with an older mod selected. Use the installer and verify that only the chosen style is enabled for that save. The active mod folder should be `%USERPROFILE%\Zomboid\mods\ZomboidAPCheckTracker\42\mod.info`. The installer moves the replaced mod **outside** `mods` into `Zomboid\APBackups` so it should no longer load. Check whether you have a second Workshop or differently named local copy.

## F9 shows rewards before the bridge connects

It **should not** in v1.6. Stop and report this as a bug; do **not** delete the reward files to mask it. The Lua stash requires a live bridge heartbeat, verified session, and matching room key. This behavior is not yet verified in game on every Build 42 build. Ensure both the **mod and bridge** are v1.6.

## F9 is empty AFTER connection

That can be legitimate if the room has not sent any items to your Zomboid slot. Check for `Connected!` and `Received ... item entries` in the bridge console, then reopen F9. The bridge should verify the server's seed identity. Don't use an older BAT from a previous ZIP.

If it remains empty after known incoming Archipelago rewards, capture the redacted bridge log and report the item IDs (not password). Unsupported item IDs or Build 42 item-name mismatches may require a fix.

## `Wrong Project Zomboid mod loaded` in bridge

The generated room's YAML selected one style, but the mod in PZ is another style (or is too old to export the style marker). Close the bridge, select the matching mod via `Install-Playstyle.bat`, enable that mod in PZ, start/reload a save and run the new bridge. **Changing the YAML now will not change the already generated room.**

## `This room uses an older APWorld`

Install the v1.6 world, restart Launcher, **generate and host a new room**. Old rooms cannot become new v1.6 rooms.

## `ConnectionRefused`, timeout, can't connect

Check the **actual** room's WebSocket address and port in F10 (`wss://host:port`), exact player slot name, and optional room password. The room link in a browser is **not** necessarily the WebSocket server address. Ensure the room is running. Try the Windows command below with the actual domain and port:

```powershell
Test-NetConnection archipelago.gg -Port YOUR_ROOM_PORT
```

If the network port succeeds but login fails, share the bridge's error text, excluding passwords. For a localhost development server `ws://127.0.0.1:PORT` may be used; **remote rooms require `wss://`**.

## Double-clicking `Install-Playstyle.bat` fails or cannot find `Players`

Keep the downloaded repository ZIP **fully extracted**. If Archipelago is installed in a non-standard location, supply `-PlayersDir` explicitly as explained in [INSTALL_WINDOWS.md](INSTALL_WINDOWS.md#when-the-installer-cannot-find-players). Do not manually delete friends' YAML files. If you changed the slot name from `ZomboidPlayer`, the supplied interactive installer currently assumes the default slot; see manual installation instructions instead.

## F8 check completed but the tracker did not update

Wait for the bridge to show `Connected!` and `Sent ... checks`. If the bridge was started before the game produced its profile file, it should complain or reconnect; verify the selected playstyle matches the room. Ensure the location is one of the 41/33/39 IDs enabled for your YAML. For a fresh run, use a fresh PZ save; check state is partly save-dependent.

## Known limitations

- **Build 42 item IDs:** Some reward IDs or rare collectible names may have changed. F9 may list an item that fails to spawn.
- **Exploration zones:** Town and Louisville detection rely on coordinates/area definitions and need in-game verification.
- **Base Building:** Checks possession of supplies rather than actual placed walls, constructed furniture, powered generators or defended fortifications.
- **Single-player:** The mod's gameplay hooks are intended for **single-player Zomboid**. Archipelago can connect to multiworlds with friends in other supported games.
- **Per-run storage:** The bridge's rewards use a server-reported seed identity and slot after connecting. Previous Zomboid **save-wide achievement progress** is not a substitute for making a new save in a new seed.
- **Password handling:** F10's room settings are written as local text under `Zomboid\Lua`. Keep that file private.
- **Fixed reward inventories:** Playstyles adjust item pools/locations; generation shuffles locations/items, not the available reward names/quantities within the selected pool.
- **No native Archipelago PZ client:** This is a Lua + PowerShell bridge prototype, not a full certified game integration.

Found a reproducible bug? Please tell us.
