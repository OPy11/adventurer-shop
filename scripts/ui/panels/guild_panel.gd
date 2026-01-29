class_name GuildPanel
extends PanelContainer

signal mission_dialog_requested(adventurer: AdventurerData)

var _title_label: Label
var _hired_scroll: ScrollContainer
var _hired_container: HBoxContainer
var _available_scroll: ScrollContainer
var _available_container: HBoxContainer
var _missions_scroll: ScrollContainer
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
	main_vbox.add_theme_constant_override("separation", 16)
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(main_vbox)

	# Header
	_title_label = Label.new()
	_title_label.text = "نقابة المغامرين"
	UITheme.style_label(_title_label, UITheme.FONT_TITLE, UITheme.ACCENT_GOLD)
	main_vbox.add_child(_title_label)

	# Hired adventurers section
	var hired_label := Label.new()
	hired_label.text = "⚔ المغامرين الموظفين:"
	UITheme.style_label(hired_label, UITheme.FONT_BODY, UITheme.TEXT_PRIMARY)
	main_vbox.add_child(hired_label)

	_hired_scroll = ScrollContainer.new()
	_hired_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_hired_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_hired_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hired_scroll.custom_minimum_size = Vector2(0, 210)
	UITheme.style_scroll_container(_hired_scroll)
	main_vbox.add_child(_hired_scroll)

	_hired_container = HBoxContainer.new()
	_hired_container.add_theme_constant_override("separation", 15)
	_hired_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hired_scroll.add_child(_hired_container)

	# Available for hire section
	var available_label := Label.new()
	available_label.text = "👤 متاحين للتوظيف:"
	UITheme.style_label(available_label, UITheme.FONT_BODY, UITheme.TEXT_PRIMARY)
	main_vbox.add_child(available_label)

	_available_scroll = ScrollContainer.new()
	_available_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_available_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_available_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_available_scroll.custom_minimum_size = Vector2(0, 210)
	UITheme.style_scroll_container(_available_scroll)
	main_vbox.add_child(_available_scroll)

	_available_container = HBoxContainer.new()
	_available_container.add_theme_constant_override("separation", 15)
	_available_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_available_scroll.add_child(_available_container)

	# Separator
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", UITheme.create_flat_stylebox(UITheme.BORDER))
	main_vbox.add_child(sep)

	# Active missions section
	var missions_label := Label.new()
	missions_label.text = "🗺 المهمات النشطة:"
	UITheme.style_label(missions_label, UITheme.FONT_BODY, UITheme.ACCENT_GOLD)
	main_vbox.add_child(missions_label)

	_missions_scroll = ScrollContainer.new()
	_missions_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_missions_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_missions_scroll.custom_minimum_size = Vector2(0, 120)
	UITheme.style_scroll_container(_missions_scroll)
	main_vbox.add_child(_missions_scroll)

	_missions_container = VBoxContainer.new()
	_missions_container.add_theme_constant_override("separation", 8)
	_missions_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_missions_scroll.add_child(_missions_container)

func _refresh_all() -> void:
	_refresh_hired()
	_refresh_available()
	_refresh_missions()

func _refresh_hired() -> void:
	for child in _hired_container.get_children():
		child.queue_free()

	if GuildSystem.hired_adventurers.is_empty():
		var empty := Label.new()
		empty.text = "لم توظف أي مغامر بعد\nوظف مغامرين من القائمة أدناه"
		UITheme.style_label(empty, UITheme.FONT_BODY, UITheme.TEXT_MUTED)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
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
		empty.text = "لا يوجد مغامرين متاحين حالياً"
		UITheme.style_label(empty, UITheme.FONT_BODY, UITheme.TEXT_MUTED)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
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
		empty.text = "لا توجد مهمات نشطة\nأرسل مغامريك لجمع المواد من الدناجن"
		UITheme.style_label(empty, UITheme.FONT_BODY, UITheme.TEXT_MUTED)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_missions_container.add_child(empty)
		return

	for mission in missions:
		_add_mission_display(mission)

func _add_mission_display(mission: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.create_card_stylebox(UITheme.BG_DARK))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	panel.add_child(hbox)

	var adventurer: AdventurerData = mission.adventurer
	var dungeon: Dictionary = mission.dungeon

	# Portrait
	var portrait := Label.new()
	portrait.text = adventurer.portrait_char
	portrait.add_theme_font_size_override("font_size", 28)
	portrait.custom_minimum_size = Vector2(45, 45)
	portrait.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(portrait)

	# Info
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	hbox.add_child(info)

	var name_label := Label.new()
	name_label.text = "%s ➜ %s" % [adventurer.name_ar, dungeon.name_ar]
	UITheme.style_label(name_label, UITheme.FONT_BODY, UITheme.TEXT_PRIMARY)
	info.add_child(name_label)

	var success_label := Label.new()
	success_label.text = "نسبة النجاح: %d%%" % int(mission.success_rate * 100)
	UITheme.style_label(success_label, UITheme.FONT_SMALL, UITheme.TEXT_MUTED)
	info.add_child(success_label)

	# Progress section
	var progress_vbox := VBoxContainer.new()
	progress_vbox.add_theme_constant_override("separation", 4)
	progress_vbox.custom_minimum_size = Vector2(150, 0)
	hbox.add_child(progress_vbox)

	var progress_value := GuildSystem.get_mission_progress(adventurer.id)
	var progress_label := Label.new()
	progress_label.text = "%d%%" % int(progress_value)
	UITheme.style_label(progress_label, UITheme.FONT_SMALL, UITheme.INFO)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_vbox.add_child(progress_label)

	var progress := ProgressBar.new()
	progress.custom_minimum_size = Vector2(0, 16)
	progress.show_percentage = false
	progress.value = progress_value
	UITheme.style_progress_bar(progress, UITheme.INFO, UITheme.BG_MEDIUM)
	progress_vbox.add_child(progress)

	_missions_container.add_child(panel)

func _on_hire_pressed(adventurer: AdventurerData) -> void:
	GuildSystem.hire_adventurer(adventurer)

func _on_fire_pressed(adventurer: AdventurerData) -> void:
	GuildSystem.fire_adventurer(adventurer)

func _on_mission_pressed(adventurer: AdventurerData) -> void:
	mission_dialog_requested.emit(adventurer)

func refresh() -> void:
	_refresh_all()
