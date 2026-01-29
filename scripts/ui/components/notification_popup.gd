class_name NotificationPopup
extends PanelContainer

signal closed

var message: String = ""
var notification_type: String = "info"
var duration: float = 3.0

var _label: Label
var _timer: Timer
var _tween: Tween

func _ready() -> void:
	_setup_ui()
	_animate_in()
	_start_timer()

func _setup_ui() -> void:
	custom_minimum_size = Vector2(300, 60)

	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)

	match notification_type:
		"success":
			style.bg_color = UITheme.SUCCESS.darkened(0.7)
			style.border_color = UITheme.SUCCESS
		"warning":
			style.bg_color = UITheme.WARNING.darkened(0.7)
			style.border_color = UITheme.WARNING
		"error":
			style.bg_color = UITheme.ERROR.darkened(0.7)
			style.border_color = UITheme.ERROR
		_:
			style.bg_color = UITheme.INFO.darkened(0.7)
			style.border_color = UITheme.INFO

	style.set_border_width_all(2)
	add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	add_child(hbox)

	var icon := Label.new()
	match notification_type:
		"success": icon.text = "✓"
		"warning": icon.text = "⚠"
		"error": icon.text = "✗"
		_: icon.text = "ℹ"
	icon.add_theme_font_size_override("font_size", 20)
	hbox.add_child(icon)

	_label = Label.new()
	_label.text = message
	_label.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	hbox.add_child(_label)

	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.flat = true
	close_btn.pressed.connect(_close)
	hbox.add_child(close_btn)

func _animate_in() -> void:
	modulate.a = 0
	position.x += 50

	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "modulate:a", 1.0, 0.3)
	_tween.tween_property(self, "position:x", position.x - 50, 0.3).set_ease(Tween.EASE_OUT)

func _start_timer() -> void:
	_timer = Timer.new()
	_timer.wait_time = duration
	_timer.one_shot = true
	_timer.timeout.connect(_close)
	add_child(_timer)
	_timer.start()

func _close() -> void:
	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "modulate:a", 0.0, 0.2)
	_tween.tween_property(self, "position:x", position.x + 50, 0.2)
	_tween.chain().tween_callback(queue_free)
	closed.emit()

func set_message(msg: String, type: String = "info") -> void:
	message = msg
	notification_type = type
	if _label:
		_label.text = msg
