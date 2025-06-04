# PatrolState.gd
extends State
class_name PatrolState

# 巡逻到下一个点时的容差距离
var point_reach_tolerance := 8.0

func _init(_owner) -> void:
	owner = _owner

func enter(prev_state: String) -> void:
	# 每次进入 Patrol 时，都要重置 patrol_index，确保索引合法
	owner.patrol_index = 0

	print("进入 PatrolState，patrol_points 数量 = ", owner.patrol_points.size())
	if owner.patrol_points.size() == 0:
		# 没有巡逻点，就切回 Idle
		owner.change_state(owner.States.IDLE)
		return

	# 进入时立即播放一次「走路」动画（方向由 play_animation 内部根据 velocity 自动检测）
	owner.play_animation("walk")

func physics_update(delta: float) -> void:
	# 1. 如果玩家进入追击范围，立刻切 Chase
	if owner.is_player_in_chase_range():
		owner.change_state(owner.States.CHASE)
		return

	# 2. 计算当前目标巡逻点
	var target_pos: Vector2 = owner.patrol_points[owner.patrol_index]
	var dir: Vector2 = (target_pos - owner.global_position).normalized()

	# 3. 应用移动
	owner.velocity = dir * owner.speed
	owner.move_and_slide()

	# 4. 持续播放「走路」动画，并根据 velocity 自动切方向
	owner.play_animation("walk")

	# 5. 如果到达当前巡逻点，就切到下一个
	if owner.global_position.distance_to(target_pos) <= point_reach_tolerance:
		owner.patrol_index = (owner.patrol_index + 1) % owner.patrol_points.size()

func exit(next_state: String) -> void:
	# 离开 Patrol 时，把速度置零，防止残留
	owner.velocity = Vector2.ZERO

func process(delta: float) -> void:
	pass
