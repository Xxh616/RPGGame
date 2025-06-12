extends Node2D

# NoticeBoard.gd
# 当玩家进入区域并按 F 键时，显示或隐藏一个自定义内容的 UI 面板。

@export var interaction_key: String = "Check"   # 输入操作名称，例如在 InputMap 中映射到 F 键
@export var ui_panel_path: NodePath				  # 指向场景中 Control（UI 板）的路径
@export var content: String = "Hello, this is a notice!"  # 默认提示内容，可在 Inspector 中修改

var _player_in_range: bool = false
@onready var _ui_panel: Control =get_node(ui_panel_path)
@onready var _label: Label = _ui_panel.get_node("Label")

func _ready() -> void:
	# 确保 UI 面板初始隐藏
	_ui_panel.visible = false
	# 监听碰撞层中进入和退出

func _process(delta: float) -> void:
	if _player_in_range and Input.is_action_just_pressed(interaction_key):
		_toggle_panel()

func _on_body_entered(body: Node) -> void:
	# 假设玩家有名为 "Player" 的组或脚本类判断
	if body.has_method("player"):
		_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.has_method("player"):
		_player_in_range = false
		# 离开范围时隐藏面板
		_ui_panel.visible = false

func _toggle_panel() -> void:
	_ui_panel.visible = not _ui_panel.visible
	if _ui_panel.visible:
		# 设置 Label 内容
		_label.text = content
