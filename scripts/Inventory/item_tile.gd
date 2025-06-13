extends MarginContainer
class_name ItemTile

@onready var icon        = $Icon       as TextureRect
@onready var count_label = $CountLabel as Label

# Provide a simple interface: pass in an Item resource and the count
func set_item(item: Item, count: int) -> void:
	icon.texture      = item.icon
	count_label.text  = str(count) if count > 1 else ""

func clear_item() -> void:
	# Clear the icon and count display
	icon.texture      = null
	count_label.text  = ""
