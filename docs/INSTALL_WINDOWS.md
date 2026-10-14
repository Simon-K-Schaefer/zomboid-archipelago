# Windows installation tutorial — Project Zomboid Build 42 + Archipelago 0.6.8

This guide covers **a new multiworld with one of the three v1.6 playstyles**. Windows 11 is the tested target environment for file paths; actual gameplay/network success still needs testing.

## 0. What you need

- Project Zomboid **Build 42**, running **single-player** (not a PZ multiplayer server).
- **Archipelago Launcher 0.6.8** installed locally, including the ability to Generate a multiworld.
- This entire repository ZIP **extracted to a normal folder** (do not run the BAT while the ZIP is still compressed).
- Internet access to the Archipelago online room after it is hosted. Your Archipelago slot name is usually **`ZomboidPlayer`**.
- **No Python installation required to play.** Windows PowerShell 5.1 is used by the bridge.

**Before updating:** Close Project Zomboid and any older `Start-Archipelago-Bridge.bat` window. Do **not** delete your save files or `Zomboid/Lua` files.

## 1. Download and extract

On GitHub, click **Code → Download ZIP**. Right-click the ZIP in Downloads and choose **Extract All**. Open the extracted directory; it should contain `Install-Playstyle.bat`, `archipelago`, `bridge`, and `playstyles`.

## 2. Pick ONE playstyle and install it

Double-click **`Install-Playstyle.bat`** and press:

- `1` — **Base Building** (41 checks, victory: **Homestead Ready**)
- `2` — **Local Exploration** (33 checks, victory: **Neighborhood Chronicle**)
- `3` — **Road Trip** (39 checks, victory: **Louisville / Big City Life**)

The installer will:

1. Copy your chosen mod to `%USERPROFILE%\Zomboid\mods\ZomboidAPCheckTracker`.
2. Put that style's YAML in the Archipelago `Players` folder as `ZomboidPlayer.yaml`.
3. Put the *current* PowerShell bridge in `%USERPROFILE%\Zomboid\APBridge`.
4. Move prior versions of the **same mod** and Zomboid YAML to a timestamped backup under `%USERPROFILE%\Zomboid\APBackups`. It leaves your friends' YAMLs alone.

It does **not** install the `.apworld` automatically: use the Archipelago Launcher for that in step 3. It also does **not** modify your reward file, check file or Project Zomboid saves.

### When the installer cannot find `Players`

In Archipelago Launcher, open the `Players` folder from the launcher's folder/menu shortcut, or locate the directory containing your current YAML files. On some Windows installations that is `%ProgramData%\Archipelago\Players`; other installation layouts differ.

Then open **Windows PowerShell** in the extracted repository folder and run, substituting your actual path:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Install-Playstyle.ps1 -Style road_trip -PlayersDir "C:\ProgramData\Archipelago\Players"
```

Change `road_trip` to `base_building` or `local_exploration` as desired. Do not create a new `Players` folder at a guessed path when your Launcher uses an existing one elsewhere.

### Prefer manual installation?

1. Copy the entire `playstyles\<chosen style>\ZomboidAPCheckTracker` folder to `%USERPROFILE%\Zomboid\mods\` and ensure **only one** `ZomboidAPCheckTracker` mod copy is active. It must contain `42\mod.info` — not another nested folder.
2. Copy `playstyles\<chosen style>\Players\ZomboidPlayer.yaml` to Archipelago's **actual** `Players` directory (replace the previous Zomboid YAML; keep friends' YAML files).
3. Copy `bridge\Archipelago-Bridge.ps1` and `bridge\Start-Archipelago-Bridge.bat` together to `%USERPROFILE%\Zomboid\APBridge\`.

The interactive installer handles these steps and backups automatically.

## 3. Install the custom APWorld

1. Open **Archipelago Launcher 0.6.8**.
2. Use **Install APWorld**, select `archipelago\project_zomboid.apworld` inside the extracted repository, and confirm.
3. **Close and reopen the Launcher** after installing/updating the world.
4. You do **not** need to extract the `.apworld` into its internal `.py` files. That is a world plugin archive.

**Security note:** Like other custom Archipelago worlds, an `.apworld` contains executable Python code that Archipelago loads. Only install archives from a source you trust.

Archipelago's custom-world setup describes installing worlds via **Install APWorld** in the Launcher: https://ap.auztin.net/tutorial/Archipelago/setup_en

## 4. Generate a new randomized multiworld

1. Ensure your `Players` folder has **one** active `ZomboidPlayer.yaml` matching the selected mod, plus **one YAML per friend** if playing a multiworld.
2. Open Archipelago Launcher and click **Generate** (without specifying a fixed seed unless you intentionally want one).
3. Wait for the successful generation message. Find the newly generated `AP_...zip` in the Launcher's **output** folder (often `%ProgramData%\Archipelago\output`, but follow the Launcher if your install differs).
4. Upload **that generated ZIP**, *not* `project_zomboid.apworld`, to [archipelago.gg](https://archipelago.gg/) to create a room.
5. Start the room, note its **WebSocket address** (for example `wss://archipelago.gg:PORT`) and share the room link with your friends. Use the actual port shown by your room; `PORT` is not literal.

Your rewards are **randomized at generation**, not every time the game starts. A different generated seed usually produces different reward placement. Location and reward *types* remain defined by your chosen style.

**Existing 50/51-check rooms from earlier versions cannot update automatically.** v1.6 has 41, 33 or 39 locations depending on the chosen YAML, so you must **generate a new room** when switching.

## 5. Enable the mod in Project Zomboid

1. Launch **Project Zomboid Build 42**.
2. Open **Mods** and enable the single installed **Zomboid Archipelago — [Your Playstyle]** mod.
3. Start a **new single-player save** for a new multiworld. Avoid reusing an old AP save because its completed-check history belongs to that save.
4. Press **F8**. The total should match your YAML: **41** / **33** / **39**. If it does not, stop and check for duplicate/outdated mod copies.

**Note:** PZ mod availability can depend on both global mod enablement and a save's mod configuration; check the Mods screen when creating the save.

## 6. Connect the room with F10 and the bridge

1. In game, press **F10**.
2. Enter the **room's WebSocket server address**, including port, e.g. `wss://archipelago.gg:PORT`.
3. Enter **slot name** `ZomboidPlayer` (unless you deliberately renamed the YAML slot in your generation settings).
4. Enter the **room password** only if there is one. Leave blank otherwise.
5. Click **Save settings**. There is **no manual seed field** in v1.6.
6. Outside the game, double-click the **new** bridge BAT: `%USERPROFILE%\Zomboid\APBridge\Start-Archipelago-Bridge.bat`.
7. Wait for a message similar to **`Connected! Playstyle: road_trip, 39 checks ...`**. The bridge will detect the generated seed identity from the server and reject the wrong style or an old v1.5 room.
8. Press **F9** to see randomized rewards sent to you. You can choose **Loot Selected** or **Loot All**. F9 is intentionally empty until the bridge is verified and live.

You may close Archipelago Launcher after generation; the **bridge and Project Zomboid must remain running** while playing. The room itself is hosted on archipelago.gg.

## 7. Next run / changing playstyles

- **Same room and save:** Keep the same mod/slot and WebSocket address; reconnect with the bridge BAT. Your claimed reward portions are stored for that run.
- **New random seed, same style:** Generate a new multiworld ZIP, host a new room, create a **new Project Zomboid save**, and update F10 with its new server address. No manual seed entry.
- **Different style:** Rerun `Install-Playstyle.bat`, choose the new style, install/check `.apworld`, generate a **new** room, start a **new save**, and connect to it.
- **Friends:** Keep their YAMLs in the `Players` directory; they must join using the slot names from the generated multiworld. Only the Zomboid player needs the Zomboid mod and bridge.

**Do not manually delete or rename `APCheckTracker_rewards.txt`, `APCheckTracker_locations.txt`, or `APCheckTracker_room.txt`.** The bridge and mod are intended to verify the active run automatically. If old rewards still show before bridge connection, report it as a bug with the version and reproduction steps.

Continue to [Troubleshooting](TROUBLESHOOTING.md).
