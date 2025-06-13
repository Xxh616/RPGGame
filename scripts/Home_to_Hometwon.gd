extends Node2D

# — Exported variables (set in the Inspector) —
# The scene file to switch to
@export var target_scene_path: String = "res://scenes/hometown.tscn"

# The (x, y) coordinates where the player will spawn in the new scene
@export var spawn_x: float = 955
@export var spawn_y: float = 247

# The direction the player should face after the transition ("up"/"down"/"left"/"right")
@export var face_direction_after: String = "down"

# Whether the player must press a confirmation key to trigger the transition
# true = must press a key after entering the area; false = transition immediately on contact
@export var require_confirmation: bool = true

# The prompt text to display (e.g., "Press [G] to enter")
@export var confirm_text: String = "Press [G] enter"

# NodePath to the prompt Label; assign in the Inspector if you have a Label node
@export var prompt_label_path: NodePath = ""

# — Private variables —
var player_in_area: bool = false
var prompt_label: Label = null

func _ready():
	# Cache and hide the prompt label if a valid NodePath was provided
	if prompt_label_path != null and has_node(prompt_label_path):
		prompt_label = get_node(prompt_label_path)
		prompt_label.visible = false

	# Connect enter/exit signals from the Area2D child
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	# Only react if the body is the player node named "player"
	if body.name == "player":
		player_in_area = true
		if prompt_label:
			prompt_label.text = confirm_text
			prompt_label.visible = true

func _on_body_exited(body):
	# Only react when the player exits the area
	if body.name == "player":
		player_in_area = false
		if prompt_label:
			prompt_label.visible = false

func _process(delta):
	if not player_in_area:
		return

	if require_confirmation:
		# Require pressing the "GOGOGO" action (e.g., G key) to trigger the transition
		if Input.is_action_just_pressed("GOGOGO"):
			_do_scene_transition()

func _do_scene_transition():
	# Hide the prompt label
	if prompt_label:
		prompt_label.visible = false

	# Store next scene spawn data in the Global singleton
	global.next_spawn_posx = spawn_x
	global.next_spawn_posy = spawn_y
	global.next_face_direction = face_direction_after

	# Perform the scene change
	if target_scene_path != "":
		var err = get_tree().change_scene_to_file(target_scene_path)
		if err != OK:
			push_error("TransitionPoint: Failed to load scene %s, error code: %s" %
				[target_scene_path, str(err)])
