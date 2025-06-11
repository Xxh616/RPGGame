extends Node2D

# DynamicSpawner.gd
# 在玩家视野外动态刷怪，并为每个生成的敌人基于其出生位置随机生成巡逻点列表

@export var enemy_scene: PackedScene               # 通用的 Enemy.tscn（挂载 EnemyBase）
@export var enemy_configs: Array[EnemyConfig] = [] # EnemyConfig 资源列表
@export var player_path: NodePath                 # 场景中玩家节点的路径
@export var max_enemies: int = 5                  # 同时允许的最大怪物数
@export var spawn_interval: float = 3.0           # 刷新间隔（秒）
@export var spawn_distance_min: float = 300.0     # 刷新距离下限（像素）
@export var spawn_distance_max: float = 600.0     # 刷新距离上限（像素）
@export var patrol_point_count: int = 3           # 每个敌人生成为圆上的巡逻点数量
@export var patrol_radius: float = 80         # 巡逻半径（相对于出生点）

var _timer: float = 0.0

func _ready() -> void:
	_timer = spawn_interval
	randomize()

func _process(delta: float) -> void:
	var enemies = get_tree().get_nodes_in_group("Enemy")
	if enemies.size() < max_enemies:
		_timer -= delta
		if _timer <= 0.0:
			_spawn_enemy()
			_timer = spawn_interval
	else:
		_timer = spawn_interval

func _spawn_enemy() -> void:
	# 获取并传递玩家引用
	var player_node = get_node_or_null(player_path) as Node2D
	if player_node == null:
		push_warning("DynamicSpawner: 无法通过 player_path 找到玩家节点")
		return

	# 计算随机生成位置（环形区域）
	var player_pos = player_node.global_position
	var angle = randf() * TAU
	var distance = randf_range(spawn_distance_min, spawn_distance_max)
	var spawn_pos = player_pos + Vector2(cos(angle), sin(angle)) * distance

	# 实例化通用 Enemy 场景，并转换类型
	var enemy_node = enemy_scene.instantiate()
	if not enemy_node is EnemyBase:
		push_error("DynamicSpawner: 实例化的 scene 不是 EnemyBase 类型！")
		return
	var enemy = enemy_node as EnemyBase

	# 随机分配配置资源
	if enemy_configs.size() > 0:
		enemy.config = enemy_configs[randi() % enemy_configs.size()]

	# 直接传递玩家引用，确保 EnemyBase.player 有值
	enemy.player = player_node

	# 设置出生点和返回点
	enemy.position = spawn_pos
	enemy.return_point = spawn_pos

	# 生成随机巡逻点列表，基于出生位置的圆上
	var patrols: Array[Vector2] = []
	for i in range(patrol_point_count):
		var a = randf() * TAU
		patrols.append(spawn_pos + Vector2(cos(a), sin(a)) * patrol_radius)
	enemy.patrol_points = patrols

	# 添加到场景树并设置全局位置
	add_child(enemy)
	enemy.global_position = spawn_pos

	# 如果 EnemyBase 有手动初始函数，可调用
	if enemy.has_method("initialize_from_config"):
		enemy.initialize_from_config()

# 使用说明：
# 1. 确保 EnemyBase.gd 在 _ready() 内执行 add_to_group("Enemy").
# 2. 在 Inspector 中设置:
#    - Enemy Scene: 拖入 Enemy.tscn
#    - Enemy Configs: 拖入一个或多个 EnemyConfig.tres
#    - Player Path: 选中玩家节点
#    - max_enemies, spawn_interval, spawn_distance_min/max, patrol_point_count, patrol_radius
