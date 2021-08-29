extends KinematicBody2D

var velocity :Vector2 = Vector2.ZERO

func _physics_process(delta):
	var collision = move_and_collide(velocity * delta)
	if collision != null:
		queue_free()
