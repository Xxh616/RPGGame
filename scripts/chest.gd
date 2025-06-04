# Scripts/Chest.gd
extends Node2D

# 将主场景中 ChestUI (Control) 的节点路径拖到此处
@export var chest_ui_path: NodePath

var player_in_range: bool = false
var chest_ui : Control  = null

func _ready():
	# 缓存 ChestUI，默认隐藏
	if chest_ui_path != null and has_node(chest_ui_path):
		chest_ui = get_node(chest_ui_path)
		chest_ui.visible = false

	# 监听自己下面 Area2D 的信号
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	# 只对名为 “player” 的节点触发
	if body.has_method("player"):
		player_in_range = true
		# （可选）如果想在此时显示一个提示文字，比如 “按 E 打开箱子”，
		# 可以在 Chest 下面再挂一个 Label，然后在这里 chest_prompt_label.visible = true
		
func _on_body_exited(body):
	if body.has_method("player"):
		player_in_range = false
		# （可选）隐藏提示文字： chest_prompt_label.visible = false

func _process(delta):
	# 只有在玩家在范围里，并且按下交互键（ui_accept）
	if player_in_range and Input.is_action_just_pressed("toggle_storage"):
		open_chest_ui()

func open_chest_ui():
	if chest_ui:
		# 如果需要暂停整个游戏世界，可以加一句： get_tree().paused = true
		chest_ui.visible = !chest_ui.visible
		# TODO: 这里可以把“箱子里的物品数据”传给 ChestUI 
		#      e.g. chest_ui.call("populate_slots", items_array)
