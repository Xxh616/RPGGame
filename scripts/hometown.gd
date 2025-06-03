extends Node2D

@export var inventory_ui_path: NodePath
@export var storage_ui_path: NodePath
@export var synthesis_ui_path: NodePath
@onready var synthesis_ui = get_node(synthesis_ui_path) as Control
@onready var inventory_ui = get_node(inventory_ui_path) as Control
@onready var storage_ui = get_node(storage_ui_path) as Control
func _unhandled_input(event):
	if event.is_action_pressed("toggle_inventory"):
		inventory_ui.visible = not inventory_ui.visible
	if event.is_action_pressed("toggle_storage"):
		storage_ui.visible = not storage_ui.visible
	if event.is_action_pressed("toggle_synthesis"):
		synthesis_ui.visible = not synthesis_ui.visible
