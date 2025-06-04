extends Node2D

@export var inventory_ui_path: NodePath

@onready var inventory_ui = get_node(inventory_ui_path) as Control

func _unhandled_input(event):
	if event.is_action_pressed("toggle_inventory"):
		inventory_ui.visible = not inventory_ui.visible
