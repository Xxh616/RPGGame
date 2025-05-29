extends MarginContainer
class_name ItemTile

@onready var icon        = $Icon       as TextureRect
@onready var count_label = $CountLabel as Label

# 给它一个简易接口：传入 Item 资源和数量
func set_item(item: Item, count: int) -> void:
	icon.texture       = item.icon
	count_label.text = str(count) if count > 1 else ""

func clear_item() -> void:
	icon.texture       = null
	count_label.text   = ""
