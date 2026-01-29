@tool
class_name StyledPanel
extends PanelContainer

@export var panel_color: Color = UITheme.BG_PANEL:
	set(value):
		panel_color = value
		_update_style()

@export var border_width: int = 2:
	set(value):
		border_width = value
		_update_style()

@export var corner_radius: int = 8:
	set(value):
		corner_radius = value
		_update_style()

@export var show_header: bool = false:
	set(value):
		show_header = value
		_update_layout()

@export var header_text: String = "":
	set(value):
		header_text = value
		_update_header()

var _header_label: Label
var _content_container: VBoxContainer

func _ready() -> void:
	_setup_structure()
	_update_style()

func _setup_structure() -> void:
	if show_header and not _header_label:
		_create_header()

func _create_header() -> void:
	if _header_label:
		return
	_header_label = Label.new()
	_header_label.text = header_text
	_header_label.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	_header_label.add_theme_font_size_override("font_size", 18)
	_header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_header_label)
	move_child(_header_label, 0)

func _update_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = panel_color
	style.border_color = UITheme.BORDER
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.set_content_margin_all(12)
	add_theme_stylebox_override("panel", style)

func _update_layout() -> void:
	if show_header:
		_create_header()
	elif _header_label:
		_header_label.queue_free()
		_header_label = null

func _update_header() -> void:
	if _header_label:
		_header_label.text = header_text

func get_content_container() -> Control:
	return _content_container if _content_container else self
