# File: res://scripts/KeyConfig.gd
extends Node
class_name KeyConfig



# 1) List of all actions that can be remapped (must match names in Project Settings → Input Map)
static var actions := [
	"attack",
	"toggle_inventory",
	"pickup_item",
	"toggle_storage",
	"toggle_synthesis",
	"GOGOGO"
]

# 2) Path to the key configuration file
const KEYCFG_PATH := "user://input.cfg"


# ----------------------------------------------------------------
# load_user_bindings():
#   Reads the player's saved action→scancode mappings from user://input.cfg,
#   appends any custom mappings to the InputMap, and returns a Dictionary
#   of the form { "attack": 35, "pickup_item": 84, ... }
# ----------------------------------------------------------------
static func load_user_bindings() -> Dictionary:
	var result := {}

	var cfg := ConfigFile.new()
	var err := cfg.load(KEYCFG_PATH)
	if err != OK:
		# Config file does not exist or failed to load — assume no custom bindings
		for action_name in KeyConfig.actions:
			result[action_name] = 0
		return result

	# Read values from the [KeyBindings] section
	for action_name in KeyConfig.actions:
		var sc := int(cfg.get_value("KeyBindings", action_name, 0))
		result[action_name] = sc
		if sc > 0:
			# Player has a custom key — add it to the InputMap
			var ev := InputEventKey.new()
			ev.physical_keycode = sc
			InputMap.action_add_event(action_name, ev)
		# If sc == 0, no custom binding — leave default mapping intact

	return result


# ----------------------------------------------------------------
# save_user_bindings(bindings_dict):
#   Writes the provided { action_name: scancode, ... } Dictionary
#   to user://input.cfg under the [KeyBindings] section.
#   Typically called when the player clicks “Save” in the key settings UI.
# ----------------------------------------------------------------
static func save_user_bindings(bindings_dict: Dictionary) -> void:
	var cfg := ConfigFile.new()

	# Load existing file if present to avoid overwriting other sections
	cfg.load(KEYCFG_PATH)

	# Write the player’s custom mappings into [KeyBindings]
	for action_name in KeyConfig.actions:
		var sc = 0
		if bindings_dict.has(action_name):
			sc = convert_character_to_int(bindings_dict[action_name])
		cfg.set_value("KeyBindings", action_name, sc)

	var save_err := cfg.save(KEYCFG_PATH)
	if save_err != OK:
		push_error("KeyConfig: Failed to write user key config to: " + KEYCFG_PATH)
	else:
		print("KeyConfig: User key config saved to: " + KEYCFG_PATH)


# Helper: Converts a single uppercase letter ("A"–"Z") to its ASCII code; returns 0 otherwise
static func convert_character_to_int(s: String) -> int:
	for i in range(65, 90):
		if String.chr(i) == s:
			return i
	return 0
