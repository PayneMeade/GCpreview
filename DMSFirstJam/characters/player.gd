extends KinematicBody2D

enum input_types {LEFT, RIGHT, JUMP, SHOOT}
var input_name = ["left", "right", "jump", "shoot"]
var input_history :Array

export(bool) var DEBUG_LABEL = false
export(float) var accel :float = 5.0
export(int) var speed :int = 180
export(int) var jump_speed :int = -900
export(int) var gravity :int = 30
export (float) var ground_friction = .2
export (float) var air_friction = .05
export (int) var gun_cooldown = 10
var gun_cooldown_timer = 0

var controller_present :bool = false
var gun_direction :Vector2
var velocity :Vector2 = Vector2.ZERO

var bullet = preload("res://objects/bullet.tscn")

func _ready():
	$FSM.state_create("standing", funcref(self, "standing"))
	$FSM.state_create("running", funcref(self, "running"))
	$FSM.state_create("in_air", funcref(self, "in_air"))
	$FSM.state_switch("standing")
	
	for x in input_types.size():
		input_history.append(0)

func _physics_process(delta):
	input_check()
	# Apply gravity
	velocity.y += gravity
	
	# Input checks
	if input_pressed("right") && speed > abs(velocity.x):
		velocity.x = speed
	if input_pressed("left") && speed > abs(velocity.x):
		velocity.x = -speed
	
	if gun_cooldown_timer > 0:
		gun_cooldown_timer -= 1
	elif input_pressed_within("shoot", 0):
		var new_bullet = bullet.instance()
		$bullet_container.add_child(new_bullet)
		new_bullet.position = global_position + gun_direction * 50
		new_bullet.velocity = gun_direction * 200
		velocity += -gun_direction * 1000
		gun_cooldown_timer = gun_cooldown
	# State code execution
	$FSM.state_execute(delta)
	$FSM.state_update()

	# Moves player based on velocity
	velocity = move_and_slide(velocity, Vector2.UP)

func _process(delta):
	#DEBUG point arrow at mouse
	$arrow.set_rotation(gun_direction.angle())

	if DEBUG_LABEL:
		var right = Input.get_action_strength("right_stick_right")
		var left = Input.get_action_strength("right_stick_left")
		var up = Input.get_action_strength("right_stick_up")
		var down = Input.get_action_strength("right_stick_down")


		$Label.text = "State = " + $FSM.state + "\n"
		$Label.text += String(velocity) + "\n" + String(is_on_floor())
		$Label.text += "\nright = " + String(right) + "\nleft = " + String(left)
		$Label.text += "\nup = " + String(up) + "\ndown = " + String(down)

### State Scripts ###

func standing(delta):
	apply_horz_fric(ground_friction)
	
	if(input_pressed_within("jump", 3)):
		velocity.y = jump_speed
		$FSM.state_switch("in_air")
	if !is_on_floor():
		$FSM.state_switch("in_air")
	elif velocity.x != 0:
		$FSM.state_switch("running")

func in_air(delta):
	apply_horz_fric(air_friction)
	if is_on_floor():
		$FSM.state_switch("standing")

func running(delta):
	apply_horz_fric(ground_friction)
	if(input_pressed_within("jump", 3)):
		velocity.y = jump_speed
		$FSM.state_switch("in_air")
	if !is_on_floor():
		$FSM.state_switch("in_air")
	elif velocity.x == 0:
		$FSM.state_switch("standing")

### End State Scripts ###


### Input Functions ###

# Updates input histories and gun direction
func input_check() -> void:
	# For each type of input, updates the input_history int associated with it
	# The rightmost bit of each int is the state on the current frame (1 = pressed, 0 = not pressed)
	# The bit to the left of the rightmost bit is the state on the previous frame, the bit to its left is
	#	the state two frames ago, etc.
	for x in input_types:
		var itype = input_types[x]
		input_history[ itype ] = (input_history[ itype ] << 1) | int(Input.is_action_pressed( input_name[ itype ] ))
	
	get_gun_angle()

# Given a type of input from the input_types enum, returns true if the input was 
# pressed offset frames ago (0 being this frame)
func input_pressed(itype :String, offset :int = 0) -> bool:
	return bool(input_history[input_types[itype.to_upper()]] & (1 << offset))

# Checks that an input was being pressed at some point in a number of frames specified by window. Specifying an offset will check that number
# of frames x frames in the past, where x is the value of offset
func input_active_within(itype :String, window :int, offset :int = 0) -> bool:	
	var mask = (1 << (window + 1)) - 1
	var read = input_history[ input_types[itype.to_upper()] ] & (mask << offset)
	if read != 0:
		return true
	return false

# Checks that an input was pressed during the number of frames specified by window. Will return false if the input is being
# held going into the window of frames being checked (input must go from inactive to active to return true). If offset is
# specified, the window of frames checked will be x frames in the past by the number (where x = offset)
func input_pressed_within(itype :String, window :int, offset :int = 0) -> bool:
	var mask = (1 << (window + 2)) - 1 # Bit mask for selecting desired frames 
	var rel = (input_history[ input_types[ itype.to_upper() ] ] & (mask << offset)) >> offset # Stores the relevant bits
	
	if(rel == 0): # if the full window is 0, then the input was not pressed
		return false
	
	var chksum = rel ^ mask # XORs the relevant bits and the mask for checking for a hold and release

	if(chksum == 0): # if chksum is 0, then the input was active the entire window, so it's being held and was not pressed in that window
		return false
	
	# If the input was pressed before the window and then released in the window (which we want to return false), the binary number will
	# have some number of leading 1s followed by 0s, e.g. 1110000, which when XOR'd with the all 1s mask, will invert
	# it to be leading 0s followed by 1s, e.f. 0001111. Due to the nature of binary numbers, this means a hold and release
	# chksum will be 1 less than a power of 2. We check to see if the chksum matches any of these possible numbers (will require
	# a number of checks equal to the window size + 1), and if so we return false
	for x in range(1, window + 2):
		if chksum == ((1 << x) - 1):
			return false
	
	# If none of the previous checks failed, then the button was pressed in the desired window and we return true
	return true

# Checks the current angle on the gun (based on either the mouse or the right stick of a controller)
func get_gun_angle() -> void:
	# var x = Input.get_action_strength("right_stick_right")
	# if(x == 0):
	# 	x = -Input.get_action_strength("right_stick_left")
	# var y = Input.get_action_strength("right_stick_down")
	# if(y == 0):
	# 	y = -Input.get_action_strength("right_stick_up")
	
	# gun_direction = Vector2(x,y).normalized()
	if(controller_present): #if a controller is present, use it for input
		pass
	else: #otherwise, use mouse and keyboard
		# gets the unit vector pointing from the player object to the cursor
		gun_direction = get_local_mouse_position().normalized()

### End Input Functions ###


### Helper Functions ###

# Applies horizontal friction using lerp. Perc will be the weight based to lerp
# Movement is clamped to 0 once it drops below 1
func apply_horz_fric(perc :float) -> void:
	if abs(velocity.x) > 0:
		velocity.x = lerp(velocity.x, 0, perc)
	else:
		velocity.x = 0

### End Helper Functions ###
