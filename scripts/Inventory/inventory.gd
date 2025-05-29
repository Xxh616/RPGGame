# res://scripts/Inventory.gd
extends Node
class_name Inventory

# —— 信号 —— 
signal item_added(item_id: String, slot_idx: int)
signal item_removed(item_id: String, slot_idx: int)
signal item_equipped(item_id: String, equip_idx: int)
signal item_unequipped(item_id: String, equip_idx: int)
signal item_used(item_id: String, slot_idx: int)

# —— 配置 —— 
@export var max_slots: int = 20

# —— 内部状态 —— 
var item_db: Dictionary = {}       # id -> Item 资源
var slots: Array = []              # 背包槽，每个元素是 { item_id, count } 或 null
var equipment := [""]              # 装备槽，这里只有一个武器槽，equipment[0]

func _ready() -> void:
	# 1) 扫描 res://Items 目录下的所有 .tres 资源，注册到 item_db
	var dir = DirAccess.open("res://Resources/Items/")
	if dir:
		dir.list_dir_begin()
		var fname = dir.get_next()
		while fname != "":
			if fname.ends_with(".tres"):
				var res = ResourceLoader.load("res://Resources/Items/%s" % fname)
				if res and res is Item:
					item_db[res.id] = res
			fname = dir.get_next()
		dir.list_dir_end()
	else:
		push_error("Inventory: 找不到 Items 目录")
	
	# 2) 初始化背包槽
	slots.resize(max_slots)
	for i in slots.size():
		slots[i] = null
	print("Loaded items:", item_db.keys())
	

# —— 获取资源 —— 
func get_item_resource(item_id: String) -> Item:
	return item_db.get(item_id, null)

# —— 背包查询 —— 
func get_slot_id(slot_idx: int) -> String:
	var e = slots[slot_idx]
	return "" if e == null else e.item_id

func get_count_by_slot(slot_idx: int) -> int:
	var e = slots[slot_idx]
	return  0 if e == null else e.count

# —— 添加物品 —— 
func add_item_by_id(item_id: String, count: int = 1) -> bool:
	if not item_db.has(item_id):
		push_warning("Inventory: 未知物品 id = %s" % item_id)
		return false
	var remaining = count
	# 1) 先往已有同 id 且未满的槽位填
	for i in slots.size():
		var e = slots[i]
		if e and e.item_id == item_id:
			var space = item_db[item_id].max_stack - e.count
			var to_add = min(space, remaining)
			if to_add > 0:
				e.count += to_add
				remaining -= to_add
				emit_signal("item_added", item_id, i)
			if remaining == 0:
				return true
	# 2) 再找空槽新建
	for i in slots.size():
		if remaining == 0:
			break
		if slots[i] == null:
			var to_add = min(item_db[item_id].max_stack, remaining)
			slots[i] = { "item_id": item_id, "count": to_add }
			remaining -= to_add
			emit_signal("item_added", item_id, i)
	# 3) 空间不足，回滚本次添加
	if remaining > 0:
		# 回滚已经加的那部分
		var rolled = count - remaining
		remove_item_by_slot(get_slot_of(item_id), rolled)
		return false
	return true

# —— 移除物品（按槽位） —— 
func remove_item_by_slot(slot_idx: int, count: int = 1) -> bool:
	var remaining = count
	# 从指定槽开始向后移除
	var e = slots[slot_idx]
	if e and e.count > 0:
		var to_remove = min(e.count, remaining)
		e.count -= to_remove
		remaining -= to_remove
		emit_signal("item_removed", e.item_id, slot_idx)
		if e.count == 0:
			slots[slot_idx] = null
		if remaining == 0:
			return true
	# 如果还没移完，则再遍历后续槽
	for i in range(slot_idx + 1, slots.size()):
		if remaining == 0:
			break
		e = slots[i]
		if e and e.item_id == slots[slot_idx].item_id:
			var to_remove = min(e.count, remaining)
			e.count -= to_remove
			remaining -= to_remove
			emit_signal("item_removed", e.item_id, i)
			if e.count == 0:
				slots[i] = null
	if remaining > 0:
		# 回滚已删部分
		add_item_by_id(slots[slot_idx].item_id, count - remaining)
		return false
	return true

# —— 使用（消耗）道具 —— 
func use_item_by_slot(slot_idx: int) -> bool:
	var e = slots[slot_idx]
	if e == null:
		return false
	var it = get_item_resource(e.item_id)
	if it.type != Item.ItemType.Consumable:
		return false
	if remove_item_by_slot(slot_idx, 1):
		emit_signal("item_used", e.item_id, slot_idx)
		return true
	return false

# —— 装备武器槽 —— 
func equip_slot(equip_idx: int, slot_idx: int) -> bool:
	if equip_idx < 0 or equip_idx >= equipment.size():
		return false
	var e = slots[slot_idx]
	if e == null:
		return false
	var it = get_item_resource(e.item_id)
	if it.type != Item.ItemType.Weapon:
		return false
	# 从背包扣一件
	if not remove_item_by_slot(slot_idx, 1):
		return false
	# 把原来槽里的武器放回背包
	var prev = equipment[equip_idx]
	if prev != "":
		add_item_by_id(prev, 1)
	# 装上新武器
	equipment[equip_idx] = it.id
	emit_signal("item_equipped", it.id, equip_idx)
	return true

# —— 脱下武器槽 —— 
func unequip_slot(equip_idx: int) -> bool:
	if equip_idx < 0 or equip_idx >= equipment.size():
		return false
	var id = equipment[equip_idx]
	if id == "":
		return false
	if add_item_by_id(id, 1):
		equipment[equip_idx] = ""
		emit_signal("item_unequipped", id, equip_idx)
		return true
	return false

# —— 获取某个 item_id 当前在哪个槽（用于回滚） —— 
func get_slot_of(item_id: String) -> int:
	for i in slots.size():
		if slots[i] and slots[i].item_id == item_id:
			return i
	return -1
