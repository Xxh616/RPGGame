extends Resource
class_name DropInfo

# The Item resource (.tres) representing the item to drop
@export var item: Item      = null

# Drop probability (0.0 to 1.0)
@export var chance: float   = 1.0

# Quantity to drop
@export var count: int      = 1

# Offset relative to the enemy’s position when spawning the drop (default is (0,0))
@export var offset: Vector2 = Vector2.ZERO
