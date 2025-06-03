# res://scripts/Inventory.gd
extends Node
class_name Inventory

# —— 信号 —— 
signal item_added(item_id: String, slot_idx: int)
signal item_removed(item_id: String, slot_idx: int)
signal item_equipped(item_id: String, equip_idx: int)
signal item_unequipped(item_id: String, equip_idx: int)
signal item_used(item_id: String, slot_idx: int)
signal item_discarded(item_id: String, equip_idx: int)
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
	# 如果索引不合法，或该槽位本来就为空，则直接返回 false
	if slot_idx < 0 or slot_idx >= slots.size():
		return false
	if slots[slot_idx] == null:
		return false

	# 1) 记录“要取出的物品 ID”，作为后续遍历的目标
	var target_id: String = slots[slot_idx].item_id
	var remaining := count

	# 2) 从指定槽开始取
	var e = slots[slot_idx]
	if e and e.count > 0:
		var to_remove = min(e.count, remaining)
		e.count -= to_remove
		remaining -= to_remove
		emit_signal("item_removed", e.item_id, slot_idx)
		if e.count == 0:
			# 把这一格清空
			slots[slot_idx] = null
		if remaining == 0:
			return true


	# 3) 如果还没取完，就继续往后找“同样 ID 的槽”取
	for i in range(slot_idx + 1, slots.size()):
		if remaining == 0:
			break
		e = slots[i]
		# 这里改成用 target_id 比较，而不是 slots[slot_idx].item_id
		if e != null and e.item_id == target_id:
			var to_remove2 = min(e.count, remaining)
			e.count -= to_remove2
			remaining -= to_remove2
			emit_signal("item_removed", e.item_id, i)
			if e.count == 0:
				slots[i] = null
	

	# 4) 如果最终还有剩余没拿完，就回滚之前已经删除掉的那部分
	if remaining > 0:
		# 用之前记录的 target_id 回滚
		add_item_by_id(target_id, count - remaining)
		return false

	return true


func discard_equip_slot(equip_idx: int) -> bool:
	if equip_idx < 0 or equip_idx >= equipment.size():
		return false
	var id = equipment[equip_idx]
	if id == "":
		return false
	# 直接清空，不放回背包
	equipment[equip_idx] = ""
	emit_signal("item_discarded", id, equip_idx)
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

func has_item(item_id: String, need_count: int) -> bool:
	var total = get_count_by_id(item_id)
	return total >= need_count
func remove_item(item_id: String, count: int) -> bool:
	# 调用现有的 remove_item_by_slot 来实现。先找一个槽包含该 id，然后从那个槽开始扣
	var slot_idx = get_slot_of(item_id)
	if slot_idx < 0:
		return false
	return remove_item_by_slot(slot_idx, count)
func add_item(item_id: String, count: int) -> bool:
	return add_item_by_id(item_id, count)
func get_count_by_id(item_id: String) -> int:
	var sum = 0
	for i in slots.size():
		var e = slots[i]
		if e and e.item_id == item_id:
			sum += int(e.count)
	return sum
func get_items_by_type(t: int) -> Array:
	var result : Array = []
	for id in item_db.keys():
		var res = item_db[id]
		if res.type != t:
			continue
		var total_in_backpack : int = 0
		for i in range(slots.size()):
			var entry = slots[i]
			if entry != null and entry.has("item_id") and entry.item_id == id:
				total_in_backpack += int(entry.count)

		if total_in_backpack <= 0:
			continue
		result.append({
			"item_id": id,
			"count": total_in_backpack,
			"icon": res.icon,
			"name": res.name
		})
		print("get_items_by_type(", t, ") → ", result)
	return result
