# MainMenu.gd
extends Control

# 通过 onready 获取按钮节点
@onready var new_game_button   : Button = $MenuContainer/NewGameButton
@onready var load_game_button  : Button = $MenuContainer/LoadGameButton
@onready var options_button    : Button = $MenuContainer/OptionsButton
@onready var quit_button       : Button = $MenuContainer/QuitButton

func _ready():
	# 将按钮按下信号连接到对应函数
	new_game_button.pressed.connect(_on_new_game_pressed)
	load_game_button.pressed.connect(_on_load_game_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

# 新游戏按钮响应，切换到游戏主场景（假设路径为 res://scenes/Game.tscn）
func _on_new_game_pressed():
	SaveGame.clear_save()
	get_tree().change_scene_to_file("res://scenes/home.tscn")
# 读取存档按钮响应，打开存档菜单（可另建一个 SaveMenu 场景）
func _on_load_game_pressed():
	
	get_tree().change_scene_to_file("res://scenes/home.tscn")

# 设置按钮响应，打开设置界面（可另建一个 OptionsMenu 场景）
func _on_options_pressed():
	get_tree().change_scene_to_file("res://scenes/settings_control.tscn")
# 退出按钮响应，退出游戏
func _on_quit_pressed():
	get_tree().quit()
