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
		if _patience_timer >= 1.0:
			dismiss_pressed.emit(customer)

func _setup_ui() -> void:
	custom_minimum_size = Vector2(280, 140)

	var style := StyleBoxFlat.new()
	style.bg_color = UITheme.BG_PANEL
	style.border_color = UITheme.BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	add_theme_stylebox_override("panel", style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 6)
	add_child(main_vbox)

	# Top row - portrait and info
	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 10)
	main_vbox.add_child(top_hbox)

	_portrait_label = Label.new()
	_portrait_label.custom_minimum_size = Vector2(50, 50)
	_portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_portrait_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_portrait_label.add_theme_font_size_override("font_size", 36)
	top_hbox.add_child(_portrait_label)

	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(info_vbox)

	var name_row := HBoxContainer.new()
	info_vbox.add_child(name_row)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 16)
	_name_label.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	name_row.add_child(_name_label)

	_mood_indicator = Label.new()
	_mood_indicator.add_theme_font_size_override("font_size", 16)
	name_row.add_child(_mood_indicator)

	_type_label = Label.new()
	_type_label.add_theme_font_size_override("font_size", 12)
	_type_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)
	info_vbox.add_child(_type_label)

	_budget_label = Label.new()
	_budget_label.add_theme_font_size_override("font_size", 12)
	_budget_label.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	info_vbox.add_child(_budget_label)

	# Patience bar
	_patience_bar = ProgressBar.new()
	_patience_bar.custom_minimum_size = Vector2(0, 8)
	_patience_bar.value = 1.0
	_patience_bar.show_percentage = false
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = UITheme.BG_DARK
	bar_style.set_corner_radius_all(4)
	_patience_bar.add_theme_stylebox_override("background", bar_style)
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = UITheme.SUCCESS
	fill_style.set_corner_radius_all(4)
	_patience_bar.add_theme_stylebox_override("fill", fill_style)
	main_vbox.add_child(_patience_bar)

	# Wants row
	var wants_label := Label.new()
	wants_label.text = "يبحث عن:"
	wants_label.add_theme_font_size_override("font_size", 11)
	wants_label.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	main_vbox.add_child(wants_label)

	_wants_container = HBoxContainer.new()
	_wants_container.add_theme_constant_override("separation", 4)
	main_vbox.add_child(_wants_container)

	# Buttons
	var btn_hbox := HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 8)
	main_vbox.add_child(btn_hbox)

	_serve_button = Button.new()
	_serve_button.text = "خدمة"
	_serve_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_serve_button.pressed.connect(func(): serve_pressed.emit(customer))
	btn_hbox.add_child(_serve_button)

	_dismiss_button = Button.new()
	_dismiss_button.text = "رفض"
	_dismiss_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dismiss_button.pressed.connect(func(): dismiss_pressed.emit(customer))
	btn_hbox.add_child(_dismiss_button)

	_style_buttons()

func _style_buttons() -> void:
	var serve_style := UITheme.create_button_stylebox(UITheme.SUCCESS.darkened(0.5))
	_serve_button.add_theme_stylebox_override("normal", serve_style)

	var dismiss_style := UITheme.create_button_stylebox(UITheme.ERROR.darkened(0.5))
	_dismiss_button.add_theme_stylebox_override("normal", dismiss_style)

func set_customer(c: CustomerData) -> void:
	customer = c
	_patience_timer = 0.0
	_update_display()

func _update_display() -> void:
	if not customer:
		return

	_portrait_label.text = customer.portrait_char
	_name_label.text = customer.name_ar
	_type_label.text = Enums.get_customer_type_name(customer.customer_type)
	_budget_label.text = "الميزانية: %d ذهب" % customer.budget

	_update_mood_indicator()
	_update_wants_display()

func _update_mood_indicator() -> void:
	match customer.current_mood:
		Enums.CustomerMood.HAPPY:
			_mood_indicator.text = " 😊"
		Enums.CustomerMood.NEUTRAL:
			_mood_indicator.text = " 😐"
		Enums.CustomerMood.ANNOYED:
			_mood_indicator.text = " 😠"
		Enums.CustomerMood.ANGRY:
			_mood_indicator.text = " 😡"

func _update_wants_display() -> void:
	# Clear previous
	for child in _wants_container.get_children():
		child.queue_free()

	for item_id in customer.wanted_items:
		var item := DataRegistry.get_item(item_id)
		if item:
			var chip := Label.new()
			chip.text = item.icon_char + " " + item.name_ar
			chip.add_theme_font_size_override("font_size", 10)

			var chip_panel := PanelContainer.new()
			var chip_style := StyleBoxFlat.new()
			chip_style.bg_color = UITheme.BG_LIGHT
			chip_style.set_corner_radius_all(4)
			chip_style.set_content_margin_all(4)
			chip_panel.add_theme_stylebox_override("panel", chip_style)
			chip_panel.add_child(chip)
			_wants_container.add_child(chip_panel)
