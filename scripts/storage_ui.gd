# res://scripts/Storage_UI.gd
extends Control
class_name StorageUI

const SLOTS_PER_PAGE := 14

@onready var select_storage_btn   = $TopBottomMargin/BottomMargin/HBoxContainer/UISelectButtonMargin/HBoxContainer/StorageMargin/SelectStorageButton   as Button
@onready var select_inventory_btn = $TopBottomMargin/BottomMargin/HBoxContainer/UISelectButtonMargin/HBoxContainer/InventoryMargin/SelectInventoryButton as Button

@onready var weapon_btn     = $TopBottomMargin/BottomMargin/HBoxContainer/ButtonIdentifyContainer/HBoxContainer/WeaponMargin/WeaponButton     as Button
@onready var consumable_btn = $TopBottomMargin/BottomMargin/HBoxContainer/ButtonIdentifyContainer/HBoxContainer/ConsumableMargin/ConsumableButton as Button
@onready var material_btn   = $TopBottomMargin/BottomMargin/HBoxContainer/ButtonIdentifyContainer/HBoxContainer/MaterialMargin/MaterialButton   as Button
@onready var special_btn    = $TopBottomMargin/BottomMargin/HBoxContainer/ButtonIdentifyContainer/HBoxContainer/SpecialMargin/SpecialButton    as Button

@onready var slot_container = $TopBottomMargin/BottomMargin/HBoxContainer/SlotMargin/GridContainer as GridContainer
@onready var slot_nodes     : Array = []  # Holds the SLOTS_PER_PAGE StorageSlot instances

@onready var prev_btn   = $TopBottomMargin/BottomMargin/HBoxContainer/MarginContainer/HBoxContainer/MarginContainer/Button   as Button
@onready var page_label = $TopBottomMargin/BottomMargin/HBoxContainer/MarginContainer/HBoxContainer/MarginContainer2/PageLabel as Label
@onready var next_btn   = $TopBottomMargin/BottomMargin/HBoxContainer/MarginContainer/HBoxContainer/MarginContainer3/Button   as Button
@onready var get_btn    = $TopBottomMargin/BottomMargin/HBoxContainer/MarginContainer/HBoxContainer/MarginContainer4/Button   as Button

# —— State fields —— #
var is_storage_mode : bool = true                # true = “withdraw from storage”, false = “deposit into storage”
var current_category := Item.ItemType.Misc       # Default to “Misc” category
var current_page := 0
var max_pages := 1

# Holds the list of items to display on the current page after filtering and paging:
# Each entry is a Dictionary {"item_id":String, "count":int, "icon":Texture2D, "name":String}
var page_items : Array = []

func _ready() -> void:
	# 1) Find each StorageSlot in the GridContainer and store in slot_nodes
	slot_nodes.clear()
	for chi in slot_container.get_children():
		if chi is StorageSlot:
			slot_nodes.append(chi)
	# slot_nodes should contain SLOTS_PER_PAGE StorageSlot instances

	# 2) Connect Storage/Inventory toggle buttons
	select_storage_btn.connect("pressed", Callable(self, "_on_storage_button_pressed"))
	select_inventory_btn.connect("pressed", Callable(self, "_on_inventory_button_pressed"))

	# 3) Connect category filter buttons
	

	# 4) Connect pagination buttons
	prev_btn.connect("pressed", Callable(self, "_on_prev_pressed"))
	next_btn.connect("pressed", Callable(self, "_on_next_pressed"))

	# 5) Connect each StorageSlot’s amount_changed signal
	for slot in slot_nodes:
		slot.connect("amount_changed", Callable(self, "_on_slot_amount_changed"))
	
	# 6) Connect the GetButton
	get_btn.connect("pressed", Callable(self, "_on_get_pressed"))
	
	# 7) Initialize: default to “withdraw mode” + “Weapon category”
	_update_mode_buttons()
	_select_mode(true)    # true = storage mode
	_on_category_button_pressed(Item.ItemType.Weapon)
	


#—————— Mode & category toggle callbacks ——————
func _on_storage_button_pressed() -> void:
	_select_mode(true)

func _on_inventory_button_pressed() -> void:
	_select_mode(false)

func _select_mode(to_storage: bool) -> void:
	if is_storage_mode == to_storage:
		return
	is_storage_mode = to_storage
	current_page = 0
	_update_mode_buttons()
	_refresh_page()

func _update_mode_buttons() -> void:
	# ** No pressed/modulate/add_color_override operations here **
	# Only update the text of the Get button at the bottom
	get_btn.text = "Get" if is_storage_mode else "Input"


# Unified category switch function
func _on_category_button_pressed(t: int) -> void:
	if current_category == t:
		return
	current_category = t
	current_page = 0
	_refresh_page()


#—————— Pagination ——————
func _on_prev_pressed() -> void:
	if current_page > 0:
		current_page -= 1
		_refresh_page()

func _on_next_pressed() -> void:
	if current_page < max_pages - 1:
		current_page += 1
		_refresh_page()


#—————— Callback when “transfer amount” in a slot changes (optional) ——————
func _on_slot_amount_changed(item_id: String, new_amount: int) -> void:
	# Currently no UI update needed
	pass


#—————— GetButton pressed — perform the actual transfer ——————
func _on_get_pressed() -> void:
	var removed_stack := []  # Array of { id, amt }
	for slot in slot_nodes:
		print("slot_id=%s"%slot.item_id)
		var id = slot.item_id
		var amt = slot.select_amount
		if id == "" or amt <= 0:
			continue
		if is_storage_mode:
			# Withdraw amt items from storage to inventory
			if StorageAutoload.remove_item_by_id(id, amt):
				if	inventory_autoload.add_item_by_id(id, amt) :
					removed_stack.append({ "id": id, "amt": amt })
				else:
					StorageAutoload.add_item_by_id(id, amt)
					push_warning("StorageUI: Inventory full, cannot withdraw %s × %d" % [id, amt])
			else:
				push_warning("StorageUI: Failed to withdraw %s × %d from storage" % [id, amt])
		else:
			# Deposit amt items from inventory into storage
			if inventory_autoload.remove_item(id, amt):
				StorageAutoload.add_item_by_id(id, amt)
			else:
				push_warning("StorageUI: Failed to remove %s × %d from inventory" % [id, amt])
	var store_list = StorageAutoload.get_items_by_type(current_category)
	print_debug(">>> After operation, storage items in category %s:" % str(current_category))
	for d in store_list:
		print_debug("    %s  × %d" % [d["item_id"], d["count"]])

	# 2) Print all items in inventory
	var inv_list = inventory_autoload.get_items_by_type(current_category)
	print_debug(">>> After operation, inventory items in category %s:" % str(current_category))
	for d in inv_list:
		print_debug("    %s  × %d" % [d["item_id"], d["count"]])
	# After transfer → refresh UI
	_refresh_page()


#—————— Core: refresh current page display ——————
func _refresh_page() -> void:
	var all_items: Array = []
	if is_storage_mode:
		all_items = StorageAutoload.get_items_by_type(current_category)
	else:
		all_items = inventory_autoload.get_items_by_type(current_category)

	var total = all_items.size()
	max_pages = int(ceil(float(total) / SLOTS_PER_PAGE))
	if max_pages == 0:
		max_pages = 1
	
	prev_btn.disabled = (current_page <= 0)
	next_btn.disabled = (current_page >= max_pages - 1)
	page_label.text   = " %d / %d " % [current_page + 1, max_pages]

	for i in range(SLOTS_PER_PAGE):
		var slot_node = slot_nodes[i] as StorageSlot
		var idx = current_page * SLOTS_PER_PAGE + i
		if idx < total:
			var info = all_items[idx]
			slot_node.set_slot(
				info["item_id"],
				info["icon"],
				info["name"],
				info["count"],
				is_storage_mode
			)
		else:
			# Call clear_slot to keep the slot background visible but empty inside
			slot_node._clear_slot()
		

#—————— Four category button callbacks ——————
func _on_weapon_button_pressed() -> void:
	if current_category == Item.ItemType.Weapon:
		return
	current_category = Item.ItemType.Weapon
	current_page = 0
	_refresh_page()

func _on_consumable_button_pressed() -> void:
	if current_category == Item.ItemType.Consumable:
		return
	current_category = Item.ItemType.Consumable
	current_page = 0
	_refresh_page()

func _on_material_button_pressed() -> void:
	if current_category == Item.ItemType.Material:
		return
	current_category = Item.ItemType.Material
	current_page = 0
	_refresh_page()

func _on_special_button_pressed() -> void:
	if current_category == Item.ItemType.Special:
		return
	current_category = Item.ItemType.Special
	current_page = 0
	_refresh_page()


func _on_close_button_pressed() -> void:
	hide()
