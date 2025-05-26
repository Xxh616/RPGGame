extends CharacterBody2D
class_name EnemyBase

@export var move_speed: float = 60
@export var max_health: int = 100
@export var attack_range: float = 20
@export var attack_trigger_range: float = 120.0

var health: int
var player: Node = null
var attacking := false
var attack_cooldown := false
var can_take_damage := true
var player_chase := false
var player_in_attack_zone := false

func _ready():
	add_to_group("Enemy")
	health = max_health
	init_timers()
	play_idle_animation()

func _physics_process(_delta):
	handle_chase()
	update_health()
	move_and_slide()

func handle_chase():
	if not player or health <= 0:
		return

	$AnimatedSprite2D.flip_h = player.position.x < position.x
	var dist = position.distance_to(player.position)

	if attacking:
		return

	if player_chase and not attack_cooldown:
		if dist <= attack_trigger_range:
			perform_attack()
		else:
			velocity = (player.position - position).normalized() * move_speed
			play_walk_animation()
	else:
		velocity = Vector2.ZERO
		play_idle_animation()



func take_damage(amount: int):
	pass

func die():
	velocity = Vector2.ZERO
	play_death_animation()
	$death_timer.start()

func update_health():
	if has_node("healthbar"):
		var bar = $healthbar
		bar.value = health
		bar.visible = health < max_health
func enemy():
	pass
		
# 可被子类重写的方法
func perform_attack():
	pass
func get_damage_amount():
	return 20
func play_idle_animation():
	pass
func play_walk_animation():
	pass
func play_death_animation():
	pass
func init_timers():
	pass
