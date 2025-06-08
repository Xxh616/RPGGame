# File: res://scripts/KeyConfig.gd
# -------------------------------------------------------------
# KeyConfig.gd
#
# 作用：
#   1) save_user_bindings(dict)    把玩家在「按键设置界面」改过的按键写到 user://input.cfg
#   2) load_user_bindings()        从 user://input.cfg 读到玩家改的那些 scancode，然后追加到 InputMap
#
# 注意：
#   - 本脚本【不】会去清除项目默认的 InputMap，这样就永远不会吞掉原来的默认键。  
#   - 只会在用户确实给某个动作自定义了新 scancode 时，做一次 InputMap.action_add_event()。  
#   - 如果玩家从未给该动作改过键或配置文件里没有对应的值，就不会对该动作做任何操作，保留项目默认。  
# -------------------------------------------------------------

extends Node
class_name KeyConfig

# 1) 定义所有「可自定义按键」的 action 名（要与 Project Settings → InputMap 里注册的名字一样）
static var actions := [
	"attack",
	"toggle_inventory",
	"pickup_item",
	"toggle_storage",
	"toggle_synthesis",
	"GOGOGO"
]

# 2) 配置文件路径
const KEYCFG_PATH := "user://input.cfg"


# ================================================================
# 从 user://input.cfg 读取玩家保存的 action→scancode 映射，并直接追加到 InputMap
# 返回一个 Dictionary，形如 { "attack":35, "pickup_item":84, ... }
# ================================================================
static func load_user_bindings() -> Dictionary:
	var result := {}

	var cfg := ConfigFile.new()
	var err := cfg.load(KEYCFG_PATH)
	if err != OK:
		# 配置文件不存在或加载失败，就认为没有玩家自定义绑定
		for action_name in KeyConfig.actions:
			result[action_name] = 0
		return result

	# 读取 [KeyBindings] 段
	for action_name in KeyConfig.actions:
		var sc := int(cfg.get_value("KeyBindings", action_name, 0))
		result[action_name] = sc
		if sc > 0:
			# 玩家确实给这个动作自定义了一个按键，就把它「追加」到 InputMap 中
			var ev := InputEventKey.new()
			ev.physical_keycode = sc
			InputMap.action_add_event(action_name, ev)
		# sc == 0：说明用户没有给这个动作绑定或使用默认，什么都不做
	return result


# ================================================================
# 把一个 { action_name:scancode, ... } 写到 user://input.cfg  
# 习惯上在玩家在「按键设置界面」里点“保存”时调用
# ================================================================
static func save_user_bindings(bindings_dict: Dictionary) -> void:
	var cfg := ConfigFile.new()

	# 如果配置文件已经存在，我们先 load 一次，避免覆盖其他段
	cfg.load(KEYCFG_PATH)

	# 把玩家改动的映射写入 [KeyBindings] 段
	for action_name in KeyConfig.actions:
		var sc = 0
		if bindings_dict.has(action_name):
			sc=convertcharactertoint(bindings_dict[action_name])
		cfg.set_value("KeyBindings", action_name, sc)

	var save_err := cfg.save(KEYCFG_PATH)
	if save_err != OK:
		push_error("KeyConfig: 无法将用户按键配置写入: " + KEYCFG_PATH)
	else:
		print("KeyConfig: 用户按键配置已保存到: " + KEYCFG_PATH)
# 假设只处理大写字母 A–Z
static func convertcharactertoint(s:String)->int:
	for i  in range (65,90):
		if String.chr(i)==s:
			return i
	return 0
