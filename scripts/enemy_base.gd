# res://scripts/EnemyBase.gd
extends CharacterBody2D
class_name EnemyBase
# —— 新增字段：攻击区偏移与大小 —— #
@export var attack_offset : Vector2 = Vector2(15, 5) # 攻击区中心与角色中心的距离
@export var attack_halfsize  : Vector2  = Vector2(20,10)  # 攻击区矩形半宽半高

# —— 缓存 AttackArea 与它的 CollisionShape2D —— #
@onready var attack_area  := $AttackArea           as Area2D
@onready var attack_shape := $AttackArea/CollisionShape2D as CollisionShape2D

# —— 新增状态：是否允许伤害判定 —— #
var attack_valid : bool = false

# —— 在 Inspector 里拖入配置 Resource（EnemyConfig.tres） —— 
@export var configs: Array[EnemyConfig] = []     # 配置资源列表
var config: EnemyConfig                         # 选中的当前配置

# —— 在 Inspector 里拖入玩家节点的 NodePath —— 
@export var player_path: NodePath
var return_point: Vector2 = Vector2.ZERO
# —— 状态枚举 —— 
enum States {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	RETURN,
	DEAD
}

# —— 内部状态机相关 —— 
var states: Dictionary = {}          # 存放各个状态实例
var current_state                   # 当前 State 对象引用
var current_state_type: int = -1     # 当前状态类型（States 中的值）
@export var initial_position: Vector2 = Vector2.ZERO
@export var patrol_points: Array[Vector2] = []
# —— 巡逻相关 —— 
var patrol_index: int = 0                # 当前正在前往的巡逻点索引

# —— 属性与状态 —— 
var health: int                          # 当前血量
var is_invincible: bool = false          # 是否处于无敌状态
var invincible_timer: float = 0.0        # 无敌剩余时间
var idle_time: float = 0.0               # Idle 计时器

# —— 缓存引用 —— 
var player: Node2D = null                # 玩家引用
var last_facing_dir: String = "down"     # 上一次朝向（"up"/"down"/"left"/"right"），用于动画播放

# —— 缓存节点引用（onready） —— 
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar := $healthBar as ProgressBar


func _ready() -> void:
	if configs.size() > 0:
		config = configs[randi() % configs.size()]
	else:
		push_error("EnemyBase: 未设置 configs 资源列表！")
		return
	print("加载了哥布林")
	# —— 1. 校验 Config —— 
	if config == null:
		push_error("EnemyBase.gd: 必须在 Inspector 里为 config 指定一个 EnemyConfig 资源！")
		return

	# —— 2. 如果配置里给了初始位置，就把自身移动到该坐标 —— 
	
	return_point = initial_position
	# —— 3. 把 AnimatedSprite2D 的 frames 换成配置里的 SpriteFrames —— 
	if anim_sprite and config.sprite_frames:
		anim_sprite.frames = config.sprite_frames
	else:
		push_error("EnemyBase.gd: 找不到 anim_sprite 或者 config.sprite_frames 未设置！")

	# —— 4. 初始化血量及血条 —— 
	health = config.max_health
	if health_bar:
		health_bar.max_value = config.max_health
		health_bar.value = health
		health_bar.visible = false

	# —— 5. 将自己加入 Enemy 组，以便玩家的 HitBox 等逻辑检测到 —— 
	add_to_group("Enemy")

	# —— 6. 拿到玩家引用 —— 
	if player != null:
		pass
	elif player_path != null and has_node(player_path):
		player = get_node(player_path) as CharacterBody2D
	else:
		push_error("EnemyBase.gd: 无法找到玩家引用！请检查 spawner 中的 player_path 或直接给 player 赋值。")

	# —— 7. 从 config 里复制巡逻点列表 —— 
	# 如果 patrol_points 为空，PatrolState 里需要处理无巡逻点情况

	# —— 8. 实例化各个状态脚本并缓存 —— 
	# 请确保这些脚本实现统一的 State 接口：new(owner: EnemyBase), enter(state_id: String), exit(state_id: String), physics_update(delta), process(delta)
	states[States.IDLE]   = preload("res://scripts/states/IdleState.gd").new(self)
	states[States.PATROL] = preload("res://scripts/states/PatrolState.gd").new(self)
	states[States.CHASE]  = preload("res://scripts/states/ChaseState.gd").new(self)
	states[States.ATTACK] = preload("res://scripts/states/AttackState.gd").new(self)
	states[States.RETURN] = preload("res://scripts/states/ReturnState.gd").new(self)
	states[States.DEAD]   = preload("res://scripts/states/DeadState.gd").new(self)
	# 1) 设定 CollisionShape2D 的初始大小

	# 2) 先关掉监测
	attack_area.monitoring  = false
	attack_area.monitorable = false

	# —— 9. 切换到初始状态 IDLE —— 
	current_state_type = -1   # 确保第一次 change_state 能够生效
	change_state(States.IDLE)


func _physics_process(delta: float) -> void:
	# —— 1) 如果当前状态是 IDLE，就走 Idle 计时逻辑，并决定是否切换到 PATROL/CHASE —— 
	if current_state_type == States.IDLE:
		idle_time += delta
		play_animation("idle")    # 持续播放 “idle” 状态动画

		# 如果玩家进入追击范围，立即切到 CHASE
		if is_player_in_chase_range():
			idle_time = 0.0
			change_state(States.CHASE)
			return

		# 如果在 IDLE 状态下“停留时间”超过 config.max_idle_time，切到 PATROL
		if idle_time >= config.max_idle_time:
			idle_time = 0.0
			change_state(States.PATROL)
			return

		# 阻止继续执行其它状态逻辑
		return

	# —— 2) 非 IDLE 状态，则调用当前状态脚本的 physics_update —— 
	if current_state:
		current_state.physics_update(delta)

	# —— 3) 无敌倒计时 —— 
	if is_invincible:
		invincible_timer -= delta
		if invincible_timer <= 0.0:
			is_invincible = false
			anim_sprite.modulate = Color(1, 1, 1, 1)

	# —— 4) 更新血条显示 —— 
	update_healthbar()
	update_attack_area()

func _process(delta: float) -> void:
	# 调用当前状态脚本的普通帧更新（如果有需要）
	if current_state:
		current_state.process(delta)


func change_state(new_state_type: int) -> void:
	# 如果要切换到的状态与当前状态相同，则直接返回
	if current_state_type == new_state_type:
		return

	# 先调用旧状态的 exit（如果存在）
	if current_state:
		current_state.exit(str(current_state_type))

	# 更新 current_state_type 和 current_state 引用
	current_state_type = new_state_type
	current_state = states.get(new_state_type, null)

	# 如果切到 IDLE，重置 idle_time
	if new_state_type == States.IDLE:
		idle_time = 0.0

	# 再调用新状态的 enter
	if current_state:
		current_state.enter(str(current_state_type))


# —— 以下是供状态脚本调用的公共方法 —— #

func is_player_in_chase_range() -> bool:
	if player == null:
		return false
	return global_position.distance_to(player.global_position) <= config.chase_range

# EnemyBase.gd
func is_player_in_attack_range() -> bool:
	if player == null:
		return false
	return global_position.distance_to(player.global_position) <= config.attack_range


func is_player_lost_sight() -> bool:
	# 玩家跑出追击范围 1.25 倍后算失去视野
	if player == null:
		return true
	return global_position.distance_to(player.global_position) > config.chase_range * 1.25

func take_damage(amount: int) -> void:
	
	if is_invincible or current_state_type == States.DEAD:
		return
	var factor=100.0/(config.defense+100.0)
	health -= amount*factor
	if health < 0:
		health = 0

	update_healthbar()

	if health <= 0:
		change_state(States.DEAD)
	else:
		# 进入无敌闪烁
		is_invincible = true
		invincible_timer = config.invincible_time
		anim_sprite.modulate = Color(1, 1, 1, 0.5)


func play_animation(state: String) -> void:
	var anim_name: String

	if state == "idle":
		# 默认播放向下 idle_down，不水平翻转
		anim_name = "idle_down"
		anim_sprite.flip_h = false
	else:
		var dir_vec: Vector2 = velocity
		var dir_name: String = last_facing_dir

		if dir_vec.length() > 0:
			# 水平优先
			if abs(dir_vec.x) > abs(dir_vec.y):
				if dir_vec.x >= 0:
					dir_name = "right"
					anim_sprite.flip_h = false
				else:
					dir_name = "right"
					anim_sprite.flip_h = true
				# 垂直翻转无需改变 flip_h
			else:
				if dir_vec.y < 0:
					dir_name = "up"
				else:
					dir_name = "down"
				anim_sprite.flip_h = false

			last_facing_dir = dir_name
		else:
			if last_facing_dir=="left":
				dir_name="right"
			# velocity 为零时，保持之前朝向
			else:
				dir_name = last_facing_dir

		anim_name = "%s_%s" % [state, dir_name]

	if anim_sprite.animation != anim_name:
		anim_sprite.play(anim_name)


func update_healthbar() -> void:
	"""
	根据当前 health 更新 ProgressBar 的数值与可见性：
	只有当血量小于最大血量时才显示血条。
	"""
	if health_bar:
		health_bar.max_value = config.max_health
		health_bar.value = health
		health_bar.visible = (health < config.max_health)


func get_patrol_point() -> Vector2:
	"""
	获取当前要前往的巡逻点坐标。如果 patrol_points 为空，则返回自身位置。
	"""
	if patrol_points.size() == 0:
		return global_position
	return patrol_points[patrol_index]


func advance_to_next_patrol() -> void:
	"""
	巡逻时，当到达当前目标点后，调用此方法更新 patrol_index 指向下一个点（循环）。
	"""
	if patrol_points.size() == 0:
		return
	patrol_index = (patrol_index + 1) % patrol_points.size()


func reset_patrol() -> void:
	"""
	重置巡逻索引，例如重新开始巡逻或恢复时调用。
	"""
	patrol_index = 0
func _spawn_drops() -> void:
	if config == null:
		return

	# 预加载 ItemDrop.tscn，只需要做一次
	var drop_scene: PackedScene = preload("res://scenes/item_drop.tscn")

	for drop_data in config.drops:
		# drop_data.chance 是 0.0~1.0
		if randf() < drop_data.chance:
			if drop_data.item == null:
				continue

			# 实例化一个 ItemDrop，并转换类型
			var drop_instance = drop_scene.instantiate() as ItemDrop
			if drop_instance == null:
				push_error("EnemyBase.gd: 无法把实例化节点转成 ItemDrop！")
				continue

			# 赋值 item_id（使用 Resource 中的 item.id 字符串）和 count
			drop_instance.item_id = drop_data.item.id
			drop_instance.count   = drop_data.count

			# 挂到父节点, 并放到“敌人中心 + offset”位置
			get_parent().add_child(drop_instance)
			drop_instance.global_position = global_position + drop_data.offset
func update_attack_area() -> void:
	# 先更新 shape.extents（如果你想动态改尺寸也在这里做）
	var rect = attack_shape.shape as RectangleShape2D
	rect.extents = attack_halfsize
	
	# 根据 last_facing_dir 移动 Area2D 的 position
	match last_facing_dir:
		"up":
			attack_area.position = Vector2(0, -attack_offset.y)
		"down":
			attack_area.position = Vector2(0,  attack_offset.y)
		"right":
			attack_area.position = Vector2( attack_offset.x, 0)
		"left":
			attack_area.position = Vector2(-attack_offset.x, 0)
	# 保持旋转不变
	attack_area.rotation_degrees = 0
func _on_attack_area_body_entered(body: Node) -> void:
	if body == player:
		attack_valid = true

func _on_attack_area_body_exited(body: Node) -> void:
	if body == player:
		attack_valid = false
