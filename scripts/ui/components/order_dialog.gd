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
	custom_minimum_size = Vector2(450, 500)

	var style := StyleBoxFlat.new()
	style.bg_color = UITheme.BG_MEDIUM
	style.border_color = UITheme.ACCENT_GOLD
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(20)
	add_theme_stylebox_override("panel", style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 12)
	add_child(main_vbox)

	# Title
	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(_title_label)

	# Item list
	var list_label := Label.new()
	list_label.text = "اختر المنتج:"
	list_label.add_theme_font_size_override("font_size", 14)
	main_vbox.add_child(list_label)

	_item_list = ItemList.new()
	_item_list.custom_minimum_size = Vector2(0, 150)
	_item_list.item_selected.connect(_on_item_selected)
	_style_item_list()
	main_vbox.add_child(_item_list)

	# Quantity
	var qty_hbox := HBoxContainer.new()
	qty_hbox.add_theme_constant_override("separation", 10)
	main_vbox.add_child(qty_hbox)

	var qty_label := Label.new()
	qty_label.text = "الكمية:"
	qty_label.add_theme_font_size_override("font_size", 14)
	qty_hbox.add_child(qty_label)

	_quantity_spin = SpinBox.new()
	_quantity_spin.min_value = 1
	_quantity_spin.max_value = 10
	_quantity_spin.value = 1
	_quantity_spin.value_changed.connect(_on_quantity_changed)
	qty_hbox.add_child(_quantity_spin)

	# Cost breakdown
	var cost_label := Label.new()
	cost_label.text = "تفاصيل التكلفة:"
	cost_label.add_theme_font_size_override("font_size", 14)
	main_vbox.add_child(cost_label)

	_cost_breakdown = VBoxContainer.new()
	main_vbox.add_child(_cost_breakdown)

	# Materials check
	_materials_check = Label.new()
	_materials_check.add_theme_font_size_override("font_size", 12)
	main_vbox.add_child(_materials_check)

	# Buttons
	var btn_hbox := HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 10)
	main_vbox.add_child(btn_hbox)

	_cancel_button = Button.new()
	_cancel_button.text = "إلغاء"
	_cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cancel_button.pressed.connect(func(): cancelled.emit(); queue_free())
	var cancel_style := UITheme.create_button_stylebox(UITheme.ERROR.darkened(0.5))
	_cancel_button.add_theme_stylebox_override("normal", cancel_style)
	btn_hbox.add_child(_cancel_button)

	_confirm_button = Button.new()
	_confirm_button.text = "تأكيد الطلب"
	_confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirm_button.disabled = true
	_confirm_button.pressed.connect(_on_confirm)
	var confirm_style := UITheme.create_button_stylebox(UITheme.SUCCESS.darkened(0.5))
	_confirm_button.add_theme_stylebox_override("normal", confirm_style)
	btn_hbox.add_child(_confirm_button)

func _style_item_list() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = UITheme.BG_DARK
	bg.set_corner_radius_all(6)
	_item_list.add_theme_stylebox_override("panel", bg)
	_item_list.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	_item_list.add_theme_color_override("font_selected_color", UITheme.ACCENT_GOLD)

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
			var display := "%s %s%s" % [item.icon_char, item.name_ar, specialty]
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
	_add_cost_line("المجموع:", "%d ذهب" % cost.total_cost, UITheme.ACCENT_GOLD)
	_add_cost_line("وقت التصنيع:", "%.1f ساعة" % cost.craft_time_hours)
	_add_cost_line("الجودة المتوقعة:", Enums.get_quality_name(cost.expected_quality))
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

func _add_cost_line(label: String, value: String, color: Color = UITheme.TEXT_SECONDARY) -> void:
	var hbox := HBoxContainer.new()
	_cost_breakdown.add_child(hbox)

	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(lbl)

	var val := Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 12)
	val.add_theme_color_override("font_color", color)
	hbox.add_child(val)

func _on_confirm() -> void:
	if selected_item and supplier:
		order_confirmed.emit(selected_item, quantity, supplier)
		queue_free()
