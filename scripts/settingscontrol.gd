# settings_control.gd
# 挂载在 SettingsControl (Control) 根节点上

extends Control

# ————————————————————————————————————————————————————————————————————————————————
# 1. 数据配置：列出所有可配置的动作及其“显示名称”和“默认键”字符串
#    - action_name:   必须与 Project Settings → InputMap 里已注册过的动作名称一致
#    - display_name:  给玩家看的文字描述
#    - default_key:   “默认键”字符串，必须跟全局常量 KEY_<NAME> 对应。例如：
#                     "E"  对应 KEY_E
#                     "I"  对应 KEY_I
#                     "T"  对应 KEY_T
#                     "Y"  对应 KEY_Y
#                     "M"  对应 KEY_M
#                     "G"  对应 KEY_G
var action_data := [
	{ "action_name":  "attack",           "display_name": "攻击",       "default_key": "E" },
	{ "action_name":  "toggle_inventory", "display_name": "打开背包",   "default_key": "I" },
	{ "action_name":  "pickup_item",      "display_name": "拾取物品",   "default_key": "T" },
	{ "action_name":  "toggle_storage",   "display_name": "打开储存箱", "default_key": "Y" },
	{ "action_name":  "toggle_synthesis", "display_name": "打开合成台", "default_key": "M" },
	{ "action_name":  "GOGOGO",           "display_name": "GOGOGO 模式","default_key": "G" }
]

# ————————————————————————————————————————————————————————————————————————————————
# 2. 本地缓存：记录每个动作当前绑定的“键名字符串”
#    例如 current_binding["attack"] = "E"，表示 attack 动作目前绑定的是键 E
var current_binding : Dictionary = {}

# ————————————————————————————————————————————————————————————————————————————————
# 3. “正在等待玩家按键”的状态记录
#    当用户点击“重新绑定”按钮后，会将该行对应的动作名与按钮引用记录到下面两个变量，
#    直到玩家敲下新键才写入 InputMap 并更新按钮文字后重置为 ""
var waiting_action_name : String = ""
var waiting_button_ref  : Button = null


func _ready() -> void:
	# —— 第一步：把项目默认绑定写入 InputMap & current_binding —— #
	_init_project_defaults()

	# —— 第二步：加载玩家自定义绑定（KeyConfig 自动把它们 add_event 到 InputMap） —— #
	current_binding=KeyConfig.load_user_bindings()

	# —— 第三步：生成／刷新一次 KeyBind 表格 —— #
	_build_keybind_grid()
func _init_project_defaults() -> void:
	for data in action_data:
		var act   = data["action_name"]
		var dkey  = data["default_key"]
		InputMap.action_erase_events(act)
		var ev = InputEventKey.new()
		match dkey:
			"E": ev.keycode = KEY_E
			"I": ev.keycode = KEY_I
			# … 其它键 …
			_: ev.keycode = KEY_UNKNOWN
		InputMap.action_add_event(act, ev)
		current_binding[act] = dkey

func _build_keybind_grid() -> void:
	var grid = $GridContainer
	# 清空旧子节点
	for c in grid.get_children():
		c.queue_free()

	# 重新按 current_binding 来生成行
	for data in action_data:
		var act  = data["action_name"]
		var disp = data["display_name"]
		
		# current_binding[act] 已经可能被 load_user_bindings 覆盖成玩家的自定义值
		var keyname = current_binding.get(act, data["default_key"])
		
		keyname=String.chr(keyname)
		current_binding[act]=keyname
		# 列 1：动作名
		var lbl = Label.new()
		lbl.text = disp
		lbl.size_flags_horizontal = Control.SIZE_FILL | Control.SIZE_SHRINK_END
		grid.add_child(lbl)

		# 列 2：当前键名
		var lbl2 = Label.new()
		lbl2.text = keyname
		lbl2.size_flags_horizontal = Control.SIZE_FILL | Control.SIZE_EXPAND
		grid.add_child(lbl2)

		# 列 3：重绑定按钮
		var btn = Button.new()
		btn.text = keyname
		btn.size_flags_horizontal = Control.SIZE_FILL | Control.SIZE_EXPAND
		btn.connect("pressed", Callable(self, "_on_ButtonRebind_pressed").bind(act, btn))
		grid.add_child(btn)
func _unhandled_input(event: InputEvent) -> void:
	# 4.0 如果当前没有任何动作在等按键，直接返回
	if waiting_action_name == "":
		return

	# 4.1 仅当捕获到按下的按键事件且不是重复按下时，才处理
	if event is InputEventKey and event.pressed and not event.echo:
		# a) 清除该动作在 InputMap 里所有旧的绑定
		InputMap.action_erase_events(waiting_action_name)

		# b) 用玩家此次敲下的 keycode 创建一个新的 InputEventKey
		var new_ev := InputEventKey.new()
		new_ev.keycode = (event as InputEventKey).keycode

		# c) 把它写回系统 InputMap
		InputMap.action_add_event(waiting_action_name, new_ev)

		# d) 用 event.as_text() 把 keycode 转成字符串（例如按 E 则 "E"）
		var new_name = (event as InputEventKey).as_text()
		# 更新本地缓存
		current_binding[waiting_action_name] = new_name

		# e) 更新对应行的按钮文字，让玩家立刻看到新绑定
		if waiting_button_ref:
			waiting_button_ref.text = new_name

		# f) 结束“等待”状态
		waiting_action_name = ""
		waiting_button_ref  = null

		# （可选）打印日志
		print("Action [%s] 已绑定到键 [%s]" % [waiting_action_name, new_name])

	# 4.2 如果你希望用户按下 Esc 取消本次录入，可以加一段类似：
	# elif event is InputEventKey and event.pressed and not event.echo \
	#      and (event as InputEventKey).keycode == KEY_ESCAPE:
	#     _restore_waiting_display()
# ————————————————————————————————————————————————————————————————————————————————


# ————————————————————————————————————————————————————————————————————————————————
# 5. 玩家点击某行的“重新绑定”按钮时调用：
#    action_name:   本行对应要重新绑定的动作名
#    button_rebind: 本行的 Button 节点引用，用来临时修改按钮文字
func _on_ButtonRebind_pressed(action_name: String, button_rebind: Button) -> void:
	# 5.1 如果已有其他动作处于“等待按键”状态，要先把它复原显示
	if waiting_action_name != "":
		_restore_waiting_display()

	# 5.2 记录正在等待哪个动作，以及对应的按钮引用
	waiting_action_name = action_name
	waiting_button_ref  = button_rebind

	# 5.3 临时把按钮文字改成“Press any key...”，提示玩家去按想绑定的键
	button_rebind.text = "Press any key..."
# ————————————————————————————————————————————————————————————————————————————————


# ————————————————————————————————————————————————————————————————————————————————
# 6. 如果想取消/复原本次等待的“按键录入”状态，就调用该方法把按钮文字还原
func _restore_waiting_display() -> void:
	if waiting_action_name != "" and waiting_button_ref:
		var old_name = str(current_binding[waiting_action_name])
		waiting_button_ref.text = old_name
	waiting_action_name = ""
	waiting_button_ref  = null
# ————————————————————————————————————————————————————————————————————————————————


# ————————————————————————————————————————————————————————————————————————————————
# 7. 玩家点击 CloseButton 时隐藏面板。如果需要将 current_binding 存盘以便下次启动恢复，可在此处实现。
func _on_CloseButton_pressed() -> void:
	hide()
	print(current_binding)
	KeyConfig.save_user_bindings(current_binding)
	# （可选示例：把 current_binding 写入 user://settings.cfg）
	# var cfg = ConfigFile.new()
	# for data in action_data:
	#     var act = data["action_name"]
	#     cfg.set_value("KeyBindings", act, current_binding[act])
	# cfg.save("user://settings.cfg")
# ————————————————————————————————————————————————————————————————————————————————
