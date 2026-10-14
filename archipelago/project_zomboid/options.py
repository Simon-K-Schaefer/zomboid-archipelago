from dataclasses import dataclass
from Options import Choice, PerGameCommonOptions

class Playstyle(Choice):
    """Selects the generated checks, item pool, and victory objective."""
    display_name = "Playstyle"
    option_base_building = 0
    option_local_exploration = 1
    option_road_trip = 2
    default = 2

@dataclass
class ProjectZomboidOptions(PerGameCommonOptions):
    playstyle: Playstyle
