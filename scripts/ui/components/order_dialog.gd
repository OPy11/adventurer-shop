class_name OrderDialog
extends PanelContainer

signal order_confirmed(item: ItemData, quantity: int, supplier: SupplierData)
signal cancelled

var supplier: SupplierData
var selected_item: ItemData
var quantity: int = 1

var _title_label: Label
var _item_list: ItemList
var _quantity_spin: SpinBox
var _cost_breakdown: VBoxContainer
var _materials_check: Label
var _confirm_button: Button
var _cancel_button: Button

func _ready() -> void:
	_setup_ui()
	_populate_items()

func _setup_ui() -> void:
	custom_minimum_size = Vector2(600, 650)
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
	_title_label = Label.new()
	UITheme.style_label(_title_label, UITheme.FONT_TITLE, UITheme.ACCENT_GOLD)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(_title_label)

	# Separator
	var sep1 := HSeparator.new()
	sep1.add_theme_stylebox_override("separator", UITheme.create_flat_stylebox(UITheme.BORDER))
	main_vbox.add_child(sep1)

	# Item list section
	var list_label := Label.new()
	list_label.text = "اختر المنتج:"
	UITheme.style_label(list_label, UITheme.FONT_BODY, UITheme.TEXT_PRIMARY)
	main_vbox.add_child(list_label)

	var list_scroll := ScrollContainer.new()
	list_scroll.custom_minimum_size = Vector2(0, 180)
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UITheme.style_scroll_container(list_scroll)
	main_vbox.add_child(list_scroll)

	_item_list = ItemList.new()
	_item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_item_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_item_list.item_selected.connect(_on_item_selected)
	_item_list.auto_height = true
	_style_item_list()
	list_scroll.add_child(_item_list)

	# Quantity section
	var qty_panel := PanelContainer.new()
	qty_panel.add_theme_stylebox_override("panel", UITheme.create_panel_stylebox(UITheme.BG_DARK, 1))
	main_vbox.add_child(qty_panel)

	var qty_hbox := HBoxContainer.new()
	qty_hbox.add_theme_constant_override("separation", 15)
	qty_panel.add_child(qty_hbox)

	var qty_label := Label.new()
	qty_label.text = "الكمية:"
	UITheme.style_label(qty_label, UITheme.FONT_BODY, UITheme.TEXT_PRIMARY)
	qty_hbox.add_child(qty_label)

	_quantity_spin = SpinBox.new()
	_quantity_spin.min_value = 1
	_quantity_spin.max_value = 10
	_quantity_spin.value = 1
	_quantity_spin.custom_minimum_size = Vector2(100, 0)
	_quantity_spin.value_changed.connect(_on_quantity_changed)
	qty_hbox.add_child(_quantity_spin)

	var qty_spacer := Control.new()
	qty_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	qty_hbox.add_child(qty_spacer)

	# Cost breakdown section
	var cost_label := Label.new()
	cost_label.text = "تفاصيل التكلفة:"
	UITheme.style_label(cost_label, UITheme.FONT_BODY, UITheme.ACCENT_GOLD)
	main_vbox.add_child(cost_label)

	var cost_panel := PanelContainer.new()
	cost_panel.add_theme_stylebox_override("panel", UITheme.create_panel_stylebox(UITheme.BG_DARK, 1))
	main_vbox.add_child(cost_panel)

	_cost_breakdown = VBoxContainer.new()
	_cost_breakdown.add_theme_constant_override("separation", 8)
	cost_panel.add_child(_cost_breakdown)

	# Materials check
	_materials_check = Label.new()
	UITheme.style_label(_materials_check, UITheme.FONT_BODY, UITheme.TEXT_PRIMARY)
	_materials_check.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(_materials_check)

	# Separator
	var sep2 := HSeparator.new()
	sep2.add_theme_stylebox_override("separator", UITheme.create_flat_stylebox(UITheme.BORDER))
	main_vbox.add_child(sep2)

	# Buttons
	var btn_hbox := HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 15)
	main_vbox.add_child(btn_hbox)

	_cancel_button = Button.new()
	_cancel_button.text = "إلغاء"
	_cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cancel_button.custom_minimum_size = Vector2(0, 45)
	_cancel_button.pressed.connect(func(): cancelled.emit(); queue_free())
	UITheme.style_button(_cancel_button, UITheme.ERROR.darkened(0.4))
	btn_hbox.add_child(_cancel_button)

	_confirm_button = Button.new()
	_confirm_button.text = "تأكيد الطلب"
	_confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirm_button.custom_minimum_size = Vector2(0, 45)
	_confirm_button.disabled = true
	_confirm_button.pressed.connect(_on_confirm)
	UITheme.style_button(_confirm_button, UITheme.SUCCESS.darkened(0.4))
	btn_hbox.add_child(_confirm_button)

func _style_item_list() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = UITheme.BG_DARK
	bg.set_corner_radius_all(6)
	bg.set_content_margin_all(8)
	_item_list.add_theme_stylebox_override("panel", bg)
	_item_list.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_item_list.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	_item_list.add_theme_color_override("font_selected_color", UITheme.ACCENT_GOLD)
	_item_list.add_theme_font_size_override("font_size", UITheme.FONT_BODY)

	# Selected item background
	var selected_bg := StyleBoxFlat.new()
	selected_bg.bg_color = UITheme.ACCENT_GOLD.darkened(0.7)
	selected_bg.set_corner_radius_all(4)
	_item_list.add_theme_stylebox_override("selected", selected_bg)
	_item_list.add_theme_stylebox_override("selected_focus", selected_bg)

func set_supplier(s: SupplierData) -> void:
	supplier = s
	if _title_label:
		_title_label.text = "طلب من: %s" % supplier.name_ar
	_populate_items()

func _populate_items() -> void:
	if not _item_list or not supplier:
		return

	_item_list.clear()

	# Get items this supplier can make
	for item_id in DataRegistry.items:
		var item: ItemData = DataRegistry.items[item_id]
		var can_make := false

		match item.category:
			Enums.ItemCategory.WEAPON, Enums.ItemCategory.ARMOR:
				can_make = supplier.supplier_type == Enums.SupplierType.BLACKSMITH
			Enums.ItemCategory.POTION:
				can_make = supplier.supplier_type == Enums.SupplierType.ALCHEMIST
			Enums.ItemCategory.ACCESSORY:
				can_make = supplier.supplier_type in [Enums.SupplierType.ENCHANTER, Enums.SupplierType.BLACKSMITH]

		if can_make:
			var specialty := " ★" if item.id in supplier.specialties else ""
			var display := "%s  %s%s" % [item.icon_char, item.name_ar, specialty]
			_item_list.add_item(display)
			_item_list.set_item_metadata(_item_list.item_count - 1, item)

func _on_item_selected(index: int) -> void:
	selected_item = _item_list.get_item_metadata(index)
	_update_cost_breakdown()

func _on_quantity_changed(value: float) -> void:
	quantity = int(value)
	_update_cost_breakdown()

func _update_cost_breakdown() -> void:
	for child in _cost_breakdown.get_children():
		child.queue_free()

	if not selected_item or not supplier:
		_confirm_button.disabled = true
		return

	var cost := SupplierSystem.calculate_order_cost(supplier, selected_item, quantity)
	var can_order := SupplierSystem.can_place_order(supplier, selected_item, quantity)

	# Material cost
	_add_cost_line("تكلفة المواد:", "%d ذهب" % cost.material_cost)
	_add_cost_line("أجرة العمل:", "%d ذهب" % cost.labor_cost)
	_add_cost_line("المجموع:", "%d ذهب" % cost.total_cost, UITheme.ACCENT_GOLD, true)
	_add_cost_line("وقت التصنيع:", "%.1f ساعة" % cost.craft_time_hours)
	_add_cost_line("الجودة المتوقعة:", Enums.get_quality_name(cost.expected_quality), UITheme.get_quality_color(cost.expected_quality))
	_add_cost_line("نسبة النجاح:", "%d%%" % int(cost.success_rate * 100))

	# Materials check
	if can_order.can_order:
		_materials_check.text = "✓ جميع المواد متوفرة"
		_materials_check.add_theme_color_override("font_color", UITheme.SUCCESS)
		_confirm_button.disabled = false
	else:
		_materials_check.text = "✗ " + can_order.reason
		_materials_check.add_theme_color_override("font_color", UITheme.ERROR)
		_confirm_button.disabled = true

func _add_cost_line(label_text: String, value: String, color: Color = UITheme.TEXT_SECONDARY, bold: bool = false) -> void:
	var hbox := HBoxContainer.new()
	_cost_breakdown.add_child(hbox)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.style_label(lbl, UITheme.FONT_BODY if bold else UITheme.FONT_SMALL, UITheme.TEXT_MUTED)
	hbox.add_child(lbl)

	var val := Label.new()
	val.text = value
	UITheme.style_label(val, UITheme.FONT_BODY if bold else UITheme.FONT_SMALL, color)
	hbox.add_child(val)

func _on_confirm() -> void:
	if selected_item and supplier:
		order_confirmed.emit(selected_item, quantity, supplier)
		queue_free()
