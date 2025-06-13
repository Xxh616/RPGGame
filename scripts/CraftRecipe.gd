extends Resource
class_name CraftRecipe

# 1) ID of the crafted item
@export var result_id: String = ""

# 2) Material requirements: keys are material item IDs, values are required quantities
@export var needs: Dictionary = {}

# 3) Category of this recipe (e.g., "Weapon", "Consumable", "Special", etc.)
@export var category: String = ""
