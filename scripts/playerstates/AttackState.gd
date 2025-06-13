# res://scripts/playerstates/AttackState.gd
extends PlayerState

# Mark whether this attack is a heavy strike
var is_heavy := false    
# Timer used to delay closing the HitBox (close after ~0.2s; adjust to match animation)
var attack_timer := 0.0  
# Ensure we open the HitBox only once and only count damage once
var has_hit := false     

func _init(_owner) -> void:
	owner = _owner

func enter(prev_state: String) -> void:
	# Entering attack: set flag, play animation, open HitBox, and bind animation end signal
	owner.attack_ip = true
	owner.velocity = Vector2.ZERO
	has_hit = false
	attack_timer = 0.0

	# 1) Play the correct attack animation
	var base_dir = owner.current_dir if owner.current_dir in ["up", "down"] else "side"
	if is_heavy:
		# Heavy strike animations: thump_attack_down/side/up
		var anim_name = "thump_attack_%s" % base_dir
		owner.thumpornot = true
		owner.PlayAnim(anim_name, true)
	else:
		# Normal combo: alternate between first and second attack
		owner.attack_index = (owner.attack_index + 1) % 2
		var suffix = "first" if owner.attack_index == 0 else "second"
		var anim_name = "attack_%s_%s" % [base_dir, suffix]
		owner.thumpornot = false
		owner.PlayAnim(anim_name, true)

	# 2) Immediately position the HitBox and enable monitoring
	owner._update_hitbox_offset()
	owner.hitbox_area.monitoring = true

	# 3) Connect to animation_finished to return to Idle when done
	if owner.anim_player and not owner.anim_player.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		owner.anim_player.connect("animation_finished", Callable(self, "_on_animation_finished"))

func physics_update(delta: float) -> void:
	# A) Allow changing facing direction mid-attack; update HitBox accordingly
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
		var new_dir = owner.current_dir
		if abs(dir_vec.x) > abs(dir_vec.y):
			new_dir = "right" if dir_vec.x > 0 else "left"
		else:
			new_dir = "down" if dir_vec.y > 0 else "up"
		if new_dir != owner.current_dir:
			owner.current_dir = new_dir
			owner._update_hitbox_offset()
			# (Optional) Could replay the attack animation facing new_dir here if desired

	# B) Increment timer; disable HitBox after a short delay to end damage window
	if not has_hit:
		attack_timer += delta
		if attack_timer >= 0.2:
			has_hit = true
			owner.hitbox_area.monitoring = false

	# C) If player health reaches zero, switch immediately to DEAD
	if global.player_health <= 0:
		owner.change_state(owner.States.DEAD)
		return

	# D) No movement allowed during attack
	owner.velocity = Vector2.ZERO

func process(delta: float) -> void:
	# Return to Idle is handled by the animation_finished callback
	pass

func exit(next_state: String) -> void:
	owner.attack_ip = false

	# 1) Disconnect animation_finished signal
	if owner.anim_player and owner.anim_player.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		owner.anim_player.disconnect("animation_finished", Callable(self, "_on_animation_finished"))

	# 2) Ensure HitBox is disabled when exiting state
	if owner.has_node("HitBox"):
		owner.hitbox_area.monitoring = false

# Called when an attack animation (heavy or combo) finishes; transition back to Idle
func _on_animation_finished(anim_name: String) -> void:
	var valid_names := []
	if is_heavy:
		valid_names = ["thump_attack_down", "thump_attack_side", "thump_attack_up"]
	else:
		valid_names = [
			"attack_down_first",  "attack_down_second",
			"attack_side_first",  "attack_side_second",
			"attack_up_first",    "attack_up_second"
		]

	if anim_name in valid_names:
		owner.change_state(owner.States.IDLE)
