# res://scripts/CraftRecipe.gd
extends Resource
class_name CraftRecipe

# 1) 合成出的物品 ID
@export var result_id: String = ""

# 2) 材料需求，用一个 Dictionary：键＝材料 item_id，值＝所需数量
@export var needs: Dictionary = {}

# 3) 这个配方所属分类，可选值 “Weapon”、“Consumable”、“Special”…… 
@export var category: String = ""
