class_name InventoryPanel
extends PanelContainer

signal item_selected(item: InventoryItem)
signal price_changed(item: InventoryItem, new_price: int)

var selected_item: InventoryItem
var filter_category: int = -1 # -1 = all

var _title_label: Label
var _filter_buttons: HBoxContainer
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
	main_vbox.add_theme_constant_override("separation", 10)
	add_child(main_vbox)

	# Header
	var header := HBoxContainer.new()
	main_vbox.add_child(header)

	_title_label = Label.new()
	_title_label.text = "المخزون"
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_label)

	# Filters
	_filter_buttons = HBoxContainer.new()
	_filter_buttons.add_theme_constant_override("separation", 5)
	main_vbox.add_child(_filter_buttons)

	_add_filter_button("الكل", -1)
	_add_filter_button("أسلحة", Enums.ItemCategory.WEAPON)
	_add_filter_button("دروع", Enums.ItemCategory.ARMOR)
	_add_filter_button("جرعات", Enums.ItemCategory.POTION)
	_add_filter_button("إكسسوارات", Enums.ItemCategory.ACCESSORY)

	# Content split
	var hsplit := HSplitContainer.new()
	hsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(hsplit)

	# Items grid
	var items_scroll := ScrollContainer.new()
	items_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_scroll.custom_minimum_size = Vector2(400, 300)
	hsplit.add_child(items_scroll)

	_items_grid = GridContainer.new()
	_items_grid.columns = 2
	_items_grid.add_theme_constant_override("h_separation", 8)
	_items_grid.add_theme_constant_override("v_separation", 8)
	items_scroll.add_child(_items_grid)

	_empty_label = Label.new()
	_empty_label.text = "المخزون فارغ"
	_empty_label.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.visible = false
	items_scroll.add_child(_empty_label)

	# Details panel
	_details_panel = PanelContainer.new()
	_details_panel.custom_minimum_size = Vector2(250, 0)
	var dp_style := UITheme.create_panel_stylebox(UITheme.BG_DARK)
	_details_panel.add_theme_stylebox_override("panel", dp_style)
	_details_panel.visible = false
	hsplit.add_child(_details_panel)

	_setup_details_panel()

func _add_filter_button(text: String, category: int) -> void:
	var btn := Button.new()
	btn.text = text
	btn.toggle_mode = true
	btn.button_pressed = category == -1
	btn.pressed.connect(func(): _set_filter(category))

	var style := UITheme.create_button_stylebox(UITheme.BG_LIGHT)
	btn.add_theme_stylebox_override("normal", style)
	var pressed_style := UITheme.create_button_stylebox(UITheme.ACCENT_GOLD.darkened(0.5), true)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	_filter_buttons.add_child(btn)

func _setup_details_panel() -> void:
	var vbox := VBoxContainer.new()
	vbox.name = "DetailsContent"
	vbox.add_theme_constant_override("separation", 10)
	_details_panel.add_child(vbox)

	var detail_title := Label.new()
	detail_title.name = "DetailTitle"
	detail_title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(detail_title)

	var detail_icon := Label.new()
	detail_icon.name = "DetailIcon"
	detail_icon.add_theme_font_size_override("font_size", 48)
	detail_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(detail_icon)

	var detail_quality := Label.new()
	detail_quality.name = "DetailQuality"
	detail_quality.add_theme_font_size_override("font_size", 12)
	vbox.add_child(detail_quality)

	var detail_stats := VBoxContainer.new()
	detail_stats.name = "DetailStats"
	vbox.add_child(detail_stats)

	# Price editor
	_price_editor = HBoxContainer.new()
	_price_editor.add_theme_constant_override("separation", 5)
	vbox.add_child(_price_editor)

	var price_label := Label.new()
	price_label.text = "السعر:"
	price_label.add_theme_font_size_override("font_size", 12)
	_price_editor.add_child(price_label)

	var price_spin := SpinBox.new()
	price_spin.name = "PriceSpin"
	price_spin.min_value = 1
	price_spin.max_value = 10000
	price_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	price_spin.value_changed.connect(_on_price_edited)
	_price_editor.add_child(price_spin)

	var market_label := Label.new()
	market_label.name = "MarketPrice"
	market_label.add_theme_font_size_override("font_size", 10)
	market_label.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	vbox.add_child(market_label)

func _connect_signals() -> void:
	GameManager.gold_changed.connect(func(_g): _refresh_inventory())

func _set_filter(category: int) -> void:
	filter_category = category
	# Update button states
	for i in range(_filter_buttons.get_child_count()):
		var btn := _filter_buttons.get_child(i) as Button
		btn.button_pressed = (i == 0 and category == -1) or (i > 0 and category == i - 1)
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
		_items_grid.visible = false
	else:
		_empty_label.visible = false
		_items_grid.visible = true

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
		var stat_label := Label.new()
		stat_label.text = "%s: %d" % [stat_name, data.stats[stat_name]]
		stat_label.add_theme_font_size_override("font_size", 11)
		stat_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)
		stats.add_child(stat_label)

	price_spin.value = selected_item.listed_price

	var fair := EconomyManager.get_fair_price(data, selected_item.quality)
	var trend := EconomyManager.get_trend_icon(data.id)
	market.text = "سعر السوق: %d %s" % [fair, trend]

func _on_price_edited(value: float) -> void:
	if selected_item:
		selected_item.listed_price = int(value)
		price_changed.emit(selected_item, int(value))
		_refresh_inventory()

func refresh() -> void:
	_refresh_inventory()
