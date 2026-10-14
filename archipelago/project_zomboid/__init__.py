"""Experimental Project Zomboid B42 multiworld with three gameplay profiles."""
from BaseClasses import Item, ItemClassification, Location, Region
from worlds.AutoWorld import World
from .locations import LOCATIONS
from .items import ITEMS
from .options import ProjectZomboidOptions
from .profiles import PROFILES, PROFILE_NAMES

NAMES_BY_ID = {v: k for k, v in LOCATIONS.items()}

class ProjectZomboidItem(Item):
    game = "Project Zomboid"

class ProjectZomboidLocation(Location):
    game = "Project Zomboid"

class ProjectZomboidWorld(World):
    game = "Project Zomboid"
    options_dataclass = ProjectZomboidOptions
    options: ProjectZomboidOptions
    item_name_to_id = ITEMS
    location_name_to_id = LOCATIONS
    required_client_version = (0, 6, 0)

    def active_profile(self):
        return PROFILES[PROFILE_NAMES[self.options.playstyle.value]]

    def create_regions(self):
        menu = Region("Menu", self.player, self.multiworld)
        self.multiworld.regions.append(menu)
        for location_id in self.active_profile()["locations"]:
            menu.locations.append(ProjectZomboidLocation(
                self.player, NAMES_BY_ID[location_id], location_id, menu))

    def create_item(self, name):
        return ProjectZomboidItem(name, ItemClassification.filler, ITEMS[name], self.player)

    def create_items(self):
        pool = self.active_profile()["pool"]
        for name in pool:
            self.multiworld.itempool.append(self.create_item(name))

    def set_rules(self):
        # Completion is client-driven: bridge sends StatusUpdate(CLIENT_GOAL)
        # once the chosen goal location is checked AND acknowledged by the server.
        self.multiworld.completion_condition[self.player] = lambda state: True

    def fill_slot_data(self):
        profile = self.active_profile()
        return {"bridge_version": 3,
                "playstyle": PROFILE_NAMES[self.options.playstyle.value],
                "location_ids": profile["locations"],
                "goal_location_id": profile["goal"],
                "check_count": len(profile["locations"])}
