# res://Scripts/TransitionPoint.gd
extends Node2D
class_name TransitionPoint

# —— Inspector-exposed variables —— 
# Path of the scene to switch to
@export var target_scene_path: String = "res://scenes/final_level.tscn"
# Coordinates where the player will spawn in the new scene (x, y)
@export var spawn_x: float = 111
@export var spawn_y: float = 400
# Optional: the direction the player will face after transition ("up"/"down"/"left"/"right")
@export var face_direction_after: String = "down"
# Whether the player must press a confirmation key to transition
# (true = must press key after entering area; false = immediate transition on collision)
@export var require_confirmation: bool = true
# Text to display as a prompt (e.g. "Press [E] to enter the hometown")
@export var confirm_text: String = "Press [G] to enter"
# NodePath to a Label for the prompt text, set in the Inspector if you have one
@export var prompt_label_path: NodePath = ""

# —— Internal state —— 
var player_in_area: bool = false
var prompt_label: Label = null

func _ready():
	# If a prompt_label_path was provided, cache and hide the Label
	if prompt_label_path != null and has_node(prompt_label_path):
		prompt_label = get_node(prompt_label_path)
		prompt_label.visible = false

	# Connect Area2D signals for body entry/exit
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	# Only trigger for the node named "player"
	if body.name == "player":
		player_in_area = true
		if prompt_label:
			prompt_label.text = confirm_text
			prompt_label.visible = true

func _on_body_exited(body):
	if body.name == "player":
		player_in_area = false
		if prompt_label:
			prompt_label.visible = false

func _process(delta):
	if not player_in_area:
		return

	if require_confirmation:
		# Wait for the player to press the interaction key (e.g. "GOGOGO" mapped to G)
		if Input.is_action_just_pressed("GOGOGO"):
			_do_scene_transition()
	else:
		# Immediate transition without confirmation
		_do_scene_transition()

func _do_scene_transition():
	# Hide the prompt label if present
	if prompt_label:
		prompt_label.visible = false

	# Store spawn position and facing direction in Global before switching scenes
	global.next_spawn_posx = spawn_x
	global.next_spawn_posy = spawn_y
	global.next_face_direction = face_direction_after

	# Perform the scene change
	if target_scene_path != "":
		var err = get_tree().change_scene_to_file(target_scene_path)
		if err != OK:
			push_error("TransitionPoint: Failed to load scene %s, error code: %s" % [target_scene_path, str(err)])
