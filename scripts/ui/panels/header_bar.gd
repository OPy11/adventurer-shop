class_name HeaderBar
extends PanelContainer

var _shop_name: Label
var _gold_label: Label
var _reputation_bar: ProgressBar
var _reputation_label: Label
var _day_label: Label
var _time_label: Label
var _speed_buttons: HBoxContainer

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_update_display()

func _process(_delta: float) -> void:
	_time_label.text = TimeManager.get_formatted_time() + " " + TimeManager.get_time_of_day_arabic()

func _setup_ui() -> void:
	custom_minimum_size = Vector2(0, 60)

	var style := StyleBoxFlat.new()
	style.bg_color = UITheme.BG_DARK
	style.border_color = UITheme.ACCENT_GOLD.darkened(0.5)
	style.border_width_bottom = 2
	style.set_content_margin_all(10)
	add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 30)
	add_child(hbox)

	# Shop name
	_shop_name = Label.new()
	_shop_name.text = GameManager.shop_name
	_shop_name.add_theme_font_size_override("font_size", 22)
	_shop_name.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	hbox.add_child(_shop_name)

	# Gold
	var gold_container := HBoxContainer.new()
	gold_container.add_theme_constant_override("separation", 5)
	hbox.add_child(gold_container)

	var gold_icon := Label.new()
	gold_icon.text = "💰"
	gold_icon.add_theme_font_size_override("font_size", 18)
	gold_container.add_child(gold_icon)

	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 18)
	_gold_label.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	gold_container.add_child(_gold_label)

	# Reputation
	var rep_container := VBoxContainer.new()
	hbox.add_child(rep_container)

	var rep_header := HBoxContainer.new()
	rep_container.add_child(rep_header)

	var rep_title := Label.new()
	rep_title.text = "السمعة: "
	rep_title.add_theme_font_size_override("font_size", 12)
	rep_title.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	rep_header.add_child(rep_title)

	_reputation_label = Label.new()
	_reputation_label.add_theme_font_size_override("font_size", 12)
	rep_header.add_child(_reputation_label)

	_reputation_bar = ProgressBar.new()
	_reputation_bar.custom_minimum_size = Vector2(100, 10)
	_reputation_bar.max_value = 100
	_reputation_bar.show_percentage = false
	_style_reputation_bar()
	rep_container.add_child(_reputation_bar)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	# Day and time
	var time_container := VBoxContainer.new()
	hbox.add_child(time_container)

	_day_label = Label.new()
	_day_label.add_theme_font_size_override("font_size", 14)
	_day_label.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	_day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_container.add_child(_day_label)

	_time_label = Label.new()
	_time_label.add_theme_font_size_override("font_size", 12)
	_time_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_container.add_child(_time_label)

	# Speed controls
	_speed_buttons = HBoxContainer.new()
	_speed_buttons.add_theme_constant_override("separation", 5)
	hbox.add_child(_speed_buttons)

	_add_speed_button("⏸", 0.0)
	_add_speed_button("▶", 1.0)
	_add_speed_button("▶▶", 3.0)
	_add_speed_button("▶▶▶", 5.0)

func _add_speed_button(text: String, speed: float) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(40, 30)
	btn.pressed.connect(func(): TimeManager.set_time_scale(speed); _update_speed_buttons(speed))

	var style := UITheme.create_button_stylebox(UITheme.BG_LIGHT)
	btn.add_theme_stylebox_override("normal", style)
	btn.set_meta("speed", speed)

	_speed_buttons.add_child(btn)

func _update_speed_buttons(current_speed: float) -> void:
	for btn in _speed_buttons.get_children():
		var speed: float = btn.get_meta("speed")
		var style: StyleBoxFlat
		if speed == current_speed:
			style = UITheme.create_button_stylebox(UITheme.ACCENT_GOLD.darkened(0.5), true)
		else:
			style = UITheme.create_button_stylebox(UITheme.BG_LIGHT)
		btn.add_theme_stylebox_override("normal", style)

func _style_reputation_bar() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = UITheme.BG_PANEL
	bg.set_corner_radius_all(5)
	_reputation_bar.add_theme_stylebox_override("background", bg)

	var fill := StyleBoxFlat.new()
	fill.bg_color = UITheme.SUCCESS
	fill.set_corner_radius_all(5)
	_reputation_bar.add_theme_stylebox_override("fill", fill)

func _connect_signals() -> void:
	GameManager.gold_changed.connect(func(_g): _update_display())
	GameManager.reputation_changed.connect(func(_r): _update_display())
	GameManager.day_changed.connect(func(_d): _update_display())

func _update_display() -> void:
	_gold_label.text = "%d" % GameManager.gold
	_reputation_bar.value = GameManager.reputation
	_reputation_label.text = "%d/100" % GameManager.reputation

	if GameManager.reputation >= 80:
		_reputation_label.add_theme_color_override("font_color", UITheme.SUCCESS)
	elif GameManager.reputation >= 50:
		_reputation_label.add_theme_color_override("font_color", UITheme.WARNING)
	else:
		_reputation_label.add_theme_color_override("font_color", UITheme.ERROR)

	_day_label.text = "اليوم %d" % GameManager.current_day
