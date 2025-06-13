# res://scripts/playerstates/ChargeState.gd
extends PlayerState
class_name PlayerChargeState

func _init(_owner) -> void:
	owner = _owner

func enter(prev_state: String) -> void:
	# Enter charge state: show charge bar, initialize data, play 'idle' still animation
	owner.is_charging = true
	owner.charge_time = 0.0
	owner.get_node("charge_bar").visible = true
	owner.get_node("charge_bar").value = 0

	var base_dir = owner.current_dir if owner.current_dir in ["up", "down"] else "side"
	var charge_anim = "idle_%s" % base_dir
	owner.PlayAnim(charge_anim, true)

	# Treat as stationary for now
	owner.moving = false
	owner.velocity = Vector2.ZERO

func physics_update(delta: float) -> void:
	# As long as the 'attack' button is held, continue charging
	if Input.is_action_pressed("attack"):
		owner.charge_time += delta

		# Update progress bar
		var ratio = owner.charge_time / owner.max_charge_time
		owner.get_node("charge_bar").value = min(ratio * 100, 100)
		if ratio >= 1.0:
			owner.get_node("charge_bar").modulate = Color(1, 0, 0)
		else:
			owner.get_node("charge_bar").modulate = Color(1, 1, 1)

		# (A) Allow small steps using arrow keys while charging
		var dir_vec := Vector2.ZERO
		if Input.is_action_pressed("ui_right"):
			dir_vec.x += 1
		if Input.is_action_pressed("ui_left"):
			dir_vec.x -= 1
		if Input.is_action_pressed("ui_down"):
			dir_vec.y += 1
		if Input.is_action_pressed("ui_up"):
			dir_vec.y -= 1

		if dir_vec != Vector2.ZERO:
			dir_vec = dir_vec.normalized()
			# Movement speed while charging (slightly slower than normal run)
			owner.velocity = dir_vec * owner.charge_move_speed
			owner.move_and_slide()

			# Update player facing direction and play 'run' animation
			var new_dir: String
			# Prioritize horizontal direction
			if abs(dir_vec.x) > abs(dir_vec.y):
				new_dir = "right" if dir_vec.x > 0 else "left"
				owner.current_dir = new_dir
				owner.PlayAnim("run_side", true)   # Force refresh run_side each frame
			else:
				if dir_vec.y > 0:
					new_dir = "down"
					owner.current_dir = "down"
					owner.PlayAnim("run_down", true)  # Force refresh run_down each frame
				else:
					new_dir = "up"
					owner.current_dir = "up"
					owner.PlayAnim("run_up", true)    # Force refresh run_up each frame

			# Keep HitBox positioned according to current facing direction
			owner._update_hitbox_offset()
			owner.moving = true
		else:
			# (B) No directional input: maintain 'stationary charging'
			owner.velocity = Vector2.ZERO
			owner.moving = false

			var base_dir2 = owner.current_dir if owner.current_dir in ["up", "down"] else "side"
			var charge_idle = "idle_%s" % base_dir2
			owner.PlayAnim(charge_idle, true)   # Force refresh the 'idle' charging pose

		return  # As long as 'attack' is still held, do not proceed further

	# (2) Release charge key: switch to normal or heavy attack
	owner.is_charging = false
	owner.get_node("charge_bar").visible = false
	owner.get_node("charge_bar").value = 0
	owner.get_node("charge_bar").modulate = Color(1, 1, 1)

	if owner.charge_time >= owner.max_charge_time:
		owner.change_state(owner.States.HEAVY_ATTACK)
	else:
		owner.change_state(owner.States.ATTACK)

	return

func process(delta: float) -> void:
	pass

func exit(next_state: String) -> void:
	# Reset velocity and movement flag
	owner.velocity = Vector2.ZERO
	owner.moving = false
