class_name AdventurerCard
extends PanelContainer

signal hire_pressed(adventurer: AdventurerData)
signal mission_pressed(adventurer: AdventurerData)
signal fire_pressed(adventurer: AdventurerData)

var adventurer: AdventurerData
var is_hired: bool = false

var _portrait_label: Label
var _name_label: Label
var _rank_label: Label
var _stats_container: VBoxContainer
var _success_value_label: Label
var _specialty_label: Label
var _cost_label: Label
var _status_label: Label
var _action_button: Button
var _fire_button: Button
var _progress_bar: ProgressBar
var _tween: Tween

func _ready() -> void:
	_setup_ui()

func _process(_delta: float) -> void:
	if adventurer and not adventurer.is_available:
		var progress := GuildSystem.get_mission_progress(adventurer.id)
		_progress_bar.value = progress
		_progress_bar.visible = true
	else:
		_progress_bar.visible = false

func _setup_ui() -> void:
	custom_minimum_size = Vector2(260, 190)

	var style := UITheme.create_card_stylebox(UITheme.BG_PANEL)
	add_theme_stylebox_override("panel", style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)
	add_child(main_vbox)

	# Header
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	main_vbox.add_child(header)

	_portrait_label = Label.new()
	_portrait_label.custom_minimum_size = Vector2(50, 50)
	_portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_portrait_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_portrait_label.add_theme_font_size_override("font_size", 36)
	header.add_child(_portrait_label)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	header.add_child(info)

	_name_label = Label.new()
	UITheme.style_label(_name_label, UITheme.FONT_HEADER, UITheme.TEXT_PRIMARY)
	info.add_child(_name_label)

	_rank_label = Label.new()
	UITheme.style_label(_rank_label, UITheme.FONT_SMALL, UITheme.TEXT_SECONDARY)
	info.add_child(_rank_label)

	# Stats panel
	var stats_panel := PanelContainer.new()
	stats_panel.add_theme_stylebox_override("panel", UITheme.create_panel_stylebox(UITheme.BG_DARK, 1))
	main_vbox.add_child(stats_panel)

	_stats_container = VBoxContainer.new()
	_stats_container.add_theme_constant_override("separation", 4)
	stats_panel.add_child(_stats_container)

	var success_hbox := HBoxContainer.new()
	_stats_container.add_child(success_hbox)

	var success_title := Label.new()
	success_title.text = "نسبة النجاح: "
	UITheme.style_label(success_title, UITheme.FONT_SMALL, UITheme.TEXT_MUTED)
	success_hbox.add_child(success_title)

	_success_value_label = Label.new()
	UITheme.style_label(_success_value_label, UITheme.FONT_SMALL, UITheme.SUCCESS)
	success_hbox.add_child(_success_value_label)

	_specialty_label = Label.new()
	UITheme.style_label(_specialty_label, UITheme.FONT_SMALL, UITheme.TEXT_SECONDARY)
	_stats_container.add_child(_specialty_label)

	_cost_label = Label.new()
	UITheme.style_label(_cost_label, UITheme.FONT_SMALL, UITheme.ACCENT_GOLD)
	main_vbox.add_child(_cost_label)

	# Progress bar
	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(0, 12)
	_progress_bar.show_percentage = false
	_progress_bar.visible = false
	UITheme.style_progress_bar(_progress_bar, UITheme.INFO, UITheme.BG_DARK)
	main_vbox.add_child(_progress_bar)

	# Footer
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	main_vbox.add_child(footer)

	_status_label = Label.new()
	UITheme.style_label(_status_label, UITheme.FONT_BODY, UITheme.TEXT_PRIMARY)
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_status_label)

	_fire_button = Button.new()
	_fire_button.text = "إقالة"
	_fire_button.visible = false
	_fire_button.custom_minimum_size = Vector2(70, 36)
	_fire_button.pressed.connect(func(): fire_pressed.emit(adventurer))
	UITheme.style_button(_fire_button, UITheme.ERROR.darkened(0.4))
	footer.add_child(_fire_button)

	_action_button = Button.new()
	_action_button.text = "توظيف"
	_action_button.custom_minimum_size = Vector2(90, 36)
	_action_button.pressed.connect(_on_action_pressed)
	UITheme.style_button(_action_button, UITheme.SUCCESS.darkened(0.4))
	footer.add_child(_action_button)

	# Hover effect
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	var hover_style := UITheme.create_card_stylebox(UITheme.BG_HOVER)
	add_theme_stylebox_override("panel", hover_style)

func _on_mouse_exited() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	var normal_style := UITheme.create_card_stylebox(UITheme.BG_PANEL)
	add_theme_stylebox_override("panel", normal_style)

func set_adventurer(a: AdventurerData, hired: bool = false) -> void:
	adventurer = a
	is_hired = hired
	_update_display()

func _update_display() -> void:
	if not adventurer or not _portrait_label:
		return

	_portrait_label.text = adventurer.portrait_char
	_name_label.text = adventurer.name_ar

	_rank_label.text = "الرتبة: %s" % adventurer.get_rank_name()
	_rank_label.add_theme_color_override("font_color", adventurer.get_rank_color())

	if _success_value_label:
		_success_value_label.text = "%d%%" % int(adventurer.success_rate * 100)

	if adventurer.specialty:
		var dungeon := DataRegistry.get_dungeon(adventurer.specialty)
		if dungeon:
			_specialty_label.text = "⚔ تخصص: %s" % dungeon.name_ar
			_specialty_label.visible = true
	else:
		_specialty_label.visible = false

	if is_hired:
		_cost_label.visible = false
		_action_button.text = "إرسال مهمة"
		_fire_button.visible = adventurer.is_available
		_action_button.disabled = not adventurer.is_available
		UITheme.style_button(_action_button, UITheme.INFO.darkened(0.4))

		if adventurer.is_available:
			_status_label.text = "✓ متاح"
			_status_label.add_theme_color_override("font_color", UITheme.SUCCESS)
		else:
			_status_label.text = "⏳ في مهمة"
			_status_label.add_theme_color_override("font_color", UITheme.WARNING)
	else:
		_cost_label.text = "💰 تكلفة التوظيف: %d ذهب" % adventurer.hire_cost
		_cost_label.visible = true
		_action_button.text = "توظيف"
		_fire_button.visible = false
		_status_label.text = ""
		UITheme.style_button(_action_button, UITheme.SUCCESS.darkened(0.4))

func _on_action_pressed() -> void:
	if is_hired:
		mission_pressed.emit(adventurer)
	else:
		hire_pressed.emit(adventurer)
