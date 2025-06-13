# res://scripts/Storage.gd
extends Node
class_name Storage

signal storage_updated
# Optional signals for UI listeners
signal item_stored(item_id: String, count: int)    # Emitted when items are stored
signal item_removed(item_id: String, count: int)   # Emitted when items are removed

# Configuration: maximum number of slots (adjust as needed)
@export var max_slots: int = 100

# Tracks the total count of each item_id in the storage box
var storage_counts: Dictionary = {}

# Internal state
# item_db: maps id:String → Item resource
var item_db: Dictionary = {}

# slots: each element is either null or a Dictionary { "item_id": String, "count": int }
var slots: Array = []

func _ready() -> void:
	# 1) Scan res://Resources/Items for all .tres files and load Item resources into item_db
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
		push_error("Storage: Items directory not found")

	# 2) Initialize the slots array
	slots.resize(max_slots)
	for i in range(slots.size()):
		slots[i] = null

	# 3) (Optional) During debugging, pre-fill the storage with some items for testing
	#    e.g., one Sword_I and five First-grade ore

	# Debug output
	print("Storage loaded items:", item_db.keys())
	print("Initial storage_counts:", storage_counts)

# Retrieve the Item resource for a given item_id
func get_item_resource(item_id: String) -> Item:
	return item_db.get(item_id, null)

# Find the first slot index containing the specified item_id
func get_slot_of(item_id: String) -> int:
	for i in range(slots.size()):
		var e = slots[i]
		if e and e.item_id == item_id:
			return i
	return -1

# Store items into the storage box by item_id
# Returns true if all items were stored; false and rolls back otherwise
func add_item_by_id(item_id: String, count: int = 1) -> bool:
	if not item_db.has(item_id):
		push_warning("Storage: Unknown item_id = %s" % item_id)
		return false

	var remaining = count

	# 1) First, add to existing slots of the same item_id that are not full
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
				storage_counts[item_id] = storage_counts.get(item_id, 0) + to_add
				emit_signal("item_stored", item_id, to_add)

	# 2) Then, place into empty slots as needed
	for i in range(slots.size()):
		if remaining <= 0:
			break
		if slots[i] == null:
			var to_add = min(item_db[item_id].max_stack, remaining)
			slots[i] = {"item_id": item_id, "count": to_add}
			remaining -= to_add
			storage_counts[item_id] = storage_counts.get(item_id, 0) + to_add
			emit_signal("item_stored", item_id, to_add)

	# 3) If there is still remaining, rollback the additions
	if remaining > 0:
		var rolled_back = count - remaining
		var idx = get_slot_of(item_id)
		if idx >= 0:
			_remove_and_rollback(idx, rolled_back)
		return false

	return true

# Private helper: rollback a given number of items starting from the specified slot
func _remove_and_rollback(start_slot_idx: int, rollback_count: int) -> void:
	var rem = rollback_count

	# Step 1: rollback from start_slot_idx
	var e = slots[start_slot_idx]
	if e != null and e.has("item_id"):
		var to_remove = min(e.count, rem)
		e.count -= to_remove
		rem -= to_remove
		if storage_counts.has(e.item_id):
			storage_counts[e.item_id] -= to_remove
		if e.count <= 0:
			slots[start_slot_idx] = null

	# Step 2: continue rolling back from later slots with the same item_id
	var rollback_id = ""
	if e != null and e.has("item_id"):
		rollback_id = e.item_id
	else:
		return
	if rollback_id == "":
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

# Remove items from a specific slot index
# Returns true if removal succeeded; false and rolls back otherwise
func remove_item_by_slot(slot_idx: int, count: int = 1) -> bool:
	var remaining = count
	if slot_idx < 0 or slot_idx >= slots.size():
		return false

	# Step 1: remove from the specified slot
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
		# If the slot is empty, consider removal failed
		return false

	# Step 2: continue removing from later slots with the same item_id
	var target_id = ""
	if slots[slot_idx] != null and slots[slot_idx].has("item_id"):
		target_id = slots[slot_idx].item_id
	else:
		target_id = e.item_id
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

	# Step 3: if still remaining, rollback the removed amount
	if remaining > 0:
		var rollback_amount = count - remaining
		if slots[slot_idx] != null and slots[slot_idx].has("item_id"):
			add_item_by_id(slots[slot_idx].item_id, rollback_amount)
		else:
			add_item_by_id(e.item_id, rollback_amount)
		return false

	return true

# Remove items by item_id (finds first slot)
func remove_item_by_id(item_id: String, count: int) -> bool:
	var idx = get_slot_of(item_id)
	if idx < 0:
		return false
	return remove_item_by_slot(idx, count)

# Get total count of an item_id across all slots
func get_total_count(item_id: String) -> int:
	var sum = 0
	for e in slots:
		if e and e.item_id == item_id:
			sum += e.count
	return sum

# Filter by type: returns an Array of Dictionaries with item_id, count, icon, and name
# Includes items even if count = 0
func get_items_by_type(t: int) -> Array:
	var result := []
	for id in item_db.keys():
		var res = item_db[id]
		if res.type != t:
			continue
		var total_in_storage = get_total_count(id)
		result.append({
			"item_id": id,
			"count": total_in_storage,
			"icon": res.icon,
			"name": res.name
		})
	return result

# Rebuild slots from storage_counts (e.g., after loading or clearing)
func fill_slots_from_counts() -> void:
	# A) Clear all existing slots
	for i in range(slots.size()):
		slots[i] = null
	# B) Distribute each item_id into slots based on storage_counts
	for item_id in storage_counts.keys():
		var total = int(storage_counts[item_id])
		if total <= 0:
			continue
		if not item_db.has(item_id):
			push_warning("Storage.fill_slots_from_counts: Resource not found for item_id = %s" % item_id)
			continue
		var stack_limit = item_db[item_id].max_stack
		var remaining = total
		# B1) Stack into existing slots first
		for i in range(slots.size()):
			if remaining <= 0:
				break
			var sd = slots[i]
			if sd and sd.item_id == item_id:
				var can_put = stack_limit - sd.count
				var put = min(can_put, remaining)
				sd.count += put
				remaining -= put
		# B2) Fill empty slots
		for i in range(slots.size()):
			if remaining <= 0:
				break
			if slots[i] == null:
				var put = min(stack_limit, remaining)
				slots[i] = {"item_id": item_id, "count": put}
				remaining -= put
		# Overflow beyond available slots is ignored
	# C) Emit update signal for UI to refresh
	emit_signal("storage_updated")
