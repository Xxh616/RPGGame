# res://scripts/Storage.gd
extends Node
class_name Storage

# —— 信号（可选，用于 UI 监听） —— 
signal item_stored(item_id: String, count: int)    # 存入时发
signal item_removed(item_id: String, count: int)   # 取出时发

# —— 配置：一个最大槽位数（可按需求改） —— 
@export var max_slots: int = 100

# —— 存储每个 item_id 在储藏箱中的实际总数量 —— 
var storage_counts: Dictionary = {}

# —— 内部状态 —— 
# item_db: id:String -> Item 资源
var item_db: Dictionary = {}

# slots: 储藏槽，每个元素要么 null，要么是一个 { "item_id": String, "count": int } 的字典
var slots: Array = []            

func _ready() -> void:
	# 1) 扫描 res://Resources/Items 下所有 .tres，将 Item 资源加载到 item_db
	var dir = DirAccess.open("res://Resources/Items/")
	if dir:
		dir.list_dir_begin()
		var fname = dir.get_next()
		while fname != "":
			if fname.ends_with(".tres"):
				var r = ResourceLoader.load("res://Resources/Items/%s" % fname)
				if r and r is Item:
					item_db[r.id] = r
				
			
			fname = dir.get_next()
		
		dir.list_dir_end()
	else:
		push_error("Storage: 找不到 Items 目录")
	

	# 2) 初始化 slots 数组
	slots.resize(max_slots)
	for i in range(slots.size()):
		slots[i] = null
	

	# 3) （可选）调试时预先给仓库放几件道具，方便测试
	#    例如：让仓库里先有一把 Sword_I 和 5 个 First-grade ore
	storage_counts["Sword_I"] = 1
	storage_counts["First-grade ore"] = 5
	# 同时把它们也放到 slots 里，保证槽位数据同步
	slots[0] = {"item_id": "Sword_I", "count": 1}
	slots[1] = {"item_id": "First-grade ore", "count": 5}

	# debug 输出一下
	print("Storage loaded items:", item_db.keys())
	print("Initial storage_counts:", storage_counts)


# —— 获取资源 —— 
func get_item_resource(item_id: String) -> Item:
	return item_db.get(item_id, null)


# —— 根据 item_id 找到它当前在储藏箱里最靠前的槽位 —— 
func get_slot_of(item_id: String) -> int:
	for i in range(slots.size()):
		var e = slots[i]
		if e and e.item_id == item_id:
			return i
		
	
	return -1


# —— 存入操作：将某个物品存入储藏箱 —— 
func add_item_by_id(item_id: String, count: int = 1) -> bool:
	if not item_db.has(item_id):
		push_warning("Storage: 未知物品 id = %s" % item_id)
		return false
	

	var remaining = count

	# 1) 先往已有同 id 且未满的槽位叠加
	for i in range(slots.size()):
		if remaining <= 0:
			break
		
		var e = slots[i]
		if e and e.item_id == item_id:
			var space = item_db[item_id].max_stack - e.count
			var to_add = min(space, remaining)
			if to_add > 0:
				e.count += to_add
				remaining -= to_add
				# 每次叠加要同时更新 storage_counts
				if not storage_counts.has(item_id):
					storage_counts[item_id] = 0
				
				storage_counts[item_id] += to_add

				emit_signal("item_stored", item_id, to_add)


	# 2) 如果还有剩下要加，就找空槽新建
	for i in range(slots.size()):
		if remaining <= 0:
			break
		
		if slots[i] == null:
			var to_add = min(item_db[item_id].max_stack, remaining)
			slots[i] = {"item_id": item_id, "count": to_add}
			remaining -= to_add

			if not storage_counts.has(item_id):
				storage_counts[item_id] = 0
			
			storage_counts[item_id] += to_add

			emit_signal("item_stored", item_id, to_add)
		

	# 3) 如果空间不足导致剩余 still > 0，就回滚刚才的添加
	if remaining > 0:
		# 回滚：移除已经加到仓库的 rolled_back 数量
		var rolled_back = count - remaining
		# 先找到合适的槽位，再 remove
		var idx = get_slot_of(item_id)
		if idx >= 0:
			_remove_and_rollback(idx, rolled_back)
		
		return false
	

	return true


# —— 私有辅助：用于回滚已经加的数量 —— 
func _remove_and_rollback(start_slot_idx: int, rollback_count: int) -> void:
	var rem = rollback_count
	# 按槽逐步移除
	var e = slots[start_slot_idx]
	if e and e.item_id != "":
		var to_remove = min(e.count, rem)
		e.count -= to_remove
		rem -= to_remove
		# 回滚时 storage_counts 要同步减去
		if storage_counts.has(e.item_id):
			storage_counts[e.item_id] -= to_remove
		
		if e.count <= 0:
			slots[start_slot_idx] = null
		
	

	for i in range(start_slot_idx + 1, slots.size()):
		if rem <= 0:
			break
		
		var e2 = slots[i]
		if e2 and e2.item_id == slots[start_slot_idx].item_id:
			var to_remove2 = min(e2.count, rem)
			e2.count -= to_remove2
			rem -= to_remove2
			if storage_counts.has(e2.item_id):
				storage_counts[e2.item_id] -= to_remove2
			
			if e2.count <= 0:
				slots[i] = null
			


	# 如果彻底回滚完毕，rem 应该归 0


# —— 按槽位移除：即取出储藏箱里某槽的物品 —— 
func remove_item_by_slot(slot_idx: int, count: int = 1) -> bool:
	var remaining = count
	if slot_idx < 0 or slot_idx >= slots.size():
		return false
	
	var e = slots[slot_idx]
	if e and e.item_id != "":
		var to_remove = min(e.count, remaining)
		e.count -= to_remove
		remaining -= to_remove

		# 同步更新 storage_counts
		if storage_counts.has(e.item_id):
			storage_counts[e.item_id] -= to_remove
		

		emit_signal("item_removed", e.item_id, to_remove)

		if e.count <= 0:
			slots[slot_idx] = null
		
		if remaining == 0:
			return true
		
	

	# 如果还没移完，就继续往后找到同 id 的槽位移除
	for i in range(slot_idx + 1, slots.size()):
		if remaining <= 0:
			break
		
		var e2 = slots[i]
		if e2 and e2.item_id == slots[slot_idx].item_id:
			var to_remove2 = min(e2.count, remaining)
			e2.count -= to_remove2
			remaining -= to_remove2

			if storage_counts.has(e2.item_id):
				storage_counts[e2.item_id] -= to_remove2
			

			emit_signal("item_removed", e2.item_id, to_remove2)
			if e2.count <= 0:
				slots[i] = null
			
		
	

	# 如果还有剩余未移完，回滚已经移的数量
	if remaining > 0:
		# 回滚部分
		var rollback_amount = count - remaining
		if slots[slot_idx] and slots[slot_idx].item_id != "":
			add_item_by_id(slots[slot_idx].item_id, rollback_amount)
		
		return false
	

	return true


# —— 如果要按 item_id 取出（不指定具体槽位），调用此函数 —— 
func remove_item_by_id(item_id: String, count: int) -> bool:
	var idx = get_slot_of(item_id)
	if idx < 0:
		return false
	
	return remove_item_by_slot(idx, count)


# —— 获取当前储藏箱里某 item_id 的总数量（累加 slots 中所有相同 id 的槽位） —— 
func get_total_count(item_id: String) -> int:
	var sum = 0
	for e in slots:
		if e and e.item_id == item_id:
			sum += e.count
		
	
	return sum


# —— 按类别筛选：返回一个 Array，包含该类别下所有 item_id（即使 count=0 也返回） —— 
func get_items_by_type(t: int) -> Array:
	var result := []

	for id in item_db.keys():
		var res = item_db[id]
		if res.type != t:
			continue
		

		# 1) 取出仓库里这个 id 的总数量（可能为 0）
		var total_in_storage := get_total_count(id)
		

		# 2) 不再过滤 total_in_storage == 0 的情况，直接 append
		result.append({
			"item_id": id,
			"count": total_in_storage,
			"icon": res.icon,
			"name": res.name
		})
	

	return result
