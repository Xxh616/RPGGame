# res://scripts/Storage.gd
extends Node
class_name Storage
signal storage_updated
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

	# —— 第一步：从 start_slot_idx 处回滚 —— #
	var e = slots[start_slot_idx]
	if e != null and e.has("item_id"):
		var to_remove = min(e.count, rem)
		e.count -= to_remove
		rem -= to_remove
		if storage_counts.has(e.item_id):
			storage_counts[e.item_id] -= to_remove
		if e.count <= 0:
			slots[start_slot_idx] = null
	# 如果 e 本身就是 null，就跳过，继续往后找

	# —— 第二步：如果 rem > 0，就接着往后面的槽位继续找同 id 回滚 —— #
	# 先拿到回滚的 item_id：
	var rollback_id = ""
	if e != null and e.has("item_id"):
		rollback_id = e.item_id
	else:
		# 如果 e 已被清空，那么还是记得最初的 item_id
		# 可以在调用此函数之前就把 item_id 缓存下来。这里假设
		# 调用时传进来的 start_slot_idx 肯定对应某个 item_id。
		# 所以暂时让调用者保证这个 item_id 先行存好。
		# 例如改成 _remove_and_rollback(start_slot_idx, rollback_count, item_id) 更稳妥。
		return

	for i in range(start_slot_idx + 1, slots.size()):
		if rem <= 0:
			break
		var e2 = slots[i]
		if e2 != null and e2.has("item_id") and e2.item_id == rollback_id:
			var to_remove2 = min(e2.count, rem)
			e2.count -= to_remove2
			rem -= to_remove2
			if storage_counts.has(e2.item_id):
				storage_counts[e2.item_id] -= to_remove2
			if e2.count <= 0:
				slots[i] = null

	# rem 最终肯定取不到 0，因为回滚时只回滚到原来刚加上的数量
	# 不需要做额外处理



# —— 按槽位移除：即取出储藏箱里某槽的物品 —— 
func remove_item_by_slot(slot_idx: int, count: int = 1) -> bool:
	var remaining = count
	if slot_idx < 0 or slot_idx >= slots.size():
		return false

	# —— 第一步：从指定槽位开始移除 —— #
	var e = slots[slot_idx]
	if e != null and e.has("item_id"):
		var to_remove = min(e.count, remaining)
		e.count -= to_remove
		remaining -= to_remove

		if storage_counts.has(e.item_id):
			storage_counts[e.item_id] -= to_remove

		emit_signal("item_removed", e.item_id, to_remove)

		if e.count <= 0:
			slots[slot_idx] = null

		if remaining == 0:
			return true
	else:
		# 如果指定的槽本身就是 null，就视为没物品，直接失败
		return false

	# —— 第二步：如果还没移完，就往后面的槽继续找“同 id”移除 —— #
	# 注意，这里要先检查 slots[slot_idx] 现在是不是 null
	# 如果它已经被清空，需要先记下原来的 item_id：
	var target_id = ""
	if slots[slot_idx] != null and slots[slot_idx].has("item_id"):
		target_id = slots[slot_idx].item_id
	else:
		# 上面 e.count <=0 后已经把 slots[slot_idx] 设为 null，
		# 但我们知道这个函数一开始传进来时它肯定有 item_id。所以这里用 e.item_id 作为 target
		target_id = e.item_id
	# 接下来遍历剩余槽位
	for i in range(slot_idx + 1, slots.size()):
		if remaining <= 0:
			break
		var e2 = slots[i]
		if e2 != null and e2.has("item_id") and e2.item_id == target_id:
			var to_remove2 = min(e2.count, remaining)
			e2.count -= to_remove2
			remaining -= to_remove2

			if storage_counts.has(e2.item_id):
				storage_counts[e2.item_id] -= to_remove2

			emit_signal("item_removed", e2.item_id, to_remove2)

			if e2.count <= 0:
				slots[i] = null

	# —— 第三步：如果依然有剩余没移完，就要回滚之前已经移走的数量 —— #
	if remaining > 0:
		var rollback_amount = count - remaining
		# 回滚时仍需检查 slots[slot_idx] 是否存在，item_id 是否有效
		if slot_idx >= 0 and slot_idx < slots.size() and slots[slot_idx] != null and slots[slot_idx].has("item_id"):
			add_item_by_id(slots[slot_idx].item_id, rollback_amount)
		else:
			# 如果原始槽被清空，直接用 e.item_id 回滚
			add_item_by_id(e.item_id, rollback_amount)
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
func fill_slots_from_counts() -> void:
	# —— A) 只要将现成的槽全部置空即可，无需重新 resize —— 
	for i in range(slots.size()):
		slots[i] = null

	# —— B) 遍历 storage_counts，把每个 item_id 拆分到槽位 —— 
	for item_id in storage_counts.keys():
		var total := int(storage_counts[item_id])
		if total <= 0:
			continue

		if not item_db.has(item_id):
			push_warning("Storage.fill_slots_from_counts: 未找到资源，item_id = %s" % item_id)
			continue

		var stack_limit = item_db[item_id].max_stack
		var remaining = total

		# —— B1) 如果之前修改过 slots，这里允许先往已有同 id 槽叠加（reload 时 slots 通常全是 null） —— 
		for i in range(slots.size()):
			if remaining <= 0:
				break
			var sd = slots[i]
			if sd and sd.item_id == item_id:
				var can_put = stack_limit - sd.count
				var put = min(can_put, remaining)
				sd.count += put
				remaining -= put

		# —— B2) 剩余数量就往空槽新放 —— 
		for i in range(slots.size()):
			if remaining <= 0:
				break
			if slots[i] == null:
				var put = min(stack_limit, remaining)
				slots[i] = {
					"item_id": item_id,
					"count": put
				}
				remaining -= put

		# 如果槽位不够，溢出部分直接忽略（正常情况下读档前 storage_counts 就来自之前的 slots，不会出现溢出）
	# end for each item_id

	# —— C) 填充完成后，发一个刷新信号，让 UI 重新读取 slots —— 
	emit_signal("storage_updated")
