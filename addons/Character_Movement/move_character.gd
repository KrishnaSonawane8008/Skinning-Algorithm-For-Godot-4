@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("Movable Char", "Node3D", preload("res://addons/Character_Movement/Movement.gd"), preload("res://addons/Character_Movement/Character_Movement_Node.png"))


func _exit_tree():
	remove_custom_type("Movable Char")
