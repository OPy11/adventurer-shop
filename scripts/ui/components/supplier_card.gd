class_name SupplierCard
extends PanelContainer

signal order_pressed(supplier: SupplierData)

var supplier: SupplierData

var _portrait_label: Label
var _name_label: Label
var _type_label: Label
var _quality_label: Label
var _mastery_bar: ProgressBar
var _cost_label: Label
var _status_label: Label
var _order_button: Button
var _progress_bar: ProgressBar

func _ready() -> void:
	_setup_ui()

func _process(_delta: float) -> void:
	if supplier and not supplier.is_available:
		var progress := SupplierSystem.get_order_progress(supplier.id)
		_progress_bar.value = progress
		_progress_bar.visible = true
	else:
		_progress_bar.visible = false

func _setup_ui() -> void:
	custom_minimum_size = Vector2(260, 160)

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

	# Header
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	main_vbox.add_child(header)

	_portrait_label = Label.new()
	_portrait_label.custom_minimum_size = Vector2(45, 45)
	_portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_portrait_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_portrait_label.add_theme_font_size_override("font_size", 32)
	header.add_child(_portrait_label)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(info)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 15)
	_name_label.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	info.add_child(_name_label)

	_type_label = Label.new()
	_type_label.add_theme_font_size_override("font_size", 11)
	_type_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)
	info.add_child(_type_label)

	# Quality and mastery
	var stats_hbox := HBoxContainer.new()
	stats_hbox.add_theme_constant_override("separation", 15)
	main_vbox.add_child(stats_hbox)

	var quality_vbox := VBoxContainer.new()
	stats_hbox.add_child(quality_vbox)

	var quality_title := Label.new()
	quality_title.text = "الجودة"
	quality_title.add_theme_font_size_override("font_size", 10)
	quality_title.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	quality_vbox.add_child(quality_title)

	_quality_label = Label.new()
	_quality_label.add_theme_font_size_override("font_size", 12)
	quality_vbox.add_child(_quality_label)

	var mastery_vbox := VBoxContainer.new()
	mastery_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_hbox.add_child(mastery_vbox)

	var mastery_title := Label.new()
	mastery_title.text = "الإتقان"
	mastery_title.add_theme_font_size_override("font_size", 10)
	mastery_title.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	mastery_vbox.add_child(mastery_title)

	_mastery_bar = ProgressBar.new()
	_mastery_bar.custom_minimum_size = Vector2(80, 12)
	_mastery_bar.show_percentage = false
	_style_progress_bar(_mastery_bar, UITheme.ACCENT_GOLD)
	mastery_vbox.add_child(_mastery_bar)

	# Cost
	_cost_label = Label.new()
	_cost_label.add_theme_font_size_override("font_size", 12)
	_cost_label.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	main_vbox.add_child(_cost_label)

	# Progress bar (hidden by default)
	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(0, 10)
	_progress_bar.show_percentage = false
	_progress_bar.visible = false
	_style_progress_bar(_progress_bar, UITheme.SUCCESS)
	main_vbox.add_child(_progress_bar)

	# Status and button
	var footer := HBoxContainer.new()
	main_vbox.add_child(footer)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_status_label)

	_order_button = Button.new()
	_order_button.text = "طلب تصنيع"
	_order_button.pressed.connect(func(): order_pressed.emit(supplier))
	var btn_style := UITheme.create_button_stylebox(UITheme.BG_LIGHT)
	_order_button.add_theme_stylebox_override("normal", btn_style)
	footer.add_child(_order_button)

func _style_progress_bar(bar: ProgressBar, fill_color: Color) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = UITheme.BG_DARK
	bg.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg)

	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)

func set_supplier(s: SupplierData) -> void:
	supplier = s
	_update_display()

func _update_display() -> void:
	if not supplier:
		return

	_portrait_label.text = supplier.portrait_char
	_name_label.text = supplier.name_ar
	_type_label.text = supplier.get_type_name()

	_quality_label.text = Enums.get_quality_name(supplier.quality_level)
	_quality_label.add_theme_color_override("font_color", UITheme.get_quality_color(supplier.quality_level))

	_mastery_bar.value = supplier.mastery

	_cost_label.text = "رسوم التعاقد: %d ذهب" % supplier.contract_cost

	if supplier.is_available:
		_status_label.text = "متاح"
		_status_label.add_theme_color_override("font_color", UITheme.SUCCESS)
		_order_button.disabled = false
	else:
		_status_label.text = "مشغول"
		_status_label.add_theme_color_override("font_color", UITheme.WARNING)
		_order_button.disabled = true
