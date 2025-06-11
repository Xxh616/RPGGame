# InnerMargin.gd
extends Control    # 或 MarginContainer（根据你具体用的节点类型而定）

# 如果你上面把弹窗的根节点改成 PopupPanel 或 WindowDialog，就要 extends PopupPanel/WindowDialog

@onready var close_button    = $MarginContainer/CloseButton
@onready var btn_return_menu = $VBoxContainer/Button      # “Return to Main Menu”
@onready var btn_settings    = $VBoxContainer/Button2     # “Settings”
@onready var btn_quit        = $VBoxContainer/Button3     # “Quit”
@onready var settings_panel       = $SettingsControl
func _ready():
	# 1) 给关闭按钮绑定：点击就隐藏整个 InnerMargin 弹窗
	close_button.pressed.connect(_on_CloseButton_pressed)

	# 2) 给“Return to Main Menu”绑定：进入主菜单场景
	btn_return_menu.pressed.connect(_on_ReturnMenu_pressed)

	# 3) 给“Settings”绑定：这里可以再弹出一个更具体的“游戏设置”界面，
	#    也可以切换到一个 Settings 场景。下面示例是切换到一个单独的 Settings 场景：
	btn_settings.pressed.connect(_on_Settings_pressed)

	# 4) 给“Quit”绑定：退出游戏
	btn_quit.pressed.connect(_on_Quit_pressed)

func _on_CloseButton_pressed():
	# 隐藏弹窗
	hide()

func _on_ReturnMenu_pressed():
	# 切换到主菜单场景，路径根据你的项目来改
	SaveGame.save_game()
	# 如果你用的是 Godot 4.x，也可以用：
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	
func _on_Settings_pressed():
	# 示例：切换到一个单独的 Settings 场景
	settings_panel.show()
	
	# 如果你想在当前场景里再弹一个更深层的“游戏设置”弹窗，也可以在这里调用：
	# $AnotherSettingsPanel.show()
	# 而不是 change_scene()，看你需求

func _on_Quit_pressed():
	SaveGame.save_game()
	get_tree().quit()
