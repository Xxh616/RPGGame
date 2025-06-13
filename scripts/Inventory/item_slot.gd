extends MarginContainer
class_name ItemSlot

# Emitted when the slot is left-clicked
signal slot_clicked(slot_index: int)
# Emitted when the slot is right-clicked
signal slot_right_clicked(slot_index: int)

@export var slot_index: int = -1
var item_id: String = ""

@onready var icon        = $IconMargin/Icon     as TextureRect
@onready var count_label = $IconMargin/CountLabel as Label

func _ready() -> void:
	# Block mouse events from propagating and listen for GUI input
	mouse_filter = MOUSE_FILTER_STOP
	connect("gui_input", Callable(self, "_on_gui_input"))

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			# Left mouse button clicked
			print("🔵 ItemSlot left-click, idx=", slot_index)
			emit_signal("slot_clicked", slot_index)
		elif event.button_index == MouseButton.MOUSE_BUTTON_RIGHT:
			# Right mouse button clicked
			print("🔴 ItemSlot right-click, idx=", slot_index)
			emit_signal("slot_right_clicked", slot_index)

func set_item(new_item_id: String, tex: Texture2D, amount: int) -> void:
	# Set the slot’s item ID, icon texture, and display count
	item_id          = new_item_id
	icon.texture     = tex
	count_label.text = str(amount) if amount > 1 else ""

func clear_item() -> void:
	# Clear the slot (no item)
	item_id          = ""
	icon.texture     = null
	count_label.text = ""
