extends Control   



@onready var close_button    = $MarginContainer/CloseButton
@onready var btn_return_menu = $VBoxContainer/Button      # “Return to Main Menu”
@onready var btn_settings    = $VBoxContainer/Button2     # “Settings”
@onready var btn_quit        = $VBoxContainer/Button3     # “Quit”
@onready var settings_panel  = $SettingsControl

func _ready():
	# 1) Connect the Close button: hide this popup when clicked
	close_button.pressed.connect(_on_CloseButton_pressed)

	# 2) Connect “Return to Main Menu”: switch to the main menu scene
	btn_return_menu.pressed.connect(_on_ReturnMenu_pressed)

	# 3) Connect “Settings”: show the settings panel or switch to a Settings scene
	btn_settings.pressed.connect(_on_Settings_pressed)

	# 4) Connect “Quit”: exit the game
	btn_quit.pressed.connect(_on_Quit_pressed)

func _on_CloseButton_pressed():
	# Hide the popup
	hide()

func _on_ReturnMenu_pressed():
	# Save the game and switch to the main menu scene (update path as needed)
	SaveGame.save_game()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_Settings_pressed():
	# Example: show an in-scene Settings panel
	settings_panel.show()

func _on_Quit_pressed():
	# Save the game and quit the application
	SaveGame.save_game()
	get_tree().quit()
