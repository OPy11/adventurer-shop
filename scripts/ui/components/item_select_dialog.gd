class_name ItemSelectDialog
extends PanelContainer

signal item_selected(item: InventoryItem)
signal cancelled

var customer: CustomerData
var available_items: Array[InventoryItem] = []

var _title_label: Label
var _scroll_container: ScrollContainer
var _items_container: VBoxContainer
var _cancel_button: Button

func _ready() -> void:
	_setup_ui()

func _setup_ui() -> void:
	custom_minimum_size = Vector2(550, 550)
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
	_title_label = UITheme.create_title_label("اختر المنتج للبيع")
	main_vbox.add_child(_title_label)

	# Separator
	var sep1 := HSeparator.new()
	sep1.add_theme_stylebox_override("separator", UITheme.create_flat_stylebox(UITheme.BORDER))
	main_vbox.add_child(sep1)

	# Scroll for items
	_scroll_container = ScrollContainer.new()
	_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll_container.custom_minimum_size = Vector2(0, 350)
	UITheme.style_scroll_container(_scroll_container)
	main_vbox.add_child(_scroll_container)

	_items_container = VBoxContainer.new()
	_items_container.add_theme_constant_override("separation", 10)
	_items_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_container.add_child(_items_container)

	# Separator
	var sep2 := HSeparator.new()
	sep2.add_theme_stylebox_override("separator", UITheme.create_flat_stylebox(UITheme.BORDER))
	main_vbox.add_child(sep2)

	# Cancel button
	_cancel_button = Button.new()
	_cancel_button.text = "إلغاء"
	_cancel_button.custom_minimum_size = Vector2(0, 45)
	_cancel_button.pressed.connect(func(): cancelled.emit(); queue_free())
	UITheme.style_button(_cancel_button, UITheme.BG_LIGHT)
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
		UITheme.style_label(empty, UITheme.FONT_BODY, UITheme.TEXT_MUTED)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	var is_wanted := item.item_data.id in customer.wanted_items

	var row := PanelContainer.new()
	var row_style := UITheme.create_card_stylebox(UITheme.BG_DARK, is_wanted)
	if is_wanted:
		row_style.border_color = UITheme.ACCENT_GOLD
	row.add_theme_stylebox_override("panel", row_style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	row.add_child(hbox)

	# Icon
	var icon := Label.new()
	icon.text = item.item_data.icon_char
	icon.add_theme_font_size_override("font_size", 28)
	icon.add_theme_color_override("font_color", UITheme.get_rarity_color(item.item_data.rarity))
	icon.custom_minimum_size = Vector2(40, 40)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon)

	# Info
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)

	var name_hbox := HBoxContainer.new()
	name_hbox.add_theme_constant_override("separation", 8)
	info.add_child(name_hbox)

	var name_label := Label.new()
	name_label.text = item.item_data.name_ar
	UITheme.style_label(name_label, UITheme.FONT_BODY, UITheme.get_rarity_color(item.item_data.rarity))
	name_hbox.add_child(name_label)

	# Mark if customer wants this
	if is_wanted:
		var wanted := Label.new()
		wanted.text = "★ يريده!"
		UITheme.style_label(wanted, UITheme.FONT_SMALL, UITheme.ACCENT_GOLD)
		name_hbox.add_child(wanted)

	var details := Label.new()
	details.text = "%s | الكمية: %d" % [Enums.get_quality_name(item.quality), item.quantity]
	UITheme.style_label(details, UITheme.FONT_SMALL, UITheme.TEXT_MUTED)
	info.add_child(details)

	# Price
	var price := Label.new()
	price.text = "%d ذهب" % item.listed_price
	UITheme.style_label(price, UITheme.FONT_BODY, UITheme.ACCENT_GOLD)
	price.custom_minimum_size = Vector2(80, 0)
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(price)

	# Select button
	var select_btn := Button.new()
	select_btn.text = "اختر"
	select_btn.custom_minimum_size = Vector2(80, 40)
	select_btn.pressed.connect(func(): item_selected.emit(item); queue_free())
	UITheme.style_button(select_btn, UITheme.SUCCESS.darkened(0.4))
	hbox.add_child(select_btn)

	_items_container.add_child(row)
