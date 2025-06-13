extends State

var death_timer := 0.0
var death_duration := 1.0  # Duration of the death animation

func enter(prev_state: String) -> void:
	owner.play_animation("die")
	death_timer = 0.0
	# Disable collisions and movement
	owner.set_collision_layer(0)
	owner.set_collision_mask(0)
	owner.velocity = Vector2.ZERO

func physics_update(delta: float) -> void:
	death_timer += delta
	if death_timer >= death_duration:
		owner._spawn_drops()
		owner.queue_free()  # After playing the death animation, destroy the node

func process(delta: float) -> void:
	pass
