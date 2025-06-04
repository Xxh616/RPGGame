# res://Scripts/TransitionPoint.gd
extends Node2D

# —— 以下变量在 Inspector 里可以直接设置 —— 
# 切换到哪个场景（文件路径）
@export var target_scene_path: String = "res://scenes/first_level.tscn"  

# 切换后玩家要出现在新场景中的哪个坐标 （x, y）
@export var spawn_x: float = 137
@export var spawn_y: float = 523

# 切换后玩家朝哪个方向（"up"/"down"/"left"/"right"），可选
@export var face_direction_after: String = "down"

# 是否要玩家按下确认键才切换？（true = 进范围后还要按 E，false = 一碰撞即切换）
@export var require_confirmation: bool = true

# 提示文字内容（示例： "按 [E] 进入家乡小镇"）
@export var confirm_text: String = "按 G 进入"

# PromptLabel 的节点路径，如果你场景里加了一个 Label，就在 Inspector 里填写它的 NodePath
@export var prompt_label_path: NodePath = ""

# —— 私有变量 —— 
var player_in_area: bool = false
var prompt_label: Label = null

func _ready():
	# 如果 Inspector 填了 prompt_label_path，就把它缓存并隐藏
	if prompt_label_path != null and has_node(prompt_label_path):
		prompt_label = get_node(prompt_label_path)
		prompt_label.visible = false

	# 监听 Area2D 信号
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	# 只对名为 "player" 的节点触发（确保你的 Player 节点名字是 "player"）
	if body.has_method("player"):
		player_in_area = true
		if prompt_label:
			prompt_label.text = confirm_text
			prompt_label.visible = true

func _on_body_exited(body):
	if body.has_method("player"):
		player_in_area = false
		if prompt_label:
			prompt_label.visible = false

func _process(delta):
	if not player_in_area:
		return

	if require_confirmation:
		# 玩家进范围后，还要按确认键（ui_accept，一般就是 E）
		if Input.is_action_just_pressed("GOGOGO"):
			_do_scene_transition()

func _do_scene_transition():
	# 隐藏提示文字
	if prompt_label:
		prompt_label.visible = false

	# 先把下一场景的位置信息写入 Global
	global.next_spawn_posx = spawn_x
	global.next_spawn_posy = spawn_y
	global.next_face_direction = face_direction_after

	# 如果你要在切换后知道当前场景，也可以在这里更新 Global.current_scene = ...
	# 但一般是新场景加载后再改，这里就不先改

	# 执行场景切换
	if target_scene_path != "":
		var err = get_tree().change_scene_to_file(target_scene_path)
		if err != OK:
			push_error("TransitionPoint: 无法加载场景 %s，错误码：%s" % [target_scene_path, str(err)])
