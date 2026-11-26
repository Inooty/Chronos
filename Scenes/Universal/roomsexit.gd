extends Area2D

@export_file("*.tscn") var target_room: String
@export var target_spawn: StringName = &""
@export var fade_time := 0.3

var player_inside := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if player_inside and Input.is_action_just_pressed("interact"):
		if target_room == "":
			push_warning("RoomExit has no target_room set")
			return

		RoomManager.change_room(target_room, target_spawn, fade_time)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = false
