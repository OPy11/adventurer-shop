class_name SuppliersPanel
extends PanelContainer

signal order_dialog_requested(supplier: SupplierData)

var _title_label: Label
var _suppliers_scroll: ScrollContainer
var _suppliers_container: HBoxContainer
var _orders_container: VBoxContainer

func _ready() -> void:
	_setup_ui()
	_refresh_suppliers()
	SupplierSystem.order_placed.connect(_on_order_placed)
	SupplierSystem.order_completed.connect(_on_order_completed)

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
	_title_label.text = "الموردين"
	UITheme.style_label(_title_label, UITheme.FONT_TITLE, UITheme.ACCENT_GOLD)
	main_vbox.add_child(_title_label)

	# Suppliers section
	var suppliers_label := Label.new()
	suppliers_label.text = "الموردين المتاحين:"
	UITheme.style_label(suppliers_label, UITheme.FONT_BODY, UITheme.TEXT_PRIMARY)
	main_vbox.add_child(suppliers_label)

	_suppliers_scroll = ScrollContainer.new()
	_suppliers_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_suppliers_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_suppliers_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_suppliers_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_suppliers_scroll.custom_minimum_size = Vector2(0, 230)
	UITheme.style_scroll_container(_suppliers_scroll)
	main_vbox.add_child(_suppliers_scroll)

	_suppliers_container = HBoxContainer.new()
	_suppliers_container.add_theme_constant_override("separation", 15)
	_suppliers_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_suppliers_scroll.add_child(_suppliers_container)

	# Separator
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", UITheme.create_flat_stylebox(UITheme.BORDER))
	main_vbox.add_child(sep)

	# Active orders section
	var orders_header := HBoxContainer.new()
	main_vbox.add_child(orders_header)

	var orders_label := Label.new()
	orders_label.text = "الطلبات النشطة:"
	UITheme.style_label(orders_label, UITheme.FONT_BODY, UITheme.ACCENT_GOLD)
	orders_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	orders_header.add_child(orders_label)

	var orders_scroll := ScrollContainer.new()
	orders_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	orders_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	orders_scroll.custom_minimum_size = Vector2(0, 150)
	UITheme.style_scroll_container(orders_scroll)
	main_vbox.add_child(orders_scroll)

	_orders_container = VBoxContainer.new()
	_orders_container.add_theme_constant_override("separation", 8)
	_orders_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	orders_scroll.add_child(_orders_container)

func _refresh_suppliers() -> void:
	for child in _suppliers_container.get_children():
		child.queue_free()

	for supplier_id in DataRegistry.suppliers:
		var supplier: SupplierData = DataRegistry.suppliers[supplier_id]
		var card := SupplierCard.new()
		card.set_supplier(supplier)
		card.order_pressed.connect(_on_order_pressed)
		_suppliers_container.add_child(card)

	_refresh_orders()

func _refresh_orders() -> void:
	for child in _orders_container.get_children():
		child.queue_free()

	var orders := SupplierSystem.get_active_orders()

	if orders.is_empty():
		var empty := Label.new()
		empty.text = "لا توجد طلبات نشطة\nاختر موردًا واطلب تصنيع منتجات"
		UITheme.style_label(empty, UITheme.FONT_BODY, UITheme.TEXT_MUTED)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_orders_container.add_child(empty)
		return

	for order in orders:
		_add_order_display(order)

func _add_order_display(order: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.create_card_stylebox(UITheme.BG_DARK))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	panel.add_child(hbox)

	# Item info
	var item: ItemData = order.item
	var icon := Label.new()
	icon.text = item.icon_char
	icon.add_theme_font_size_override("font_size", 24)
	icon.add_theme_color_override("font_color", UITheme.get_rarity_color(item.rarity))
	icon.custom_minimum_size = Vector2(40, 40)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	hbox.add_child(info)

	var name_label := Label.new()
	name_label.text = "%d × %s" % [order.quantity, item.name_ar]
	UITheme.style_label(name_label, UITheme.FONT_BODY, UITheme.TEXT_PRIMARY)
	info.add_child(name_label)

	var supplier: SupplierData = order.supplier
	var supplier_label := Label.new()
	supplier_label.text = "من: %s" % supplier.name_ar
	UITheme.style_label(supplier_label, UITheme.FONT_SMALL, UITheme.TEXT_MUTED)
	info.add_child(supplier_label)

	# Progress section
	var progress_vbox := VBoxContainer.new()
	progress_vbox.add_theme_constant_override("separation", 4)
	progress_vbox.custom_minimum_size = Vector2(150, 0)
	hbox.add_child(progress_vbox)

	var progress_value := SupplierSystem.get_order_progress(supplier.id)
	var progress_label := Label.new()
	progress_label.text = "%d%%" % int(progress_value)
	UITheme.style_label(progress_label, UITheme.FONT_SMALL, UITheme.SUCCESS)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_vbox.add_child(progress_label)

	var progress := ProgressBar.new()
	progress.custom_minimum_size = Vector2(0, 16)
	progress.show_percentage = false
	progress.value = progress_value
	UITheme.style_progress_bar(progress, UITheme.SUCCESS, UITheme.BG_MEDIUM)
	progress_vbox.add_child(progress)

	# Cancel button
	var cancel := Button.new()
	cancel.text = "إلغاء"
	cancel.custom_minimum_size = Vector2(70, 36)
	cancel.pressed.connect(func(): SupplierSystem.cancel_order(supplier.id); _refresh_orders())
	UITheme.style_button(cancel, UITheme.ERROR.darkened(0.5))
	hbox.add_child(cancel)

	_orders_container.add_child(panel)

func _on_order_pressed(supplier: SupplierData) -> void:
	order_dialog_requested.emit(supplier)

func _on_order_placed(_supplier: SupplierData, _item: ItemData, _qty: int) -> void:
	_refresh_suppliers()

func _on_order_completed(_supplier: SupplierData, _item: ItemData, _success: bool) -> void:
	_refresh_suppliers()

func refresh() -> void:
	_refresh_suppliers()
