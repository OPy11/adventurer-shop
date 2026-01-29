class_name ItemSlot
extends PanelContainer

signal clicked(item: InventoryItem)
signal price_changed(item: InventoryItem, new_price: int)

var inventory_item: InventoryItem
var is_selected: bool = false

var _icon_label: Label
var _name_label: Label
var _quality_label: Label
var _quantity_label: Label
var _price_label: Label
var _tween: Tween

func _ready() -> void:
	_setup_ui()
	_connect_signals()

func _setup_ui() -> void:
	custom_minimum_size = Vector2(200, 90)

	var style := UITheme.create_card_stylebox(UITheme.BG_PANEL)
	add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	add_child(hbox)

	# Icon
	_icon_label = Label.new()
	_icon_label.custom_minimum_size = Vector2(45, 45)
	_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_icon_label.add_theme_font_size_override("font_size", 32)
	hbox.add_child(_icon_label)

	# Info VBox
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 3)
	hbox.add_child(vbox)

	_name_label = Label.new()
	UITheme.style_label(_name_label, UITheme.FONT_BODY, UITheme.TEXT_PRIMARY)
	_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	vbox.add_child(_name_label)

	var details_hbox := HBoxContainer.new()
	details_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(details_hbox)

	_quality_label = Label.new()
	UITheme.style_label(_quality_label, UITheme.FONT_SMALL, UITheme.TEXT_SECONDARY)
	details_hbox.add_child(_quality_label)

	_quantity_label = Label.new()
	UITheme.style_label(_quantity_label, UITheme.FONT_SMALL, UITheme.TEXT_MUTED)
	details_hbox.add_child(_quantity_label)

	_price_label = Label.new()
	UITheme.style_label(_price_label, UITheme.FONT_BODY, UITheme.ACCENT_GOLD)
	vbox.add_child(_price_label)

func _connect_signals() -> void:
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func set_item(item: InventoryItem) -> void:
	inventory_item = item
	_update_display()

func _update_display() -> void:
	if not inventory_item or not inventory_item.item_data or not _icon_label:
		visible = false
		return

	visible = true
	var data := inventory_item.item_data

	_icon_label.text = data.icon_char
	_icon_label.add_theme_color_override("font_color", UITheme.get_rarity_color(data.rarity))

	_name_label.text = data.name_ar
	_name_label.add_theme_color_override("font_color", UITheme.get_rarity_color(data.rarity))

	_quality_label.text = Enums.get_quality_name(inventory_item.quality)
	_quality_label.add_theme_color_override("font_color", UITheme.get_quality_color(inventory_item.quality))

	_quantity_label.text = "×%d" % inventory_item.quantity

	_price_label.text = "%d ذهب" % inventory_item.listed_price

	# Show age discount indicator
	if inventory_item.age_days > 7:
		_price_label.text += " (خصم!)"
		_price_label.add_theme_color_override("font_color", UITheme.SUCCESS)
	else:
		_price_label.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)

func set_selected(selected: bool) -> void:
	is_selected = selected
	var style := UITheme.create_card_stylebox(UITheme.BG_PANEL, selected)
	if selected:
		style.bg_color = UITheme.BG_HOVER
	add_theme_stylebox_override("panel", style)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			clicked.emit(inventory_item)

func _on_mouse_entered() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate", Color(1.15, 1.15, 1.15), 0.1)

	if not is_selected:
		var hover_style := UITheme.create_card_stylebox(UITheme.BG_HOVER)
		add_theme_stylebox_override("panel", hover_style)

func _on_mouse_exited() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate", Color.WHITE, 0.1)

	if not is_selected:
		var normal_style := UITheme.create_card_stylebox(UITheme.BG_PANEL)
		add_theme_stylebox_override("panel", normal_style)
