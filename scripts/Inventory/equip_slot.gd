extends ItemSlot
class_name EquipSlot

# When the player clicks an equip slot, emit this signal with the slot index and the current item ID ("" means unequip)
signal equip_changed(slot_index: int, item_id: String)

func _ready() -> void:
	# Call the parent _ready() to initialize mouse input listening
	super._ready()
	# Connect our own slot_clicked signal to the handler
	connect("slot_clicked", Callable(self, "_on_slot_clicked"))

func _on_slot_clicked(clicked_index: int) -> void:
	# After clicking, emit equip_changed with the slot index and the stored item_id
	# Note: ItemSlot already assigns self.item_id in set_item()
	emit_signal("equip_changed", slot_index, item_id)
