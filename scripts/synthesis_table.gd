# Scripts/SynthesisTable.gd
extends CharacterBody2D

# Drag the NodePath of SynthesisUI (Control) from the main scene into this export
@export var synthesis_ui_path: NodePath

var player_in_range: bool = false
var synthesis_ui: Control = null

func _ready():
	# Cache the SynthesisUI and hide it by default
	if synthesis_ui_path != null and has_node(synthesis_ui_path):
		synthesis_ui = get_node(synthesis_ui_path)
		synthesis_ui.visible = false

	# Connect signals from the Area2D under this node
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	# If the entering body is the player, mark as in range
	if body.has_method("player"):
		player_in_range = true
		# (Optional) Show a prompt label, e.g. "Press E to synthesize"

func _on_body_exited(body):
	# If the exiting body is the player, mark as out of range
	if body.has_method("player"):
		player_in_range = false
		# (Optional) Hide the prompt label

func _process(delta):
	# When player is in range and presses the synthesis toggle key, open the UI
	if player_in_range and Input.is_action_just_pressed("toggle_synthesis"):
		open_synthesis_ui()

func open_synthesis_ui():
	if synthesis_ui:
		# get_tree().paused = true  # Uncomment to pause game logic when UI is open
		synthesis_ui.visible = !synthesis_ui.visible
		# TODO: Pass the available recipes and the player's current inventory to the UI,
		#       e.g.: synthesis_ui.call("init_recipes", recipe_array, player_inventory)
