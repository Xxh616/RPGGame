# NoticeBoard.gd
extends Node2D
class_name NoticeBoard

# The input action name to listen for (e.g. mapped to the “F” key)
@export var interaction_key: String = "Check"
# Path to the UI panel Control node that displays the notice
@export var ui_panel_path: NodePath
# The text content to show in the notice label
@export var content: String = "Hello, this is a notice!"

# Internal flag: is the player currently in range?
var _player_in_range: bool = false
@onready var label:Label=$Label
# Cached references
@onready var _ui_panel: Control = get_node(ui_panel_path)
@onready var _label: Label = _ui_panel.get_node("Label")
@onready var _area: Area2D = $Area2D

func _ready() -> void:
	label.visible=false
	# Ensure the UI panel is hidden at start
	_ui_panel.visible = false
	# Connect the Area2D enter/exit signals

func _process(delta: float) -> void:
	# When player is in range and presses the interaction key, toggle the panel
	if _player_in_range and Input.is_action_just_pressed(interaction_key):
		_toggle_panel()

func _on_body_entered(body: Node) -> void:
	# If the entering body is the player, set the flag
	if body.has_method("player"):
		_player_in_range = true
		label.visible=true

func _on_body_exited(body: Node) -> void:
	# If the exiting body is the player, unset the flag and hide the panel
	if body.has_method("player"):
		_player_in_range = false
		_ui_panel.visible = false
		label.visible=false

func _toggle_panel() -> void:
	# Show or hide the UI panel and update its label text when showing
	_ui_panel.visible = not _ui_panel.visible
	if _ui_panel.visible:
		_label.text = content
