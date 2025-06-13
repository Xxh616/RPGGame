extends Node2D

# The following variables can be set directly in the Inspector
# The scene file path to switch to
@export var target_scene_path: String = "res://scenes/hometown.tscn"

# The coordinates (x, y) where the player should appear in the new scene
@export var spawn_x: float = 776
@export var spawn_y: float = 150

# The direction the player should face after transitioning ("up"/"down"/"left"/"right")
@export var face_direction_after: String = "down"

# Whether the player must press a confirmation key to transition
# (true = must press the key after entering area, false = transition on collision)
@export var require_confirmation: bool = true

# The prompt text to display (e.g., "Press G to enter")
@export var confirm_text: String = "按 G 进入"

# The NodePath to a Label for showing the prompt; set this if you have a Label node
@export var prompt_label_path: NodePath = ""

# Private variables
var player_in_area: bool = false
var prompt_label: Label = null

func _ready():
	# Cache and hide the prompt label if a valid path was provided
	if prompt_label_path != null and has_node(prompt_label_path):
		prompt_label = get_node(prompt_label_path)
		prompt_label.visible = false

	# Connect Area2D signals
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	# Only react if the body is the player (ensure your Player node implements a "player" method)
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
		# Require the player to press the confirmation action (e.g., "toggle_storage" or custom) to transition
		if Input.is_action_just_pressed("GOGOGO"):
			_do_scene_transition()
	else:
		# If no confirmation is required, transition immediately
		_do_scene_transition()

func _do_scene_transition():
	# Hide the prompt label
	if prompt_label:
		prompt_label.visible = false

	# Store the next scene spawn data in a global script or singleton
	global.next_spawn_posx = spawn_x
	global.next_spawn_posy = spawn_y
	global.next_face_direction = face_direction_after

	# Execute the scene change
	if target_scene_path != "":
		var err = get_tree().change_scene_to_file(target_scene_path)
		if err != OK:
			push_error("TransitionPoint: Failed to load scene %s, error code: %s" % [target_scene_path, str(err)])
