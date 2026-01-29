class_name DungeonCard
extends PanelContainer

signal selected(dungeon_id: String)

var dungeon_data: Dictionary
var adventurer: AdventurerData
var _tween: Tween

var _name_label: Label
var _difficulty_label: Label
var _duration_label: Label
var _success_label: Label
var _rewards_container: HBoxContainer
var _select_button: Button

func _ready() -> void:
	_setup_ui()

func _setup_ui() -> void:
	custom_minimum_size = Vector2(0, 160)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := UITheme.create_card_stylebox(UITheme.BG_PANEL)
	add_theme_stylebox_override("panel", style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)
	add_child(main_vbox)

	# Header with name and difficulty
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 15)
	main_vbox.add_child(header)

	_name_label = Label.new()
	UITheme.style_label(_name_label, UITheme.FONT_HEADER, UITheme.TEXT_PRIMARY)
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_name_label)

	_difficulty_label = Label.new()
	UITheme.style_label(_difficulty_label, UITheme.FONT_BODY, UITheme.TEXT_PRIMARY)
	header.add_child(_difficulty_label)

	# Info panel
	var info_panel := PanelContainer.new()
	info_panel.add_theme_stylebox_override("panel", UITheme.create_panel_stylebox(UITheme.BG_DARK, 1))
	main_vbox.add_child(info_panel)

	var info_hbox := HBoxContainer.new()
	info_hbox.add_theme_constant_override("separation", 20)
	info_panel.add_child(info_hbox)

	# Duration
	var duration_vbox := VBoxContainer.new()
	duration_vbox.add_theme_constant_override("separation", 2)
	info_hbox.add_child(duration_vbox)

	var duration_title := Label.new()
	duration_title.text = "المدة"
	UITheme.style_label(duration_title, UITheme.FONT_TINY, UITheme.TEXT_MUTED)
	duration_vbox.add_child(duration_title)

	_duration_label = Label.new()
	UITheme.style_label(_duration_label, UITheme.FONT_BODY, UITheme.TEXT_PRIMARY)
	duration_vbox.add_child(_duration_label)

	# Success rate
	var success_vbox := VBoxContainer.new()
	success_vbox.add_theme_constant_override("separation", 2)
	info_hbox.add_child(success_vbox)

	var success_title := Label.new()
	success_title.text = "نسبة النجاح"
	UITheme.style_label(success_title, UITheme.FONT_TINY, UITheme.TEXT_MUTED)
	success_vbox.add_child(success_title)

	_success_label = Label.new()
	UITheme.style_label(_success_label, UITheme.FONT_BODY, UITheme.SUCCESS)
	success_vbox.add_child(_success_label)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_hbox.add_child(spacer)

	# Rewards section
	var rewards_vbox := VBoxContainer.new()
	rewards_vbox.add_theme_constant_override("separation", 4)
	main_vbox.add_child(rewards_vbox)

	var rewards_title := Label.new()
	rewards_title.text = "المكافآت المحتملة:"
	UITheme.style_label(rewards_title, UITheme.FONT_SMALL, UITheme.TEXT_MUTED)
	rewards_vbox.add_child(rewards_title)

	_rewards_container = HBoxContainer.new()
	_rewards_container.add_theme_constant_override("separation", 6)
	rewards_vbox.add_child(_rewards_container)

	# Select button
	_select_button = Button.new()
	_select_button.text = "اختيار هذا الدنجن"
	_select_button.custom_minimum_size = Vector2(0, 40)
	_select_button.pressed.connect(func(): selected.emit(dungeon_data.id))
	UITheme.style_button(_select_button, UITheme.INFO.darkened(0.4))
	main_vbox.add_child(_select_button)

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

func set_dungeon(data: Dictionary, adv: AdventurerData = null) -> void:
	dungeon_data = data
	adventurer = adv
	_update_display()

func _update_display() -> void:
	if dungeon_data.is_empty() or not _name_label:
		return

	_name_label.text = dungeon_data.name_ar

	var difficulty_text := ""
	var difficulty_color := Color.WHITE
	match dungeon_data.difficulty:
		Enums.MissionDifficulty.EASY:
			difficulty_text = "⭐ سهل"
			difficulty_color = UITheme.SUCCESS
		Enums.MissionDifficulty.MEDIUM:
			difficulty_text = "⭐⭐ متوسط"
			difficulty_color = UITheme.WARNING
		Enums.MissionDifficulty.HARD:
			difficulty_text = "⭐⭐⭐ صعب"
			difficulty_color = UITheme.ERROR
		Enums.MissionDifficulty.DEADLY:
			difficulty_text = "💀 قاتل"
			difficulty_color = Color.DARK_RED

	_difficulty_label.text = difficulty_text
	_difficulty_label.add_theme_color_override("font_color", difficulty_color)

	var duration: float = dungeon_data.duration_hours
	if adventurer:
		duration = adventurer.get_mission_duration(duration)
	_duration_label.text = "%d ساعة" % int(ceil(duration))

	if adventurer:
		var success_rate := adventurer.calculate_mission_success(
			dungeon_data.difficulty,
			dungeon_data.id
		)
		_success_label.text = "%d%%" % int(success_rate * 100)
		if success_rate >= 0.7:
			_success_label.add_theme_color_override("font_color", UITheme.SUCCESS)
		elif success_rate >= 0.4:
			_success_label.add_theme_color_override("font_color", UITheme.WARNING)
		else:
			_success_label.add_theme_color_override("font_color", UITheme.ERROR)
	else:
		_success_label.text = "—"

	_update_rewards()

func _update_rewards() -> void:
	for child in _rewards_container.get_children():
		child.queue_free()

	var rewards: Dictionary = dungeon_data.get("rewards", {})
	for mat_id in rewards:
		var mat := DataRegistry.get_material(mat_id)
		if mat:
			var panel := PanelContainer.new()
			var style := StyleBoxFlat.new()
			style.bg_color = UITheme.BG_DARK
			style.set_corner_radius_all(4)
			style.set_content_margin_all(6)
			style.content_margin_top = 4
			style.content_margin_bottom = 4
			panel.add_theme_stylebox_override("panel", style)

			var chip := Label.new()
			chip.text = "%s ×%d" % [mat.icon_char, rewards[mat_id]]
			UITheme.style_label(chip, UITheme.FONT_SMALL, UITheme.get_rarity_color(mat.rarity))
			panel.add_child(chip)

			_rewards_container.add_child(panel)
