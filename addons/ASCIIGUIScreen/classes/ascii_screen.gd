@tool
@icon("res://addons/ASCIIGUIScreen/icons/ascii_screen_icon.png")
class_name ASCIIScreen
extends RichTextLabel
## Displays the text for every child [ASCIIElement] in the chosen [ASCIITheme].
## 
## - renders every child's [member ASCIIElement.render_data] in the same [RichTextLabel] grid [br]
## - uses its children's position to assign it a position on its grid                         [br]
## - draws from top to bottom                                                                 [br]
## - supports the use of BBCode in its children (tested: color, url)                          [br]


# =================================================================
# 1. CONSTANTS & ENUMS
# =================================================================

const DEBUG_SPEED_CONSOLE_OUTPUT : bool = false
const STANDARD_ASCII_THEME : String = "res://addons/ASCIIGUIScreen/resources/ascii_themes/standard_ascii_theme.tres"
const STANDARD_COLOR_MAP_SHADER : String = "res://addons/ASCIIGUIScreen/resources/ascii_color.gdshader"

enum ColorMode {
	## Faster, less precise. Scaling issues on non-native resolutions [br]
	## It works by overlaying the color_map over the text. If the text is not aligned perfectly on the grid, the effect breaks. [br]
	## For non native font-sizes use enable_precise_grid_control and line_sub_pixel_offset to tinker until it looks right.
	SHADER,
	## Slower, requires BBCode enabled, prettier[br]
	## Effectively places a bunch of color tags in the [member RichTextLabel.text] field.
	BBCODE
}

# =================================================================
# 2. EXPORT
# =================================================================

@export_group("Theme and Visual Settings")
@export var used_ascii_theme : ASCIITheme = load(STANDARD_ASCII_THEME):
	set(value):
		if used_ascii_theme.is_connected("theme_changed",_on_ascii_theme_changed):
			used_ascii_theme.disconnect("theme_changed",_on_ascii_theme_changed)
		
		if not value:
			push_warning("An ASCII Theme must be set. Using default.")
			used_ascii_theme = load(STANDARD_ASCII_THEME)
		else:
			used_ascii_theme = value
		
		used_ascii_theme.theme_changed.connect(_on_ascii_theme_changed)
		update_all_children()
		reload_screen_and_children()
		refresh_screen()

## Fills the background of the screen with a set of random characters, if true. [br][br]
##
## The characters can be determined in [member ASCIITheme.fill_characters]
@export var fill_with_random_characters : bool:
	set(value):
		fill_with_random_characters = value
		refresh_screen()

## Displays its children's text property in its own text property, if true.
@export var display_children : bool = true:
	set(value):
		display_children = value
		refresh_screen()

@export var show_color : bool = true:
	set(value):
		show_color = value
		refresh_screen()

@export_group("Grid Size (Read Only)")
## Automatically generated Grid-Size of the [ASCIIScreen]         [br]
##                                                                [br]
## - should not be adjusted manually                              [br]
## - size is dependent on [member ASCIIScreen.size]       
##   and the font-size of the font in 
##   [member ASCIIScreen.used_ascii_theme]                        [br]
## - determines the size of [member ASCIIScreen.character_map] 
@export var grid_size : Vector2i = Vector2i(5,5):
	get: return _grid_size
	set(value):
		pass

@export_group("Advanced Rendering Options")

@export var color_mode : ColorMode = ColorMode.BBCODE:
	set(value):
		var changed : bool = color_mode != value
		color_mode = value
		if changed and color_mode == ColorMode.SHADER:
			material = color_shader_material
		elif changed:
			material = CanvasItemMaterial.new()
		refresh_screen()

@export var color_map_shader : Shader = preload(STANDARD_COLOR_MAP_SHADER)

## WARNING for ColorMode.SHADER: If this is not equal to the native size of the font or a multiple of it, this will break the display (causing stretching and misaligned color-texture). [br][br]
## 
## However: You can optionally enable the custom ascii bbcode effect, which allows to manually adjust the rendering position of the final text.[br]
## @experimental
@export_range(1,200) var font_size : int = 16:
	set(value):
		if value % 2:
			if value < font_size:
				font_size = value-1
			else:
				font_size = value+1
		else:
			font_size = value
		reload_screen_and_children()
		refresh_screen()

@export_subgroup("Shader Mode finetuning (Experimental)")

## Only for ColorMode.SHADER. Enables the [ASCIIEffect] on every line of text. Requires BBCode to be enabled.[br]
## @experimental
@export var enable_precise_grid_control : bool = false:
	set(value):
		enable_precise_grid_control = value
		refresh_screen()

## Only for ColorMode.SHADER. If the ASCII characters are STILL not properly displayed, try tinkering with this. Only affects the placement if not equal to 0.0[br]
## @experimental
@export var line_sub_pixel_offset : float = 0.0:
	set(value):
		line_sub_pixel_offset = value
		refresh_screen()

# =================================================================
# 3. PUBLIC / ONREADY VARIABLES
# =================================================================

## Shader used to change the color of the final text.
var color_shader_material : ShaderMaterial
var character_map         : PackedStringArray = []
var color_image           : Image

# =================================================================
# 4. PRIVATE VARIABLES
# =================================================================

var _cached_ascii_cell_dimensions : Vector2
@export_storage var _grid_size    : Vector2i

# =================================================================
# 5. BUILT-IN VIRTUAL METHODS
# =================================================================

func _init() -> void:
	bbcode_enabled = true
	scroll_active  = false
	autowrap_mode  = TextServer.AUTOWRAP_OFF
	child_entered_tree.connect(_on_child_entered)
	child_exiting_tree.connect(_on_child_exiting)
	child_order_changed.connect(_on_child_order_changed)
	resized.connect(_on_size_changed)
	custom_effects.append(ASCIIEffect.new())
	
func _ready() -> void:
	reload_screen()
	update_all_children()
	refresh_screen()

# =================================================================
# 6. PRIVATE / INTERNAL METHODS
# =================================================================

func _reload_shader() -> void:
	color_shader_material        = ShaderMaterial.new()
	color_shader_material.shader = color_map_shader
	if color_mode == ColorMode.SHADER:
		material = color_shader_material

func _reload_font() -> void:
	add_theme_font_override("normal_font",       used_ascii_theme.font)
	add_theme_font_override("bold_font",         used_ascii_theme.font)
	add_theme_font_override("mono_font",         used_ascii_theme.font)
	add_theme_font_override("italics_font",      used_ascii_theme.font)
	add_theme_font_override("bold_italics_font", used_ascii_theme.font)
	
	add_theme_font_size_override("normal_font_size",       font_size)
	add_theme_font_size_override("bold_font_size",         font_size)
	add_theme_font_size_override("mono_font_size",         font_size)
	add_theme_font_size_override("italics_font_size",      font_size)
	add_theme_font_size_override("bold_italics_font_size", font_size)
	
	_cached_ascii_cell_dimensions = Vector2(font_size / 2.0, font_size)

func _update_character_map_size() -> void:
	character_map.resize(grid_size.x * grid_size.y)

## Updates [member ASCIIScreen.grid_size], as well as the dimensions
## of [member ASCIIScreen.character_map]
func _reload_grid() -> void:
	if _cached_ascii_cell_dimensions == Vector2.ZERO:
		push_error("Dimensions of the font have been cached as Vector2(0,0)!")
		return
	_grid_size = Vector2i(size) / Vector2i(_cached_ascii_cell_dimensions)
	_update_character_map_size()

func _update_child_dimensions(child : ASCIIElement) -> void:
	var dimensions : Vector2 = Vector2(child.get_ascii_dimensions()) * _cached_ascii_cell_dimensions
	child.custom_minimum_size = dimensions
	child.custom_maximum_size = dimensions

## Fills every element in [member ASCIIScreen.character_map] with a character specified in
## [member ASCIIScreen.used_ascii_theme]
func _fill_character_map_with_characters() -> void:
	if not used_ascii_theme:
		push_error("used_ascii_theme is not valid!")
		return
	
	var fill_characters : PackedStringArray
	
	if fill_with_random_characters and used_ascii_theme.fill_characters:
		fill_characters = used_ascii_theme.fill_characters.split("")
	else:
		fill_characters = used_ascii_theme.empty_character.split("")
	for i : int in range(character_map.size()):
		var random_index : int = randi_range(0,fill_characters.size()-1)
		character_map[i] = fill_characters[random_index]

func _inject_used_ascii_theme(child : ASCIIElement) -> void:
	child.used_parent_ascii_theme = used_ascii_theme
	child.refresh()

## Function that overrides the character_map and color_image.
func _overwrite_character_and_color_map_with_child(child : ASCIIElement, color_image_data : PackedByteArray) -> void:
	if not child.render_data or not child.render_data.character_map or not child.render_data.color_image_data:
		if not child is ASCIITextElement:
			push_warning("Invalid render_data in child %s" % child.name)
		return
	
	var child_character_map : PackedStringArray = child.render_data.character_map
	var child_color_image_data : PackedByteArray = child.render_data.color_image_data
	
	var offset_x_standard   : int               = child.position.x / (font_size / 2)
	var offset              : Vector2i          = Vector2i(offset_x_standard, roundi(child.position.y / (font_size) ) )
	var child_offset        : Vector2i          = Vector2i.ZERO
	var child_dimensions    : Vector2i          = child.get_ascii_dimensions()
	
	var child_is_ascii_pixel_art : bool = child is ASCIIPixelArt 
	
	var used_transparency_character : String
	if child is ASCIITextElement and child.override_transparency_character:
		used_transparency_character = child.override_transparency_character
	else:
		used_transparency_character = used_ascii_theme.transparency_character
	
	# Bounds
	
	var max_dimensions : int = child_dimensions.x * child_dimensions.y
	
	var elements_to_draw : PackedInt32Array = []
	
	var elements_to_color_blend : PackedByteArray = []
	elements_to_color_blend.resize(max_dimensions)
	
	var child_index_to_screen_index_map : PackedInt32Array = []
	child_index_to_screen_index_map.resize(max_dimensions)
	
	var start_line : int = max(0, -offset.y)
	var end_line : int = min(child_dimensions.y, grid_size.y - offset.y)
	
	var start_cell : int = max(0, -offset.x)
	var end_cell : int = min(child_dimensions.x, grid_size.x - offset.x)
	
	#var draw_count : int = 0
	for line : int in range(start_line, end_line):
		var line_offset : int = line + offset.y
		var child_line_base : int = child_dimensions.x * line
		var screen_line_base : int = grid_size.x * line_offset
		
		#var cell : int = start_cell
		for cell : int in range(start_cell, end_cell):
			var index : int = child_line_base + cell
			var screen_index : int = screen_line_base + cell + offset.x
			
			var alpha : int = color_image_data[screen_index * 4 + 3]
			if alpha == 255:
				continue
			elif alpha != 0:
				elements_to_color_blend[index] = true
			
			elements_to_draw.append(index)
			child_index_to_screen_index_map[index] = screen_index
	
	for i : int in elements_to_draw:
		var element : String = child_character_map[i]
		
		# Transparency
		if not element == used_transparency_character:
			
			# Optional color blending on contrast
			var screen_index : int = child_index_to_screen_index_map[i]
			
			var child_color_index : int = i * 4
			var screen_color_index : int = screen_index * 4
			
			if not child_is_ascii_pixel_art or not child.blend_color_based_on_transparency:
				character_map[screen_index] = element
			elif child_color_image_data[child_color_index+3] == 255:
				character_map[screen_index] = element
			
			# Optional color blending on color
			var new_color : Color = Color.from_rgba8(
				child_color_image_data[child_color_index],
				child_color_image_data[child_color_index+1],
				child_color_image_data[child_color_index+2],
				child_color_image_data[child_color_index+3]
			)
			
			if elements_to_color_blend[i]:
				var ground_color : Color = Color.from_rgba8(
					color_image_data[screen_color_index],
					color_image_data[screen_color_index+1],
					color_image_data[screen_color_index+2],
					color_image_data[screen_color_index+3]
				)
				new_color = new_color.blend(ground_color)
			
			color_image_data[screen_color_index]   = new_color.r8
			color_image_data[screen_color_index+1] = new_color.g8
			color_image_data[screen_color_index+2] = new_color.b8
			if child_is_ascii_pixel_art and child.blend_color_based_on_transparency:
				color_image_data[screen_color_index+3] = new_color.a8
			else:
				color_image_data[screen_color_index+3] = 255

func _display_text() -> void:
	if not is_node_ready():
		return
	
	var start_time : int
	if DEBUG_SPEED_CONSOLE_OUTPUT:
		start_time = Time.get_ticks_msec()
	
	text = ""
	
	_fill_character_map_with_characters()
	
	var color_image_data : PackedByteArray = []
	color_image_data.resize(grid_size.x * grid_size.y * 4)
	
	# Overwrite with Children
	if display_children:
		var children : Array[Node] = get_children()
		children.reverse()
		for child : Node in children:
			if child is ASCIIElement and child.visible:
				_overwrite_character_and_color_map_with_child(child, color_image_data)
	
	color_image = Image.create_from_data(grid_size.x, grid_size.y, false, Image.Format.FORMAT_RGBA8, color_image_data)
	
	var overwrite_time : int
	if DEBUG_SPEED_CONSOLE_OUTPUT:
		overwrite_time = Time.get_ticks_msec()
	
	if not show_color:
		color_image.fill(used_ascii_theme.fallback_color)
	
	# <---- Building final text ---->
	var final_lines : PackedStringArray = []
	
	const COLOR_OPENING : String = "[color="
	const COLOR_CLOSING : String = "[/color]"
	var image_data : PackedByteArray = color_image.get_data()
	var image_max_x : int = color_image.get_size().x
	
	for y : int in grid_size.y:
		var current_line_characters : PackedStringArray = []
		
		if enable_precise_grid_control:
			var ascii_prefix : String
			if not line_sub_pixel_offset:
				ascii_prefix = "[ascii cell_width=%s line=%s]" % [_cached_ascii_cell_dimensions.x, y]
			else:
				ascii_prefix = "[ascii cell_width=%s line=%s y_offset=%s]" % [_cached_ascii_cell_dimensions.x, y, line_sub_pixel_offset]
			current_line_characters.append(ascii_prefix)
		
		if show_color and color_mode == ColorMode.BBCODE:
			var last_color_string : String = ""
			var color_open : bool = false
			
			for x : int in grid_size.x:
				var color_index : int = (image_max_x * y + x) * 4
				var color_string : String = Color8(image_data[color_index], image_data[color_index+1], image_data[color_index+2], image_data[color_index+3]).to_html(false)
				
				if color_string != last_color_string:
					if color_open:
						current_line_characters.append(COLOR_CLOSING)
					
					current_line_characters.append(COLOR_OPENING)
					current_line_characters.append(color_string)
					current_line_characters.append("]")
					
					last_color_string = color_string
					color_open = true
				
				current_line_characters.append(character_map[y * grid_size.x + x])
			
			if color_open:
				current_line_characters.append(COLOR_CLOSING)
		
		else:
			for x : int in grid_size.x:
				current_line_characters.append(character_map[y * grid_size.x + x])
		
		if enable_precise_grid_control:
			var ascii_suffix : String = "[/ascii]"
			current_line_characters.append(ascii_suffix)
		
		final_lines.append("".join(current_line_characters))
	
	text = "\n".join(final_lines)
	
	var join_time : int
	if DEBUG_SPEED_CONSOLE_OUTPUT:
		join_time = Time.get_ticks_msec()
	
	# Color Map
	if color_mode == ColorMode.SHADER:
		var color_texture : ImageTexture = ImageTexture.create_from_image(color_image)
		color_shader_material.set_shader_parameter("color_map", color_texture)
		color_shader_material.set_shader_parameter("grid_size", Vector2(grid_size))
		color_shader_material.set_shader_parameter("node_size", grid_size * Vector2i(_cached_ascii_cell_dimensions))
	
	var color_time : int
	if DEBUG_SPEED_CONSOLE_OUTPUT:
		color_time = Time.get_ticks_msec()
		print("%s   ~   (%s ms for overwriting) (%s ms for joining) (%s ms for coloring)" % [color_time-start_time, overwrite_time-start_time, join_time-overwrite_time, color_time - join_time])


# =================================================================
# 7. PUBLIC METHODS
# =================================================================

## Everything is recalculated entirely, including all children. Does not refresh the screen. (Very slow)
func reload_screen_and_children() -> void:
	reload_screen()
	update_all_children()
	reload_children()

## Everything regarding the screen is recalculated, not including the render_data in the children. Does not refresh the screen. (Fairly quick)
func reload_screen() -> void:
	_reload_font()
	_reload_grid()
	_reload_shader()

## Schedules a reload in all [ASCIIElement] children. Does not refresh the screen.
func reload_children() -> void:
	for child in get_children():
		if child is ASCIIElement:
			child.refresh()

## Overwrites relevant data for all [ASCIIElement] children.
func update_all_children() -> void:
	if not used_ascii_theme:
		push_error("Can not update children: used_ascii_theme is not valid!")
		return
	for child in get_children():
		if child is ASCIIElement:
			_inject_used_ascii_theme(child)
			_update_child_dimensions(child)

## Refreshes the displayed text. Does not recalculate anything. (Fast).
func refresh_screen() -> void:
	if not used_ascii_theme:
		push_error("Can not refresh the screen: used_ascii_theme is not valid!")
		return
	_display_text()

# =================================================================
# 8. CALLABLES
# =================================================================

func _on_child_entered(child : Node) -> void:
	if child is ASCIIElement:
		_inject_used_ascii_theme(child)
	
	if Engine.is_editor_hint():
		if child is ASCIIElement:
			if not child.is_connected("visibility_changed", refresh_screen):
				child.visibility_changed.connect(refresh_screen)
			if not child.is_connected("editor_update_me", _on_child_needs_update):
				child.editor_update_me.connect(_on_child_needs_update)

func _on_child_order_changed() -> void:
	refresh_screen()

func _on_child_exiting(child : Node) -> void:
	if child is ASCIIElement:
		refresh_screen()

func _on_size_changed() -> void:
	_reload_grid()
	refresh_screen()

func _on_child_needs_update(child) -> void:
	_update_child_dimensions(child)
	refresh_screen()

func _on_ascii_theme_changed() -> void:
	add_theme_color_override("default_color", used_ascii_theme.fallback_color)
	reload_screen_and_children()
	refresh_screen()
