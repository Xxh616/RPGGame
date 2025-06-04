# Scripts/SynthesisTable.gd
extends Node2D

# 将主场景中 SynthesisUI (Control) 的节点路径拖到此处
@export var synthesis_ui_path: NodePath

var player_in_range: bool = false
var synthesis_ui : Control = null

func _ready():
	# 缓存 SynthesisUI，默认隐藏
	if synthesis_ui_path != null and has_node(synthesis_ui_path):
		synthesis_ui = get_node(synthesis_ui_path)
		synthesis_ui.visible = false

	# 监听自己下面 Area2D 的信号
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.has_method("player"):
		player_in_range = true
		# （可选）显示一个提示 Label，例如 “按 E 进行合成”
		
func _on_body_exited(body):
	if body.has_method("player"):
		player_in_range = false
		# （可选）隐藏提示 Label

func _process(delta):
	if player_in_range and Input.is_action_just_pressed("toggle_synthesis"):
		open_synthesis_ui()

func open_synthesis_ui():
	if synthesis_ui:
		# get_tree().paused = true  # 如果想暂停世界逻辑，可以加这一行
		synthesis_ui.visible = !synthesis_ui.visible
		# TODO: 把“可用配方数据”+“玩家当前背包”传给 SynthesisUI，
		#      例如： synthesis_ui.call("init_recipes", recipe_array, player_inventory)
