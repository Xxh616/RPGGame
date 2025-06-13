extends Resource
class_name Item

enum ItemType {
	Weapon,
	Consumable,
	Material,
	Special,
	Misc
}

# Unique identifier for the item
@export var id: String = ""
# Display name in the UI
@export var name: String = ""
# Icon texture shown in inventory slot
@export var icon: Texture2D
# Maximum stack size
@export var max_stack: int = 1
# Other attributes, such as description, value, type, or effect scripts
@export var description: String = ""
@export var type: ItemType = ItemType.Misc
# Attack bonus provided by the item
@export var attack: int = 0
# Defense bonus provided by the item
@export var defense: int = 0
# Multiplier to increase visibility range (e.g., for night vision)
@export var visible_increase: float = 0
# Duration of the buff effect in seconds
@export var buff_duration: float = 10.0
