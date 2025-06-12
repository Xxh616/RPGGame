# SaveManager.gd
# 挂载到 AutoLoad，名字为 SaveManager

extends Node

# —— 存档文件路径 —— #
const SAVE_PATH := "user://savegame.json"

# —— 加密参数 —— #
const ENCRYPTION_PASSWORD := "3x7Mp9FdL2QkNzYvHgP1sRtVbJ4wAeCz"  # 32 字节随机口令
const KEY_SIZE           := 32  # AES-256 需要 32 字节
const IV_SIZE            := 16  # CBC 模式下 IV 长度固定 16 字节
const BLOCK_SIZE         := 16  # AES 块大小

# —— 全局变量 —— #
var save_data : Dictionary = {}

# —— 将口令字符串转成固定长度的密钥字节数组 —— #
func _derive_key_bytes() -> PackedByteArray:
	var key_bytes = ENCRYPTION_PASSWORD.to_utf8_buffer()
	if key_bytes.size() < KEY_SIZE:
		key_bytes.resize(KEY_SIZE)
	elif key_bytes.size() > KEY_SIZE:
		key_bytes = key_bytes.subarray(0, KEY_SIZE)
	return key_bytes

# ========== 保存并加密 ========== #
func save_game() -> void:
	# —— 原存档数据填充 —— #
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

	# —— JSON → 原始字节 —— #
	var plaintext = JSON.stringify(save_data).to_utf8_buffer()

	# —— PKCS#7 填充 —— #
	var pad_len = BLOCK_SIZE - (plaintext.size() % BLOCK_SIZE)
	if pad_len == 0:
		pad_len = BLOCK_SIZE
	for i in range(pad_len):
		plaintext.append(pad_len)

	# —— 派生密钥 & 随机 IV —— #
	var key_bytes = _derive_key_bytes()
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var iv = PackedByteArray()
	iv.resize(IV_SIZE)
	for i in range(IV_SIZE):
		iv[i] = rng.randi_range(0, 255)

	# —— AES-CBC 加密 —— #
	var aes = AESContext.new()
	aes.start(AESContext.MODE_CBC_ENCRYPT, key_bytes, iv)
	var cipher = aes.update(plaintext)
	aes.finish()

	# —— IV + 密文 → Base64 —— #
	var combined = iv + cipher
	var b64 = Marshalls.raw_to_base64(combined)

	# —— 写文件 —— #
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

	# —— Base64 → 二进制 —— #
	var combined = Marshalls.base64_to_raw(b64)
	if combined.size() < IV_SIZE:
		push_error("SaveManager: 解密失败（数据太短）")
		return

	# —— 拆 IV & 密文 —— #
	var iv = combined.subarray(0, IV_SIZE)
	var cipher = combined.subarray(IV_SIZE, combined.size())

	# —— 派生密钥 & 解密 —— #
	var key_bytes = _derive_key_bytes()
	var aes = AESContext.new()
	aes.start(AESContext.MODE_CBC_DECRYPT, key_bytes, iv)
	var decrypted_padded = aes.update(cipher)
	aes.finish()

	# —— 去除 PKCS#7 填充 —— #
	var decrypted = decrypted_padded
	if decrypted.size() > 0:
		var pad = decrypted[decrypted.size() - 1]
		if pad > 0 and pad <= BLOCK_SIZE and decrypted.size() >= pad:
			decrypted = decrypted.subarray(0, decrypted.size() - pad)

	# —— 字节 → JSON —— #
	var json_str = decrypted.get_string_from_utf8()
	var res = JSON.parse_string(json_str)
	if res.has("error") and res["error"] != OK:
		push_error("SaveManager: JSON 解析失败：" + res.error_string)
		return
	save_data = res
	print("SaveManager: 存档已解密并加载")

	# —— 按原逻辑恢复各单例数据 —— #
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
	# 1) 删除存档文件
	var dir = DirAccess.open("user://")
	if dir:
		if dir.remove("savegame.json") != OK:
			push_error("SaveManager: 无法删除存档文件")
		else:
			print("SaveManager: 存档文件已删除")
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
