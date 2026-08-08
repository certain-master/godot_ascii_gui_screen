@tool
class_name ASCIITheme
extends Resource
## A Resource defining a set of characters, a font and fallback color for an ASCIIScreen.

signal theme_changed()

## Use a monospace font for accurate display
@export var font : Font:
	set(value):
		font = value
		theme_changed.emit()

## A set of single ASCII characters representing contrast.           [br]
##                                                                   [br]
## These are only used for [ASCIIPixelArt].                          [br]
##                                                                   [br]
## - expected to be ordered from high contrast to low contrast.      [br]
## - forbidden characters: [code] "[" "]" [/code]                    [br]
@export var contrast_characters : String = "█▓▒░":
	set(value):
		contrast_characters = value
		theme_changed.emit()

## A single ASCII character used to indicate a transparent character.            [br]
##                                                                               [br]
## e.g. if used in an [ASCIIElement], this character will be replaced
## by whatever is drawn 'underneath' [br][br]
## 
## (with [code]transparency_character = "~"[/code]) rendering this:
## [codeblock]
## ┌──────────────────────┐
## │~This is an example!~~│
## │~~~~~~~~~~~~~~~~~~~~~~│
## │~~~~~~~~~~~\o/~~~~~~~~│
## │~~~~~~~~~~~ | ~~~~~~~~│
## │~~~~~~~~~~~ ┴ ~~~~~~~~│
## │~~~~~~~~~~~~~~~~~~~~~~│
## └──────────────────────┘
## [/codeblock]
## in front of this:
## [codeblock]
## ffffffffffffffffffffffff
## ffffffffffffffffffffffff
## ffffffffffffffffffffffff
## ffffffffffffffffffffffff
## ffffffffffffffffffffffff
## ffffffffffffffffffffffff
## ffffffffffffffffffffffff
## ffffffffffffffffffffffff
## [/codeblock]
## would render this:
## [codeblock]
## ┌──────────────────────┐
## │fThis is an example!ff│
## │ffffffffffffffffffffff│
## │fffffffffff\o/ffffffff│
## │fffffffffff | ffffffff│
## │fffffffffff ┴ ffffffff│
## │ffffffffffffffffffffff│
## └──────────────────────┘
## [/codeblock]
@export var transparency_character : String = "~":
	set(value):
		transparency_character = value
		theme_changed.emit()

## A single ASCII character that is considered zero contrast and will override its background.[br][br]
## 
## (with [code]empty_character = " "[/code]) rendering this:
## [codeblock]
## ┌──────────────────────┐
## │ This is an example!  │
## │                      │
## │           \o/ ~~~~~  │
## │            |  ~~~~~  │
## │            ┴  ~~~~~  │
## │                      │
## └──────────────────────┘
## [/codeblock]
## in front of this:
## [codeblock]
## ffffffffffffffffffffffff
## ffffffffffffffffffffffff
## ffffffffffffffffffffffff
## ffffffffffffffffffffffff
## ffffffffffffffffffffffff
## ffffffffffffffffffffffff
## ffffffffffffffffffffffff
## ffffffffffffffffffffffff
## [/codeblock]
## would render this:
## [codeblock]
## ┌──────────────────────┐
## │ This is an example!  │
## │                      │
## │           \o/ fffff  │
## │            |  fffff  │
## │            ┴  fffff  │
## │                      │
## └──────────────────────┘
## [/codeblock]
@export var empty_character : String = " ":
	set(value):
		empty_character = value
		theme_changed.emit()

## A string of ASCII characters that will be used to fill the background of the screen in random order.[br]
## If not set, the [member ASCIITheme.empty_character] will be used instead.
@export var fill_characters : String:
	set(value):
		fill_characters = value
		theme_changed.emit()

## Color that is used when no color data is available or [member ASCIIScreen.show_color] is set to false.
@export var fallback_color : Color = Color.WHITE:
	set(value):
		fallback_color = value
		theme_changed.emit()
