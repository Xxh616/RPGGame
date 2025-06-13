extends MarginContainer
class_name InventoryUI

var last_slot_idx: int = -1

# —— Inspector Configuration —— 
@onready var inventory = inventory_autoload
@export var weapon_slot_node: NodePath
@export var item_slots_grid: NodePath
@export var empty_item: Resource          # Drag a .tres with an empty icon in the Inspector
@export var drop_scene: PackedScene = preload("res://scenes/item_drop.tscn")
@export var player_node: NodePath         # Drag your “Player” node in the Inspector

# —— Runtime References —— 
@onready var weapon_slot   = get_node(weapon_slot_node) as ItemSlot
@onready var grid          = get_node(item_slots_grid) as GridContainer
@onready var context_menu  = $ContextMenu as PopupMenu
@onready var attack_label      = $InventoryMargin/VBoxSplit/BottomMargin/HBoxSplit/LeftMargin/LeftVBox/AttributeMargin/AttributeVBox/AttackMargin/AttackLabel as Label
@onready var statpoints_label = $InventoryMargin/VBoxSplit/BottomMargin/HBoxSplit/LeftMargin/LeftVBox/AttributeMargin/AttributeVBox/StatPointsMargin/StatPointsLabel as Label
@onready var defense_label     = $InventoryMargin/VBoxSplit/BottomMargin/HBoxSplit/LeftMargin/LeftVBox/AttributeMargin/AttributeVBox/DefenseMargin/DefenseLabel as Label
@onready var attack_add_button  = $InventoryMargin/VBoxSplit/BottomMargin/HBoxSplit/LeftMargin/LeftVBox/AttributeMargin/AttributeVBox/AttackMargin/AttackAddButton as Button
@onready var defense_add_button = $InventoryMargin/VBoxSplit/BottomMargin/HBoxSplit/LeftMargin/LeftVBox/AttributeMargin/AttributeVBox/DefenseMargin/DefenseAddButton as Button

var item_slots := []  # Holds all inventory slot instances

func _ready() -> void:
	var e = empty_item
	weapon_slot.set_item(e.id, e.icon, 0)
	_setup_weapon_slot()
	_setup_item_slots()
	_bind_inventory_signals()
	context_menu.connect("id_pressed", Callable(self, "_on_context_menu_id_pressed"))
	_refresh_ui()

func _setup_weapon_slot() -> void:
	# Use -1 as the index for the equipment slot
	weapon_slot.slot_index = -1
	weapon_slot.connect("slot_right_clicked", Callable(self, "_on_weapon_slot_right_clicked"))
	weapon_slot.connect("slot_clicked",        Callable(self, "_on_weapon_slot_clicked"))

func _setup_item_slots() -> void:
	item_slots.clear()
	for i in range(grid.get_child_count()):
		var node = grid.get_child(i)
		if node is ItemSlot:
			var slot = node as ItemSlot
			slot.slot_index = i
			slot.connect("slot_right_clicked", Callable(self, "_on_item_slot_right_clicked"))
			slot.connect("slot_clicked",        Callable(self, "_on_item_slot_clicked"))
			item_slots.append(slot)

func _bind_inventory_signals() -> void:
	inventory.connect("item_added",      Callable(self, "_on_inventory_changed"))
	inventory.connect("item_removed",    Callable(self, "_on_inventory_changed"))
	inventory.connect("item_equipped",   Callable(self, "_on_inventory_changed"))
	inventory.connect("item_unequipped", Callable(self, "_on_inventory_changed"))
	inventory.connect("inventory_updated", Callable(self, "_on_inventory_updated"))

func _show_context_menu_at_mouse(slot_idx: int) -> void:
	context_menu.clear()

	if slot_idx < 0:
		# Equipment slot: Unequip + Drop
		context_menu.add_item("Unequip", 0)
	else:
		var sid = inventory.get_slot_id(slot_idx)
		if sid == "":  # Don't show menu for empty slot
			return
		var itm = inventory.get_item_resource(sid)
		if itm.type == Item.ItemType.Weapon:
			context_menu.add_item("Equip", 1)
		elif itm.type == Item.ItemType.Consumable:
			context_menu.add_item("Use", 2)
	context_menu.add_separator()
	context_menu.add_item("Drop", 3)

	var mp = get_viewport().get_mouse_position()
	context_menu.popup(Rect2(mp, Vector2.ZERO))

func _on_context_menu_id_pressed(id: int) -> void:
	match id:
		0:
			# Unequip
			var wid = inventory.equipment[0]
			if wid != "":
				var w = inventory.get_item_resource(wid)
				global.player_attack  -= w.attack
				global.player_defense -= w.defense
			inventory.unequip_slot(0)
		1:
			# Equip selected weapon
			var sid = inventory.get_slot_id(last_slot_idx)
			var w   = inventory.get_item_resource(sid)
			global.player_attack  += w.attack
			global.player_defense += w.defense
			inventory.equip_slot(0, last_slot_idx)
		2:
			# Use consumable
			var sid = inventory.get_slot_id(last_slot_idx)
			if sid != "":
				var itm = inventory.get_item_resource(sid)
				if itm and itm.id == "Power Potion":
					_apply_attack_potion_buff(itm)
				if itm and itm.id == "Defense Potion":
					_apply_attack_potion_buff(itm)
				if itm and itm.id == "Night Vision Potion":
					_apply_attack_potion_buff(itm)
				if itm and itm.id == "Attribute Potion":
					global.player_status += 1
				if itm and itm.id == "Health Potion":
					if global.player_health + 20 >= global.player_max_health:
						global.player_health = global.player_max_health
					else:
						global.player_health += 20
			inventory.use_item_by_slot(last_slot_idx)
		3:
			# Drop item: distinguish equipment slot (-1) vs inventory slot (>=0)
			if last_slot_idx < 0:
				# Equipment slot → actual drop
				var eid = inventory.equipment[0]
				inventory.unequip_slot(0)
				_spawn_drop(eid, 1)
			else:
				# Inventory slot → drop entire stack
				var sid = inventory.get_slot_id(last_slot_idx)
				var cnt = inventory.get_count_by_slot(last_slot_idx)
				inventory.remove_item_by_slot(last_slot_idx, cnt)
				_spawn_drop(sid, cnt)

	_refresh_ui()

func _spawn_drop(item_id: String, count: int) -> void:
	# 1) Instantiate the drop scene
	var drop = drop_scene.instantiate() as Node2D
	drop.item_id = item_id
	drop.count   = count

	# 2) Find the 'World' node, not a UI node
	#    Assume your world scene node is named 'World' under the root:
	var world = get_tree().current_scene as Node2D
	# —— Or if you exported a world_node: NodePath in the Inspector, use that:
	# var world = get_node(world_node) as Node2D

	world.add_child(drop)

	# 3) Place at the player's current position
	var p = get_node(player_node) as Node2D
	drop.global_position = p.global_position

# —— Signal Callbacks —— 
func _on_item_slot_right_clicked(idx: int) -> void:
	# Record which slot was right-clicked
	last_slot_idx = idx
	# Then show the context menu again
	_show_context_menu_at_mouse(idx)

func _on_item_slot_clicked(slot_idx: int) -> void:
	var sid = inventory.get_slot_id(slot_idx)
	if sid == "":
		return  # Ignore empty slots

	var itm = inventory.get_item_resource(sid)
	if itm == null:
		push_error("InventoryUI: Item resource not found, id=" + sid)
		return

	if itm.type == Item.ItemType.Weapon:
		# Equip weapon on click
		global.player_attack  += itm.attack
		global.player_defense += itm.defense
		inventory.equip_slot(0, slot_idx)
	elif itm.type == Item.ItemType.Consumable:
		# Use consumable on click
		inventory.use_item_by_slot(slot_idx)
		if itm.id == "health_potion":
			_apply_attack_potion_buff(itm)

	_refresh_ui()

func _on_weapon_slot_clicked(_idx: int) -> void:
	# Unequip weapon when weapon slot is clicked
	var wid = inventory.equipment[0]
	if wid != "":
		var w = inventory.get_item_resource(wid)
		global.player_attack  -= w.attack
		global.player_defense -= w.defense
	inventory.unequip_slot(0)
	_refresh_ui()

func _on_inventory_changed(item_id: String, index: int) -> void:
	_refresh_ui()

func _on_inventory_updated() -> void:
	_refresh_ui()

func _on_weapon_slot_right_clicked(_idx: int) -> void:
	last_slot_idx = -1  # Use -1 to mark equipment slot
	_show_context_menu_at_mouse(-1)

# —— Refresh UI —— 
func _refresh_ui() -> void:
	if global.player_status <= 0:
		attack_add_button.disabled  = true
		defense_add_button.disabled = true
	else:
		attack_add_button.disabled  = false
		defense_add_button.disabled = false

	attack_label.text     = "%d" % global.player_attack
	defense_label.text    = "%d" % global.player_defense
	statpoints_label.text = "%d" % global.player_status

	# —— Equipment Slot
	var id = inventory.equipment[0]
	if id != "":
		var it = inventory.get_item_resource(id)
		weapon_slot.set_item(id, it.icon, 1)
	else:
		# Use placeholder resource to show empty slot icon
		var e = empty_item as Item
		weapon_slot.set_item(e.id, e.icon, 0)

	# —— Inventory Slots
	# Originally wrote `for i in inventory.max_slots:`, which makes i a number rather than a range
	# Correct syntax: for i in range(inventory.max_slots):
	for i in range(inventory.max_slots):
		var slot = item_slots[i]
		var sid  = inventory.get_slot_id(i)
		var cnt  = inventory.get_count_by_slot(i)
		if sid != "" and cnt != 0:
			var it = inventory.get_item_resource(sid)
			slot.set_item(sid, it.icon, cnt)
		else:
			slot.clear_item()

func _update_player_stats() -> void:
	var wid = inventory.equipment[0]
	if wid != "":
		var w = inventory.get_item_resource(wid)
		global.player_attack  += w.attack
		global.player_defense += w.defense

func _on_close_button_pressed() -> void:
	hide()

func _on_attack_add_button_pressed() -> void:
	if global.player_status > 0:
		global.player_attack  += 1
		global.player_status  -= 1
		_refresh_ui()

func _on_defense_add_button_pressed() -> void:
	if global.player_status > 0:
		global.player_defense += 1
		global.player_status  -= 1
		_refresh_ui()

func _apply_attack_potion_buff(itm: Item) -> void:
	var bonus    = itm.attack
	var duration = itm.buff_duration
	var defense  = itm.defense
	var increase_visible = itm.visible_increase

	# 1) Apply buff immediately
	global.player_attack  += bonus
	global.player_attack  += defense
	global.visible_range.x *= increase_visible
	global.visible_range.y *= increase_visible
	_refresh_ui()

	# 2) Wait asynchronously
	await get_tree().create_timer(duration).timeout

	# 3) Revert buff when duration ends
	global.player_attack  -= bonus
	global.player_defense -= defense
	global.visible_range.x /= increase_visible
	global.visible_range.y /= increase_visible
	_refresh_ui()

func _on_organize_pressed() -> void:
	# Call Inventory singleton to organize data directly
	inventory_autoload.organize_inventory()
	_refresh_ui()
