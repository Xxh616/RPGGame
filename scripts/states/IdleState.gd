extends State
class_name IdleState

func _init(_owner) -> void:
	owner = _owner

func enter(prev_state: String) -> void:
	owner.anim_sprite.play("idle_down")

func physics_update(delta: float) -> void:
	pass

func process(delta: float) -> void:
	pass
