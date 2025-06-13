extends Node
class_name Inventory

signal inventory_updated
# —— Signals —— 
signal item_added(item_id: String, slot_idx: int)
signal item_removed(item_id: String, slot_idx: int)
signal item_equipped(item_id: String, equip_idx: int)
signal item_unequipped(item_id: String, equip_idx: int)
signal item_used(item_id: String, slot_idx: int)
signal item_discarded(item_id: String, equip_idx: int)

# —— Configuration —— 
@export var max_slots: int = 20

# —— Internal State —— 
var item_db: Dictionary = {}       # id -> Item resource
var slots: Array = []              # Inventory slots, each element is { item_id, count } or null
var equipment := [""]              # Equipment slots; only one weapon slot at equipment[0]

func _ready() -> void:
	# 1) Scan all .tres files under res://Resources/Items/ and register into item_db
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
		push_error("Inventory: Items directory not found")
	
	# 2) Initialize inventory slots
	slots.resize(max_slots)
	for i in slots.size():
		slots[i] = null
	print("Loaded items:", item_db.keys())
	emit_signal("inventory_updated")

# —— Resource Lookup —— 
func get_item_resource(item_id: String) -> Item:
	return item_db.get(item_id, null)

# —— Inventory Queries —— 
func get_slot_id(slot_idx: int) -> String:
	var e = slots[slot_idx]
	return "" if e == null else e.item_id

func get_count_by_slot(slot_idx: int) -> int:
	var e = slots[slot_idx]
	return 0 if e == null else e.count

# —— Add Item —— 
func add_item_by_id(item_id: String, count: int = 1) -> bool:
	if not item_db.has(item_id):
		push_warning("Inventory: Unknown item id = %s" % item_id)
		return false
	var remaining = count
	# 1) First fill existing stacks of the same id that aren't full
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
	# 2) Then find empty slots to create new stacks
	for i in slots.size():
		if remaining == 0:
			break
		if slots[i] == null:
			var to_add = min(item_db[item_id].max_stack, remaining)
			slots[i] = { "item_id": item_id, "count": to_add }
			remaining -= to_add
			emit_signal("item_added", item_id, i)
	# 3) If not enough space, roll back added portion
	if remaining > 0:
		var rolled = count - remaining
		remove_item_by_slot(get_slot_of(item_id), rolled)
		return false
	return true

# —— Remove Item by Slot —— 
func remove_item_by_slot(slot_idx: int, count: int = 1) -> bool:
	# Return false if index invalid or slot already empty
	if slot_idx < 0 or slot_idx >= slots.size():
		return false
	if slots[slot_idx] == null:
		return false

	# 1) Record target_id for rollback if needed
	var target_id: String = slots[slot_idx].item_id
	var remaining := count
	var actually_removed := 0  # Total removed

	# 2) Remove from the specified slot first
	var e = slots[slot_idx]
	if e and e.count > 0:
		var to_remove = min(e.count, remaining)
		e.count -= to_remove
		remaining -= to_remove
		actually_removed += to_remove
		emit_signal("item_removed", e.item_id, slot_idx)
		if e.count == 0:
			slots[slot_idx] = null
		if remaining == 0:
			emit_signal("inventory_updated")
			return true

	# 3) Continue removing from subsequent slots with the same id
	for i in range(slot_idx + 1, slots.size()):
		if remaining == 0:
			break
		e = slots[i]
		if e != null and e.item_id == target_id:
			var to_remove2 = min(e.count, remaining)
			e.count -= to_remove2
			remaining -= to_remove2
			actually_removed += to_remove2
			emit_signal("item_removed", e.item_id, i)
			if e.count == 0:
				slots[i] = null

	# 4) If still not enough removed, roll back the removal
	if remaining > 0:
		add_item_by_id(target_id, actually_removed)
		return false

	# Removal complete; signal update
	emit_signal("inventory_updated")
	return true

func discard_equip_slot(equip_idx: int) -> bool:
	if equip_idx < 0 or equip_idx >= equipment.size():
		return false
	var id = equipment[equip_idx]
	if id == "":
		return false
	# Remove without returning to inventory
	equipment[equip_idx] = ""
	emit_signal("item_discarded", id, equip_idx)
	return true

# —— Use (Consume) Item —— 
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

# —— Equip Weapon Slot —— 
func equip_slot(equip_idx: int, slot_idx: int) -> bool:
	if equip_idx < 0 or equip_idx >= equipment.size():
		return false
	var e = slots[slot_idx]
	if e == null:
		return false
	var it = get_item_resource(e.item_id)
	if it.type != Item.ItemType.Weapon:
		return false
	# Remove one from inventory
	if not remove_item_by_slot(slot_idx, 1):
		return false
	# Return previous weapon in slot back to inventory
	var prev = equipment[equip_idx]
	if prev != "":
		add_item_by_id(prev, 1)
	# Equip new weapon
	equipment[equip_idx] = it.id
	emit_signal("item_equipped", it.id, equip_idx)
	return true

# —— Unequip Weapon Slot —— 
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

# —— Find slot containing an item_id (for rollback) —— 
func get_slot_of(item_id: String) -> int:
	for i in slots.size():
		if slots[i] and slots[i].item_id == item_id:
			return i
	return -1

func has_item(item_id: String, need_count: int) -> bool:
	var total = get_count_by_id(item_id)
	return total >= need_count

func remove_item(item_id: String, count: int) -> bool:
	# Use remove_item_by_slot starting from first found slot
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
	var result: Array = []
	for id in item_db.keys():
		var res = item_db[id]
		if res.type != t:
			continue
		var total_in_backpack: int = 0
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

func organize_inventory() -> void:
	# —— 1) Gather all non-empty slots —— #
	var items_list := []      # Temp list of { "item_id":…, "count":… } dictionaries
	for entry in slots:
		if entry != null:
			items_list.append(entry)

	# items_list.sort_custom(self, "_sort_by_item_id")
	# Here we keep insertion order

	# —— 2) Clear all slots —— #
	for i in range(slots.size()):
		slots[i] = null

	# —— 3) Refill slots from items_list —— #
	for j in range(items_list.size()):
		if j < slots.size():
			slots[j] = items_list[j]
		else:
			break

	# —— 4) Signal UI to refresh —— #
	emit_signal("inventory_updated")
