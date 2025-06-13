# Scripts/Chest.gd
extends CharacterBody2D

# Drag the NodePath to the ChestUI (Control) node in the main scene here
@export var chest_ui_path: NodePath

var player_in_range: bool = false
var chest_ui: Control = null

func _ready():
	# Cache the ChestUI and hide it by default
	if chest_ui_path != null and has_node(chest_ui_path):
		chest_ui = get_node(chest_ui_path)
		chest_ui.visible = false

	# Connect to this node's Area2D signals for detecting when bodies enter/exit
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	# Only respond to the player node
	if body.has_method("player"):
		player_in_range = true
		# (Optional) To show a prompt like "Press E to open chest",
		# you could add a Label under this Chest node and set:
		# chest_prompt_label.visible = true

func _on_body_exited(body):
	if body.has_method("player"):
		player_in_range = false
		# (Optional) Hide the prompt:
		# chest_prompt_label.visible = false

func _process(delta):
	# Only when the player is in range and presses the interact key
	if player_in_range and Input.is_action_just_pressed("toggle_storage"):
		open_chest_ui()

func open_chest_ui():
	if chest_ui:
		# If you want to pause the entire game world, you can add:
		# get_tree().paused = true
		chest_ui.visible = !chest_ui.visible
		# TODO: Send the chest's item data to the ChestUI, e.g.:
		# chest_ui.call("populate_slots", items_array)
