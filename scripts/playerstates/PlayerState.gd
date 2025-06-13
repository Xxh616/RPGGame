extends RefCounted
class_name PlayerState   # Rename original State to PlayerState

# Each State is given an owner (the Player or Goblin instance) to access shared data and methods
var owner

func _init(_owner) -> void:
	owner = _owner

func enter(prev_state: String) -> void:
	# Called when this state is entered; override in subclasses
	pass

func physics_update(delta: float) -> void:
	# Called every physics frame; override for movement and physics-related logic
	pass

func process(delta: float) -> void:
	# Called every idle frame; override for non-physics logic (e.g., UI updates)
	pass

func exit(next_state: String) -> void:
	# Called when this state is exited; override for cleanup
	pass
