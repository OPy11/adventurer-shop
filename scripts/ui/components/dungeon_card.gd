class_name DungeonCard
extends PanelContainer

signal selected(dungeon_id: String)

var dungeon_data: Dictionary
var adventurer: AdventurerData

var _name_label: Label
var _difficulty_label: Label
var _duration_label: Label
var _success_label: Label
var _rewards_container: HBoxContainer
var _select_button: Button

func _ready() -> void:
	_setup_ui()

func _setup_ui() -> void:
	custom_minimum_size = Vector2(220, 140)

	var style := StyleBoxFlat.new()
	style.bg_color = UITheme.BG_PANEL
	style.border_color = UITheme.BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	add_theme_stylebox_override("panel", style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 5)
	add_child(main_vbox)

	# Name
	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 16)
	_name_label.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	main_vbox.add_child(_name_label)

	# Difficulty and duration
	var info_hbox := HBoxContainer.new()
	info_hbox.add_theme_constant_override("separation", 15)
	main_vbox.add_child(info_hbox)

	_difficulty_label = Label.new()
	_difficulty_label.add_theme_font_size_override("font_size", 12)
	info_hbox.add_child(_difficulty_label)

	_duration_label = Label.new()
	_duration_label.add_theme_font_size_override("font_size", 12)
	_duration_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)
	info_hbox.add_child(_duration_label)

	# Success rate
	_success_label = Label.new()
	_success_label.add_theme_font_size_override("font_size", 12)
	main_vbox.add_child(_success_label)

	# Rewards
	var rewards_title := Label.new()
	rewards_title.text = "المكافآت المحتملة:"
	rewards_title.add_theme_font_size_override("font_size", 10)
	rewards_title.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	main_vbox.add_child(rewards_title)

	_rewards_container = HBoxContainer.new()
	_rewards_container.add_theme_constant_override("separation", 4)
	main_vbox.add_child(_rewards_container)

	# Select button
	_select_button = Button.new()
	_select_button.text = "اختيار"
	_select_button.pressed.connect(func(): selected.emit(dungeon_data.id))
	var btn_style := UITheme.create_button_stylebox(UITheme.BG_LIGHT)
	_select_button.add_theme_stylebox_override("normal", btn_style)
	main_vbox.add_child(_select_button)

func set_dungeon(data: Dictionary, adv: AdventurerData = null) -> void:
	dungeon_data = data
	adventurer = adv
	_update_display()

func _update_display() -> void:
	if dungeon_data.is_empty():
		return

	_name_label.text = dungeon_data.name_ar

	var difficulty_text := ""
	var difficulty_color := Color.WHITE
	match dungeon_data.difficulty:
		Enums.MissionDifficulty.EASY:
			difficulty_text = "سهل"
			difficulty_color = UITheme.SUCCESS
		Enums.MissionDifficulty.MEDIUM:
			difficulty_text = "متوسط"
			difficulty_color = UITheme.WARNING
		Enums.MissionDifficulty.HARD:
			difficulty_text = "صعب"
			difficulty_color = UITheme.ERROR
		Enums.MissionDifficulty.DEADLY:
			difficulty_text = "قاتل"
			difficulty_color = Color.DARK_RED

	_difficulty_label.text = difficulty_text
	_difficulty_label.add_theme_color_override("font_color", difficulty_color)

	var duration: float = dungeon_data.duration_hours
	if adventurer:
		duration = adventurer.get_mission_duration(duration)
	_duration_label.text = "المدة: %d ساعة" % int(ceil(duration))

	if adventurer:
		var success_rate := adventurer.calculate_mission_success(
			dungeon_data.difficulty,
			dungeon_data.id
		)
		_success_label.text = "نسبة النجاح: %d%%" % int(success_rate * 100)
		if success_rate >= 0.7:
			_success_label.add_theme_color_override("font_color", UITheme.SUCCESS)
		elif success_rate >= 0.4:
			_success_label.add_theme_color_override("font_color", UITheme.WARNING)
		else:
			_success_label.add_theme_color_override("font_color", UITheme.ERROR)
	else:
		_success_label.text = ""

	_update_rewards()

func _update_rewards() -> void:
	for child in _rewards_container.get_children():
		child.queue_free()

	var rewards: Dictionary = dungeon_data.get("rewards", {})
	for mat_id in rewards:
		var mat := DataRegistry.get_material(mat_id)
		if mat:
			var chip := Label.new()
			chip.text = "%s×%d" % [mat.icon_char, rewards[mat_id]]
			chip.add_theme_font_size_override("font_size", 10)
			chip.add_theme_color_override("font_color", UITheme.get_rarity_color(mat.rarity))

			var panel := PanelContainer.new()
			var style := StyleBoxFlat.new()
			style.bg_color = UITheme.BG_DARK
			style.set_corner_radius_all(3)
			style.set_content_margin_all(3)
			panel.add_theme_stylebox_override("panel", style)
			panel.add_child(chip)
			_rewards_container.add_child(panel)
