extends Node3D

@export var move_speed: float
#var move_speed=30
var Camera=Camera3D.new()
# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(Camera)
	Camera.global_position=global_position



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_key_pressed(KEY_W):
		translate(Vector3(0,0,-1)*move_speed*delta)
	if Input.is_key_pressed(KEY_S):
		translate(Vector3(0,0,1)*move_speed*delta)
	if Input.is_key_pressed(KEY_A):
		translate(Vector3(-1,0,0)*move_speed*delta)
	if Input.is_key_pressed(KEY_D):
		translate(Vector3(1,0,0)*move_speed*delta)
	if Input.is_key_pressed(KEY_E):
		translate(Vector3(0,1,0)*move_speed*delta)
	if Input.is_key_pressed(KEY_SPACE):
		translate(Vector3(0,-1,0)*move_speed*delta)
	#if Input.is_key_pressed(KEY_W):
		#translate(Vector3(0,0,-1)*move_speed*delta)
	#if Input.is_key_pressed(KEY_W):
		#translate(Vector3(0,0,-1)*move_speed*delta)
	#if Input.is_mouse_button_pressed( MOUSE_BUTTON_RIGHT):
		
	
	
	
	
func _unhandled_input(event):
	if Input.is_mouse_button_pressed( MOUSE_BUTTON_MIDDLE):
		if event is InputEventMouseMotion:
			rotate_object_local(Vector3.UP ,-event.relative.x*0.00511111)
			Camera.rotate_object_local(Vector3(1,0,0),event.relative.y*0.0051111)
			Camera.rotation.x=clamp(Camera.rotation.x, -PI/2,PI/2)

