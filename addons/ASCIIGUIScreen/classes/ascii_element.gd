@tool
@icon("res://addons/ASCIIGUIScreen/icons/ascii_icon.png")
extends Control
class_name ASCIIElement
## An ASCIIElement used to display ASCII characters on an [ASCIIScreen]
##
## This class on its own has no real functionality. Use a child class instead, e.g. [ASCIIPixelArt] or [ASCIITextElement]

# =================================================================
# 1. CONSTANTS & ENUMS & SIGNALS
# =================================================================

## Used by [ASCIIScreen] to know when to schedule a redraw (or a change in dimensions)
signal editor_update_me(node : ASCIIElement)

# =================================================================
# 2. EXPORT
# =================================================================

## Contains the data relevant to display ASCII characters on an [ASCIIScreen].
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR) var render_data : ASCIIRenderData:
	set(value):
		_render_data = value
	get:
		if stored_render_data and lock_render_data:
			return stored_render_data
		return _render_data

@export_group("'Baking' ASCII RenderData")

## If true, the [member ASCIIElement.stored_render_data] is used instead of [member ASCIIElement.render_data].[br][br]
## 
## While true, render_data does not change and stored_render_data is not updated. It is also serialized. [br][br]
## 
## This allows for someone to pregenerate [ASCIIRenderData] and assign it.
@export var lock_render_data : bool = false:
	set(value):
		if value:
			if not render_data:
				push_error("Can't lock render data, as it is null.")
				return
			stored_render_data = render_data.duplicate_deep()
			lock_render_data = value
		else:
			lock_render_data = value
			stored_render_data = null
			_on_property_changed()

## If [member ASCIIElement.lock_render_data] is true, this is used instead of [member ASCIIElement.render_data].
@export var stored_render_data : ASCIIRenderData

# =================================================================
# 3. PUBLIC / ONREADY VARIABLES
# =================================================================

# Injected by parent ([ASCIIScreen])
var used_parent_ascii_theme : ASCIITheme = load(ASCIIScreen.STANDARD_ASCII_THEME)

# =================================================================
# 4. PRIVATE VARIABLES
# =================================================================

var _render_data : ASCIIRenderData = ASCIIRenderData.new()

var _cached_dimensions : Vector2i

var _last_position : Vector2

# =================================================================
# 5. BUILT-IN VIRTUAL METHODS
# =================================================================

func _init() -> void:
	_last_position = position
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size = Vector2(20,20)
	set_notify_transform(true)

func _ready() -> void:
	if get_parent() is not ASCIIScreen:
		push_error("ASCIIElement is not child of an ASCIIScreen.")
	refresh()

# =================================================================
# 6. PRIVATE / INTERNAL METHODS
# =================================================================

## Updates the cached dimensions.[br][br]
## Overwritten in child class.
func _update_cached_dimensions() -> void:
	return

# =================================================================
# 7. PUBLIC METHODS
# =================================================================

## Reparses or rerenders [member ASCIIElement.render_data], after updating its own dimensions.[br][br]
## Overwritten in child class.
func refresh() -> void:
	return

## Returns a [Vector2i] of the grid size dimensions of this [ASCIIElement]
func get_ascii_dimensions() -> Vector2i:
	if not _cached_dimensions:
		return Vector2i(0,0)
	return _cached_dimensions

# =================================================================
# 8. CALLABLES
# =================================================================

## Typically called by any setter to schedule a refresh in the Editor.
func _on_property_changed() -> void:
	if not is_node_ready():
		return
	refresh()
	editor_update_me.emit(self)

## Recognizes changes to the position of the Node and emits editor_update_me()
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and position != _last_position:
		_last_position = position
		editor_update_me.emit(self)
