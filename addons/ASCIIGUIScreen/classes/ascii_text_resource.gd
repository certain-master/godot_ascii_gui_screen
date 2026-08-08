@tool
class_name ASCIITextResource
extends Resource
## A Resource that makes ASCII text assets reuseable across different Scenes.
## 
## Use together with [ASCIITextElement].

signal text_changed()

@export_multiline("monospace", "no_wrap") var text : String:
	set(value):
		text = value
		text_changed.emit()
