extends Node2D

# The following variables can be set in the Inspector
# The scene to switch to (file path)
@export var target_scene_path: String = "res://scenes/home.tscn"  

# The coordinates (x, y) where the player will appear in the new scene
@export var spawn_x: float = 71
@export var spawn_y: float = 68

# The direction the player will face after switching ("up"/"down"/"left"/"right"), optional
@export var face_direction_after: String = "down"

# Whether the player must press a confirmation key to switch
# true = must press the key after entering the area; false = switch immediately on contact
@export var require_confirmation: bool = true

# Prompt text to display (e.g., "Press G to enter")
@export var confirm_text: String = "Press G to enter"

# NodePath to the prompt Label; set this in the Inspector if you have a Label node
@export var prompt_label_path: NodePath = ""

# Private variables
var player_in_area: bool = false
var prompt_label: Label = null

func _ready():
	# Cache the prompt_label and hide it if a valid path was provided in the Inspector
	if prompt_label_path != null and has_node(prompt_label_path):
		prompt_label = get_node(prompt_label_path)
		prompt_label.visible = false

	# Connect Area2D enter/exit signals
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	# Only trigger for the player node (ensure your Player node implements a `player` method)
	if body.has_method("player"):
		player_in_area = true
		if prompt_label:
			prompt_label.text = confirm_text
			prompt_label.visible = true

func _on_body_exited(body):
	# Only respond when the player exits the area
	if body.has_method("player"):
		player_in_area = false
		if prompt_label:
			prompt_label.visible = false

func _process(delta):
	if not player_in_area:
		return

	if require_confirmation:
		# After entering the area, require the "GOGOGO" action to switch scenes
		if Input.is_action_just_pressed("GOGOGO"):
			_do_scene_transition()

func _do_scene_transition():
	# Hide the prompt label
	if prompt_label:
		prompt_label.visible = false

	# Store the next scene's spawn information in the Global singleton
	global.next_spawn_posx = spawn_x
	global.next_spawn_posy = spawn_y
	global.next_face_direction = face_direction_after

	# Perform the scene change
	if target_scene_path != "":
		var err = get_tree().change_scene_to_file(target_scene_path)
		if err != OK:
			push_error("TransitionPoint: Failed to load scene %s, error code: %s" % [target_scene_path, str(err)])
