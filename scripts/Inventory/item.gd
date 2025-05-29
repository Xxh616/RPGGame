# res://scripts/Item.gd
extends Resource
class_name Item
enum ItemType {
	Weapon,
	Consumable,
	Armor,
	Misc
}
# 物品的唯一标识
@export var id: String = ""
# 在界面上显示的名称
@export var name: String = ""
# 格子里显示的图标
@export var icon: Texture2D
# 最大堆叠数
@export var max_stack: int = 1
# （可选）其它属性，比如描述、价值、类型、效果脚本……
@export var description: String = ""
@export var type: ItemType = ItemType.Misc
