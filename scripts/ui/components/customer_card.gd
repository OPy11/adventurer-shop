class_name CustomerCard
extends PanelContainer

signal serve_pressed(customer: CustomerData)
signal dismiss_pressed(customer: CustomerData)

var customer: CustomerData

var _portrait_label: Label
var _name_label: Label
var _type_label: Label
var _budget_label: Label
var _mood_indicator: Label
var _wants_container: HBoxContainer
var _serve_button: Button
var _dismiss_button: Button
var _patience_bar: ProgressBar
var _tween: Tween

var _patience_timer: float = 0.0

func _ready() -> void:
	_setup_ui()

func _process(delta: float) -> void:
	if customer and customer.patience > 0:
		_patience_timer += delta / (customer.patience * 60.0)
		_patience_bar.value = 1.0 - _patience_timer

		# Update patience bar color based on remaining time
		var remaining := 1.0 - _patience_timer
		var fill := _patience_bar.get_theme_stylebox("fill") as StyleBoxFlat
		if fill:
			if remaining > 0.5:
				fill.bg_color = UITheme.SUCCESS
			elif remaining > 0.25:
				fill.bg_color = UITheme.WARNING
			else:
				fill.bg_color = UITheme.ERROR

		if _patience_timer >= 1.0:
			dismiss_pressed.emit(customer)

func _setup_ui() -> void:
	custom_minimum_size = Vector2(300, 180)

	var style := UITheme.create_card_stylebox(UITheme.BG_PANEL)
	add_theme_stylebox_override("panel", style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)
	add_child(main_vbox)

	# Top row - portrait and info
	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 12)
	main_vbox.add_child(top_hbox)

	_portrait_label = Label.new()
	_portrait_label.custom_minimum_size = Vector2(55, 55)
	_portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_portrait_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_portrait_label.add_theme_font_size_override("font_size", 38)
	top_hbox.add_child(_portrait_label)

	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 2)
	top_hbox.add_child(info_vbox)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	info_vbox.add_child(name_row)

	_name_label = Label.new()
	UITheme.style_label(_name_label, UITheme.FONT_HEADER, UITheme.TEXT_PRIMARY)
	name_row.add_child(_name_label)

	_mood_indicator = Label.new()
	_mood_indicator.add_theme_font_size_override("font_size", 18)
	name_row.add_child(_mood_indicator)

	_type_label = Label.new()
	UITheme.style_label(_type_label, UITheme.FONT_SMALL, UITheme.TEXT_SECONDARY)
	info_vbox.add_child(_type_label)

	_budget_label = Label.new()
	UITheme.style_label(_budget_label, UITheme.FONT_SMALL, UITheme.ACCENT_GOLD)
	info_vbox.add_child(_budget_label)

	# Patience bar
	_patience_bar = ProgressBar.new()
	_patience_bar.custom_minimum_size = Vector2(0, 10)
	_patience_bar.value = 1.0
	_patience_bar.show_percentage = false
	UITheme.style_progress_bar(_patience_bar, UITheme.SUCCESS, UITheme.BG_DARK)
	main_vbox.add_child(_patience_bar)

	# Wants row
	var wants_label := Label.new()
	wants_label.text = "يبحث عن:"
	UITheme.style_label(wants_label, UITheme.FONT_SMALL, UITheme.TEXT_MUTED)
	main_vbox.add_child(wants_label)

	var wants_scroll := ScrollContainer.new()
	wants_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	wants_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	wants_scroll.custom_minimum_size = Vector2(0, 35)
	main_vbox.add_child(wants_scroll)

	_wants_container = HBoxContainer.new()
	_wants_container.add_theme_constant_override("separation", 6)
	wants_scroll.add_child(_wants_container)

	# Buttons
	var btn_hbox := HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 10)
	main_vbox.add_child(btn_hbox)

	_serve_button = Button.new()
	_serve_button.text = "خدمة"
	_serve_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_serve_button.custom_minimum_size = Vector2(0, 38)
	_serve_button.pressed.connect(func(): serve_pressed.emit(customer))
	UITheme.style_button(_serve_button, UITheme.SUCCESS.darkened(0.4))
	btn_hbox.add_child(_serve_button)

	_dismiss_button = Button.new()
	_dismiss_button.text = "رفض"
	_dismiss_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dismiss_button.custom_minimum_size = Vector2(0, 38)
	_dismiss_button.pressed.connect(func(): dismiss_pressed.emit(customer))
	UITheme.style_button(_dismiss_button, UITheme.ERROR.darkened(0.4))
	btn_hbox.add_child(_dismiss_button)

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

func set_customer(c: CustomerData) -> void:
	customer = c
	_patience_timer = 0.0
	_update_display()

func _update_display() -> void:
	if not customer or not _portrait_label:
		return

	_portrait_label.text = customer.portrait_char
	_name_label.text = customer.name_ar
	_type_label.text = Enums.get_customer_type_name(customer.customer_type)
	_budget_label.text = "💰 الميزانية: %d ذهب" % customer.budget

	_update_mood_indicator()
	_update_wants_display()

func _update_mood_indicator() -> void:
	match customer.current_mood:
		Enums.CustomerMood.HAPPY:
			_mood_indicator.text = "😊"
		Enums.CustomerMood.NEUTRAL:
			_mood_indicator.text = "😐"
		Enums.CustomerMood.ANNOYED:
			_mood_indicator.text = "😠"
		Enums.CustomerMood.ANGRY:
			_mood_indicator.text = "😡"

func _update_wants_display() -> void:
	# Clear previous
	for child in _wants_container.get_children():
		child.queue_free()

	for item_id in customer.wanted_items:
		var item := DataRegistry.get_item(item_id)
		if item:
			var chip_panel := PanelContainer.new()
			var chip_style := StyleBoxFlat.new()
			chip_style.bg_color = UITheme.BG_LIGHT
			chip_style.set_corner_radius_all(4)
			chip_style.set_content_margin_all(6)
			chip_style.content_margin_top = 4
			chip_style.content_margin_bottom = 4
			chip_panel.add_theme_stylebox_override("panel", chip_style)

			var chip := Label.new()
			chip.text = "%s %s" % [item.icon_char, item.name_ar]
			UITheme.style_label(chip, UITheme.FONT_SMALL, UITheme.TEXT_PRIMARY)
			chip_panel.add_child(chip)

			_wants_container.add_child(chip_panel)
