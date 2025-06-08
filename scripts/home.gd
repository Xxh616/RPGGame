extends Node2D

# 导出一个变量，用来指定 Inventory UI 的节点路径
@export var inventory_ui_path: NodePath

# 缓存几个会用到的 UI 节点
@onready var inventory_ui = get_node(inventory_ui_path) as Control
@onready var synthesis_ui  = $CanvasLayer/Synthesis_UI  as Control
@onready var storage_ui    = $CanvasLayer/Storage_UI    as Control
@onready var inner_margin  = $CanvasLayer/Control/InnerMargin   as Control
@onready var hud_control   = $CanvasLayer/Control       as Control

func _physics_process(delta: float) -> void:
	hud_control.visible = not (
		inventory_ui.visible 
		or synthesis_ui.visible 
		or storage_ui.visible
	)
func _ready():
	# 确保本场景已经初始化完成，才去做存档恢复
	call_deferred("_deferred_load")
	var restored := KeyConfig.load_user_bindings()
func _deferred_load():
	SaveGame.load_game()

func _unhandled_input(event):
	# 当玩家按下 “toggle_inventory” 的按键时，切换 InventoryUI 的可见性
	if event.is_action_pressed("toggle_inventory"):
		inventory_ui.visible = not inventory_ui.visible

# 假设这是某个按钮的信号回调——点击后切换 InnerMargin 的可见性
func _on_button_pressed() -> void:
	inner_margin.visible = not inner_margin.visible
