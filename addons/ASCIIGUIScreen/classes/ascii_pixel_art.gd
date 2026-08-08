@tool
@icon("res://addons/ASCIIGUIScreen/icons/ascii_pixel_art_icon.png")
extends ASCIIElement
class_name ASCIIPixelArt
## An [ASCIIElement] that supports the use of any pixel art image and converts it to ASCII.
## 
## Must be placed as the child of an [ASCIIScreen] to function.

@export_tool_button("REFRESH", "Loop") var clicK_to_refresh : Callable = refresh

## Any Texture2D the ASCII characters are converted from.
@export var texture : Texture2D:
	set(value):
		texture = value
		_on_property_changed()

## If true, transparency in the [member ASCIIPixelArt.texture] will be displayed and color is blended.
@export var blend_color_based_on_transparency : bool = false:
	set(value):
		blend_color_based_on_transparency = value
		_on_property_changed()

## Inverts which character represents low vs high contrast for this [ASCIIElement]. (see [member ASCIITheme.contrast_characters])
@export var invert_contrast : bool = false:
	set(value):
		invert_contrast = value
		_on_property_changed()

@export var scaling_parameter : float = 1.0:
	set(value):
		if value > 0.0:
			scaling_parameter = value
		else:
			push_warning("scaling_parameter has to be larger than 0.0")
			scaling_parameter = 0.01
		_on_property_changed()

@export var interpolation : Image.Interpolation = Image.Interpolation.INTERPOLATE_NEAREST:
	set(value):
		interpolation = value
		_on_property_changed()

func _init() -> void:
	super()

func _ready() -> void:
	super()

func _update_cached_dimensions() -> void:
	if not texture:
		_cached_dimensions = Vector2i.ZERO
		return
	if not (render_data.color_image_height and render_data.color_image_width):
		_cached_dimensions = Vector2i.ZERO
		return
	_cached_dimensions = Vector2i(render_data.color_image_width, render_data.color_image_height)

func refresh() -> void:
	if not is_node_ready():
		return
	if not lock_render_data and texture:
		render_data = ASCIITools.convert_image_to_ascii_render_data(texture, used_parent_ascii_theme, invert_contrast, scaling_parameter, interpolation)
	else:
		render_data = ASCIIRenderData.new()
	_update_cached_dimensions()
