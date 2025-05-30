# res://scripts/InventoryUI.gd
extends MarginContainer
class_name InventoryUI
var last_slot_idx: int = -1



# —— Inspector 配置 —— 
@onready var inventory = inventory_autoload
@export var weapon_slot_node: NodePath
@export var item_slots_grid: NodePath
@export var empty_item:        Resource    # 在 Inspector 里拖入一个 .tres，里面只定义好一个空图标
@export var drop_scene: PackedScene = preload("res://scenes/item_drop.tscn")
@export var player_node: NodePath      # Inspector 拖入你的 “Player” 节点
# —— 运行时引用 —— 
@onready var weapon_slot = get_node(weapon_slot_node) as ItemSlot
@onready var grid        = get_node(item_slots_grid) as GridContainer
@onready var context_menu = $ContextMenu as PopupMenu

var item_slots := []  # 存所有背包格实例

func _ready() -> void:
	inventory.add_item_by_id("health_potion", 2)
	inventory.add_item_by_id("Sword_I", 1)
	var e = empty_item
	weapon_slot.set_item(e.id, e.icon, 0)
	_setup_weapon_slot()
	_setup_item_slots()
	_bind_inventory_signals()
	context_menu.connect("id_pressed", Callable(self, "_on_context_menu_id_pressed"))
	_refresh_ui()
	

func _setup_weapon_slot() -> void:
	# 装备槽用 -1 号
	weapon_slot.slot_index = -1
	weapon_slot.connect("slot_right_clicked", Callable(self, "_on_weapon_slot_right_clicked"))
	weapon_slot.connect("slot_clicked",       Callable(self, "_on_weapon_slot_clicked"))

func _setup_item_slots() -> void:
	item_slots.clear()
	for i in range(grid.get_child_count()):
		var node = grid.get_child(i)
		if node is ItemSlot:
			var slot = node as ItemSlot
			slot.slot_index = i
			slot.connect("slot_right_clicked", Callable(self, "_on_item_slot_right_clicked"))
			slot.connect("slot_clicked",       Callable(self, "_on_item_slot_clicked"))
			item_slots.append(slot)

func _bind_inventory_signals() -> void:
	inventory.connect("item_added",   Callable(self, "_on_inventory_changed"))
	inventory.connect("item_removed", Callable(self, "_on_inventory_changed"))
	inventory.connect("item_equipped",   Callable(self, "_on_inventory_changed"))
	inventory.connect("item_unequipped", Callable(self, "_on_inventory_changed"))

func _show_context_menu_at_mouse(slot_idx: int) -> void:
	context_menu.clear()

	if slot_idx < 0:
		# 装备槽：卸下 + 丢弃
		context_menu.add_item("卸下", 0)
	else:
		var sid = inventory.get_slot_id(slot_idx)
		if sid == "":  # 空槽不弹菜单
			return
		var itm = inventory.get_item_resource(sid)
		if itm.type == Item.ItemType.Weapon:
			context_menu.add_item("装备", 1)
		elif itm.type == Item.ItemType.Consumable:
			context_menu.add_item("使用", 2)
	context_menu.add_separator()
	context_menu.add_item("丢弃", 3)

	var mp = get_viewport().get_mouse_position()
	context_menu.popup(Rect2(mp, Vector2.ZERO))

	
func _on_context_menu_id_pressed(id: int) -> void:
	match id:
		0:
			inventory.unequip_slot(0)
		1:
			inventory.equip_slot(0, last_slot_idx)
		2:
			inventory.use_item_by_slot(last_slot_idx)
		3:
			# 区分装备槽（-1）和背包槽（>=0）
			if last_slot_idx < 0:
				# 装备槽 → 真正丢弃
				var eid = inventory.equipment[0]
				inventory.unequip_slot(0)
				_spawn_drop(eid, 1)
			else:
				# 背包槽 → 按数量丢弃
				var sid = inventory.get_slot_id(last_slot_idx)
				var cnt = inventory.get_count_by_slot(last_slot_idx)
				inventory.remove_item_by_slot(last_slot_idx, cnt)
				_spawn_drop(sid, cnt)
	_refresh_ui()
func _spawn_drop(item_id: String, count: int) -> void:
	# 1) 实例化掉落场景
	var drop = drop_scene.instantiate() as Node2D
	drop.item_id = item_id
	drop.count   = count

	# 2) 找到“世界”节点，而不是 UI 节点
	#    假设你的世界场景节点叫 World，挂在根节点下：
	var world = get_tree().current_scene as Node2D
	# —— 或者如果你在 Inspector 里 export 了一个 world_node: NodePath，就用它：
	# var world = get_node(world_node) as Node2D

	world.add_child(drop)

	# 3) 放到玩家当前位置
	var p = get_node(player_node) as Node2D
	print(p.global_position)
	drop.global_position = p.global_position
	
# —— 信号回调 —— 
func _on_item_slot_right_clicked(idx: int) -> void:
	# 记录当前右键的是哪个槽
	last_slot_idx = idx
	# 再弹出菜单
	_show_context_menu_at_mouse(idx)
func _on_item_slot_clicked(slot_idx: int) -> void:
	print("🔔 点中了背包格子：", slot_idx)
	var sid = inventory.get_slot_id(slot_idx)
	if sid == "":
		return  # 空槽直接忽略

	var itm = inventory.get_item_resource(sid)
	if itm == null:
		push_error("InventoryUI: 未找到物品资源，id=" + sid)
		return
	if itm.type == Item.ItemType.Weapon:
		inventory.equip_slot(0, slot_idx)
	elif itm.type == Item.ItemType.Consumable:
		inventory.use_item_by_slot(slot_idx)
	_refresh_ui()

func _on_weapon_slot_clicked(_idx: int) -> void:
	inventory.unequip_slot(0)
	_refresh_ui()
func _on_inventory_changed(item_id: String, index: int)-> void:
	_refresh_ui()
func _on_weapon_slot_right_clicked(_idx: int) -> void:
	last_slot_idx = -1    # 装备槽用 -1 标记
	_show_context_menu_at_mouse(-1)
# —— 刷新界面 —— 

func _refresh_ui() -> void:
	# —— 装备槽 —— 
	var id = inventory.equipment[0]
	if id != "":
		var it = inventory.get_item_resource(id)
		weapon_slot.set_item(id, it.icon, 1)
	else:
		# 用占位资源来显示“空槽”图标
		var e = empty_item as Item
		weapon_slot.set_item(e.id, e.icon, 0)

	# —— 背包格子 —— （保持不变） …
	for i in inventory.max_slots:
		var slot = item_slots[i]
		var sid  = inventory.get_slot_id(i)
		var cnt  = inventory.get_count_by_slot(i)
		if sid != "":
			var it = inventory.get_item_resource(sid)
			slot.set_item(sid, it.icon, cnt)
		else:
			slot.clear_item()


func _on_close_button_pressed() -> void:
	hide()
