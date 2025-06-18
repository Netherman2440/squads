from enum import Enum

class Position(Enum):
    """Player position enumeration"""
    NONE = "none"
    GOALIE = "goalie"
    FIELD = "field"
    DEFENDER = "defender"
    MIDFIELDER = "midfielder"
    FORWARD = "forward" 

class UserRole(Enum):
    """User role enumeration"""
    NONE = "none"
    OWNER = "owner"
    ADMIN = "admin"
    MODERATOR = "moderator"
    MEMBER = "member"