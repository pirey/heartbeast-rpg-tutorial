extends KinematicBody2D

const EnemyDeathEffect = preload("res://Effects/EnemyDeathEffect.tscn")

export var MAX_SPEED = 50
export var ACCELERATION = 300
export var FRICTION = 200
export var WANDER_TARGET_DETECTION_RANGE = 4

enum {
	IDLE,
	WANDER,
	CHASE
}

onready var sprite = $AnimatedSprite
onready var stats = $Stats
onready var playerDetectionZone = $PlayerDetectionZone
onready var hurtbox = $Hurtbox
onready var softCollision = $SoftCollision
onready var wanderController = $WanderController

var knockback = Vector2.ZERO
var velocity = Vector2.ZERO
var state = IDLE

func _physics_process(delta):
	knockback = knockback.move_toward(Vector2.ZERO, 200 * delta)
	knockback = move_and_slide(knockback)
	
	match state:
		IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
			seek_player()
			if wanderController.get_time_left() == 0:
				wander_or_idle()
		WANDER:
			seek_player()
			if wanderController.get_time_left() == 0:
				wander_or_idle()
			if global_position.distance_to(wanderController.target_position) <= WANDER_TARGET_DETECTION_RANGE:
				wander_or_idle()
			accelerate_towards_point(delta, wanderController.target_position)
		CHASE:
			var player = playerDetectionZone.player
			if player != null:
				accelerate_towards_point(delta, player.global_position)
			else:
				state = IDLE
			
	if softCollision.is_colliding():
		velocity += softCollision.get_push_vector() * delta * 400
	velocity = move_and_slide(velocity)
			
func seek_player():
	if playerDetectionZone.can_see_player():
		state = CHASE

func pick_random_state(state_list):
	state_list.shuffle()
	return state_list.pop_front()

func wander_or_idle():
	state = pick_random_state([IDLE, WANDER])
	wanderController.start_wander_timer(rand_range(1, 3))

func accelerate_towards_point(delta, point):
	var direction = global_position.direction_to(point)
	velocity = velocity.move_toward(direction * MAX_SPEED, ACCELERATION * delta)
	sprite.flip_h = velocity.x < 0

func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage
	knockback = area.knockback_vector * 120
	hurtbox.create_hit_effect()

func _on_Stats_no_health():
	var enemyDeathEffect = EnemyDeathEffect.instance()
	enemyDeathEffect.global_position = global_position
	get_parent().add_child(enemyDeathEffect)
	queue_free()
