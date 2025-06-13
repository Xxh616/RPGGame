# settings_control.gd
# Attached to the SettingsControl (Control) root node

extends Control

# ————————————————————————————————————————————————————————————————————————————————
# 1. Configuration data: list all configurable actions with their display names and default key strings
#    - action_name:  must match the action names registered in Project Settings → Input Map
#    - display_name: text shown to the player
#    - default_key:  default key string, must correspond to global KEY_<NAME> constants, e.g.:
#                    "E" → KEY_E
#                    "I" → KEY_I
#                    "T" → KEY_T
#                    "Y" → KEY_Y
#                    "M" → KEY_M
#                    "G" → KEY_G
var action_data := [
	{ "action_name":  "attack",           "display_name": "Attack",           "default_key": "E" },
	{ "action_name":  "toggle_inventory", "display_name": "Inventory",        "default_key": "I" },
	{ "action_name":  "pickup_item",      "display_name": "Pickup",           "default_key": "T" },
	{ "action_name":  "toggle_storage",   "display_name": "StorageBox",       "default_key": "Y" },
	{ "action_name":  "toggle_synthesis", "display_name": "SynthesisTable",   "default_key": "M" },
	{ "action_name":  "GOGOGO",           "display_name": "Transmit",         "default_key": "G" }
]

# ————————————————————————————————————————————————————————————————————————————————
# 2. Local cache: record the current bound key string for each action
#    e.g. current_binding["attack"] = "E"
var current_binding : Dictionary = {}

# ————————————————————————————————————————————————————————————————————————————————
# 3. State for “waiting for player key input”
#    When the user clicks a “Rebind” button, record the action name and button reference until
#    the player presses a new key.
var waiting_action_name : String = ""
var waiting_button_ref  : Button = null

func _ready() -> void:
	# Step 1: Initialize default project bindings in InputMap & current_binding
	_init_project_defaults()
	# Step 2: Load player’s custom bindings (KeyConfig will add them to InputMap)
	current_binding = KeyConfig.load_user_bindings()
	# Step 3: Build or refresh the key binding grid
	_build_keybind_grid()

func _init_project_defaults() -> void:
	for data in action_data:
		var act  = data["action_name"]
		var dkey = data["default_key"]
		# Remove all existing events for this action
		InputMap.action_erase_events(act)
		var ev = InputEventKey.new()
		match dkey:
			"E": ev.keycode = KEY_E
			"I": ev.keycode = KEY_I
			"T": ev.keycode = KEY_T
			"Y": ev.keycode = KEY_Y
			"M": ev.keycode = KEY_M
			"G": ev.keycode = KEY_G
			_:  ev.keycode = KEY_UNKNOWN
		InputMap.action_add_event(act, ev)
		current_binding[act] = dkey

func _build_keybind_grid() -> void:
	var grid = $GridContainer
	# Clear old children
	for c in grid.get_children():
		c.queue_free()
	# Recreate rows based on current_binding
	for data in action_data:
		var act  = data["action_name"]
		var disp = data["display_name"]
		# current_binding may have been overridden by load_user_bindings
		var keycode = current_binding.get(act, data["default_key"])
		var keyname = String.chr(keycode)
		current_binding[act] = keyname
		# Column 1: Display name label
		var lbl = Label.new()
		lbl.text = disp
		lbl.size_flags_horizontal = Control.SIZE_FILL | Control.SIZE_SHRINK_END
		grid.add_child(lbl)
		# Column 2: Current key label
		var lbl2 = Label.new()
		lbl2.text = keyname
		lbl2.size_flags_horizontal = Control.SIZE_FILL | Control.SIZE_EXPAND
		grid.add_child(lbl2)
		# Column 3: Rebind button
		var btn = Button.new()
		btn.text = keyname
		btn.size_flags_horizontal = Control.SIZE_FILL | Control.SIZE_EXPAND
		btn.connect("pressed", Callable(self, "_on_ButtonRebind_pressed").bind(act, btn))
		grid.add_child(btn)

func _unhandled_input(event: InputEvent) -> void:
	# If not waiting for any action, ignore
	if waiting_action_name == "":
		return
	# Process only non-echo key press events
	if event is InputEventKey and event.pressed and not event.echo:
		# a) Erase old bindings for this action
		InputMap.action_erase_events(waiting_action_name)
		# b) Create new event with the pressed keycode
		var new_ev := InputEventKey.new()
		new_ev.keycode = (event as InputEventKey).keycode
		# c) Add new event back into InputMap
		InputMap.action_add_event(waiting_action_name, new_ev)
		# d) Convert keycode to string (e.g. "E")
		var new_name = (event as InputEventKey).as_text()
		# Update local cache
		current_binding[waiting_action_name] = new_name
		# e) Update button text immediately
		if waiting_button_ref:
			waiting_button_ref.text = new_name
		# f) End waiting state
		waiting_action_name = ""
		waiting_button_ref  = null
		# Optional: log the new binding
		print("Action [%s] bound to key [%s]" % [waiting_action_name, new_name])

# ————————————————————————————————————————————————————————————————————————————————
# 5. Called when user clicks a row’s “Rebind” button:
#    action_name:   the action to rebind
#    button_rebind: the Button node reference to update its text
func _on_ButtonRebind_pressed(action_name: String, button_rebind: Button) -> void:
	# If another action was waiting, restore its display first
	if waiting_action_name != "":
		_restore_waiting_display()
	# Record the action and button to wait for next key press
	waiting_action_name = action_name
	waiting_button_ref  = button_rebind
	# Temporarily change button text to prompt input
	button_rebind.text = "Press any key..."

# ————————————————————————————————————————————————————————————————————————————————
# 6. Restore button text if the waiting state is canceled
func _restore_waiting_display() -> void:
	if waiting_action_name != "" and waiting_button_ref:
		var old_name = str(current_binding[waiting_action_name])
		waiting_button_ref.text = old_name
	waiting_action_name = ""
	waiting_button_ref  = null

# ————————————————————————————————————————————————————————————————————————————————
# 7. Called when user clicks CloseButton: hide panel and save current_binding
func _on_CloseButton_pressed() -> void:
	hide()
	print(current_binding)
	KeyConfig.save_user_bindings(current_binding)
	# Optional: write current_binding to user://settings.cfg for next launch
	# var cfg = ConfigFile.new()
	# for data in action_data:
	#     var act = data["action_name"]
	#     cfg.set_value("KeyBindings", act, current_binding[act])
	# cfg.save("user://settings.cfg")
