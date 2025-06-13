# MainMenu.gd
extends Control

# Get button nodes via onready
@onready var new_game_button  : Button  = $MenuContainer/NewGameButton
@onready var load_game_button : Button  = $MenuContainer/LoadGameButton
@onready var options_button   : Button  = $MenuContainer/OptionsButton
@onready var quit_button      : Button  = $MenuContainer/QuitButton
# Settings panel control node
@onready var settings_panel   : Control = $Control

func _ready():
	# Connect each button's pressed signal to its handler function
	new_game_button.pressed.connect(_on_new_game_pressed)
	load_game_button.pressed.connect(_on_load_game_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

# Handler for New Game button: clear any existing save and switch to the home scene
func _on_new_game_pressed():
	SaveGame.clear_save()
	get_tree().change_scene_to_file("res://scenes/home.tscn")

# Handler for Load Game button: switch to the home scene or a dedicated save menu
func _on_load_game_pressed():
	get_tree().change_scene_to_file("res://scenes/home.tscn")

# Handler for Options button: show the settings panel
func _on_options_pressed():
	settings_panel.show()

# Handler for Quit button: exit the game application
func _on_quit_pressed():
	get_tree().quit()
