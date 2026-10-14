# Project Zomboid × Archipelago — Three Playstyles (Build 42)

An **experimental, community-style Archipelago integration** for **Project Zomboid Build 42 (Windows, single-player)**. Includes a custom Archipelago game (`.apworld`), a Project Zomboid Lua mod, three YAML presets, and a **PowerShell WebSocket bridge**.

> **Status: experimental** This is not an official Project Zomboid or Archipelago project.

## Choose a playstyle

| Playstyle | Archipelago checks | Victory objective | What you'll do |
|---|---:|---|---|
| **Base Building** | **41** | **Homestead Ready** (ID 100087) | Collect building materials, tools, supplies and improve homestead skills |
| **Local Exploration** | **33** | **Neighborhood Chronicle** (ID 100092) | Scavenge local buildings and collect keepsakes, a map, and medical essentials |
| **Road Trip** | **39** | **Big City Life** (ID 100027) | Prepare a vehicle, explore multiple towns and reach Louisville |

You install **one matching mod + YAML** per Project Zomboid slot. All three share the **same `.apworld`** and bridge. A fresh randomized Archipelago seed assigns rewards to the enabled checks; new seeds do *not* require changing a manual seed number in F10.

### Download / get started

1. On GitHub, choose **Code → Download ZIP**, then **Extract All**. (If you cloned this repository, skip extraction.)
2. Close Project Zomboid and any running Archipelago bridge.
3. Double-click **`Install-Playstyle.bat`** and choose **1, 2 or 3**. The installer backs up the previous matching mod and Zomboid slot YAML, and installs the new bridge. **It does not delete your reward/check files or your saves.**
4. In **Archipelago Launcher 0.6.8**, choose **Install APWorld** and select `archipelago/project_zomboid.apworld` from this repository. Restart the launcher.
5. Click **Generate** to make a **new** multiworld using the installed `ZomboidPlayer.yaml` and your friends' YAML files. Upload the generated multiworld ZIP to [archipelago.gg](https://archipelago.gg/).
6. In Project Zomboid Build 42, enable the newly installed **Zomboid Archipelago** mod. Start a **new single-player save** for a new multiworld, open **F8** to confirm the check count, and use **F10** to save the room's WebSocket server address and your slot name (usually `ZomboidPlayer`).
7. Run `%USERPROFILE%\Zomboid\APBridge\Start-Archipelago-Bridge.bat`. Wait for **Connected!**, then use **F9** to view and manually claim randomized rewards.

**If the installer cannot find your Archipelago `Players` folder**, follow [the Windows installation guide](docs/INSTALL_WINDOWS.md#when-the-installer-cannot-find-players) to give its actual path.

**[Troubleshooting](docs/TROUBLESHOOTING.md)**  
**[Playstyle/check design](docs/PLAYSTYLES.md)** 

## Keyboard controls

| Key | Action |
|---|---|
| **F8** | Achievement/check list for the selected playstyle |
| **F9** | Manual reward stash; only available with a live verified room connection |
| **F10** | Room server URL, slot name and optional password |

## Important rules

- The `.apworld`, YAML and mod **must be the same release**; choose **only one** playstyle for `ZomboidPlayer` in each generated room.
- **Changing playstyle or location count requires generating a new multiworld and hosting a new room**. A running tracker cannot add/remove locations.
- A new seed randomizes **reward placement**, not the menu of possible reward types. Each playstyle has its own pool.
- The **Bridge connects the Zomboid slot** to the Archipelago room. Project Zomboid itself remains single-player; the Archipelago *multiworld* can include friends' games.
- **Base Building does not detect placed player-built walls/furniture**; its current objectives check carried materials/tools/skills. See [limitations](docs/TROUBLESHOOTING.md#known-limitations).


## License

Disclaimer: Code was partially generated or refined with generative AI (GPT-6)

MIT License — see [LICENSE](LICENSE). Third-party names belong to their respective owners.
