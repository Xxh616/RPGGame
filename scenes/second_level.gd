extends Node2D

# 导出一个变量，用来指定 Inventory UI 的节点路径
@export var inventory_ui_path: NodePath
@onready var light_2d := $player/PointLight2D as Light2D
# 缓存几个会用到的 UI 节点
@onready var inventory_ui = get_node(inventory_ui_path) as Control
@onready var inner_margin  = $CanvasLayer/Control/InnerMargin   as Control
@onready var hud_control   = $CanvasLayer/Control      as Control

func _physics_process(delta: float) -> void:
		# 其它场景，只用根据背包是否打开来决定 HUD
		hud_control.visible = not inventory_ui.visible
		_on_playerdie()
		_light_adjust()
func _unhandled_input(event):
	# 当玩家按下 “toggle_inventory” 的按键时，切换 InventoryUI 的可见性
	if event.is_action_pressed("toggle_inventory"):
		inventory_ui.visible = not inventory_ui.visible

# 假设这是某个按钮的信号回调——点击后切换 InnerMargin 的可见性
func _on_button_pressed() -> void:
	inner_margin.visible = not inner_margin.visible
func _on_playerdie():
	if global.player_alive==false:
		get_tree().change_scene_to_file("res://scenes/home.tscn")
func _light_adjust():
	light_2d.scale.x=global.visible_range.x
	light_2d.scale.y=global.visible_range.y
