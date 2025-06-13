# SaveManager.gd


extends Node


const SAVE_PATH := "user://savegame.json"


const ENCRYPTION_PASSWORD := "3x7Mp9FdL2QkNzYvHgP1sRtVbJ4wAeCz" 
const KEY_SIZE           := 32  
const IV_SIZE            := 16  
const BLOCK_SIZE         := 16  


var save_data : Dictionary = {}


func _derive_key_bytes() -> PackedByteArray:
	var key_bytes = ENCRYPTION_PASSWORD.to_utf8_buffer()
	if key_bytes.size() < KEY_SIZE:
		key_bytes.resize(KEY_SIZE)
	elif key_bytes.size() > KEY_SIZE:
		key_bytes = key_bytes.subarray(0, KEY_SIZE)
	return key_bytes


func save_game() -> void:
	
	if has_node("/root/global"):
		save_data["player_stats"] = {
			"health":  global.player_health,
			"attack":  global.player_attack,
			"defense": global.player_defense,
			"status":  global.player_status,
		}
	else:
		save_data["player_stats"] = {}

	if has_node("/root/inventory_autoload"):
		save_data["inventory"] = inventory_autoload.slots.duplicate()
		save_data["equipment"] = inventory_autoload.equipment.duplicate()
	else:
		save_data["inventory"] = []
		save_data["equipment"] = []

	if has_node("/root/StorageAutoload"):
		var scopy = {}
		for k in StorageAutoload.storage_counts.keys():
			scopy[k] = StorageAutoload.storage_counts[k]
		save_data["storage_box"] = scopy
	else:
		save_data["storage_box"] = {}

	
	var plaintext = JSON.stringify(save_data).to_utf8_buffer()

	
	var pad_len = BLOCK_SIZE - (plaintext.size() % BLOCK_SIZE)
	if pad_len == 0:
		pad_len = BLOCK_SIZE
	for i in range(pad_len):
		plaintext.append(pad_len)

	
	var key_bytes = _derive_key_bytes()
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var iv = PackedByteArray()
	iv.resize(IV_SIZE)
	for i in range(IV_SIZE):
		iv[i] = rng.randi_range(0, 255)

	var aes = AESContext.new()
	aes.start(AESContext.MODE_CBC_ENCRYPT, key_bytes, iv)
	var cipher = aes.update(plaintext)
	aes.finish()

	
	var combined = iv + cipher
	var b64 = Marshalls.raw_to_base64(combined)

	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("SaveManager: 无法打开存档文件写入")
		return
	file.store_string(b64)
	file.close()
	print("SaveManager: 存档已加密并保存")

# ========== 解密并加载 ========== #
func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("SaveManager: 未找到存档，跳过读档")
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("SaveManager: 无法打开存档文件")
		return
	var b64 = file.get_as_text()
	file.close()

	
	var combined = Marshalls.base64_to_raw(b64)
	if combined.size() < IV_SIZE:
		push_error("SaveManager: 解密失败（数据太短）")
		return

	
	var iv = PackedByteArray()
	for i in range(IV_SIZE):
		iv.append(combined[i])

	var cipher = PackedByteArray()
	for i in range(IV_SIZE, combined.size()):
		cipher.append(combined[i])

	
	var key_bytes = _derive_key_bytes()
	var aes = AESContext.new()
	aes.start(AESContext.MODE_CBC_DECRYPT, key_bytes, iv)
	var decrypted_padded = aes.update(cipher)
	aes.finish()

	var decrypted = decrypted_padded
	if decrypted.size() > 0:
		var pad = decrypted[decrypted.size() - 1]
		if pad > 0 and pad <= BLOCK_SIZE and decrypted.size() >= pad:
			var tmp := PackedByteArray()
			for i in range(decrypted_padded.size() - pad):
				tmp.append(decrypted_padded[i])
			decrypted = tmp

	
	var json_str = decrypted.get_string_from_utf8()
	var res = JSON.parse_string(json_str)
	if res.has("error") and res["error"] != OK:
		push_error("SaveManager: JSON 解析失败：" + res.error_string)
		return
	save_data = res
	print("SaveManager: 存档已解密并加载")

	
	if save_data.has("player_stats"):
		var s = save_data["player_stats"]
		if s.has("health"):  global.player_health  = s["health"]
		if s.has("attack"):  global.player_attack  = s["attack"]
		if s.has("defense"): global.player_defense = s["defense"]
		if s.has("status"):  global.player_status  = s["status"]

	if save_data.has("inventory"):
		inventory_autoload.slots.clear()
		for e in save_data["inventory"]:
			inventory_autoload.slots.append(e)
		if save_data.has("equipment"):
			inventory_autoload.equipment.clear()
			for eq in save_data["equipment"]:
				inventory_autoload.equipment.append(eq)
		inventory_autoload.emit_signal("inventory_updated")

	if save_data.has("storage_box"):
		StorageAutoload.storage_counts.clear()
		for k in save_data["storage_box"].keys():
			StorageAutoload.storage_counts[k] = save_data["storage_box"][k]
		StorageAutoload.fill_slots_from_counts()

# ========== 一键清档 ========== #
func clear_save() -> void:
	
	var dir = DirAccess.open("user://")
	if dir:
		if dir.remove("savegame.json") != OK:
			push_error("SaveManager: 无法删除存档文件")
		else:
			print("SaveManager: 存档文件已删除")
	else:
		push_error("SaveManager: 无法打开 user:// 目录")

	
	save_data.clear()

	
	global.player_health  = global.player_max_health
	global.player_attack  = 10
	global.player_defense = 10
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
