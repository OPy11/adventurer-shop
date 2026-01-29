class_name MissionDialog
extends PanelContainer

signal mission_started(adventurer: AdventurerData, dungeon_id: String)
signal cancelled

var adventurer: AdventurerData

var _title_label: Label
var _adventurer_info: VBoxContainer
var _scroll_container: ScrollContainer
var _dungeons_container: VBoxContainer
var _cancel_button: Button

func _ready() -> void:
	_setup_ui()
	_populate_dungeons()

func _setup_ui() -> void:
	custom_minimum_size = Vector2(650, 600)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var style := UITheme.create_dialog_stylebox()
	add_theme_stylebox_override("panel", style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 16)
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(main_vbox)

	# Title
	_title_label = UITheme.create_title_label("إرسال في مهمة")
	main_vbox.add_child(_title_label)

	# Separator
	var sep1 := HSeparator.new()
	sep1.add_theme_stylebox_override("separator", UITheme.create_flat_stylebox(UITheme.BORDER))
	main_vbox.add_child(sep1)

	# Adventurer info
	_adventurer_info = VBoxContainer.new()
	main_vbox.add_child(_adventurer_info)

	# Dungeons label
	var dungeons_label := Label.new()
	dungeons_label.text = "اختر الدنجن:"
	UITheme.style_label(dungeons_label, UITheme.FONT_BODY, UITheme.ACCENT_GOLD)
	main_vbox.add_child(dungeons_label)

	# Dungeons scroll
	_scroll_container = ScrollContainer.new()
	_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_container.custom_minimum_size = Vector2(0, 300)
	_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UITheme.style_scroll_container(_scroll_container)
	main_vbox.add_child(_scroll_container)

	_dungeons_container = VBoxContainer.new()
	_dungeons_container.add_theme_constant_override("separation", 12)
	_dungeons_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_container.add_child(_dungeons_container)

	# Separator
	var sep2 := HSeparator.new()
	sep2.add_theme_stylebox_override("separator", UITheme.create_flat_stylebox(UITheme.BORDER))
	main_vbox.add_child(sep2)

	# Cancel button
	_cancel_button = Button.new()
	_cancel_button.text = "إلغاء"
	_cancel_button.custom_minimum_size = Vector2(0, 45)
	_cancel_button.pressed.connect(func(): cancelled.emit(); queue_free())
	UITheme.style_button(_cancel_button, UITheme.BG_LIGHT)
	main_vbox.add_child(_cancel_button)

func set_adventurer(adv: AdventurerData) -> void:
	adventurer = adv
	if _title_label:
		_title_label.text = "إرسال %s في مهمة" % adventurer.name_ar
	_update_adventurer_info()
	_populate_dungeons()

func _update_adventurer_info() -> void:
	if not adventurer or not _adventurer_info:
		return

	for child in _adventurer_info.get_children():
		child.queue_free()

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.create_panel_stylebox(UITheme.BG_DARK, 1))
	_adventurer_info.add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	panel.add_child(hbox)

	var portrait := Label.new()
	portrait.text = adventurer.portrait_char
	portrait.add_theme_font_size_override("font_size", 40)
	portrait.custom_minimum_size = Vector2(50, 50)
	portrait.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(portrait)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	hbox.add_child(info)

	var name_label := Label.new()
	name_label.text = adventurer.name_ar
	UITheme.style_label(name_label, UITheme.FONT_HEADER, UITheme.TEXT_PRIMARY)
	info.add_child(name_label)

	var rank_label := Label.new()
	rank_label.text = "الرتبة: %s" % adventurer.get_rank_name()
	UITheme.style_label(rank_label, UITheme.FONT_BODY, adventurer.get_rank_color())
	info.add_child(rank_label)

	var success_label := Label.new()
	success_label.text = "نسبة النجاح الأساسية: %d%%" % int(adventurer.success_rate * 100)
	UITheme.style_label(success_label, UITheme.FONT_SMALL, UITheme.TEXT_MUTED)
	info.add_child(success_label)

func _populate_dungeons() -> void:
	if not _dungeons_container or not adventurer:
		return

	for child in _dungeons_container.get_children():
		child.queue_free()

	var dungeons := GuildSystem.get_available_dungeons()

	if dungeons.is_empty():
		var empty := Label.new()
		empty.text = "لا توجد مغامرات متاحة"
		UITheme.style_label(empty, UITheme.FONT_BODY, UITheme.TEXT_MUTED)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_dungeons_container.add_child(empty)
		return

	for dungeon in dungeons:
		var card := DungeonCard.new()
		card.set_dungeon(dungeon, adventurer)
		card.selected.connect(_on_dungeon_selected)

		# Check if adventurer can go
		var check := GuildSystem.can_start_mission(adventurer, dungeon.id)
		if not check.can_start:
			card.modulate = Color(0.6, 0.6, 0.6)
			card.tooltip_text = check.reason

		_dungeons_container.add_child(card)

func _on_dungeon_selected(dungeon_id: String) -> void:
	if GuildSystem.start_mission(adventurer, dungeon_id):
		mission_started.emit(adventurer, dungeon_id)
		queue_free()
