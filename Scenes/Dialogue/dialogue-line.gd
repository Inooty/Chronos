extends DE
class_name DialogueLine

@export var speaker: String
@export_multiline var text: String

@export_group("Typing")
@export var textspeed := 30.0
@export_dir var textsoundfolder: String
@export var textsound: AudioStream
@export_range(-80.0, 24.0, 0.1) var textvolume := 0.0
@export var textpitchmin := 0.85
@export var textpitchmax := 1.15

@export_group("Talking Animation")
@export var talk_enabled := false
@export var talknode: NodePath
@export var talkanimation: StringName
@export var talkidle: StringName

@export_group("Animation")
@export var animationplayer: NodePath
@export var animationname: StringName
@export var spritenode: NodePath
@export var spriteanimation: StringName
