@tool
extends Object
class_name ASCIITools
## Contains only static methods. Essential for converting text or textures to ASCII.

## Returns the matching suffix-tag for a given BBCode prefix-tag [br][br]
##
## e.g. tag=[code]'[color=red]'[/code] would return [code]'[/color]'[/code]
static func to_closed_bbcode_tag(tag : String) -> String:
	return "[/" + to_bbcode_tag_keyword(tag) + "]"

## Returns the keyword for a given BBCode tag [br][br]
##
## e.g. tag=[code]'[color=red]'[/code] would return [code]'color'[/code]
static func to_bbcode_tag_keyword(tag : String) -> String:
	var start := 1
	if tag.begins_with("[/"):
		start = 2
	var end := tag.find("=")
	if end == -1:
		end = tag.find("]")
	if end == -1:
		end = tag.length()
	return tag.substr(start, end - start)

## Returns true, if both "[" and "]" are contained in a given string.
static func contains_tag(string : String) -> bool:
	return (string.contains("[") and string.contains("]"))

## Returns a [Color] from a given BBCode color-tag[br][br]
##
## e.g. tag=[code]'[color=red]'[/code] would return [code]Color.RED[/code] [br]
## (works with every color supported by [method Color.from_string()])
static func bbc_color_tag_to_color_code(bbcode_prefix_tag : String, fallback_color : Color = Color.WHITE) -> Color:
	var split_tag    : PackedStringArray = bbcode_prefix_tag.rstrip("]").split("=")
	var color_string : String            = split_tag[split_tag.size()-1]
	var color        : Color             = Color.from_string(color_string, fallback_color)
	
	return color


## returns [cached_prefix,cached_suffix,color_cache]
static func get_rebuilt_suffix_prefix_color_cache(prefixes : PackedStringArray, fallback_color : Color) -> Array:
	
	var color_cache   : Color = fallback_color
	var cached_prefix : String
	var cached_suffix : String
	
	if prefixes.is_empty():
		cached_prefix = ""
		cached_suffix = ""
		return [cached_prefix, cached_suffix, color_cache]
	
	var filtered_prefixes : PackedStringArray = []
	# Sort out color tags
	for prefix in prefixes:
		if ASCIITools.to_bbcode_tag_keyword(prefix) == "color":
			color_cache = ASCIITools.bbc_color_tag_to_color_code(prefix)
		else:
			filtered_prefixes.append(prefix)
	cached_prefix = "".join(filtered_prefixes)
	
	var suffixes : PackedStringArray = filtered_prefixes.duplicate()
	var suffixes_ordered : PackedStringArray = []
	for i in range(suffixes.size()-1,-1,-1):
		var suffix : String = suffixes[i]
		suffix = ASCIITools.to_closed_bbcode_tag(suffix)
		suffixes_ordered.append(suffix)
	cached_suffix = "".join(suffixes_ordered)
	
	return [cached_prefix,cached_suffix,color_cache]

## Returns the render_data for any given BBCode text.
static func parse_bbcode(
		text_array                      : PackedStringArray,
		dimensions                      : Vector2i,
		ascii_theme                     : ASCIITheme,
		processing_mode                 : ASCIITextElement.ProcessingMode = ASCIITextElement.ProcessingMode.MULTI_TAG,
		override_transparency_character : String                          = ""
	) -> ASCIIRenderData:
	
	var render_data : ASCIIRenderData = ASCIIRenderData.new()
	
	# Skipping if it has no size on the screen anyway
	if dimensions == Vector2i.ZERO:
		return render_data
	
	if not ascii_theme:
		push_warning("No valid ascii_theme was given.")
		return render_data
	if not text_array or text_array.size() == 0:
		push_warning("No valid text_array was given. Either null or size of 0.")
		return render_data
	
	# Character Override
	var used_transparency_character : String
	if override_transparency_character:
		used_transparency_character = override_transparency_character
	else:
		used_transparency_character = ascii_theme.transparency_character
	
	# Filling character_map with transparent background
	var character_map : PackedStringArray
	character_map.resize(dimensions[0]*dimensions[1])
	character_map.fill(ascii_theme.empty_character)
	
	# Filling color_image with fallback_color
	var color_image : Image = Image.create(dimensions.x, dimensions.y, false, Image.Format.FORMAT_RGBA8)
	color_image.fill(ascii_theme.fallback_color)
	
	# Cache and Cursor
	var cursor_x                      : int               = 0
	var cursor_y                      : int               = 0
	var color_cache                   : Color             = ascii_theme.fallback_color
	var cached_prefix                 : String
	var cached_suffix                 : String
	var tag_cursor_cache              : PackedStringArray = []
	var cursor_in_cache               : bool              = false
	var batch_already_read_prefix_tag : bool              = false
	
	# Array of prefix tags
	var active_tags : PackedStringArray = []
	# Array containing only the keyword of a tag (e.g. "color" or "url")
	var active_tag_keywords : PackedStringArray = []

	for character : String in text_array:
		
		# <--- Normal Behaviour --->
		
		if not cursor_in_cache:
			var index : int = cursor_y * dimensions[0] + cursor_x
			
			# Transparency characters
			if character == used_transparency_character:
				character_map[index] = character
				cursor_x += 1
				continue
			
			# Move to next line if there is a break
			elif character == "\n":
				cursor_y += 1
				cursor_x = 0
				continue
			
			# Opening BBCode tag found
			elif processing_mode != ASCIITextElement.ProcessingMode.NO_TAGS and character == "[":
				tag_cursor_cache.append(character)
				cursor_in_cache = true
				continue
			
			# Writing character + non-color prefixes to cache
			
			if cached_prefix.is_empty():
				character_map[index] = character
			else:
				character_map[index] = cached_prefix + character + cached_suffix
			
			# Writing current cached color into color_image
			color_image.set_pixel(cursor_x, cursor_y, color_cache)
			
			cursor_x += 1
			continue
		
		# <--- Behaviour while cursor is inside a BBCode tags --->
		else:
			tag_cursor_cache.append(character)
			
			if not character == "]":
				continue
			
			# If the end of the tag is detected
			var is_closing_tag : bool = false
			var joint_tag_from_cache : String = "".join(tag_cursor_cache)
			
			if processing_mode == ASCIITextElement.ProcessingMode.COLOR_ONLY:
				if not batch_already_read_prefix_tag:
					color_cache = ASCIITools.bbc_color_tag_to_color_code(joint_tag_from_cache)
					batch_already_read_prefix_tag = true
				else:
					color_cache = ascii_theme.fallback_color
					batch_already_read_prefix_tag = false
				cursor_in_cache = false
				tag_cursor_cache = []
				continue
			
			var keyword_from_cache : String = ASCIITools.to_bbcode_tag_keyword(joint_tag_from_cache)
			
			# Depending on it being an opening or closing tag, add or erase it to the active_tags
			if not active_tags.is_empty():
				for i : int in active_tag_keywords.size():
					if active_tag_keywords[i] == keyword_from_cache:
						active_tags.remove_at(i)
						active_tag_keywords.remove_at(i)
						is_closing_tag = true
						break
			
			if not is_closing_tag:
				active_tags.append(joint_tag_from_cache)
				active_tag_keywords.append(keyword_from_cache)
			
			var cache_array : Array = get_rebuilt_suffix_prefix_color_cache(active_tags, ascii_theme.fallback_color)
			cached_prefix           = cache_array[0]
			cached_suffix           = cache_array[1]
			color_cache             = cache_array[2]
			cursor_in_cache         = false
			tag_cursor_cache        = []
	
	render_data.character_map = character_map
	render_data.color_image_data = color_image.get_data()
	render_data.color_image_height = color_image.get_height()
	render_data.color_image_width = color_image.get_width()
	return render_data

const ASCII_CHARACTERS_PER_PIXEL : int = 2

## Returns the render_data for any given Texture2D.
static func convert_image_to_ascii_render_data(texture : Texture2D, ascii_theme : ASCIITheme, invert_contrast = false, scaling : float = 1.0, interpolation = Image.Interpolation.INTERPOLATE_NEAREST) -> ASCIIRenderData:
	var render_data : ASCIIRenderData = ASCIIRenderData.new()
	
	var character_map : PackedStringArray
	
	if not texture or not ascii_theme:
		push_error("Invalid arguments.")
		return render_data
	
	# Image needed to iterate
	var image : Image = texture.get_image().duplicate()
	
	if not image:
		push_warning("Text was not converted to Image.")
		return render_data
	
	if scaling != 1.0:
		var image_scaled_size : Vector2i = Vector2i(texture.get_size() * scaling)
		image.resize(image_scaled_size.x, image_scaled_size.y, interpolation)
	
	var dimensions : Vector2i = Vector2i(image.get_width() * ASCII_CHARACTERS_PER_PIXEL, image.get_height())
	
	var color_image : Image = Image.create(dimensions.x, dimensions.y, false, Image.Format.FORMAT_RGBA8)
	character_map.resize(dimensions.x * dimensions.y)
	
	var contrast_characters_array  : PackedStringArray = ascii_theme.contrast_characters.split("")
	contrast_characters_array.append(ascii_theme.empty_character)
	var contrast_characters_amount : int               = contrast_characters_array.size()
	
	# This is deliberate... Has to do because of the way the order of characters was defined in ASCIITheme
	if not invert_contrast:
		contrast_characters_array.reverse()
	
	for y in image.get_height():
		for x in image.get_width():
			var pixel_color : Color = image.get_pixel(x,y)
			
			# Logic for Contrast
			var luminance      : float  = pixel_color.get_luminance()
			var contrast_index : int    = int(luminance * (contrast_characters_amount - 1))
			var character      : String = contrast_characters_array[contrast_index]
			
			for n in ASCII_CHARACTERS_PER_PIXEL:
				var target_x : int = x * ASCII_CHARACTERS_PER_PIXEL + n
				var index    : int = y * dimensions.x + target_x
				
				color_image.set_pixel(target_x, y, pixel_color)
				
				# Logic for transparency
				if pixel_color.a == 0.0:
					character_map[index] = ascii_theme.transparency_character
					continue
				
				# Logic for Contrast
				character_map[index] = character
	
	render_data.character_map = character_map
	render_data.color_image_data = color_image.get_data()
	render_data.color_image_height = color_image.get_height()
	render_data.color_image_width = color_image.get_width()
	
	return render_data
