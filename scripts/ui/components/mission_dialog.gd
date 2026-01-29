class_name MissionDialog
extends PanelContainer

signal mission_started(adventurer: AdventurerData, dungeon_id: String)
signal cancelled

var adventurer: AdventurerData

var _title_label: Label
var _adventurer_info: VBoxContainer
var _dungeons_container: VBoxContainer
var _cancel_button: Button

func _ready() -> void:
	_setup_ui()
	_populate_dungeons()

func _setup_ui() -> void:
	custom_minimum_size = Vector2(500, 450)

	var style := StyleBoxFlat.new()
	style.bg_color = UITheme.BG_MEDIUM
	style.border_color = UITheme.ACCENT_GOLD
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(20)
	add_theme_stylebox_override("panel", style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 15)
	add_child(main_vbox)

	# Title
	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(_title_label)

	# Adventurer info
	_adventurer_info = VBoxContainer.new()
	main_vbox.add_child(_adventurer_info)

	# Dungeons label
	var dungeons_label := Label.new()
	dungeons_label.text = "اختر الدنجن:"
	dungeons_label.add_theme_font_size_override("font_size", 14)
	main_vbox.add_child(dungeons_label)

	# Dungeons scroll
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 250)
	main_vbox.add_child(scroll)

	var scroll_content := VBoxContainer.new()
	scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(scroll_content)

	_dungeons_container = VBoxContainer.new()
	_dungeons_container.add_theme_constant_override("separation", 10)
	scroll_content.add_child(_dungeons_container)

	# Cancel button
	_cancel_button = Button.new()
	_cancel_button.text = "إلغاء"
	_cancel_button.pressed.connect(func(): cancelled.emit(); queue_free())
	var btn_style := UITheme.create_button_stylebox(UITheme.BG_LIGHT)
	_cancel_button.add_theme_stylebox_override("normal", btn_style)
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
	var style := UITheme.create_panel_stylebox(UITheme.BG_DARK)
	panel.add_theme_stylebox_override("panel", style)
	_adventurer_info.add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	panel.add_child(hbox)

	var portrait := Label.new()
	portrait.text = adventurer.portrait_char
	portrait.add_theme_font_size_override("font_size", 36)
	hbox.add_child(portrait)

	var info := VBoxContainer.new()
	hbox.add_child(info)

	var name_label := Label.new()
	name_label.text = adventurer.name_ar
	name_label.add_theme_font_size_override("font_size", 16)
	info.add_child(name_label)

	var rank_label := Label.new()
	rank_label.text = "الرتبة: %s" % adventurer.get_rank_name()
	rank_label.add_theme_font_size_override("font_size", 12)
	rank_label.add_theme_color_override("font_color", adventurer.get_rank_color())
	info.add_child(rank_label)

	var success_label := Label.new()
	success_label.text = "نسبة النجاح الأساسية: %d%%" % int(adventurer.success_rate * 100)
	success_label.add_theme_font_size_override("font_size", 11)
	success_label.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	info.add_child(success_label)

func _populate_dungeons() -> void:
	if not _dungeons_container or not adventurer:
		return

	for child in _dungeons_container.get_children():
		child.queue_free()

	var dungeons := GuildSystem.get_available_dungeons()

	for dungeon in dungeons:
		var card := DungeonCard.new()
		card.set_dungeon(dungeon, adventurer)
		card.selected.connect(_on_dungeon_selected)

		# Check if adventurer can go
		var check := GuildSystem.can_start_mission(adventurer, dungeon.id)
		if not check.can_start:
			card.modulate = Color(0.5, 0.5, 0.5)
			card.tooltip_text = check.reason

		_dungeons_container.add_child(card)

func _on_dungeon_selected(dungeon_id: String) -> void:
	if GuildSystem.start_mission(adventurer, dungeon_id):
		mission_started.emit(adventurer, dungeon_id)
		queue_free()
