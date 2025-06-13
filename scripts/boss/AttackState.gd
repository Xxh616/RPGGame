# res://scripts/states/AttackState.gd
extends BossState
class_name BossAttackState

var damage_frames := [3, 4]        # Frames at which to deal damage
var processed_frames := []         # Frames that have already processed damage
var anim_finished := false         # Used to detect when the animation has finished
var player_has_attack := false

func _init(_owner: Boss) -> void:
	owner = _owner

func enter(prev_state: String) -> void:
	# Reset state
	processed_frames.clear()
	anim_finished = false
	owner.velocity = Vector2.ZERO

	# Calculate facing suffix and update last_facing_dir
	var dv = (owner.player_node.global_position - owner.global_position).normalized()
	var suffix := ""
	if abs(dv.x) > abs(dv.y):
		suffix = "left" if dv.x < 0 else "right"
		owner.anim_sprite.flip_h = dv.x < 0
	else:
		suffix = "up" if dv.y < 0 else "down"
	owner.last_facing_dir = suffix

	# Update attack area
	owner.update_attack_area(suffix)
	var dir = "right" if suffix == "left" else suffix
	# Play attack animation (Loop disabled in SpriteFrames)
	owner.anim_sprite.play("attack_" + dir)

func physics_update(delta: float) -> void:
	# No movement during attack
	pass

func process(delta: float) -> void:
	if owner.player_in_safe_zone:
		owner.change_state(owner.States.RETURN)
		return

	var anim_name = owner.anim_sprite.animation
	if not anim_name.begins_with("attack_"):
		return

	var total = owner.anim_sprite.sprite_frames.get_frame_count(anim_name)
	var cur = owner.anim_sprite.frame

	# 1) Check if current frame is a damage frame
	if cur in damage_frames and not (cur in processed_frames):
		_do_damage(cur)
		processed_frames.append(cur)

	# 2) Detect last animation frame and switch state upon completion
	if cur == total - 1 and not anim_finished:
		anim_finished = true
		player_has_attack = false
		_on_attack_done()

func _do_damage(cur: int) -> void:
	# Iterate through bodies in attack area, and damage player_node only once
	for body in owner.attack_area.get_overlapping_bodies():
		if body == owner.player_node and body.has_method("take_damage"):
			var factor = (100 + owner.attack) / 100
			if cur == 3:
				body.take_damage(65 * factor)
				player_has_attack = true
				break  # Each attack frame hits only once
			elif cur == 4 and not player_has_attack:
				body.take_damage(50 * factor)
				player_has_attack = true
				break

func _on_attack_done() -> void:
	# Reset attack cooldown
	owner.time_since_last_attack = 0.0
	if owner.is_player_in_attack_range():
		# —— Replay this state directly without using change_state() ——
		processed_frames.clear()
		anim_finished = false
		# Play the one-shot attack animation
		owner.anim_sprite.play(owner.anim_sprite.animation)
		return

	# Switch back to Chase or Idle based on player distance
	if owner.is_player_in_chase_range():
		owner.change_state(owner.States.CHASE)
	else:
		owner.change_state(owner.States.IDLE)

func exit(next_state: String) -> void:
	# Optional: clean up or stop animation
	pass
