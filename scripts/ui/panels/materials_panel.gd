class_name MaterialsPanel
extends PanelContainer

var _title_label: Label
var _materials_grid: GridContainer
var _empty_label: Label

func _ready() -> void:
	_setup_ui()
	_refresh_materials()

func _setup_ui() -> void:
	var style := UITheme.create_panel_stylebox(UITheme.BG_MEDIUM)
	add_theme_stylebox_override("panel", style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	add_child(main_vbox)

	# Header
	_title_label = Label.new()
	_title_label.text = "المواد الخام"
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	main_vbox.add_child(_title_label)

	# Scroll container
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 200)
	main_vbox.add_child(scroll)

	_materials_grid = GridContainer.new()
	_materials_grid.columns = 3
	_materials_grid.add_theme_constant_override("h_separation", 8)
	_materials_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_materials_grid)

	_empty_label = Label.new()
	_empty_label.text = "لا توجد مواد"
	_empty_label.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.visible = false
	main_vbox.add_child(_empty_label)

func _refresh_materials() -> void:
	for child in _materials_grid.get_children():
		child.queue_free()

	var materials := GameManager.materials
	if materials.is_empty():
		_empty_label.visible = true
		_materials_grid.visible = false
		return

	_empty_label.visible = false
	_materials_grid.visible = true

	for mat_id in materials:
		var quantity: int = materials[mat_id]
		var mat_data := DataRegistry.get_material(mat_id)
		if mat_data:
			_add_material_slot(mat_data, quantity)

func _add_material_slot(mat: MaterialData, quantity: int) -> void:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(100, 70)

	var slot_style := StyleBoxFlat.new()
	slot_style.bg_color = UITheme.BG_DARK
	slot_style.border_color = UITheme.get_rarity_color(mat.rarity).darkened(0.3)
	slot_style.set_border_width_all(2)
	slot_style.set_corner_radius_all(6)
	slot_style.set_content_margin_all(6)
	slot.add_theme_stylebox_override("panel", slot_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	slot.add_child(vbox)

	# Icon and quantity
	var top_hbox := HBoxContainer.new()
	vbox.add_child(top_hbox)

	var icon := Label.new()
	icon.text = mat.icon_char
	icon.add_theme_font_size_override("font_size", 20)
	icon.add_theme_color_override("font_color", UITheme.get_rarity_color(mat.rarity))
	top_hbox.add_child(icon)

	var qty_label := Label.new()
	qty_label.text = " ×%d" % quantity
	qty_label.add_theme_font_size_override("font_size", 12)
	qty_label.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	top_hbox.add_child(qty_label)

	# Name
	var name_label := Label.new()
	name_label.text = mat.name_ar
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)
	vbox.add_child(name_label)

	# Market price
	var price := EconomyManager.get_material_price(mat.id, mat.base_price)
	var price_label := Label.new()
	price_label.text = "%d ذهب" % price
	price_label.add_theme_font_size_override("font_size", 9)
	price_label.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	vbox.add_child(price_label)

	# Tooltip
	slot.tooltip_text = "%s\n%s\nالقيمة: %d ذهب" % [
		mat.name_ar,
		Enums.get_rarity_name(mat.rarity),
		price * quantity
	]

	_materials_grid.add_child(slot)

func refresh() -> void:
	_refresh_materials()
