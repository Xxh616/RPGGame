# res://scripts/playerstates/IdleState.gd
extends PlayerState
class_name PlayerIdleState

func _init(_owner) -> void:
	owner = _owner

func enter(prev_state: String) -> void:
	print("**ENTER IdleState**, current_dir=", owner.current_dir)
	# Upon entering IdleState, play the idle animation matching the current facing direction
	var base_dir = owner.current_dir if owner.current_dir in ["up", "down"] else "side"
	var anim_name = "idle_%s" % base_dir
	owner.PlayAnim(anim_name, true)

	# Ensure velocity is zero so no residual movement carries over
	owner.velocity = Vector2.ZERO

func physics_update(delta: float) -> void:
	var x_input := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var y_input := Input.get_action_strength("ui_down")  - Input.get_action_strength("ui_up")

	# If you want Idle to only change facing direction on arrow keys without auto-moving, do this:
	if x_input != 0 or y_input != 0:
		# First compute the new facing direction
		var new_dir = owner.current_dir
		if abs(x_input) > abs(y_input):
			new_dir = "right" if x_input > 0 else "left"
		else:
			new_dir = "down"  if y_input > 0 else "up"

		if new_dir != owner.current_dir:
			owner.current_dir = new_dir
			owner._update_hitbox_offset()    # ← Immediately update HitBox to the new direction

		# If you still want arrow keys to enter Move state, keep this line:
		owner.change_state(owner.States.MOVE)
		return

	# If you want to prevent Idle from ever switching to Move on input, comment out the above change_state line,
	# so it only updates the HitBox without leaving Idle.

	# 2. Check for attack button press
	if Input.is_action_just_pressed("attack") and not owner.attack_ip:
		owner.change_state(owner.States.CHARGE)
		return

	# 3. Check for pickup key press
	if Input.is_action_just_pressed("pickup_item"):
		owner._refresh_drop_labels()
		if owner.itemselect != null:
			owner.itemselect.pickup()
			owner.nearby_drops.erase(owner.itemselect)
			owner.itemselect.show_label(false)
			owner.itemselect = null

	# 4. Always keep velocity at zero in Idle
	owner.velocity = Vector2.ZERO

func process(delta: float) -> void:
	# In Idle state you can perform non-physics logic, e.g., refresh drop indicators or handle mouse hover
	pass

func exit(next_state: String) -> void:
	# Optional cleanup when leaving Idle state can go here
	pass
