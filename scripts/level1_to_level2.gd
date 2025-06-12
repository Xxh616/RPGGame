# res://Scripts/TransitionPoint.gd
extends Node2D
@export var label:Label
# -- Exported variables (set these in the Inspector) --
# The scene to switch to (file path)
@export var target_scene_path: String = "res://scenes/second_level.tscn"
# Where the player will spawn in the new scene (x, y)
@export var spawn_x: float = 66
@export var spawn_y: float = 129
# The direction the player will face after switching ("up"/"down"/"left"/"right")
@export var face_direction_after: String = "down"
# Whether the player must press a confirmation key to switch
# true = must press key after entering area; false = switch immediately on collision
@export var require_confirmation: bool = true
# Text to display as a prompt (e.g. "Press [E] to enter your hometown")
@export var confirm_text: String = "Press G enter"
# NodePath to the Label node used for prompts—set this if you have one in your scene
@export var prompt_label_path: NodePath = ""

# -- Private state --
var player_in_area: bool = false
var prompt_label: Label = null

func _ready():
	# If a valid prompt_label_path was provided, cache and hide that Label
	if prompt_label_path != null and has_node(prompt_label_path):
		prompt_label = get_node(prompt_label_path)
		prompt_label.visible = false

	# Connect to the Area2D’s enter/exit signals
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	# Only react to the Player (ensure your Player node is named "player")
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
		# Wait for the custom "GOGOGO" action (e.g. mapped to G) to trigger the transition
		if Input.is_action_just_pressed("GOGOGO"):
			_do_scene_transition()

func _do_scene_transition():
	# Hide the prompt if it’s visible
	if prompt_label:
		prompt_label.visible = false

	# Write spawn data into a global singleton for the next scene
	global.next_spawn_posx = spawn_x
	global.next_spawn_posy = spawn_y
	global.next_face_direction = face_direction_after

	# If the player lacks the required key item, show a warning and abort
	if !inventory_autoload.has_item("Abyssal Dark Key", 1):
		label.text = "You need to have a Abyssal Dark Key in your backpack to enter the next level"
		label.visible = true
		await get_tree().create_timer(2.0).timeout
		label.visible = false
		return

	# Finally, perform the actual scene change
	if target_scene_path != "":
		var err = get_tree().change_scene_to_file(target_scene_path)
		if err != OK:
			push_error("TransitionPoint: Failed to load scene %s, error code: %s" % [target_scene_path, str(err)])
