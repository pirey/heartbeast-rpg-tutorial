extends KinematicBody2D

const ACCELERATION = 500
const MAX_SPEED = 80
const ROLL_SPEED = 100
const FRICTION = 500

enum {
	MOVE,
	ROLL,
	ATTACK
}

var velocity = Vector2.ZERO
var roll_vector = Vector2.DOWN
var state = MOVE
var stats = PlayerStats

onready var animationPlayer = $AnimationPlayer
onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")
onready var swordHitbox = $HitboxPivot/SwordHitbox
onready var hurtbox = $Hurtbox

func _ready():
	stats.connect("no_health", self, "queue_free")
	animationTree.active = true
	swordHitbox.knockback_vector = roll_vector

func _physics_process(delta):
	match state:
		MOVE:
			move_state(delta)
		ROLL:
			roll_state(delta)
		ATTACK:
			attack_state(delta)

func move_state(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	
	if input_vector != Vector2.ZERO:
		roll_vector = input_vector
		swordHitbox.knockback_vector = input_vector
		animationTree.set("parameters/Idle/blend_position", input_vector)
		animationTree.set("parameters/Run/blend_position", input_vector)
		animationTree.set("parameters/Attack/blend_position", input_vector)
		animationTree.set("parameters/Roll/blend_position", roll_vector)
		animationState.travel("Run")
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
		
		
		if Input.is_action_just_pressed("roll"):
			PlayerStats.max_health -= 1
			state = ROLL
	else:
		animationState.travel("Idle")
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

	move()
	
	if Input.is_action_just_pressed("attack"):
		state = ATTACK

func roll_state(delta):
	velocity = roll_vector * ROLL_SPEED
	animationState.travel("Roll")
	move()
	
func attack_state(delta):
	velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta / 2)
	animationState.travel("Attack")
	move()

func move():
	velocity = move_and_slide(velocity)

func roll_state_finished():
	state = MOVE	

func attack_state_finished():
	state = MOVE

func _on_Hurtbox_area_entered(area):
	stats.health -= 1
	hurtbox.start_invicibility(0.5)
	hurtbox.create_hit_effect()
