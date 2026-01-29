@tool
class_name StyledButton
extends Button

@export var button_color: Color = UITheme.BG_LIGHT:
	set(value):
		button_color = value
		_update_style()

@export var use_gold_accent: bool = false:
	set(value):
		use_gold_accent = value
		_update_style()

var _tween: Tween

func _ready() -> void:
	_update_style()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_pressed)

func _update_style() -> void:
	var normal := UITheme.create_button_stylebox(button_color)
	var hover := UITheme.create_button_hover_stylebox(button_color)
	var pressed_style := UITheme.create_button_stylebox(button_color, true)
	var disabled := UITheme.create_button_stylebox(button_color.darkened(0.3))

	if use_gold_accent:
		normal.border_color = UITheme.ACCENT_GOLD.darkened(0.3)

	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", pressed_style)
	add_theme_stylebox_override("disabled", disabled)

	add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	add_theme_color_override("font_hover_color", UITheme.ACCENT_GOLD)
	add_theme_color_override("font_pressed_color", UITheme.ACCENT_GOLD)
	add_theme_color_override("font_disabled_color", UITheme.TEXT_MUTED)

func _on_mouse_entered() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(1.02, 1.02), 0.1)

func _on_mouse_exited() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2.ONE, 0.1)

func _on_pressed() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.05)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.1)
