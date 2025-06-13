extends BossState
class_name BossIdleState

func _init(_owner: Boss) -> void:
	owner = _owner

func enter(prev_state: String) -> void:
	# Adjust facing based on last_facing_dir and play the corresponding idle animation
	var dir = owner.last_facing_dir
	var suffix = "right" if dir == "left" else dir
	owner.anim_sprite.flip_h = (dir == "left")
	owner.anim_sprite.play("idle_" + suffix)

func physics_update(delta: float) -> void:
	# If the player enters chase range, switch to CHASE state
	if owner.is_player_in_chase_range():
		owner.change_state(owner.States.CHASE)

func process(delta: float) -> void:
	pass

func exit(next_state: String) -> void:
	pass
