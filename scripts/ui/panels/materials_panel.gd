class_name MaterialsPanel
extends PanelContainer

var _title_label: Label
var _scroll_container: ScrollContainer
var _materials_grid: GridContainer
var _empty_label: Label

func _ready() -> void:
	_setup_ui()
	_refresh_materials()

func _setup_ui() -> void:
	var style := UITheme.create_panel_stylebox(UITheme.BG_MEDIUM)
	add_theme_stylebox_override("panel", style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 12)
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(main_vbox)

	# Header
	_title_label = Label.new()
	_title_label.text = "المواد الخام"
	UITheme.style_label(_title_label, UITheme.FONT_HEADER, UITheme.ACCENT_GOLD)
	main_vbox.add_child(_title_label)

	# Separator
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", UITheme.create_flat_stylebox(UITheme.BORDER))
	main_vbox.add_child(sep)

	# Scroll container
	_scroll_container = ScrollContainer.new()
	_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll_container.custom_minimum_size = Vector2(0, 300)
	UITheme.style_scroll_container(_scroll_container)
	main_vbox.add_child(_scroll_container)

	_materials_grid = GridContainer.new()
	_materials_grid.columns = 3
	_materials_grid.add_theme_constant_override("h_separation", 10)
	_materials_grid.add_theme_constant_override("v_separation", 10)
	_materials_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_container.add_child(_materials_grid)

	_empty_label = Label.new()
	_empty_label.text = "لا توجد مواد\nأرسل مغامرين للدناجن أو اشتر من السوق"
	UITheme.style_label(_empty_label, UITheme.FONT_BODY, UITheme.TEXT_MUTED)
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_empty_label.visible = false
	main_vbox.add_child(_empty_label)

func _refresh_materials() -> void:
	for child in _materials_grid.get_children():
		child.queue_free()

	var materials := GameManager.materials
	if materials.is_empty():
		_empty_label.visible = true
		_scroll_container.visible = false
		return

	_empty_label.visible = false
	_scroll_container.visible = true

	for mat_id in materials:
		var quantity: int = materials[mat_id]
		var mat_data := DataRegistry.get_material(mat_id)
		if mat_data:
			_add_material_slot(mat_data, quantity)

func _add_material_slot(mat: MaterialData, quantity: int) -> void:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(110, 90)

	var slot_style := StyleBoxFlat.new()
	slot_style.bg_color = UITheme.BG_DARK
	slot_style.border_color = UITheme.get_rarity_color(mat.rarity).darkened(0.2)
	slot_style.set_border_width_all(2)
	slot_style.set_corner_radius_all(8)
	slot_style.set_content_margin_all(8)
	slot.add_theme_stylebox_override("panel", slot_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	slot.add_child(vbox)

	# Icon and quantity row
	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 4)
	vbox.add_child(top_hbox)

	var icon := Label.new()
	icon.text = mat.icon_char
	icon.add_theme_font_size_override("font_size", 22)
	icon.add_theme_color_override("font_color", UITheme.get_rarity_color(mat.rarity))
	top_hbox.add_child(icon)

	var qty_label := Label.new()
	qty_label.text = "×%d" % quantity
	UITheme.style_label(qty_label, UITheme.FONT_BODY, UITheme.TEXT_PRIMARY)
	top_hbox.add_child(qty_label)

	# Name
	var name_label := Label.new()
	name_label.text = mat.name_ar
	UITheme.style_label(name_label, UITheme.FONT_SMALL, UITheme.TEXT_SECONDARY)
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	vbox.add_child(name_label)

	# Market price
	var price := EconomyManager.get_material_price(mat.id, mat.base_price)
	var price_label := Label.new()
	price_label.text = "%d ذهب" % price
	UITheme.style_label(price_label, UITheme.FONT_TINY, UITheme.ACCENT_GOLD)
	vbox.add_child(price_label)

	# Tooltip with full info
	slot.tooltip_text = "%s\n%s\nالقيمة الإجمالية: %d ذهب" % [
		mat.name_ar,
		Enums.get_rarity_name(mat.rarity),
		price * quantity
	]

	# Hover effect
	slot.mouse_entered.connect(func():
		slot_style.bg_color = UITheme.BG_HOVER
		slot.add_theme_stylebox_override("panel", slot_style)
	)
	slot.mouse_exited.connect(func():
		slot_style.bg_color = UITheme.BG_DARK
		slot.add_theme_stylebox_override("panel", slot_style)
	)

	_materials_grid.add_child(slot)

func refresh() -> void:
	_refresh_materials()
