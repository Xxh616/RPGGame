# res://scripts/Goblin.gd
extends CharacterBody2D

# —— 导出属性，可在 Inspector 里调节 —— 
@export var speed: float = 40                  # 巡逻/追击的基础移动速度
@export var run_speed: float = 70.0            # （暂留，若需要跑动与巡逻两种速度可使用）
@export var chase_range: float = 150.0         # 玩家进入追击范围时，Goblin 从 Idle/Patrol 切到 Chase
@export var attack_range: float = 40.0         # 近身攻击时的判定范围（可以用于后期 AttackState）
@export var invincible_time: float = 0.8       # 受击后闪烁的短暂无敌时间
@export var max_health: int = 100              # 最大血量

# Idle 状态下停留时间（秒），超时就从 Idle→Patrol（可选）
@export var max_idle_time: float = 1.5

# 用于关联玩家节点：在 Inspector 里拖拽 Player（CharacterBody2D）到这里
@export var player_path: NodePath

# 巡逻点数组：会在 _ready() 中自动填写
@export var patrol_points: Array[Vector2] = []

# —— 枚举各个状态 ID —— 
enum States {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	RETURN,
	DEAD
}

# —— 下面是内部变量 —— 
var states := {}               # 存放各状态实例
var current_state              # 当前 State 对象引用
var current_state_type: int    # 当前状态的类型（IDLE/ PATROL/ CHASE…）

var patrol_index: int = 0      # 巡逻时当前目标点的索引

# 当前剩余血量
var health: int

# 短暂无敌相关
var is_invincible: bool = false
var invincible_timer: float = 0.0

# Idle 计时
var idle_time: float = 0.0

# 缓存玩家引用
var player: Node2D = null

# 记录上一次朝向，用于 Idle 动画和转向
var last_facing_dir: String = "down"   # 初始朝下

# —— 缓存节点引用 —— 
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar := $HealthBar       as ProgressBar   # 或 TextureProgress
@onready var patrol_container := $PatrolPointContainer as Node2D


func _ready() -> void:
	# 1) 自动设置当前血量为最大
	health = max_health

	# 2) 把自己加入 Enemy 组，以便玩家的 HitBox 可以检测到
	add_to_group("Enemy")

	# 3) 拿到玩家引用
	if player_path != null and has_node(player_path):
		player = get_node(player_path) as Node2D
	else:
		push_error("Goblin.gd: 请在 Inspector 里把 player_path 指向一个有效的 Player 节点！")
	

	# 4) 读取巡逻点
	for child in patrol_container.get_children():
		if child is Marker2D:
			patrol_points.append(child.global_position)
		
	

	print("Goblin 已找到 player=", player)
	print("读取到的 patrol_points:", patrol_points)

	# 5) 初始化血条：最大值设为 max_health，初始血条不可见
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
		health_bar.visible = false
	

	# 6) 实例化各个状态，并传入 self
	states[States.IDLE]   = preload("res://scripts/states/IdleState.gd").new(self)
	states[States.PATROL] = preload("res://scripts/states/PatrolState.gd").new(self)
	states[States.CHASE]  = preload("res://scripts/states/ChaseState.gd").new(self)
	states[States.ATTACK] = preload("res://scripts/states/AttackState.gd").new(self)
	states[States.RETURN] = preload("res://scripts/states/ReturnState.gd").new(self)
	states[States.DEAD]   = preload("res://scripts/states/DeadState.gd").new(self)

	# 7) 初始状态设为 IDLE。注意 current_state_type 先设为一个不在 enum 里的值，以便首次 change_state 能生效
	current_state_type = -1
	change_state(States.IDLE)



func _physics_process(delta: float) -> void:
	# —— 1) 如果当前还是 Idle，就走 Idle 计时逻辑，并决定是否切 Patrol/Chase —— 
	if current_state_type == States.IDLE:
		idle_time += delta
		play_animation("idle")    # 持续播放 idle 朝向动画

		# 如果玩家进入追击范围，立刻切到 CHASE
		if is_player_in_chase_range():
			idle_time = 0.0
			change_state(States.CHASE)
			return
		

		# 如果在 IDLE 状态下“停留时间”超过 max_idle_time，切到 Patrol
		if idle_time >= max_idle_time:
			idle_time = 0.0
			change_state(States.PATROL)
			return
		

		# 不要再继续往下执行“状态自身逻辑”
		return
	

	# —— 2) 非 Idle 状态，调用具体状态的物理帧更新 —— 
	if current_state:
		current_state.physics_update(delta)
	

	# —— 3) 受击无敌倒计时 —— 
	if is_invincible:
		invincible_timer -= delta
		if invincible_timer <= 0.0:
			is_invincible = false
			anim_sprite.modulate = Color(1, 1, 1, 1)
		
	



func _process(delta: float) -> void:
	# 调用当前状态的普通帧更新（如果有需要）
	if current_state:
		current_state.process(delta)
	



func change_state(new_state_type: int) -> void:
	# 如果要切换到的状态和当前状态相同，就直接返回
	if current_state_type == new_state_type:
		return
	

	# 先调用 exit
	if current_state:
		current_state.exit(str(current_state_type))
	

	# 更新状态类型与引用
	current_state_type = new_state_type
	current_state = states[new_state_type]

	# 进入 Idle 时，重置 Idle 计时
	if new_state_type == States.IDLE:
		idle_time = 0.0
	

	# 再调用 enter
	current_state.enter(str(current_state_type))



# —— 以下是供状态脚本调用的公共方法 —— #

# 判断玩家是否在追击范围内
func is_player_in_chase_range() -> bool:
	if player == null:
		return false
	
	return global_position.distance_to(player.global_position) <= chase_range

# 判断玩家是否在攻击范围内（如果 AttackState 需要用到）
func is_player_in_attack_range() -> bool:
	if player == null:
		return false
	
	return global_position.distance_to(player.global_position) <= attack_range


# 判断玩家已经跑出视野（超过 chase_range * 1.25）
func is_player_lost_sight() -> bool:
	if player == null:
		return true
	
	return global_position.distance_to(player.global_position) > chase_range * 1.25



# 受到伤害时调用：健康值减少并播放闪烁；死亡时切 Dead
func take_damage(amount: int) -> void:
	if is_invincible or current_state_type == States.DEAD:
		return
	

	health -= amount
	if health < 0:
		health = 0
	

	# 更新并显示血条
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
		health_bar.visible = (health < max_health)
	

	print("Goblin.take_damage() 收到伤害=", amount, " 剩余血量=", health)

	if health <= 0:
		change_state(States.DEAD)
	else:
		# 闪烁 + 无敌帧
		is_invincible = true
		invincible_timer = invincible_time
		anim_sprite.modulate = Color(1, 1, 1, 0.5)
	



# 根据 state（"idle"、"walk"、"run"、"attack" 等）和朝向自动拼出动画名称并播放
func play_animation(state: String) -> void:
	var anim_name: String

	# 如果是 “idle” 状态，播放刚好面朝下的 idle_down，然后通过 flip_h 翻转实现左右
	if state == "idle":
		# 此处我们默认 “idle_down” 贴图向下不翻转
		anim_name = "idle_down"
		anim_sprite.flip_h = false
	else:
		# 非 Idle 状态，根据 velocity 向量决定朝向
		var dir_vec: Vector2 = velocity
		var dir_name: String = last_facing_dir

		if dir_vec.length() > 0:
			if abs(dir_vec.x) > abs(dir_vec.y):
				if dir_vec.x >= 0:
					dir_name = "right"
					anim_sprite.flip_h = false
				else:
					dir_name = "right"
					anim_sprite.flip_h = true
				
			else:
				if dir_vec.y < 0:
					dir_name = "up"
				else:
					dir_name = "down"
				
				anim_sprite.flip_h = false
			
			last_facing_dir = dir_name
		else:
			dir_name = last_facing_dir
		

		anim_name = "%s_%s" % [state, dir_name]
	

	if anim_sprite.animation != anim_name:
		anim_sprite.play(anim_name)
	
