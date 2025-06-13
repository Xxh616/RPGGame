extends RefCounted
class_name State

# Reference passed in by the main script to access the goblin's properties, methods, and scene tree
var owner

func _init(_owner):
	owner = _owner

# Called when entering this state (optional, e.g., play an animation)
func enter(prev_state: String) -> void:
	pass

# Called when exiting this state (optional, e.g., reset parameters)
func exit(next_state: String) -> void:
	pass

# Called every frame for physics-related logic
func physics_update(delta: float) -> void:
	pass

# Called every frame for non-physics logic, such as playing animations or sending signals
func process(delta: float) -> void:
	pass
