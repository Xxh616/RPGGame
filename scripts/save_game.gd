# SaveManager.gd
# 挂载到 AutoLoad，名字为 SaveManager

extends Node

# 存档文件路径，推荐用 user://
const SAVE_PATH := "user://savegame.json"

var custom_actions := [
	"attack",
	"toggle_inventory",
	"pickup_item",
	"toggle_storage",
	"toggle_synthesis",
	"GOGOGO"
]
# 存储用的全局字典
var save_data : Dictionary = {}


# ==================================================
# 读取存档：只恢复玩家数值、背包、储存箱，不处理坐标
# ==================================================
func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("SaveManager: 未找到存档，跳过读档。")
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: 打不开存档：" + SAVE_PATH)
		return

	var text = file.get_as_text()
	file.close()

	var result = JSON.parse_string(text)
	if result.has("error") and result["error"] != OK:
		push_error("SaveManager: 解析 JSON 失败：" + result.error_string)
		return

	save_data = result
	print("SaveManager: 已读取存档数据。")

	# ------ 恢复玩家数值（Global 单例） ------
	if save_data.has("player_stats"):
		var stats = save_data["player_stats"]
		if stats.has("health"):
			global.player_health = stats["health"]
		if stats.has("attack"):
			global.player_attack = stats["attack"]
		if stats.has("defense"):
			global.player_defense = stats["defense"]
		if stats.has("status"):
			global.player_status = stats["status"]
	else:
		print("SaveManager: 存档里无 player_stats。")

	# ------ 恢复背包 (Inventory 单例) ------
	if save_data.has("inventory"):
		inventory_autoload.slots.clear()
		for entry in save_data["inventory"]:
			inventory_autoload.slots.append(entry)
		if save_data.has("equipment"):
			inventory_autoload.equipment.clear()
			for eq in save_data["equipment"]:
				inventory_autoload.equipment.append(eq)
		inventory_autoload.emit_signal("inventory_updated")
	else:
		print("SaveManager: 存档里无 inventory。")

	# ------ 恢复储存箱 (Storage 单例) ------
	if save_data.has("storage_box"):
		StorageAutoload.storage_counts.clear()
		for key in save_data["storage_box"].keys():
			var cnt = save_data["storage_box"][key]
			StorageAutoload.storage_counts[key] = cnt
			print("   —— 恢复道具",key, "数量 =", cnt)
		StorageAutoload.fill_slots_from_counts()
	else:
		print("SaveManager: 存档里无 storage_box。")
	# —— （F）恢复按键绑定 (InputMap) —— #
	# —— （B）存按键绑定到 save_data["keybindings"] —— #
	
	


# ==================================================
# 保存存档：只写 玩家数值、背包、储存箱
# ==================================================
func save_game() -> void:
	global.has_load=false
	# ------ 玩家数值 (Global) ------
	if has_node("/root/global"):
		var ps := {}
		ps["health"] = global.player_health
		ps["defense"]=global.player_defense
		ps["attack"]=global.player_attack
		ps["status"]=global.player_status
		save_data["player_stats"] = ps
	else:
		print("SaveManager: 无法写入玩家属性（缺少 Global 单例）。")
		save_data["player_stats"] = {}

	# ------ 背包 (Inventory) ------
	if has_node("/root/inventory_autoload"):
		save_data["inventory"] = inventory_autoload.slots.duplicate()
		save_data["equipment"] = inventory_autoload.equipment.duplicate()
	else:
		print("SaveManager: 无法写入背包（缺少 Inventory 单例）。")
		save_data["inventory"] = []
		save_data["equipment"] = []

	# ------ 储存箱 (Storage) ------
	if has_node("/root/StorageAutoload"):
		var scopy := {}
		for k in StorageAutoload.storage_counts.keys():
			scopy[k] = StorageAutoload.storage_counts[k]
		save_data["storage_box"] = scopy
	else:
		print("SaveManager: 无法写入储存箱（缺少 Storage 单例）。")
		save_data["storage_box"] = {}
	# —— （D）存按键绑定 (InputMap) —— #
	# 先调用一次上面写好的函数，把所有 action 对应的第一个 scancode 存进 save_data
	
		
		
	
	# ------ 把 save_data 转 JSON 写盘 ------
	var json_str := JSON.stringify(save_data)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: 无法打开存档文件：" + SAVE_PATH)
		return

	file.store_string(json_str)
	file.close()
	print("SaveManager: 存档已保存到", SAVE_PATH)
func clear_save() -> void:
	# 1) 删除存档文件
	var dir := DirAccess.open("user://")
	if dir:
		if dir.remove("savegame.json") != OK:
			push_error("SaveManager: 无法删除存档文件")
		else:
			print("SaveManager: 存档文件已删除。")
	else:
		push_error("SaveManager: 无法打开 user:// 目录")

	# 2) 清空内存里的 save_data
	save_data.clear()

	# 3) 重置各单例到初始状态
	# —— 全局属性
	global.player_health  = global.player_max_health
	global.player_attack  = 1
	global.player_defense = 1
	global.player_status  = 5

	# —— Inventory
	inventory_autoload.slots.clear()
	inventory_autoload.slots.resize(inventory_autoload.max_slots)
	for i in range(inventory_autoload.max_slots):
		inventory_autoload.slots[i] = null
	inventory_autoload.equipment = [""]
	inventory_autoload.emit_signal("inventory_updated")

	# —— Storage
	StorageAutoload.storage_counts.clear()
	StorageAutoload.slots.clear()
	StorageAutoload.slots.resize(StorageAutoload.max_slots)
	for i in range(StorageAutoload.max_slots):
		StorageAutoload.slots[i] = null
	StorageAutoload.emit_signal("storage_updated")
	
	
