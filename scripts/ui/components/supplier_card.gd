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
var _tween: Tween

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
	custom_minimum_size = Vector2(280, 200)

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

	_type_label = Label.new()
	UITheme.style_label(_type_label, UITheme.FONT_SMALL, UITheme.TEXT_SECONDARY)
	info.add_child(_type_label)

	# Quality and mastery section
	var stats_panel := PanelContainer.new()
	stats_panel.add_theme_stylebox_override("panel", UITheme.create_panel_stylebox(UITheme.BG_DARK, 1))
	main_vbox.add_child(stats_panel)

	var stats_hbox := HBoxContainer.new()
	stats_hbox.add_theme_constant_override("separation", 20)
	stats_panel.add_child(stats_hbox)

	var quality_vbox := VBoxContainer.new()
	quality_vbox.add_theme_constant_override("separation", 2)
	stats_hbox.add_child(quality_vbox)

	var quality_title := Label.new()
	quality_title.text = "الجودة"
	UITheme.style_label(quality_title, UITheme.FONT_TINY, UITheme.TEXT_MUTED)
	quality_vbox.add_child(quality_title)

	_quality_label = Label.new()
	UITheme.style_label(_quality_label, UITheme.FONT_SMALL, UITheme.TEXT_PRIMARY)
	quality_vbox.add_child(_quality_label)

	var mastery_vbox := VBoxContainer.new()
	mastery_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mastery_vbox.add_theme_constant_override("separation", 2)
	stats_hbox.add_child(mastery_vbox)

	var mastery_title := Label.new()
	mastery_title.text = "الإتقان"
	UITheme.style_label(mastery_title, UITheme.FONT_TINY, UITheme.TEXT_MUTED)
	mastery_vbox.add_child(mastery_title)

	_mastery_bar = ProgressBar.new()
	_mastery_bar.custom_minimum_size = Vector2(100, 14)
	_mastery_bar.show_percentage = false
	UITheme.style_progress_bar(_mastery_bar, UITheme.ACCENT_GOLD, UITheme.BG_MEDIUM)
	mastery_vbox.add_child(_mastery_bar)

	# Cost
	_cost_label = Label.new()
	UITheme.style_label(_cost_label, UITheme.FONT_SMALL, UITheme.ACCENT_GOLD)
	main_vbox.add_child(_cost_label)

	# Progress bar (hidden by default)
	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(0, 12)
	_progress_bar.show_percentage = false
	_progress_bar.visible = false
	UITheme.style_progress_bar(_progress_bar, UITheme.SUCCESS, UITheme.BG_DARK)
	main_vbox.add_child(_progress_bar)

	# Status and button
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	main_vbox.add_child(footer)

	_status_label = Label.new()
	UITheme.style_label(_status_label, UITheme.FONT_BODY, UITheme.TEXT_PRIMARY)
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_status_label)

	_order_button = Button.new()
	_order_button.text = "طلب تصنيع"
	_order_button.custom_minimum_size = Vector2(100, 38)
	_order_button.pressed.connect(func(): order_pressed.emit(supplier))
	UITheme.style_button(_order_button, UITheme.INFO.darkened(0.4))
	footer.add_child(_order_button)

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

func set_supplier(s: SupplierData) -> void:
	supplier = s
	_update_display()

func _update_display() -> void:
	if not supplier or not _portrait_label:
		return

	_portrait_label.text = supplier.portrait_char
	_name_label.text = supplier.name_ar
	_type_label.text = supplier.get_type_name()

	_quality_label.text = Enums.get_quality_name(supplier.quality_level)
	_quality_label.add_theme_color_override("font_color", UITheme.get_quality_color(supplier.quality_level))

	_mastery_bar.value = supplier.mastery

	_cost_label.text = "💰 رسوم التعاقد: %d ذهب" % supplier.contract_cost

	if supplier.is_available:
		_status_label.text = "✓ متاح"
		_status_label.add_theme_color_override("font_color", UITheme.SUCCESS)
		_order_button.disabled = false
	else:
		_status_label.text = "⏳ مشغول"
		_status_label.add_theme_color_override("font_color", UITheme.WARNING)
		_order_button.disabled = true
