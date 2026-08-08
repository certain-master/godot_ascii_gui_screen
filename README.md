# Godot ASCII GUI Screen

This plugin adds an ASCIIScreen Node, which can display any number of child ASCIIElement Nodes in the same text label (RichTextLabel).

## Features

Every significant property or method in the plugin is explained using GDScript documentation comments.

### ![ascii_screen_icon](addons/ASCIIGUIScreen/icons/ascii_screen_icon.png) ASCIIScreen (RichTextLabel)
- renders any amount of children in the order of their hierarchy in the tree in the same RichTextLabel
- this is effectively a grid
- color support through either BBCode or a Shader

### ![ascii_screen_icon](addons/ASCIIGUIScreen/icons/ascii_text_element_icon.png) ASCIITextElement
- displays text on the parent ASCIIScreen
- support for BBCode color
- support for BBCode url

![ASCIITextElement](.example_videos/text_example.mp4)

### ![ascii_screen_icon](addons/ASCIIGUIScreen/icons/ascii_pixel_art_icon.png) ASCIIPixelArt
- automatically converts a Texture2D to ASCII characters
- preserves color
- matches contrast
- optionally respects Alpha (transparency) and blends color 

![ASCIIPixelArt](.example_videos/color_blending_example.mp4)

### ASCIITheme Resource
-  define a set of characters for your own ASCIITheme (e.g. ```@%#*+=-:.``` or ```█▓▒░```)
-  set a font to use in the whole ASCIIScreen

![ASCIITheme](.example_videos/theme_example.mp4)

### Performance

I spent a lot of time optimizing the performance in the Editor (and in the Game).

On my 8 year old laptop, a screen refresh takes around 28 msec with the slower BBCode color mode. On my main PC, only around 10 msec.

I might be able to make this even faster in the future.

The example GIFs have been compressed to 2fps and are not representative of the performance.

## Installation

Tested on **Godot Engine 4.7.1**

### Method 1: With the downloade archive
- unpack the downloadable archive in the root (res://) folder of your Godot project
- make sure to enable the plugin in your project settings

### Method 2: Through the Godot Asset Store
- install from the Godot Asset Store
- make sure to enable the plugin in your project settings

## How to Use

1. Create a new ASCIIScreen Node
2. Adjust its size in the Editor (grid size is adjusted automatically)
3. Add any number of ASCIITextElements or ASCIIPixelArts as children of that ASCIIScreen
4. Give the ASCIITextElements or ASCIIPixelArts either a texture or a text to display

## Known Limitations

- with the Shader color mode there are issues with font-sizes that are not a multiple of its native size (workaround with a custom BBCode effect is implemented)
