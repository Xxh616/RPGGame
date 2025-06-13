# res://scripts/states/DeadState.gd
extends PlayerState
class_name PlayerDeadState

var has_played_death_anim := false

func _init(_owner) -> void:
	owner = _owner

func enter(prev_state: String) -> void:
	print("Entered death state")
	# Upon entering the dead state, immediately disable all input and stop movement
	owner.velocity = Vector2.ZERO
	owner.attack_ip = false
	owner.is_charging = false
	owner.moving = false

	# Play death animation (use "dead" regardless of direction here)
	var anim_name = "dead"
	owner.PlayAnim(anim_name, true)

	# Wait for animation and any effects (2.2 seconds), then save and mark player as dead
	await owner.get_tree().create_timer(2.2).timeout
	SaveGame.save_game()
	global.player_alive = false

func physics_update(delta: float) -> void:
	# While dead, no movement or state changes are allowed
	owner.velocity = Vector2.ZERO
	pass  # Do not change state unless you implement automatic respawn

func process(delta: float) -> void:
	# No additional logic; the character remains playing the death animation
	pass
