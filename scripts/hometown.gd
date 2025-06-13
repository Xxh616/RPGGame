extends Node2D

# Export a variable to specify the NodePath for the Inventory UI
@export var inventory_ui_path: NodePath

# Cache frequently used UI nodes
@onready var inventory_ui = get_node(inventory_ui_path) as Control
@onready var inner_margin  = $CanvasLayer/Control/InnerMargin as Control
@onready var hud_control   = $CanvasLayer/Control       as Control

func _physics_process(delta: float) -> void:
	# In other scenes, show or hide the HUD based solely on the Inventory UI visibility
	hud_control.visible = not inventory_ui.visible
	_on_playerdie()

func _unhandled_input(event):
	# When the player presses the "toggle_inventory" action, toggle the Inventory UI
	if event.is_action_pressed("toggle_inventory"):
		inventory_ui.visible = not inventory_ui.visible

# Example button signal callback – toggle the InnerMargin visibility
func _on_button_pressed() -> void:
	inner_margin.visible = not inner_margin.visible

func _on_playerdie():
	# If the player has died, switch back to the home scene
	if global.player_alive == false:
		get_tree().change_scene_to_file("res://scenes/home.tscn")
