# Three playstyles

The same `archipelago/project_zomboid.apworld` implements three different **generation-time** location lists and reward pools. The YAML `playstyle` option chooses one. The selected Project Zomboid mod displays only the selected list in F8, and the bridge reads the server-provided slot data to ensure the styles agree.

| YAML value | F8 / tracker count | Victory check | ID |
|---|---:|---|---:|
| `base_building` | 41 | Homestead Ready | `100087` |
| `local_exploration` | 33 | Neighborhood Chronicle | `100092` |
| `road_trip` | 39 | Big City Life (Louisville) | `100027` |

## Base Building — 41 checks

Theme: **developing a homestead**. Includes survival, carpentry/cooking/mechanics/electrical preparation, building supplies, workshops, power, gardening and sentimental scavenging. Its goal **Homestead Ready** requires carrying specified construction materials together.

**Important:** The current prototype checks material possession/skill milestones. It does **not** inspect a built structure, crafted walls, actual generator installation or defended base layout. Avoid describing it as fully fledged placed-building detection until Build 42 event hooks are implemented and tested.

Reward pool favors lumber, fasteners, tools, construction supplies, generators, metalworking, gardening and some medical/food support.

## Local Exploration — 33 checks

Theme: **nearby scavenging and keepsakes**, without requiring a cross-map Louisville expedition. Includes short survival/combat milestones, basic skills, supplies, memorable collectibles, medical scavenging and local map-related checks. Its goal **Neighborhood Chronicle** requires carrying a diary, map and bandages together.

Reward pool favors food, medical supplies, communication equipment, a few weapons and practical exploration resources. **Some collectible item IDs are heuristic and may need Build 42 adjustments.**

## Road Trip — 39 checks

Theme: **prepare a vehicle and travel between towns**, then reach **Louisville**. Includes driving milestones, town discovery, vehicle/repair gear, short combat/survival checks and keepsakes. Its goal is **Big City Life**, reaching the Louisville check zone.

Reward pool favors fuel, repair supplies, tools, food, medicine and protection. **Town zone detection and the precise Louisville boundary need live verification on the target Build 42 build.**

## How rewards work

- The generated `.apworld` gives Archipelago a **fixed-size item pool** for the chosen style (one item entry per location, with repetitions).
- The **generation seed randomizes placement** of these reward entries across the multiworld and players according to the generation algorithm.
- The PowerShell bridge maps received Archipelago item IDs to Project Zomboid item identifiers and quantities, which F9 offers to be claimed manually, potentially in multiple portions.
- A different seed does **not** necessarily produce different *item types*. It shuffles where and when they arrive.
- Completing **One Last Lesson** (death) is intended to be an *optional* location check across the profiles, not a mandatory victory requirement.

## Editing a playstyle as a developer

The authoritative generator profile location IDs, pool and goal are in `archipelago/project_zomboid/profiles.py`, while all IDs/names are in `locations.py` and `items.py`. The matching Lua check filter is the `profileAllowed` table in `playstyles/<style>/ZomboidAPCheckTracker/42/media/lua/client/AP_CheckTracker.lua`.

**Whenever either side changes**, update and verify the other side, rebuild `project_zomboid.apworld`, and regenerate the multiworld.
