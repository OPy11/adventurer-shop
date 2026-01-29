class_name GuildPanel
extends PanelContainer

signal mission_dialog_requested(adventurer: AdventurerData)

var _title_label: Label
var _available_container: HBoxContainer
var _hired_container: HBoxContainer
var _missions_container: VBoxContainer

func _ready() -> void:
	_setup_ui()
	_refresh_all()
	GuildSystem.adventurer_hired.connect(func(_a): _refresh_all())
	GuildSystem.mission_started.connect(func(_a, _d): _refresh_all())
	GuildSystem.mission_completed.connect(func(_a, _s, _r): _refresh_all())

func _setup_ui() -> void:
	var style := UITheme.create_panel_stylebox(UITheme.BG_MEDIUM)
	add_theme_stylebox_override("panel", style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 15)
	add_child(main_vbox)

	# Header
	_title_label = Label.new()
	_title_label.text = "نقابة المغامرين"
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	main_vbox.add_child(_title_label)

	# Hired adventurers
	var hired_label := Label.new()
	hired_label.text = "المغامرين الموظفين:"
	hired_label.add_theme_font_size_override("font_size", 14)
	main_vbox.add_child(hired_label)

	var hired_scroll := ScrollContainer.new()
	hired_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hired_scroll.custom_minimum_size = Vector2(0, 170)
	main_vbox.add_child(hired_scroll)

	_hired_container = HBoxContainer.new()
	_hired_container.add_theme_constant_override("separation", 10)
	hired_scroll.add_child(_hired_container)

	# Available for hire
	var available_label := Label.new()
	available_label.text = "متاحين للتوظيف:"
	available_label.add_theme_font_size_override("font_size", 14)
	main_vbox.add_child(available_label)

	var available_scroll := ScrollContainer.new()
	available_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	available_scroll.custom_minimum_size = Vector2(0, 170)
	main_vbox.add_child(available_scroll)

	_available_container = HBoxContainer.new()
	_available_container.add_theme_constant_override("separation", 10)
	available_scroll.add_child(_available_container)

	# Active missions
	var missions_label := Label.new()
	missions_label.text = "المهمات النشطة:"
	missions_label.add_theme_font_size_override("font_size", 14)
	main_vbox.add_child(missions_label)

	_missions_container = VBoxContainer.new()
	_missions_container.add_theme_constant_override("separation", 5)
	main_vbox.add_child(_missions_container)

func _refresh_all() -> void:
	_refresh_hired()
	_refresh_available()
	_refresh_missions()

func _refresh_hired() -> void:
	for child in _hired_container.get_children():
		child.queue_free()

	if GuildSystem.hired_adventurers.is_empty():
		var empty := Label.new()
		empty.text = "لم توظف أي مغامر بعد"
		empty.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
		_hired_container.add_child(empty)
		return

	for adventurer in GuildSystem.hired_adventurers:
		var card := AdventurerCard.new()
		card.set_adventurer(adventurer, true)
		card.mission_pressed.connect(_on_mission_pressed)
		card.fire_pressed.connect(_on_fire_pressed)
		_hired_container.add_child(card)

func _refresh_available() -> void:
	for child in _available_container.get_children():
		child.queue_free()

	if GuildSystem.available_adventurers.is_empty():
		var empty := Label.new()
		empty.text = "لا يوجد مغامرين متاحين"
		empty.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
		_available_container.add_child(empty)
		return

	for adventurer in GuildSystem.available_adventurers:
		var card := AdventurerCard.new()
		card.set_adventurer(adventurer, false)
		card.hire_pressed.connect(_on_hire_pressed)
		_available_container.add_child(card)

func _refresh_missions() -> void:
	for child in _missions_container.get_children():
		child.queue_free()

	var missions := GuildSystem.get_active_missions()

	if missions.is_empty():
		var empty := Label.new()
		empty.text = "لا توجد مهمات نشطة"
		empty.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
		_missions_container.add_child(empty)
		return

	for mission in missions:
		_add_mission_display(mission)

func _add_mission_display(mission: Dictionary) -> void:
	var panel := PanelContainer.new()
	var style := UITheme.create_panel_stylebox(UITheme.BG_DARK, 1)
	panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	panel.add_child(hbox)

	var adventurer: AdventurerData = mission.adventurer
	var dungeon: Dictionary = mission.dungeon

	# Portrait
	var portrait := Label.new()
	portrait.text = adventurer.portrait_char
	portrait.add_theme_font_size_override("font_size", 24)
	hbox.add_child(portrait)

	# Info
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)

	var name_label := Label.new()
	name_label.text = "%s -> %s" % [adventurer.name_ar, dungeon.name_ar]
	name_label.add_theme_font_size_override("font_size", 12)
	info.add_child(name_label)

	var success_label := Label.new()
	success_label.text = "نسبة النجاح: %d%%" % int(mission.success_rate * 100)
	success_label.add_theme_font_size_override("font_size", 10)
	success_label.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	info.add_child(success_label)

	# Progress
	var progress := ProgressBar.new()
	progress.custom_minimum_size = Vector2(120, 15)
	progress.show_percentage = true
	progress.value = GuildSystem.get_mission_progress(adventurer.id)
	_style_progress_bar(progress)
	hbox.add_child(progress)

	_missions_container.add_child(panel)

func _style_progress_bar(bar: ProgressBar) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = UITheme.BG_MEDIUM
	bg.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg)

	var fill := StyleBoxFlat.new()
	fill.bg_color = UITheme.INFO
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)

func _on_hire_pressed(adventurer: AdventurerData) -> void:
	GuildSystem.hire_adventurer(adventurer)

func _on_fire_pressed(adventurer: AdventurerData) -> void:
	GuildSystem.fire_adventurer(adventurer)

func _on_mission_pressed(adventurer: AdventurerData) -> void:
	mission_dialog_requested.emit(adventurer)

func refresh() -> void:
	_refresh_all()
