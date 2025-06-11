extends CharacterBody2D
class_name Boss


@export var chase_speed: float        = 80.0
@export var stopping_distance: float = 40   # 和攻击范围一致
@export var attack_cooldown: float   = 1.5    # 攻击间隔（秒）
@onready var attack_area: Area2D            = $AttackArea
@onready var attack_shape: RectangleShape2D = $AttackArea/CollisionShape2D.shape
var attack_range=10
enum States { IDLE, CHASE, ATTACK, DEAD,RETURN}

var states: Dictionary = {}
var current_state: BossState = null
var current_state_type: int = -1

# 攻击冷却计时
var time_since_last_attack: float = 999.0

# —— 新增：安全区 & 回家点 —— 
@export var safe_zone_path: NodePath
@export var home_position: Vector2 = Vector2(376,189)

# —— 原状态机部分略去 —— 

# 标记玩家是否在安全区
var player_in_safe_zone: bool = false

@onready var safe_zone: Area2D           = get_node(safe_zone_path)
# 缓存节点
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var agent: NavigationAgent2D      = $NavigationAgent2D
@export var player_path: NodePath            # 在 Inspector 里填：../player
@onready var player_node: Node2D = get_node(player_path) # 根据你场景实际路径修改
# —— 新增：血量系统 —— 
@export var max_health: int = 100
var health: int

# 缓存血条控件（假设你用的是 ProgressBar 或 TextureProgress）
@onready var health_bar := $healthBar
# 最后一次面向方向，用于 Idle
var last_facing_dir: String = "down"

func _ready() -> void:
	# 注册状态
	states[States.IDLE]   = BossIdleState.new(self)
	states[States.CHASE]  = BossChaseState.new(self)
	states[States.ATTACK] = BossAttackState.new(self)
	states[States.DEAD]   = BossDeadState.new(self)
	states[States.RETURN] = BossReturnState.new(self)
	# 导航参数
	agent.max_speed = chase_speed
	agent.target_desired_distance = stopping_distance
	add_to_group("Enemy")
	change_state(States.IDLE)

func _physics_process(delta: float) -> void:
	update_healthbar()
	if current_state:
		current_state.physics_update(delta)

func _process(delta: float) -> void:
	# 累计冷却
	time_since_last_attack += delta
	if current_state:
		current_state.process(delta)

func change_state(new_state: int) -> void:
	if new_state == current_state_type:
		return
	if current_state:
		current_state.exit(str(new_state))
	current_state_type = new_state
	current_state = states[new_state]
	print("Boss切换状态%s"%current_state_type)
	if current_state:
		current_state.enter(str(current_state_type))

func is_player_in_chase_range() -> bool:
	# 只要玩家在两倍攻击距离内就开始追
	return player_node and global_position.distance_to(player_node.global_position) <= stopping_distance * 100

func is_player_in_attack_range() -> bool:
	return player_node and global_position.distance_to(player_node.global_position) <= stopping_distance
func update_attack_area(dir: String) -> void:
	var offset := Vector2.ZERO
	var extents := Vector2(10, 10)
	var rot_deg := 0.0

	match dir:
		"up":
			offset = Vector2(0, -attack_range)
			rot_deg = -90
			extents = Vector2(30, 20)
		"down":
			offset = Vector2(0, attack_range)
			rot_deg = 90
			extents = Vector2(30, 20)
		"left":
			offset = Vector2(-attack_range, 0)
			rot_deg = 0
			extents = Vector2(30, 20)
		"right":
			offset = Vector2(attack_range, 0)
			rot_deg = 0
			extents = Vector2(30, 20)

	# 应用位置、旋转和大小
	attack_area.position = offset
	attack_area.rotation_degrees = rot_deg
	attack_shape.extents = extents
func _on_safe_zone_enter(body: Node) -> void:
	if body == player_node:
		player_in_safe_zone = true
		# 只要玩家一进安全区，立刻中断任何 Chase/Attack，去 RETURN
		change_state(States.RETURN)

func _on_safe_zone_exit(body: Node) -> void:
	if body == player_node:
		player_in_safe_zone = false
func take_damage(amount: int) -> void:
	# 如果已经死了，就不处理
	if current_state_type == States.DEAD:
		return

	health = max(health - amount, 0)
	health_bar.value = health
   

	if health == 0:
		change_state(States.DEAD)
func update_healthbar() -> void:
	"""
	根据当前 health 更新 ProgressBar 的数值与可见性：
	只有当血量小于最大血量时才显示血条。
	"""
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
		health_bar.visible = (health < max_health)
