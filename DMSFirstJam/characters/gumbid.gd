extends KinematicBody2D
export(float) var accel :float = 5.0
export(int) var speed :int = 180
export(int) var gravity :int = 30
var controller_present :bool = false
var velocity :Vector2 = Vector2.ZERO
onready var Rray = get_node("Rray")
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$FSM.state_create("standing", funcref(self, "standing"))
	$FSM.state_create("in_air", funcref(self, "in_air"))
	$FSM.state_switch("standing")
	 # Replace with function body.
	
func standing(delta):
	if is_on_floor():
		velocity.x = speed
	if !Rray.is_colliding() or is_on_wall():
		speed = speed * -1
		velocity.x = speed
	

func in_air(delta):
	if is_on_floor():
		$FSM.state_switch("standing")

		
func _physics_process(delta):
	# Apply gravity
	velocity.y += gravity
	
	$FSM.state_execute(delta)
	$FSM.state_update()
	# Moves gumbid based on velocity
	$Label.text = "speed : " + String(speed) + "\nvelocity : " + String(velocity)
	velocity = move_and_slide(velocity, Vector2.UP)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
