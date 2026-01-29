class_name SuppliersPanel
extends PanelContainer

signal order_dialog_requested(supplier: SupplierData)

var _title_label: Label
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
	main_vbox.add_theme_constant_override("separation", 15)
	add_child(main_vbox)

	# Header
	_title_label = Label.new()
	_title_label.text = "الموردين"
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	main_vbox.add_child(_title_label)

	# Suppliers scroll
	var suppliers_label := Label.new()
	suppliers_label.text = "الموردين المتاحين:"
	suppliers_label.add_theme_font_size_override("font_size", 14)
	main_vbox.add_child(suppliers_label)

	var suppliers_scroll := ScrollContainer.new()
	suppliers_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	suppliers_scroll.custom_minimum_size = Vector2(0, 180)
	main_vbox.add_child(suppliers_scroll)

	_suppliers_container = HBoxContainer.new()
	_suppliers_container.add_theme_constant_override("separation", 10)
	suppliers_scroll.add_child(_suppliers_container)

	# Active orders
	var orders_label := Label.new()
	orders_label.text = "الطلبات النشطة:"
	orders_label.add_theme_font_size_override("font_size", 14)
	main_vbox.add_child(orders_label)

	_orders_container = VBoxContainer.new()
	_orders_container.add_theme_constant_override("separation", 5)
	main_vbox.add_child(_orders_container)

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
		empty.text = "لا توجد طلبات نشطة"
		empty.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
		_orders_container.add_child(empty)
		return

	for order in orders:
		_add_order_display(order)

func _add_order_display(order: Dictionary) -> void:
	var panel := PanelContainer.new()
	var style := UITheme.create_panel_stylebox(UITheme.BG_DARK, 1)
	panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	panel.add_child(hbox)

	# Item info
	var item: ItemData = order.item
	var icon := Label.new()
	icon.text = item.icon_char
	icon.add_theme_font_size_override("font_size", 20)
	hbox.add_child(icon)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)

	var name_label := Label.new()
	name_label.text = "%d × %s" % [order.quantity, item.name_ar]
	name_label.add_theme_font_size_override("font_size", 12)
	info.add_child(name_label)

	var supplier: SupplierData = order.supplier
	var supplier_label := Label.new()
	supplier_label.text = "من: %s" % supplier.name_ar
	supplier_label.add_theme_font_size_override("font_size", 10)
	supplier_label.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	info.add_child(supplier_label)

	# Progress
	var progress := ProgressBar.new()
	progress.custom_minimum_size = Vector2(100, 15)
	progress.show_percentage = true
	progress.value = SupplierSystem.get_order_progress(supplier.id)
	_style_progress_bar(progress)
	hbox.add_child(progress)

	# Cancel button
	var cancel := Button.new()
	cancel.text = "إلغاء"
	cancel.pressed.connect(func(): SupplierSystem.cancel_order(supplier.id); _refresh_orders())
	var btn_style := UITheme.create_button_stylebox(UITheme.ERROR.darkened(0.6))
	cancel.add_theme_stylebox_override("normal", btn_style)
	hbox.add_child(cancel)

	_orders_container.add_child(panel)

func _style_progress_bar(bar: ProgressBar) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = UITheme.BG_MEDIUM
	bg.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg)

	var fill := StyleBoxFlat.new()
	fill.bg_color = UITheme.SUCCESS
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)

func _on_order_pressed(supplier: SupplierData) -> void:
	order_dialog_requested.emit(supplier)

func _on_order_placed(_supplier: SupplierData, _item: ItemData, _qty: int) -> void:
	_refresh_suppliers()

func _on_order_completed(_supplier: SupplierData, _item: ItemData, _success: bool) -> void:
	_refresh_suppliers()

func refresh() -> void:
	_refresh_suppliers()
