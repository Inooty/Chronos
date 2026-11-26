extends Area2D

signal dialogue_finished

const DIALOGUE_SCENE = preload("res://Scenes/Dialogue/dialogue.tscn")

@export var dialogue: Array[DE] = []

@export_group("Click Mode")
@export var click_activate := false
@export var pick_range := 10.0
@export var click_action: StringName = &"use"

@export_group("Named Sets")
@export var sets: Array[DialogueSet] = []
@export var start_set: StringName = &""

@export_group("Stages")
@export var later_dialogues: Array[DialogueSet] = []
@export var loop_stages := false

@export_group("Activation")
@export var activate_instant := false
@export var only_activate_once := true
@export var once_id: StringName = &""
@export var interact_action: StringName = &"interact"

@export_group("Dialogue")
@export var lock_player := true
@export var stop_animations := true        # stop line animations when the dialogue ends
@export var restore_camera_zoom := true    # zoom back to normal when the dialogue ends
@export var bottom_margin := 16.0          # gap between the box and the bottom of the screen

var stage := 0
var activated := false
var dialogue_active := false
var players_inside: Array[Node2D] = []
var _ponder_set := false


func _ready() -> void:
	add_to_group("persist_state")   # remembered by RoomState (optional autoload)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _exit_tree() -> void:
	_set_ponder(null, false)


func save_state() -> Dictionary:
	return {"activated": activated, "stage": stage, "start_set": String(start_set)}


func load_state(d: Dictionary) -> void:
	activated = d.get("activated", activated)
	stage = d.get("stage", stage)
	start_set = StringName(d.get("start_set", String(start_set)))


func _seen() -> bool:
	return once_id != &"" and GameState.has_flag(once_id)


func _process(_delta: float) -> void:
	if click_activate:
		_process_click()
		return
	if activate_instant or players_inside.is_empty():
		return
	if InputMap.has_action(interact_action) and Input.is_action_just_pressed(interact_action):
		activate(players_inside[0])


func _process_click() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	var available := not dialogue_active and not (only_activate_once and activated) and not _seen()
	var holding: bool = player.get("holding") == true
	var in_range := available and not holding \
		and global_position.distance_to(player.global_position) < pick_range

	_set_ponder(player, in_range)

	if in_range and Input.is_action_just_pressed(click_action):
		_set_ponder(player, false)
		activate(player)

func _set_ponder(player: Node, value: bool) -> void:
	if value == _ponder_set:
		return
	_ponder_set = value
	if player == null and is_inside_tree():
		player = get_tree().get_first_node_in_group("player")
	if player and "pondering" in player:
		player.pondering = value


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	players_inside.append(body)
	if activate_instant and not click_activate:
		activate(body)


func _on_body_exited(body: Node2D) -> void:
	players_inside.erase(body)


func set_start(id: StringName) -> void:
	start_set = id


func set_stage(n: int) -> void:
	stage = clampi(n, 0, later_dialogues.size())


func activate(body: Node2D) -> void:
	if only_activate_once and activated:
		return
	_start(body, &"")


func play(set_id: StringName = &"") -> void:
	var players := get_tree().get_nodes_in_group("player")
	var body: Node2D = players[0] if players.size() > 0 else self
	if not _start(body, set_id):
		dialogue_finished.emit.call_deferred()
		return
	await dialogue_finished


func _find_set(id: StringName) -> DialogueSet:
	for s in sets:
		if s != null and s.id == id:
			return s
	return null


func _pick_lines(set_id: StringName) -> Array[DE]:
	var id := set_id if set_id != &"" else start_set
	if id != &"":
		var s := _find_set(id)
		if s:
			return s.lines
		push_warning("DialogueArea2D '%s': no set named '%s'" % [name, id])
		return []

	var lines: Array[DE] = dialogue
	if stage > 0 and stage - 1 < later_dialogues.size() and later_dialogues[stage - 1] != null:
		lines = later_dialogues[stage - 1].lines
	var last_stage := later_dialogues.size()
	if stage < last_stage:
		stage += 1
	elif loop_stages and last_stage > 0:
		stage = 0
	return lines


func _set_players_move(value: bool) -> void:
	for p in get_tree().get_nodes_in_group("player"):
		if "move" in p:
			p.move = value

func _start(_body: Node2D, set_id: StringName) -> bool:
	if dialogue_active:
		push_warning("DialogueArea2D '%s' is already playing" % name)
		return false
	if _seen():
		activated = true
		return false

	var lines := _pick_lines(set_id)
	if lines.is_empty():
		push_warning("DialogueArea2D '%s' has nothing to play" % name)
		return false

	activated = true
	dialogue_active = true
	if once_id != &"":
		GameState.set_flag(once_id)

	var replaced := false
	for old in get_tree().get_nodes_in_group("dialogue"):
		if old.has_method("dismiss"):
			old.dismiss()
			replaced = true
	if replaced:
		_set_players_move(not lock_player)
	if lock_player:
		_set_players_move(false)

	var set_map := {}
	for s in sets:
		if s != null:
			set_map[s.id] = s.lines
	for s in later_dialogues:
		if s != null and s.id != &"":
			set_map[s.id] = s.lines

	var d = DIALOGUE_SCENE.instantiate()
	d.dialogue = lines
	d.sets = set_map
	d.lock_player = lock_player
	d.bottom_margin = bottom_margin
	d.restore_zoom = restore_camera_zoom
	d.stop_animations = stop_animations
	d.origin = self
	d.layer = 100
	d.tree_exited.connect(func(): dialogue_active = false)
	d.finished.connect(func(): dialogue_finished.emit())
	get_tree().current_scene.add_child(d)
	return true
