extends Control

## Main game UI controller

var _header_bar: HeaderBar
var _tab_container: TabContainer
var _shop_panel: ShopPanel
var _inventory_panel: InventoryPanel
var _materials_panel: MaterialsPanel
var _suppliers_panel: SuppliersPanel
var _guild_panel: GuildPanel
var _notification_container: VBoxContainer
var _dialog_layer: CanvasLayer

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_give_starting_items()

func _setup_ui() -> void:
	# Set full rect
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Background
	var bg := ColorRect.new()
	bg.color = UITheme.BG_DARK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Main layout
	var main_vbox := VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 0)
	add_child(main_vbox)

	# Header
	_header_bar = HeaderBar.new()
	main_vbox.add_child(_header_bar)

	# Content area with tabs
	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 0)
	main_vbox.add_child(content)

	# Left sidebar with materials
	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size = Vector2(400, 0)
	sidebar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(sidebar)

	_materials_panel = MaterialsPanel.new()
	_materials_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_materials_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sidebar.add_child(_materials_panel)

	# Main content with tabs
	_tab_container = TabContainer.new()
	_tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tab_container.tab_alignment = TabBar.ALIGNMENT_CENTER
	_tab_container.clip_tabs = false
	_style_tabs()
	content.add_child(_tab_container)

	# Shop tab
	_shop_panel = ShopPanel.new()
	_shop_panel.name = "المتجر"
	_shop_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_shop_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tab_container.add_child(_shop_panel)

	# Inventory tab
	_inventory_panel = InventoryPanel.new()
	_inventory_panel.name = "المخزون"
	_inventory_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inventory_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tab_container.add_child(_inventory_panel)

	# Suppliers tab
	_suppliers_panel = SuppliersPanel.new()
	_suppliers_panel.name = "الموردين"
	_suppliers_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_suppliers_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tab_container.add_child(_suppliers_panel)

	# Guild tab
	_guild_panel = GuildPanel.new()
	_guild_panel.name = "النقابة"
	_guild_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_guild_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tab_container.add_child(_guild_panel)

	# Notification container (top right)
	_notification_container = VBoxContainer.new()
	_notification_container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_notification_container.set_anchor(SIDE_LEFT, 1.0)
	_notification_container.set_anchor(SIDE_RIGHT, 1.0)
	_notification_container.offset_left = -340
	_notification_container.offset_right = -15
	_notification_container.offset_top = 80
	_notification_container.custom_minimum_size = Vector2(320, 0)
	_notification_container.add_theme_constant_override("separation", 8)
	add_child(_notification_container)

	# Dialog layer (above everything)
	_dialog_layer = CanvasLayer.new()
	_dialog_layer.layer = 10
	add_child(_dialog_layer)

	var dialog_bg := ColorRect.new()
	dialog_bg.name = "DialogBG"
	dialog_bg.color = Color(0, 0, 0, 0.75)
	dialog_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialog_bg.visible = false
	dialog_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	# Allow clicking background to close dialog
	dialog_bg.gui_input.connect(_on_dialog_bg_input)
	_dialog_layer.add_child(dialog_bg)

func _style_tabs() -> void:
	# Panel background
	var tab_bg := StyleBoxFlat.new()
	tab_bg.bg_color = UITheme.BG_MEDIUM
	tab_bg.set_content_margin_all(12)
	_tab_container.add_theme_stylebox_override("panel", tab_bg)

	# Tab font size - larger for better readability
	_tab_container.add_theme_font_size_override("font_size", UITheme.FONT_HEADER)

	# Tab bar styling - unselected
	var tab_unselected := StyleBoxFlat.new()
	tab_unselected.bg_color = UITheme.BG_DARK
	tab_unselected.set_corner_radius_all(8)
	tab_unselected.corner_radius_bottom_left = 0
	tab_unselected.corner_radius_bottom_right = 0
	tab_unselected.set_content_margin_all(14)
	tab_unselected.content_margin_bottom = 10
	tab_unselected.content_margin_top = 12
	_tab_container.add_theme_stylebox_override("tab_unselected", tab_unselected)

	# Tab bar styling - selected
	var tab_selected := StyleBoxFlat.new()
	tab_selected.bg_color = UITheme.BG_MEDIUM
	tab_selected.border_color = UITheme.ACCENT_GOLD
	tab_selected.set_border_width_all(0)
	tab_selected.border_width_top = 3
	tab_selected.set_corner_radius_all(8)
	tab_selected.corner_radius_bottom_left = 0
	tab_selected.corner_radius_bottom_right = 0
	tab_selected.set_content_margin_all(14)
	tab_selected.content_margin_bottom = 10
	tab_selected.content_margin_top = 12
	_tab_container.add_theme_stylebox_override("tab_selected", tab_selected)

	# Tab bar styling - hovered
	var tab_hovered := StyleBoxFlat.new()
	tab_hovered.bg_color = UITheme.BG_LIGHT.darkened(0.1)
	tab_hovered.set_corner_radius_all(8)
	tab_hovered.corner_radius_bottom_left = 0
	tab_hovered.corner_radius_bottom_right = 0
	tab_hovered.set_content_margin_all(14)
	tab_hovered.content_margin_bottom = 10
	tab_hovered.content_margin_top = 12
	_tab_container.add_theme_stylebox_override("tab_hovered", tab_hovered)

	# Tab text colors
	_tab_container.add_theme_color_override("font_selected_color", UITheme.ACCENT_GOLD)
	_tab_container.add_theme_color_override("font_unselected_color", UITheme.TEXT_PRIMARY)
	_tab_container.add_theme_color_override("font_hovered_color", UITheme.ACCENT_GOLD)

func _connect_signals() -> void:
	GameManager.notification_added.connect(_on_notification)
	_shop_panel.serve_customer.connect(_on_serve_customer)
	_suppliers_panel.order_dialog_requested.connect(_on_order_dialog_requested)
	_guild_panel.mission_dialog_requested.connect(_on_mission_dialog_requested)

func _on_notification(message: String, type: String) -> void:
	var popup := NotificationPopup.new()
	popup.message = message
	popup.notification_type = type
	_notification_container.add_child(popup)

	# Limit notifications
	while _notification_container.get_child_count() > 5:
		var first_child := _notification_container.get_child(0)
		if first_child:
			first_child.queue_free()

func _on_serve_customer(customer: CustomerData) -> void:
	if GameManager.inventory.is_empty():
		GameManager.notify("ليس لديك أي بضائع للبيع!", "error")
		return

	# Show item selection dialog
	_show_dialog_bg()

	var dialog := ItemSelectDialog.new()
	dialog.setup(customer, GameManager.inventory)
	dialog.item_selected.connect(func(item: InventoryItem):
		_hide_dialog_bg()
		# Small delay then show sale dialog
		await get_tree().create_timer(0.1).timeout
		_show_sale_dialog(customer, item)
	)
	dialog.cancelled.connect(_hide_dialog_bg)
	_center_dialog(dialog)
	_dialog_layer.add_child(dialog)

func _show_sale_dialog(customer: CustomerData, item: InventoryItem) -> void:
	_show_dialog_bg()

	var dialog := SaleDialog.new()
	dialog.setup(customer, item)
	dialog.sale_completed.connect(_on_sale_completed)
	dialog.sale_cancelled.connect(_hide_dialog_bg)
	dialog.customer_left_angry.connect(func():
		CustomerSystem.customer_leaves_angry(customer)
		_hide_dialog_bg()
	)
	_center_dialog(dialog)
	_dialog_layer.add_child(dialog)

func _on_sale_completed(_item: InventoryItem, _price: int) -> void:
	_hide_dialog_bg()
	_inventory_panel.refresh()
	_materials_panel.refresh()

func _on_order_dialog_requested(supplier: SupplierData) -> void:
	_show_dialog_bg()

	var dialog := OrderDialog.new()
	dialog.set_supplier(supplier)
	dialog.order_confirmed.connect(_on_order_confirmed)
	dialog.cancelled.connect(_hide_dialog_bg)
	_center_dialog(dialog)
	_dialog_layer.add_child(dialog)

func _on_order_confirmed(item: ItemData, quantity: int, supplier: SupplierData) -> void:
	SupplierSystem.place_order(supplier, item, quantity)
	_hide_dialog_bg()
	_materials_panel.refresh()
	_suppliers_panel.refresh()

func _on_mission_dialog_requested(adventurer: AdventurerData) -> void:
	_show_dialog_bg()

	var dialog := MissionDialog.new()
	dialog.set_adventurer(adventurer)
	dialog.mission_started.connect(_on_mission_started)
	dialog.cancelled.connect(_hide_dialog_bg)
	_center_dialog(dialog)
	_dialog_layer.add_child(dialog)

func _on_mission_started(_adventurer: AdventurerData, _dungeon_id: String) -> void:
	_hide_dialog_bg()
	_guild_panel.refresh()

func _center_dialog(dialog: Control) -> void:
	# Center the dialog on screen
	dialog.set_anchors_preset(Control.PRESET_CENTER)
	dialog.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dialog.grow_vertical = Control.GROW_DIRECTION_BOTH

func _show_dialog_bg() -> void:
	var bg := _dialog_layer.get_node("DialogBG")
	bg.visible = true

	# Fade in animation
	bg.modulate.a = 0
	var tween := create_tween()
	tween.tween_property(bg, "modulate:a", 1.0, 0.2)

func _hide_dialog_bg() -> void:
	var bg := _dialog_layer.get_node("DialogBG")

	# Fade out animation
	var tween := create_tween()
	tween.tween_property(bg, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func():
		bg.visible = false
		# Remove dialogs
		for child in _dialog_layer.get_children():
			if child.name != "DialogBG":
				child.queue_free()
	)

func _on_dialog_bg_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_hide_dialog_bg()

func _give_starting_items() -> void:
	# Give player some starting inventory and materials
	var iron_sword := DataRegistry.get_item("iron_sword")
	if iron_sword:
		var item := InventoryItem.new(iron_sword, 3, Enums.Quality.STANDARD)
		item.purchase_price = 30
		GameManager.add_to_inventory(item)

	var health_potion := DataRegistry.get_item("health_potion")
	if health_potion:
		var item := InventoryItem.new(health_potion, 5, Enums.Quality.GOOD)
		item.purchase_price = 10
		GameManager.add_to_inventory(item)

	var leather_armor := DataRegistry.get_item("leather_armor")
	if leather_armor:
		var item := InventoryItem.new(leather_armor, 2, Enums.Quality.STANDARD)
		item.purchase_price = 25
		GameManager.add_to_inventory(item)

	# Starting materials
	GameManager.add_material("iron_ore", 15)
	GameManager.add_material("leather", 10)
	GameManager.add_material("wood", 20)
	GameManager.add_material("magic_herb", 8)
	GameManager.add_material("copper_ore", 12)

	GameManager.notify("مرحباً بك في %s!" % GameManager.shop_name, "success")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_hide_dialog_bg()

	# Tab shortcuts
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_tab_container.current_tab = 0
			KEY_2:
				_tab_container.current_tab = 1
			KEY_3:
				_tab_container.current_tab = 2
			KEY_4:
				_tab_container.current_tab = 3
			KEY_SPACE:
				TimeManager.toggle_pause()
