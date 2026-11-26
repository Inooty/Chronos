extends DialogueLine
class_name DialogueChoice

@export_group("Choices")
@export var choicetext: Array[String]
@export var choicetextcall: Array[DialogueFunction]
@export var choicejump: Array[StringName]
@export var choiceresponse: Array[DialogueText]
