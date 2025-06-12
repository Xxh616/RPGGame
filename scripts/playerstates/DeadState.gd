# res://scripts/states/DeadState.gd
extends PlayerState
class_name PlayerDeadState

var has_played_death_anim := false

func _init(_owner) -> void:
	owner = _owner

func enter(prev_state: String) -> void:
	print("进入死亡")
	# 进入死亡状态时，立刻禁止一切输入、停止人物移动
	owner.velocity = Vector2.ZERO
	owner.attack_ip = false
	owner.is_charging = false
	owner.moving = false

	# 播放死亡动画：根据 current_dir 决定用 up/down/side
	
	var anim_name = "dead"

	owner.PlayAnim("dead", true)
	await owner.get_tree().create_timer(2.2).timeout
	SaveGame.save_game()
	global.player_alive=false



func physics_update(delta: float) -> void:
	# 死亡状态时，不允许任何移动或切换
	owner.velocity = Vector2.ZERO
	# 不需要调用 owner.change_state()，除非你让死亡后某个时机自动重生
	pass

func process(delta: float) -> void:
	# 不做额外逻辑，角色保持死亡动画即可
	pass
