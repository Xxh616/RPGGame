extends Node2D

# Export a variable to specify the NodePath of the Inventory UI
@export var inventory_ui_path: NodePath

# Cache commonly used UI nodes
@onready var inventory_ui = get_node(inventory_ui_path) as Control
@onready var synthesis_ui  = $CanvasLayer/Synthesis_UI  as Control
@onready var storage_ui    = $CanvasLayer/Storage_UI    as Control
@onready var inner_margin  = $CanvasLayer/Control/InnerMargin   as Control
@onready var hud_control   = $CanvasLayer/Control       as Control

func _physics_process(delta: float) -> void:
	# Hide HUD whenever any UI panel is open
	hud_control.visible = not (
		inventory_ui.visible 
		or synthesis_ui.visible 
		or storage_ui.visible
	)

func _ready():
	if global.player_alive == false:
		# If the player was marked dead, bring them back to life
		global.player_alive = true
		show_rebirth_message()
	# Restore player health to max on scene load
	global.player_health = global.player_max_health
	if not global.has_load:
		# Defer save-game loading until scene is fully initialized
		call_deferred("_deferred_load")
		var restored := KeyConfig.load_user_bindings()
		global.has_load = true

func _deferred_load():
	SaveGame.load_game()
	global.player_health = global.player_max_health
	

func _unhandled_input(event):
	# Toggle the Inventory UI when the "toggle_inventory" action is pressed
	if event.is_action_pressed("toggle_inventory"):
		inventory_ui.visible = not inventory_ui.visible

# Example button signal callback – toggles the visibility of InnerMargin
func _on_button_pressed() -> void:
	inner_margin.visible = not inner_margin.visible

func show_rebirth_message() -> void:
	var label = $Label
	label.text = "You have been reborn back in the hut"
	label.visible = true
	# Automatically hide the message after 2 seconds
	await get_tree().create_timer(2.0).timeout
	label.visible = false
