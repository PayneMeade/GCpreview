extends Node

# Name of the current state
var state :String = ""

# Name of the state for the next frame
var state_next :String = ""

# Amount of frames spent in the current state
var state_timer :int = 0

# True if this is the first frame in this state, false otherwise
var state_new :bool = false

# Dictionary of all the states and their FuncRefs. State names are keys, 
# with their associated FuncRef as the value
var state_dict :Dictionary

# Executes the function for the current state
func state_execute(delta):
	# Checks that the state name is not an empty string 
	# (i.e. state_switch has not been called yet)
	if(!state.empty()):
		# Error checks that the state name exists in the dictionary
		# and calls the associated function if it does
		if(state_dict.has(state)):
			state_dict[state].call_func(delta)
		# If the state isn't in state_dict, switches to the first
		# state in the dictionary (if the dictionary has any entries)
		elif(state_dict.size() > 0):
			state_switch(state_dict.keys()[0])

# Switches to the state associated with state_name, if it exists
# in state_dict. Note that this new state will not run until the
# next frame. 
func state_switch(state_name :String):
	# Checks that the given state is in state_dict and sets
	# state_next to it if so
	if(state_dict.has(state_name)):
		state_next = state_name
	# If the given state isn't in the dictionary, switches to the first
	# state in the dictionary (should one exist)
	elif(state_dict.size() > 0):
		state_next = state_dict.keys()[0]
	# If all else fails, sets state_next to an empty string,
	# disabling the state machine until a valid state_switch call
	# is made
	else:
		state_next = ""
		
# Updates state trackers
func state_update():
	# If we are switching states next frame, updates the state variable
	# to the new state, resets the timer, and sets state_new to true
	if(state_next != state):
		state = state_next
		state_timer = 0
		state_new = true
	# If the state is not changing, increments the state timer and sets
	# state_new to false
	else:
		state_timer += 1
		state_new = false

# Adds a state to the state_dict
func state_create(name :String, script :FuncRef):
	# Adds the new state, with the state name as the key and the associate
	# FuncRef as the value
	state_dict[name] = script
