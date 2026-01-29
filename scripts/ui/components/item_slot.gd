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
	custom_minimum_size = Vector2(180, 80)

	var style := StyleBoxFlat.new()
	style.bg_color = UITheme.BG_PANEL
	style.border_color = UITheme.BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	add_child(hbox)

	# Icon
	_icon_label = Label.new()
	_icon_label.custom_minimum_size = Vector2(40, 40)
	_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_icon_label.add_theme_font_size_override("font_size", 28)
	hbox.add_child(_icon_label)

	# Info VBox
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_name_label)

	var details_hbox := HBoxContainer.new()
	vbox.add_child(details_hbox)

	_quality_label = Label.new()
	_quality_label.add_theme_font_size_override("font_size", 11)
	details_hbox.add_child(_quality_label)

	_quantity_label = Label.new()
	_quantity_label.add_theme_font_size_override("font_size", 11)
	_quantity_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)
	details_hbox.add_child(_quantity_label)

	_price_label = Label.new()
	_price_label.add_theme_font_size_override("font_size", 13)
	_price_label.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	vbox.add_child(_price_label)

func _connect_signals() -> void:
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func set_item(item: InventoryItem) -> void:
	inventory_item = item
	_update_display()

func _update_display() -> void:
	if not inventory_item or not inventory_item.item_data:
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

	_quantity_label.text = " × %d" % inventory_item.quantity

	_price_label.text = "%d ذهب" % inventory_item.listed_price

	# Show age discount indicator
	if inventory_item.age_days > 7:
		_price_label.text += " (خصم!)"
		_price_label.add_theme_color_override("font_color", UITheme.SUCCESS)

func set_selected(selected: bool) -> void:
	is_selected = selected
	var style := get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.border_color = UITheme.ACCENT_GOLD if selected else UITheme.BORDER
	style.border_width_bottom = 3 if selected else 2
	add_theme_stylebox_override("panel", style)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			clicked.emit(inventory_item)

func _on_mouse_entered() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate", Color(1.1, 1.1, 1.1), 0.1)

func _on_mouse_exited() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate", Color.WHITE, 0.1)
