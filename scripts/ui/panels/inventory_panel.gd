class_name InventoryPanel
extends PanelContainer

signal item_selected(item: InventoryItem)
signal price_changed(item: InventoryItem, new_price: int)

var selected_item: InventoryItem
var filter_category: int = -1 # -1 = all

var _title_label: Label
var _filter_buttons: HBoxContainer
var _items_scroll: ScrollContainer
var _items_grid: GridContainer
var _details_panel: PanelContainer
var _price_editor: HBoxContainer
var _empty_label: Label

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_refresh_inventory()

func _setup_ui() -> void:
	var style := UITheme.create_panel_stylebox(UITheme.BG_MEDIUM)
	add_theme_stylebox_override("panel", style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 12)
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(main_vbox)

	# Header
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 15)
	main_vbox.add_child(header)

	_title_label = Label.new()
	_title_label.text = "المخزون"
	UITheme.style_label(_title_label, UITheme.FONT_TITLE, UITheme.ACCENT_GOLD)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_label)

	# Filters
	_filter_buttons = HBoxContainer.new()
	_filter_buttons.add_theme_constant_override("separation", 8)
	main_vbox.add_child(_filter_buttons)

	_add_filter_button("الكل", -1)
	_add_filter_button("⚔ أسلحة", Enums.ItemCategory.WEAPON)
	_add_filter_button("🛡 دروع", Enums.ItemCategory.ARMOR)
	_add_filter_button("🧪 جرعات", Enums.ItemCategory.POTION)
	_add_filter_button("💍 إكسسوارات", Enums.ItemCategory.ACCESSORY)

	# Content split
	var hsplit := HSplitContainer.new()
	hsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hsplit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hsplit.split_offset = -300
	main_vbox.add_child(hsplit)

	# Items area
	var items_container := VBoxContainer.new()
	items_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hsplit.add_child(items_container)

	# Items grid scroll
	_items_scroll = ScrollContainer.new()
	_items_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_items_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_items_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_items_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_items_scroll.custom_minimum_size = Vector2(450, 350)
	UITheme.style_scroll_container(_items_scroll)
	items_container.add_child(_items_scroll)

	_items_grid = GridContainer.new()
	_items_grid.columns = 2
	_items_grid.add_theme_constant_override("h_separation", 10)
	_items_grid.add_theme_constant_override("v_separation", 10)
	_items_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_items_scroll.add_child(_items_grid)

	_empty_label = Label.new()
	_empty_label.text = "المخزون فارغ\nاطلب منتجات من الموردين"
	UITheme.style_label(_empty_label, UITheme.FONT_BODY, UITheme.TEXT_MUTED)
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_empty_label.visible = false
	items_container.add_child(_empty_label)

	# Details panel
	_details_panel = PanelContainer.new()
	_details_panel.custom_minimum_size = Vector2(300, 0)
	_details_panel.add_theme_stylebox_override("panel", UITheme.create_panel_stylebox(UITheme.BG_DARK))
	_details_panel.visible = false
	hsplit.add_child(_details_panel)

	_setup_details_panel()

func _add_filter_button(text: String, category: int) -> void:
	var btn := Button.new()
	btn.text = text
	btn.toggle_mode = true
	btn.button_pressed = category == -1
	btn.custom_minimum_size = Vector2(0, 36)
	btn.pressed.connect(func(): _set_filter(category))
	UITheme.style_button(btn, UITheme.BG_LIGHT)

	_filter_buttons.add_child(btn)

func _setup_details_panel() -> void:
	var vbox := VBoxContainer.new()
	vbox.name = "DetailsContent"
	vbox.add_theme_constant_override("separation", 12)
	_details_panel.add_child(vbox)

	var detail_title := Label.new()
	detail_title.name = "DetailTitle"
	UITheme.style_label(detail_title, UITheme.FONT_HEADER, UITheme.TEXT_PRIMARY)
	detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(detail_title)

	var detail_icon := Label.new()
	detail_icon.name = "DetailIcon"
	detail_icon.add_theme_font_size_override("font_size", 56)
	detail_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(detail_icon)

	var detail_quality := Label.new()
	detail_quality.name = "DetailQuality"
	UITheme.style_label(detail_quality, UITheme.FONT_BODY, UITheme.TEXT_SECONDARY)
	detail_quality.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(detail_quality)

	# Separator
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", UITheme.create_flat_stylebox(UITheme.BORDER))
	vbox.add_child(sep)

	var detail_stats := VBoxContainer.new()
	detail_stats.name = "DetailStats"
	detail_stats.add_theme_constant_override("separation", 6)
	vbox.add_child(detail_stats)

	# Price editor panel
	var price_panel := PanelContainer.new()
	price_panel.add_theme_stylebox_override("panel", UITheme.create_panel_stylebox(UITheme.BG_MEDIUM, 1))
	vbox.add_child(price_panel)

	var price_vbox := VBoxContainer.new()
	price_vbox.add_theme_constant_override("separation", 8)
	price_panel.add_child(price_vbox)

	var price_title := Label.new()
	price_title.text = "تعديل السعر"
	UITheme.style_label(price_title, UITheme.FONT_BODY, UITheme.ACCENT_GOLD)
	price_vbox.add_child(price_title)

	_price_editor = HBoxContainer.new()
	_price_editor.add_theme_constant_override("separation", 10)
	price_vbox.add_child(_price_editor)

	var price_label := Label.new()
	price_label.text = "السعر:"
	UITheme.style_label(price_label, UITheme.FONT_BODY, UITheme.TEXT_PRIMARY)
	_price_editor.add_child(price_label)

	var price_spin := SpinBox.new()
	price_spin.name = "PriceSpin"
	price_spin.min_value = 1
	price_spin.max_value = 10000
	price_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	price_spin.value_changed.connect(_on_price_edited)
	_price_editor.add_child(price_spin)

	var gold_label := Label.new()
	gold_label.text = "ذهب"
	UITheme.style_label(gold_label, UITheme.FONT_BODY, UITheme.ACCENT_GOLD)
	_price_editor.add_child(gold_label)

	var market_label := Label.new()
	market_label.name = "MarketPrice"
	UITheme.style_label(market_label, UITheme.FONT_SMALL, UITheme.TEXT_MUTED)
	market_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_vbox.add_child(market_label)

func _connect_signals() -> void:
	GameManager.gold_changed.connect(func(_g): _refresh_inventory())

func _set_filter(category: int) -> void:
	filter_category = category
	# Update button states
	for i in range(_filter_buttons.get_child_count()):
		var btn := _filter_buttons.get_child(i) as Button
		var is_active := (i == 0 and category == -1) or (i > 0 and category == i - 1)
		btn.button_pressed = is_active
		if is_active:
			var active_style := UITheme.create_button_stylebox(UITheme.ACCENT_GOLD.darkened(0.5), true)
			btn.add_theme_stylebox_override("normal", active_style)
		else:
			UITheme.style_button(btn, UITheme.BG_LIGHT)
	_refresh_inventory()

func _refresh_inventory() -> void:
	# Clear grid
	for child in _items_grid.get_children():
		child.queue_free()

	var items := GameManager.inventory
	var filtered: Array[InventoryItem] = []

	for item in items:
		if filter_category == -1 or item.item_data.category == filter_category:
			filtered.append(item)

	if filtered.is_empty():
		_empty_label.visible = true
		_items_scroll.visible = false
	else:
		_empty_label.visible = false
		_items_scroll.visible = true

		for item in filtered:
			var slot := ItemSlot.new()
			slot.set_item(item)
			slot.clicked.connect(_on_item_clicked)
			_items_grid.add_child(slot)

func _on_item_clicked(item: InventoryItem) -> void:
	selected_item = item
	_update_details_panel()
	_details_panel.visible = true
	item_selected.emit(item)

	# Update selection visuals
	for child in _items_grid.get_children():
		if child is ItemSlot:
			child.set_selected(child.inventory_item == item)

func _update_details_panel() -> void:
	if not selected_item:
		return

	var content := _details_panel.get_node("DetailsContent")
	var title := content.get_node("DetailTitle") as Label
	var icon := content.get_node("DetailIcon") as Label
	var quality := content.get_node("DetailQuality") as Label
	var stats := content.get_node("DetailStats") as VBoxContainer
	var price_spin := _price_editor.get_node("PriceSpin") as SpinBox
	var market := content.get_node("MarketPrice") as Label

	var data := selected_item.item_data

	title.text = data.name_ar
	title.add_theme_color_override("font_color", UITheme.get_rarity_color(data.rarity))

	icon.text = data.icon_char
	icon.add_theme_color_override("font_color", UITheme.get_rarity_color(data.rarity))

	quality.text = "الجودة: %s | الكمية: %d" % [
		Enums.get_quality_name(selected_item.quality),
		selected_item.quantity
	]
	quality.add_theme_color_override("font_color", UITheme.get_quality_color(selected_item.quality))

	# Stats
	for child in stats.get_children():
		child.queue_free()

	for stat_name in data.stats:
		var stat_hbox := HBoxContainer.new()
		stats.add_child(stat_hbox)

		var stat_label := Label.new()
		stat_label.text = "%s:" % stat_name
		stat_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.style_label(stat_label, UITheme.FONT_SMALL, UITheme.TEXT_MUTED)
		stat_hbox.add_child(stat_label)

		var stat_value := Label.new()
		stat_value.text = str(data.stats[stat_name])
		UITheme.style_label(stat_value, UITheme.FONT_SMALL, UITheme.TEXT_PRIMARY)
		stat_hbox.add_child(stat_value)

	price_spin.value = selected_item.listed_price

	var fair := EconomyManager.get_fair_price(data, selected_item.quality)
	var trend := EconomyManager.get_trend_icon(data.id)
	market.text = "💡 سعر السوق: %d %s" % [fair, trend]

func _on_price_edited(value: float) -> void:
	if selected_item:
		selected_item.listed_price = int(value)
		price_changed.emit(selected_item, int(value))
		_refresh_inventory()

func refresh() -> void:
	_refresh_inventory()
