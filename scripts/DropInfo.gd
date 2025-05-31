# res://scripts/DropInfo.gd
extends Resource
class_name DropInfo

# —— 要掉落的物品资源（.tres），类型为 Item 资源 —— 
@export var item: Item      = null

# —— 掉落概率（0.0~1.0） —— 
@export var chance: float   = 1.0

# —— 掉落时的数量 —— 
@export var count: int      = 1

# —— 掉落偏移量（相对敌人位置），默认 (0,0) —— 
@export var offset: Vector2 = Vector2.ZERO
