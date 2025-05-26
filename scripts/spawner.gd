# res://scripts/Spawner.gd
extends Node2D

# —— Inspector 可设 —— 
@export var slime_scene: PackedScene = preload("res://scenes/slime_base.tscn")
@export var configs: Array[SlimeConfig] = [
	preload("res://configs/Small_Slime_Red.tres")
]
@export var spawn_area_node: NodePath    # 拖入 SpawnArea 的节点路径
@export var respawn_delay: float = 5.0   # 击杀后延迟补一只
@export var initial_count: int = 15      # 一开始生成数量
@export var max_count: int = 22          # 最大存活数
@export var resume_count: int = 15       # 降到此数才恢复刷怪

# —— 内部状态 —— 
var alive_count: int = 0

# —— 缓存引用 —— 
@onready var spawn_area: Area2D = get_node(spawn_area_node)
@onready var spawn_timer: Timer = $spawn_timer

func _ready() -> void:
	randomize()
	spawn_timer.connect("timeout", Callable(self, "_on_spawn_timer_timeout"))
	# 初始批量生成
	for i in initial_count:
		_spawn_slime()

func _on_spawn_timer_timeout() -> void:
	# 定时器超时后尝试补怪
	_spawn_slime()

func _spawn_slime() -> void:
	# 如果已达上限，不再刷
	if alive_count >= max_count:
		return

	# 1) 随机挑一个配置
	var cfg = configs[randi() % configs.size()]
	# 2) 实例化 SlimeBase
	var slime: SlimeBase = slime_scene.instantiate()
	slime.config = cfg

	# 3) 随机在区域内定位
	var shape = spawn_area.get_node("CollisionShape2D").shape
	if shape is RectangleShape2D:
		var ext = shape.extents
		var center = spawn_area.global_position
		slime.position = center + Vector2(
			randf_range(-ext.x, ext.x),
			randf_range(-ext.y, ext.y)
		)
	else:
		slime.position = spawn_area.global_position

	# 4) 加入场景并监听死亡
	add_child(slime)
	alive_count += 1
	slime.connect("died", Callable(self, "_on_slime_died"))

func _on_slime_died() -> void:
	# 某只死亡，存活数减
	alive_count -= 1
	# 停掉定时器
	spawn_timer.stop()
	# 如果存活数降到 resume_count 以下，才开始延迟补怪
	if alive_count <= resume_count:
		await get_tree().create_timer(respawn_delay).timeout
		spawn_timer.start()
