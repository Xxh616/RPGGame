extends State
class_name PlayerAttackState

var attack_cooldown := 1.0  # Total duration for animation + cooldown
var timer := 0.0            # Elapsed time

func _init(_owner) -> void:
	owner = _owner

func enter(prev_state: String) -> void:
	timer = 0.0
	# 2) Update and activate the attack area
	owner.update_attack_area()
	owner.attack_area.monitoring  = true
	owner.attack_area.monitorable = true
	var to_player = owner.player.global_position - owner.global_position
	if abs(to_player.x) > abs(to_player.y):
		owner.last_facing_dir = "right" if to_player.x > 0 else "left"
	else:
		owner.last_facing_dir = "down" if to_player.y > 0 else "up"

	# 3) Play attack animation
	owner.play_animation("attack")


func physics_update(delta: float) -> void:
	# Disable movement during attack
	owner.velocity = Vector2.ZERO

	timer += delta

	# Attempt to hit once at 0.5 seconds into the attack
	if timer >= 0.5 and timer - delta < 0.5:
		if owner.attack_valid:
			var factor = (100 + owner.config.attack) / 100.0
			owner.player.take_damage(20 * factor)
		# Regardless of hit success, do not repeat this trigger
		owner.attack_valid = false

	# When the current attack cycle (animation + cooldown) ends
	if timer >= attack_cooldown:
		timer = 0.0

		# First, disable monitoring for this attack cycle
		owner.attack_area.monitoring  = false
		owner.attack_area.monitorable = false

		# Decide next action: if player still in range, chain attack; otherwise switch to Chase
		if owner.attack_valid:
			# For the next chain: realign attack area, re-enable monitoring, and replay animation
			owner.update_attack_area()
			owner.attack_area.monitoring  = true
			owner.attack_area.monitorable = true
			owner.attack_valid = false
			owner.play_animation("attack")
		else:
			owner.change_state(owner.States.CHASE)

func process(delta: float) -> void:
	# No additional logic needed in process for attack state
	pass

func exit(next_state: String) -> void:
	# Ensure attack area is disabled when exiting the attack state
	owner.attack_area.call_deferred("set_monitoring", false)
	owner.attack_area.call_deferred("set_monitorable", false)
