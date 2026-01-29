class_name ShopPanel
extends PanelContainer

signal serve_customer(customer: CustomerData)

var _title_label: Label
var _status_label: Label
var _customers_container: HBoxContainer
var _empty_label: Label

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_refresh_customers()

func _setup_ui() -> void:
	var style := UITheme.create_panel_stylebox(UITheme.BG_MEDIUM)
	add_theme_stylebox_override("panel", style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	add_child(main_vbox)

	# Header
	var header := HBoxContainer.new()
	main_vbox.add_child(header)

	_title_label = Label.new()
	_title_label.text = "المتجر"
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_label)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 14)
	header.add_child(_status_label)

	# Customers label
	var customers_title := Label.new()
	customers_title.text = "الزبائن المنتظرين:"
	customers_title.add_theme_font_size_override("font_size", 14)
	main_vbox.add_child(customers_title)

	# Customers scroll
	var scroll := ScrollContainer.new()
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 160)
	main_vbox.add_child(scroll)

	_customers_container = HBoxContainer.new()
	_customers_container.add_theme_constant_override("separation", 10)
	scroll.add_child(_customers_container)

	_empty_label = Label.new()
	_empty_label.text = "لا يوجد زبائن حالياً"
	_empty_label.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.visible = false
	main_vbox.add_child(_empty_label)

func _connect_signals() -> void:
	CustomerSystem.customer_spawned.connect(_on_customer_spawned)
	CustomerSystem.customer_left.connect(_on_customer_left)
	TimeManager.shop_hours_changed.connect(_on_shop_hours_changed)

func _refresh_customers() -> void:
	for child in _customers_container.get_children():
		child.queue_free()

	var customers := CustomerSystem.get_waiting_customers()

	if customers.is_empty():
		_empty_label.visible = true
		_customers_container.visible = false
	else:
		_empty_label.visible = false
		_customers_container.visible = true

		for customer in customers:
			_add_customer_card(customer)

	_update_status()

func _add_customer_card(customer: CustomerData) -> void:
	var card := CustomerCard.new()
	card.set_customer(customer)
	card.serve_pressed.connect(_on_serve_pressed)
	card.dismiss_pressed.connect(_on_dismiss_pressed)
	_customers_container.add_child(card)

func _update_status() -> void:
	if GameManager.is_shop_open:
		_status_label.text = "مفتوح 🟢"
		_status_label.add_theme_color_override("font_color", UITheme.SUCCESS)
	else:
		_status_label.text = "مغلق 🔴"
		_status_label.add_theme_color_override("font_color", UITheme.ERROR)

func _on_customer_spawned(_customer: CustomerData) -> void:
	_refresh_customers()

func _on_customer_left(_customer: CustomerData, _result: Enums.TransactionResult) -> void:
	_refresh_customers()

func _on_shop_hours_changed(_is_open: bool) -> void:
	_update_status()
	_refresh_customers()

func _on_serve_pressed(customer: CustomerData) -> void:
	serve_customer.emit(customer)

func _on_dismiss_pressed(customer: CustomerData) -> void:
	CustomerSystem.customer_leaves_angry(customer)

func refresh() -> void:
	_refresh_customers()
