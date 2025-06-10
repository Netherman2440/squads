from enum import Enum

class Position(Enum):
    """Player position enumeration"""
    NONE = "none"
    GOALIE = "goalie"
    FIELD = "field"
    DEFENDER = "defender"
    MIDFIELDER = "midfielder"
    FORWARD = "forward" 