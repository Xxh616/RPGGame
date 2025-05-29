# res://scripts/ItemSlot.gd
extends MarginContainer
class_name ItemSlot

signal slot_clicked(slot_index: int)
signal slot_right_clicked(slot_index: int)

@export var slot_index: int = -1
var item_id: String = ""

@onready var icon        = $IconMargin/Icon     as TextureRect
@onready var count_label = $IconMargin/CountLabel  as Label

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	connect("gui_input", Callable(self, "_on_gui_input"))

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			print("🔵 ItemSlot 左键, idx=", slot_index)
			emit_signal("slot_clicked", slot_index)
		elif event.button_index == MouseButton.MOUSE_BUTTON_RIGHT:
			print("🔴 ItemSlot 右键, idx=", slot_index)
			emit_signal("slot_right_clicked", slot_index)

func set_item(new_item_id: String, tex: Texture2D, amount: int) -> void:
	item_id           = new_item_id
	icon.texture      = tex
	count_label.text  = str(amount) if amount > 1 else ""

func clear_item() -> void:
	item_id           = ""
	icon.texture      = null
	count_label.text  = ""
