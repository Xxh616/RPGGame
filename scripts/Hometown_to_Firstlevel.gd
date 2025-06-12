# res://Scripts/TransitionPoint.gd
extends Node2D

# -- Exported variables (set these in the Inspector) --
# The scene to switch to (file path)
@export var target_scene_path: String = "res://scenes/first_level.tscn"

# The coordinates (x, y) where the player will appear in the new scene
@export var spawn_x: float = 137
@export var spawn_y: float = 523
@export var label:Label
# The direction the player will face after switching ("up"/"down"/"left"/"right"), optional
@export var face_direction_after: String = "down"

# Whether the player must press a confirmation key to switch
# true = must press key after entering area; false = switch immediately on contact
@export var require_confirmation: bool = true

# Prompt text to display (e.g., "Press [E] to enter your hometown")
@export var confirm_text: String = "Press G to enter"

# NodePath to the Prompt Label; if you have a Label in your scene, set its NodePath here
@export var prompt_label_path: NodePath = ""

# -- Private variables --
var player_in_area: bool = false
var prompt_label: Label = null

func _ready():
	
	# If prompt_label_path is set in the Inspector, cache the Label node and hide it
	if prompt_label_path != null and has_node(prompt_label_path):
		prompt_label = get_node(prompt_label_path)
		prompt_label.visible = false

	# Connect to the Area2D enter/exit signals
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	# Only trigger for the node named "player" (ensure your Player node is named "player")
	if body.has_method("player"):
		player_in_area = true
		if prompt_label:
			prompt_label.text = confirm_text
			prompt_label.visible = true

func _on_body_exited(body):
	if body.has_method("player"):
		player_in_area = false
		if prompt_label:
			prompt_label.visible = false

func _process(delta):
	if not player_in_area:
		return

	if require_confirmation:
		# After entering the area, the player must press the "GOGOGO" action to switch
		if Input.is_action_just_pressed("GOGOGO"):
			_do_scene_transition()

func _do_scene_transition():
	# Hide the prompt label
	if prompt_label:
		prompt_label.visible = false

	# First, write the next scene's spawn information to the Global singleton
	global.next_spawn_posx = spawn_x
	global.next_spawn_posy = spawn_y
	global.next_face_direction = face_direction_after

	# If you need to track the current scene after switching, you can update Global.current_scene here.
	# However, it's usually done after the new scene loads, so we leave it for later.

	# Check for required item; if missing, show a warning and abort
	if !inventory_autoload.has_item("Magic Book", 1):
		label.text = "You need to have a magic book in your backpack to enter the next level"
		label.visible = true
		await get_tree().create_timer(2.0).timeout
		label.visible = false
		return

	# Perform the scene change
	if target_scene_path != "":
		var err = get_tree().change_scene_to_file(target_scene_path)
		if err != OK:
			push_error("TransitionPoint: Failed to load scene %s, error code: %s" % [target_scene_path, str(err)])
