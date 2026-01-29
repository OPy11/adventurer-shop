class_name HeaderBar
extends PanelContainer

var _shop_name: Label
var _gold_label: Label
var _reputation_bar: ProgressBar
var _reputation_label: Label
var _day_label: Label
var _time_label: Label
var _speed_buttons: HBoxContainer
var _current_speed: float = 1.0

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_update_display()

func _process(_delta: float) -> void:
	_time_label.text = "%s %s" % [TimeManager.get_formatted_time(), TimeManager.get_time_of_day_arabic()]

func _setup_ui() -> void:
	custom_minimum_size = Vector2(0, 65)

	var style := StyleBoxFlat.new()
	style.bg_color = UITheme.BG_DARK
	style.border_color = UITheme.ACCENT_GOLD.darkened(0.5)
	style.border_width_bottom = 3
	style.set_content_margin_all(12)
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 25)
	add_child(hbox)

	# Shop name
	_shop_name = Label.new()
	_shop_name.text = GameManager.shop_name
	UITheme.style_label(_shop_name, UITheme.FONT_TITLE, UITheme.ACCENT_GOLD)
	hbox.add_child(_shop_name)

	# Gold section
	var gold_panel := PanelContainer.new()
	gold_panel.add_theme_stylebox_override("panel", UITheme.create_panel_stylebox(UITheme.BG_PANEL, 1))
	hbox.add_child(gold_panel)

	var gold_container := HBoxContainer.new()
	gold_container.add_theme_constant_override("separation", 8)
	gold_panel.add_child(gold_container)

	var gold_icon := Label.new()
	gold_icon.text = "💰"
	gold_icon.add_theme_font_size_override("font_size", 20)
	gold_container.add_child(gold_icon)

	_gold_label = Label.new()
	UITheme.style_label(_gold_label, UITheme.FONT_HEADER, UITheme.ACCENT_GOLD)
	gold_container.add_child(_gold_label)

	# Reputation section
	var rep_panel := PanelContainer.new()
	rep_panel.add_theme_stylebox_override("panel", UITheme.create_panel_stylebox(UITheme.BG_PANEL, 1))
	hbox.add_child(rep_panel)

	var rep_container := HBoxContainer.new()
	rep_container.add_theme_constant_override("separation", 12)
	rep_panel.add_child(rep_container)

	var rep_icon := Label.new()
	rep_icon.text = "⭐"
	rep_icon.add_theme_font_size_override("font_size", 18)
	rep_container.add_child(rep_icon)

	var rep_info := VBoxContainer.new()
	rep_info.add_theme_constant_override("separation", 2)
	rep_container.add_child(rep_info)

	var rep_header := HBoxContainer.new()
	rep_header.add_theme_constant_override("separation", 8)
	rep_info.add_child(rep_header)

	var rep_title := Label.new()
	rep_title.text = "السمعة:"
	UITheme.style_label(rep_title, UITheme.FONT_SMALL, UITheme.TEXT_MUTED)
	rep_header.add_child(rep_title)

	_reputation_label = Label.new()
	UITheme.style_label(_reputation_label, UITheme.FONT_BODY, UITheme.SUCCESS)
	rep_header.add_child(_reputation_label)

	_reputation_bar = ProgressBar.new()
	_reputation_bar.custom_minimum_size = Vector2(120, 12)
	_reputation_bar.max_value = 100
	_reputation_bar.show_percentage = false
	UITheme.style_progress_bar(_reputation_bar, UITheme.SUCCESS, UITheme.BG_DARK)
	rep_info.add_child(_reputation_bar)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	# Day and time section
	var time_panel := PanelContainer.new()
	time_panel.add_theme_stylebox_override("panel", UITheme.create_panel_stylebox(UITheme.BG_PANEL, 1))
	hbox.add_child(time_panel)

	var time_container := VBoxContainer.new()
	time_container.add_theme_constant_override("separation", 2)
	time_panel.add_child(time_container)

	_day_label = Label.new()
	UITheme.style_label(_day_label, UITheme.FONT_BODY, UITheme.TEXT_PRIMARY)
	_day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_container.add_child(_day_label)

	_time_label = Label.new()
	UITheme.style_label(_time_label, UITheme.FONT_SMALL, UITheme.TEXT_SECONDARY)
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_container.add_child(_time_label)

	# Speed controls
	var speed_panel := PanelContainer.new()
	speed_panel.add_theme_stylebox_override("panel", UITheme.create_panel_stylebox(UITheme.BG_PANEL, 1))
	hbox.add_child(speed_panel)

	_speed_buttons = HBoxContainer.new()
	_speed_buttons.add_theme_constant_override("separation", 6)
	speed_panel.add_child(_speed_buttons)

	_add_speed_button("⏸", 0.0, "إيقاف مؤقت")
	_add_speed_button("▶", 1.0, "سرعة عادية")
	_add_speed_button("▶▶", 3.0, "سرعة مضاعفة")
	_add_speed_button("▶▶▶", 5.0, "سرعة قصوى")

	_update_speed_buttons(1.0)

func _add_speed_button(text: String, speed: float, tooltip: String) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(45, 35)
	btn.tooltip_text = tooltip
	btn.pressed.connect(func():
		TimeManager.set_time_scale(speed)
		_current_speed = speed
		_update_speed_buttons(speed)
	)
	btn.set_meta("speed", speed)
	UITheme.style_button(btn, UITheme.BG_LIGHT)
	_speed_buttons.add_child(btn)

func _update_speed_buttons(current_speed: float) -> void:
	for btn in _speed_buttons.get_children():
		var speed: float = btn.get_meta("speed")
		if speed == current_speed:
			var active_style := UITheme.create_button_stylebox(UITheme.ACCENT_GOLD.darkened(0.4), true)
			btn.add_theme_stylebox_override("normal", active_style)
			btn.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
		else:
			UITheme.style_button(btn, UITheme.BG_LIGHT)

func _connect_signals() -> void:
	GameManager.gold_changed.connect(func(_g): _update_display())
	GameManager.reputation_changed.connect(func(_r): _update_display())
	GameManager.day_changed.connect(func(_d): _update_display())

func _update_display() -> void:
	_gold_label.text = "%d" % GameManager.gold

	_reputation_bar.value = GameManager.reputation
	_reputation_label.text = "%d/100" % GameManager.reputation

	# Update reputation color based on value
	var rep_color := UITheme.SUCCESS
	if GameManager.reputation < 50:
		rep_color = UITheme.ERROR
	elif GameManager.reputation < 80:
		rep_color = UITheme.WARNING

	_reputation_label.add_theme_color_override("font_color", rep_color)
	UITheme.style_progress_bar(_reputation_bar, rep_color, UITheme.BG_DARK)

	_day_label.text = "📅 اليوم %d" % GameManager.current_day
