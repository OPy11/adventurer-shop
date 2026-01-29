class_name NotificationPopup
extends PanelContainer

var message: String = ""
var notification_type: String = "info"

var _icon_label: Label
var _message_label: Label
var _close_button: Button
var _timer: Timer

func _ready() -> void:
	_setup_ui()
	_animate_in()
	_start_timer()

func _setup_ui() -> void:
	custom_minimum_size = Vector2(320, 70)
	size_flags_horizontal = Control.SIZE_SHRINK_END

	var bg_color := UITheme.BG_PANEL
	var border_color := UITheme.INFO
	var icon_text := "ℹ"

	match notification_type:
		"success":
			bg_color = UITheme.SUCCESS.darkened(0.7)
			border_color = UITheme.SUCCESS
			icon_text = "✓"
		"warning":
			bg_color = UITheme.WARNING.darkened(0.7)
			border_color = UITheme.WARNING
			icon_text = "⚠"
		"error":
			bg_color = UITheme.ERROR.darkened(0.7)
			border_color = UITheme.ERROR
			icon_text = "✗"
		"info":
			bg_color = UITheme.INFO.darkened(0.7)
			border_color = UITheme.INFO
			icon_text = "ℹ"

	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.border_width_left = 4
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	add_child(hbox)

	# Icon
	_icon_label = Label.new()
	_icon_label.text = icon_text
	_icon_label.add_theme_font_size_override("font_size", 22)
	_icon_label.add_theme_color_override("font_color", border_color)
	_icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(_icon_label)

	# Message
	_message_label = Label.new()
	_message_label.text = message
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UITheme.style_label(_message_label, UITheme.FONT_BODY, UITheme.TEXT_PRIMARY)
	hbox.add_child(_message_label)

	# Close button
	_close_button = Button.new()
	_close_button.text = "×"
	_close_button.custom_minimum_size = Vector2(30, 30)
	_close_button.pressed.connect(_dismiss)
	_close_button.flat = true
	_close_button.add_theme_font_size_override("font_size", 18)
	_close_button.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	_close_button.add_theme_color_override("font_hover_color", UITheme.TEXT_PRIMARY)
	hbox.add_child(_close_button)

func _animate_in() -> void:
	modulate.a = 0
	position.x += 50

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", position.x - 50, 0.3).set_ease(Tween.EASE_OUT)

func _start_timer() -> void:
	_timer = Timer.new()
	_timer.wait_time = 4.0
	_timer.one_shot = true
	_timer.timeout.connect(_dismiss)
	add_child(_timer)
	_timer.start()

func _dismiss() -> void:
	if _timer:
		_timer.stop()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:x", position.x + 50, 0.2).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
