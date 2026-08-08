@tool
@icon("res://addons/ASCIIGUIScreen/icons/ascii_text_element_icon.png")
extends ASCIIElement
class_name ASCIITextElement

# =================================================================
# 1. CONSTANTS & ENUMS & SIGNALS
# =================================================================

enum ProcessingMode {
	## (Default): [br]
	## - slowest [br]
	## - works for multiple nested BBCode tags. (tested: color, url) [br]
	MULTI_TAG,
	## [br]
	## - significantly faster than MULTI_TAG [br]
	## - requires the text to ONLY contain the color tag, or no tags at all [br]
	COLOR_ONLY,
	## [br]
	## - fastest, skips the BBCode-parsing [br]
	## [br]
	NO_TAGS
}

# =================================================================
# 2. EXPORT
# =================================================================

@export var text_resource : ASCIITextResource = ASCIITextResource.new():
	set(value):
		if text_resource and text_resource.is_connected("text_changed", _on_text_resource_changed):
			text_resource.disconnect("text_changed", _on_text_resource_changed)
		text_resource = value
		if text_resource:
			text_resource.text_changed.connect(_on_text_resource_changed)
		_on_property_changed()

## An optimization option if more performance is needed. [br][br]
##
## If you are unsure, going with the Default may be slower, it should be fast enough, 
## because the parsing is only done on changes to [member ASCIIArtElement.text] or any property
## that have an effect.
@export var processing_mode : ProcessingMode = ProcessingMode.MULTI_TAG:
	set(value):
		processing_mode = value
		_on_property_changed()

## This single character will be treated as a transparent placeholder
## instead of the one specified in the [member ASCIIScreen.used_ascii_theme] of the parent [ASCIIScreen].
## 
## e.g. if your text looks like this... :
## [codeblock]
## ┌──────────────────────┐
## │ This is an example!  │
## │                      │
## │           \o/        │
## │            |         │
## │            ┴         │
## │                      │
## └──────────────────────┘
## [/codeblock]
## ... you can set the override_transparency_character to [code]" "[/code] to make the background transparent.
@export var override_transparency_character : String:
	set(value):
		if value.length() > 1:
			push_warning("Setting override_transparency_character of an ASCIIArtElement to multiple characters is not allowed. Value was not changed.")
			return
		override_transparency_character = value
		_on_property_changed()

# =================================================================
# 3. PUBLIC / ONREADY VARIABLES
# =================================================================

var text : String:
	get:
		if text_resource:
			return text_resource.text
		return ""
	set(value):
		if text_resource:
			text_resource.text = value

# =================================================================
# 4. PRIVATE VARIABLES
# =================================================================

var _cached_split_text_array : PackedStringArray

# =================================================================
# 5. BUILT-IN VIRTUAL METHODS
# =================================================================

func _init() -> void:
	super()

func _ready() -> void:
	super()

# =================================================================
# 6. PRIVATE / INTERNAL METHODS
# =================================================================

func _update_cached_dimensions() -> void:
	var dimension_x : int = 0
	var dimension_y : int = 0
	var max_x : int = 0
	
	if lock_render_data and stored_render_data and stored_render_data.character_map and not stored_render_data.character_map.is_empty():
		_cached_dimensions = Vector2i(stored_render_data.color_image_width, stored_render_data.color_image_height)
		return
	
	var used_text : String = text
	
	if used_text.is_empty():
		_cached_dimensions = Vector2i.ZERO
		return
	
	dimension_y += 1
	var cursor_in_tag : bool = false
	
	for character : String in used_text:
		
		if cursor_in_tag:
			if character == "]":
				cursor_in_tag = false
				continue
			continue
		
		if character == "\n":
			dimension_y += 1
			if dimension_x > max_x:
				max_x = dimension_x
			dimension_x = 0
			continue
			
		if character == "[" and not processing_mode == ProcessingMode.NO_TAGS:
			cursor_in_tag = true
			continue
		
		dimension_x += 1
	if dimension_x > max_x:
		max_x = dimension_x
	_cached_dimensions = Vector2i(max_x,dimension_y)

# =================================================================
# 7. PUBLIC METHODS
# =================================================================

func refresh() -> void:
	_update_cached_dimensions()
	if not (lock_render_data and stored_render_data):
		_cached_split_text_array = text.split("")
		render_data = ASCIITools.parse_bbcode(_cached_split_text_array,_cached_dimensions,used_parent_ascii_theme,processing_mode,override_transparency_character)

func get_ascii_dimensions() -> Vector2i:
	if _cached_dimensions:
		return _cached_dimensions
	_update_cached_dimensions()
	return _cached_dimensions

# =================================================================
# 8. CALLABLES
# =================================================================

func _on_text_resource_changed() -> void:
	_on_property_changed()
