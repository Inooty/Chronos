extends DialogueLine
class_name DialogueText

enum FunctionTiming { LINE_START, AFTER_TYPING, AFTER_ENTER }

@export_group("")
@export var persist_end := false   # remember that the AnimationPlayer animation finished

@export var camerapos := Vector2(999.999, 999.999)   # 999.999 = don't move the camera
@export var cameratranstime := 1.0

@export_group("Camera Zoom")
@export var camerazoom := 0.0             # 0 = don't change. 1 = normal, 2 = zoomed in
@export var camerazoomtime := 0.5         # seconds (0 = instant)
@export var camerazoomuntilend := false   # OFF = only this line. ON = until the dialogue ends

@export_group("Function")
@export var use_function := false
@export var function_call: DialogueFunction
@export var function_timing: FunctionTiming = FunctionTiming.AFTER_ENTER
@export var function_blocks := false      # ON = dialogue waits for the function (and its waitsignal)

func persist_key(ap: Node) -> StringName:
	return StringName("anim_end:%s:%s" % [ap.get_path(), animationname])
