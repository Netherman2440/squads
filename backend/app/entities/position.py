from enum import Enum

class Position(Enum):
    NONE = "none"
    GOALIE = "goalie"
    FIELD = "field"
    DEFENDER = "defender"
    MIDFIELDER = "midfielder"
    FORWARD = "forward"