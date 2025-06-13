extends PlayerState
class_name PlayerMoveState

func _init(_owner) -> void:
	owner = _owner

func enter(prev_state: String) -> void:
	print("**ENTER MoveState**")
	# Play a default placeholder animation; physics_update will adjust it based on movement direction
	owner.PlayAnim("run_side", true)
	owner.moving = true

func physics_update(delta: float) -> void:
	# 1) If currently attacking or charging, immediately switch back to Idle
	if owner.attack_ip or owner.is_charging:
		owner.velocity = Vector2.ZERO
		owner.moving = false
		owner.change_state(owner.States.IDLE)
		return

	# 2) Read input to determine movement vector
	var dir_vec := Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		dir_vec.x += 1
	if Input.is_action_pressed("ui_left"):
		dir_vec.x -= 1
	if Input.is_action_pressed("ui_down"):
		dir_vec.y += 1
	if Input.is_action_pressed("ui_up"):
		dir_vec.y -= 1

	# 3) If no directional input, stop and return to Idle
	if dir_vec == Vector2.ZERO:
		owner.velocity = Vector2.ZERO
		owner.moving = false
		owner.change_state(owner.States.IDLE)
		return

	# 4) With directional input, normalize vector and apply speed
	dir_vec = dir_vec.normalized()
	owner.velocity = dir_vec * owner.speed

	# 5) Determine facing direction from dir_vec, update current_dir and HitBox immediately, then play the correct run animation
	var new_dir: String = owner.current_dir
	if abs(dir_vec.x) > abs(dir_vec.y):
		# Horizontal movement takes priority
		if dir_vec.x > 0:
			new_dir = "right"
		else:
			new_dir = "left"
		if new_dir != owner.current_dir:
			owner.current_dir = new_dir
			owner._update_hitbox_offset()  # ← Update HitBox position immediately
		owner.PlayAnim("run_side", true)
	else:
		# Vertical movement takes priority
		if dir_vec.y > 0:
			new_dir = "down"
			if new_dir != owner.current_dir:
				owner.current_dir = new_dir
				owner._update_hitbox_offset()  # ← Update HitBox position immediately
			owner.PlayAnim("run_down", true)
		else:
			new_dir = "up"
			if new_dir != owner.current_dir:
				owner.current_dir = new_dir
				owner._update_hitbox_offset()  # ← Update HitBox position immediately
			owner.PlayAnim("run_up", true)

	# 6) If the attack button is pressed, switch to Charge state
	if Input.is_action_just_pressed("attack"):
		owner.change_state(owner.States.CHARGE)
		return

	# 7) If player health is zero, switch to Dead state
	if global.player_health <= 0:
		owner.change_state(owner.States.DEAD)
		return

	# Note: Do not call move_and_slide() here; movement is handled centrally in Player.gd

func process(delta: float) -> void:
	# Refresh any dropped-item indicators or other non-physics logic
	owner._refresh_drop_labels()

func exit(next_state: String) -> void:
	# Reset movement flags when exiting Move state
	owner.velocity = Vector2.ZERO
	owner.moving = false
