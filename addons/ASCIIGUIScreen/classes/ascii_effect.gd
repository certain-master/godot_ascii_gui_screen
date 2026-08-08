@tool
class_name ASCIIEffect
extends RichTextEffect

var bbcode = "ascii"

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var cell_width: float = char_fx.env.get("cell_width", 8.0)
	var cell_height: float = char_fx.env.get("cell_height", cell_width * 2.0)
	var line: int = char_fx.env.get("line", 0)
	
	var y_offset: float = char_fx.env.get("y_offset", cell_height * 0.875)
	
	var target_x: float = char_fx.relative_index * cell_width
	var target_y: float = (line * cell_height) + y_offset
	
	char_fx.transform.origin = Vector2(target_x, target_y)
	char_fx.offset = Vector2.ZERO
	
	return true
