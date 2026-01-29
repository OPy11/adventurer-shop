class_name ItemSelectDialog
extends PanelContainer

signal item_selected(item: InventoryItem)
signal cancelled

var customer: CustomerData
var available_items: Array[InventoryItem] = []

var _title_label: Label
var _items_container: VBoxContainer
var _cancel_button: Button

func _ready() -> void:
	_setup_ui()

func _setup_ui() -> void:
	custom_minimum_size = Vector2(400, 400)

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
	_title_label.text = "اختر المنتج للبيع"
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(_title_label)

	# Scroll for items
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll)

	_items_container = VBoxContainer.new()
	_items_container.add_theme_constant_override("separation", 8)
	scroll.add_child(_items_container)

	# Cancel button
	_cancel_button = Button.new()
	_cancel_button.text = "إلغاء"
	_cancel_button.pressed.connect(func(): cancelled.emit(); queue_free())
	var btn_style := UITheme.create_button_stylebox(UITheme.BG_LIGHT)
	_cancel_button.add_theme_stylebox_override("normal", btn_style)
	main_vbox.add_child(_cancel_button)

func setup(c: CustomerData, items: Array[InventoryItem]) -> void:
	customer = c
	available_items = items
	_populate_items()

func _populate_items() -> void:
	for child in _items_container.get_children():
		child.queue_free()

	if available_items.is_empty():
		var empty := Label.new()
		empty.text = "لا توجد منتجات للبيع"
		empty.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
		_items_container.add_child(empty)
		return

	# Sort by what customer wants first
	var sorted_items := available_items.duplicate()
	sorted_items.sort_custom(func(a: InventoryItem, b: InventoryItem) -> bool:
		var a_wanted := a.item_data.id in customer.wanted_items
		var b_wanted := b.item_data.id in customer.wanted_items
		if a_wanted and not b_wanted:
			return true
		if b_wanted and not a_wanted:
			return false
		return a.item_data.base_price > b.item_data.base_price
	)

	for item in sorted_items:
		_add_item_row(item)

func _add_item_row(item: InventoryItem) -> void:
	var row := PanelContainer.new()
	var row_style := UITheme.create_panel_stylebox(UITheme.BG_DARK, 1)
	row.add_theme_stylebox_override("panel", row_style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	row.add_child(hbox)

	# Icon
	var icon := Label.new()
	icon.text = item.item_data.icon_char
	icon.add_theme_font_size_override("font_size", 24)
	icon.add_theme_color_override("font_color", UITheme.get_rarity_color(item.item_data.rarity))
	hbox.add_child(icon)

	# Info
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)

	var name_hbox := HBoxContainer.new()
	info.add_child(name_hbox)

	var name_label := Label.new()
	name_label.text = item.item_data.name_ar
	name_label.add_theme_font_size_override("font_size", 14)
	name_hbox.add_child(name_label)

	# Mark if customer wants this
	if item.item_data.id in customer.wanted_items:
		var wanted := Label.new()
		wanted.text = " ★ يريده"
		wanted.add_theme_font_size_override("font_size", 10)
		wanted.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
		name_hbox.add_child(wanted)

	var details := Label.new()
	details.text = "%s | الكمية: %d" % [Enums.get_quality_name(item.quality), item.quantity]
	details.add_theme_font_size_override("font_size", 11)
	details.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	info.add_child(details)

	# Price
	var price := Label.new()
	price.text = "%d ذهب" % item.listed_price
	price.add_theme_font_size_override("font_size", 14)
	price.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	hbox.add_child(price)

	# Select button
	var select_btn := Button.new()
	select_btn.text = "اختر"
	select_btn.pressed.connect(func(): item_selected.emit(item); queue_free())
	var btn_style := UITheme.create_button_stylebox(UITheme.SUCCESS.darkened(0.5))
	select_btn.add_theme_stylebox_override("normal", btn_style)
	hbox.add_child(select_btn)

	_items_container.add_child(row)
