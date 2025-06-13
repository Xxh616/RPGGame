extends Node2D
class_name GameController  # (Optional) give this script a class name

# Exported variable to specify the Inventory UI node path
@export var inventory_ui_path: NodePath
# Cache a reference to the player's 2D light
@onready var light_2d := $player/PointLight2D as Light2D
# Cache references to UI nodes that will be used
@onready var inventory_ui = get_node(inventory_ui_path) as Control
@onready var inner_margin  = $CanvasLayer/Control/InnerMargin   as Control
@onready var hud_control   = $CanvasLayer/Control                as Control

func _physics_process(delta: float) -> void:
	# For all other scenes, show HUD only when Inventory UI is closed
	hud_control.visible = not inventory_ui.visible
	_on_player_die()
	_light_adjust()

func _unhandled_input(event):
	# Toggle Inventory UI visibility when the player presses the "toggle_inventory" action
	if event.is_action_pressed("toggle_inventory"):
		inventory_ui.visible = not inventory_ui.visible

# Example callback for a button signal — toggles InnerMargin visibility when clicked
func _on_button_pressed() -> void:
	inner_margin.visible = not inner_margin.visible

func _on_player_die():
	# If the player is dead, switch back to the home scene
	if global.player_alive == false:
		get_tree().change_scene_to_file("res://scenes/home.tscn")

func _light_adjust():
	# Adjust the 2D light's scale based on the global visible range
	light_2d.scale.x = global.visible_range.x
	light_2d.scale.y = global.visible_range.y
