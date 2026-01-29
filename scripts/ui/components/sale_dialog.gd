class_name SaleDialog
extends PanelContainer

signal sale_completed(item: InventoryItem, final_price: int)
signal sale_cancelled
signal customer_left_angry

var customer: CustomerData
var inventory_item: InventoryItem
var asking_price: int = 0
var fair_price: int = 0
var negotiation_round: int = 0
var max_negotiations: int = 3

var _customer_portrait: Label
var _customer_name: Label
var _customer_mood: Label
var _item_display: VBoxContainer
var _price_spin: SpinBox
var _fair_price_label: Label
var _response_label: Label
var _offer_button: Button
var _accept_button: Button
var _reject_button: Button
var _close_button: Button

func _ready() -> void:
	_setup_ui()

func _setup_ui() -> void:
	custom_minimum_size = Vector2(550, 600)
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
	var title := UITheme.create_title_label("عملية البيع")
	main_vbox.add_child(title)

	# Separator
	var sep1 := HSeparator.new()
	sep1.add_theme_stylebox_override("separator", UITheme.create_flat_stylebox(UITheme.BORDER))
	main_vbox.add_child(sep1)

	# Customer info panel
	var customer_panel := PanelContainer.new()
	customer_panel.add_theme_stylebox_override("panel", UITheme.create_panel_stylebox(UITheme.BG_DARK, 1))
	main_vbox.add_child(customer_panel)

	var customer_hbox := HBoxContainer.new()
	customer_hbox.add_theme_constant_override("separation", 15)
	customer_panel.add_child(customer_hbox)

	_customer_portrait = Label.new()
	_customer_portrait.custom_minimum_size = Vector2(60, 60)
	_customer_portrait.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_customer_portrait.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_customer_portrait.add_theme_font_size_override("font_size", 40)
	customer_hbox.add_child(_customer_portrait)

	var customer_info := VBoxContainer.new()
	customer_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	customer_hbox.add_child(customer_info)

	_customer_name = Label.new()
	UITheme.style_label(_customer_name, UITheme.FONT_HEADER, UITheme.TEXT_PRIMARY)
	customer_info.add_child(_customer_name)

	_customer_mood = Label.new()
	UITheme.style_label(_customer_mood, UITheme.FONT_BODY, UITheme.TEXT_SECONDARY)
	customer_info.add_child(_customer_mood)

	# Item display section
	var item_label := Label.new()
	item_label.text = "المنتج المعروض:"
	UITheme.style_label(item_label, UITheme.FONT_BODY, UITheme.ACCENT_GOLD)
	main_vbox.add_child(item_label)

	var item_panel := PanelContainer.new()
	item_panel.add_theme_stylebox_override("panel", UITheme.create_panel_stylebox(UITheme.BG_DARK, 1))
	main_vbox.add_child(item_panel)

	_item_display = VBoxContainer.new()
	_item_display.add_theme_constant_override("separation", 8)
	item_panel.add_child(_item_display)

	# Price controls
	var price_panel := PanelContainer.new()
	price_panel.add_theme_stylebox_override("panel", UITheme.create_panel_stylebox(UITheme.BG_DARK, 1))
	main_vbox.add_child(price_panel)

	var price_vbox := VBoxContainer.new()
	price_vbox.add_theme_constant_override("separation", 10)
	price_panel.add_child(price_vbox)

	var price_hbox := HBoxContainer.new()
	price_hbox.add_theme_constant_override("separation", 15)
	price_vbox.add_child(price_hbox)

	var price_label := Label.new()
	price_label.text = "السعر المطلوب:"
	UITheme.style_label(price_label, UITheme.FONT_BODY, UITheme.TEXT_PRIMARY)
	price_hbox.add_child(price_label)

	_price_spin = SpinBox.new()
	_price_spin.min_value = 1
	_price_spin.max_value = 10000
	_price_spin.custom_minimum_size = Vector2(120, 0)
	_price_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_price_spin.value_changed.connect(_on_price_changed)
	price_hbox.add_child(_price_spin)

	var gold_label := Label.new()
	gold_label.text = "ذهب"
	UITheme.style_label(gold_label, UITheme.FONT_BODY, UITheme.ACCENT_GOLD)
	price_hbox.add_child(gold_label)

	_fair_price_label = Label.new()
	UITheme.style_label(_fair_price_label, UITheme.FONT_SMALL, UITheme.TEXT_MUTED)
	_fair_price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_vbox.add_child(_fair_price_label)

	# Response area
	var response_panel := PanelContainer.new()
	response_panel.add_theme_stylebox_override("panel", UITheme.create_panel_stylebox(UITheme.BG_PANEL, 1))
	response_panel.custom_minimum_size = Vector2(0, 80)
	main_vbox.add_child(response_panel)

	_response_label = Label.new()
	UITheme.style_label(_response_label, UITheme.FONT_BODY, UITheme.TEXT_PRIMARY)
	_response_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_response_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_response_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	response_panel.add_child(_response_label)

	# Separator
	var sep2 := HSeparator.new()
	sep2.add_theme_stylebox_override("separator", UITheme.create_flat_stylebox(UITheme.BORDER))
	main_vbox.add_child(sep2)

	# Buttons
	var btn_hbox := HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 12)
	main_vbox.add_child(btn_hbox)

	_offer_button = Button.new()
	_offer_button.text = "قدم العرض"
	_offer_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_offer_button.custom_minimum_size = Vector2(0, 45)
	_offer_button.pressed.connect(_on_offer_pressed)
	UITheme.style_button(_offer_button, UITheme.INFO.darkened(0.4))
	btn_hbox.add_child(_offer_button)

	_accept_button = Button.new()
	_accept_button.text = "قبول"
	_accept_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_accept_button.custom_minimum_size = Vector2(0, 45)
	_accept_button.visible = false
	_accept_button.pressed.connect(_on_accept_pressed)
	UITheme.style_button(_accept_button, UITheme.SUCCESS.darkened(0.4))
	btn_hbox.add_child(_accept_button)

	_reject_button = Button.new()
	_reject_button.text = "رفض"
	_reject_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reject_button.custom_minimum_size = Vector2(0, 45)
	_reject_button.visible = false
	_reject_button.pressed.connect(_on_reject_pressed)
	UITheme.style_button(_reject_button, UITheme.ERROR.darkened(0.4))
	btn_hbox.add_child(_reject_button)

	_close_button = Button.new()
	_close_button.text = "إغلاق"
	_close_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_close_button.custom_minimum_size = Vector2(0, 45)
	_close_button.pressed.connect(func(): sale_cancelled.emit(); queue_free())
	UITheme.style_button(_close_button, UITheme.BG_LIGHT)
	btn_hbox.add_child(_close_button)

func setup(c: CustomerData, item: InventoryItem) -> void:
	customer = c
	inventory_item = item
	fair_price = EconomyManager.get_fair_price(item.item_data, item.quality)
	asking_price = item.listed_price
	_update_display()

func _update_display() -> void:
	if not customer or not inventory_item or not _customer_portrait:
		return

	_customer_portrait.text = customer.portrait_char
	_customer_name.text = customer.name_ar
	_update_mood_display()

	# Item display
	for child in _item_display.get_children():
		child.queue_free()

	var item_hbox := HBoxContainer.new()
	item_hbox.add_theme_constant_override("separation", 12)
	_item_display.add_child(item_hbox)

	var icon := Label.new()
	icon.text = inventory_item.item_data.icon_char
	icon.add_theme_font_size_override("font_size", 32)
	icon.add_theme_color_override("font_color", UITheme.get_rarity_color(inventory_item.item_data.rarity))
	item_hbox.add_child(icon)

	var item_info := VBoxContainer.new()
	item_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_hbox.add_child(item_info)

	var name_lbl := Label.new()
	name_lbl.text = inventory_item.item_data.name_ar
	UITheme.style_label(name_lbl, UITheme.FONT_BODY, UITheme.get_rarity_color(inventory_item.item_data.rarity))
	item_info.add_child(name_lbl)

	var quality_lbl := Label.new()
	quality_lbl.text = "الجودة: %s | الكمية: %d" % [Enums.get_quality_name(inventory_item.quality), inventory_item.quantity]
	UITheme.style_label(quality_lbl, UITheme.FONT_SMALL, UITheme.get_quality_color(inventory_item.quality))
	item_info.add_child(quality_lbl)

	_price_spin.value = asking_price
	_fair_price_label.text = "💡 السعر العادل: %d ذهب" % fair_price

func _update_mood_display() -> void:
	var mood_text := ""
	var mood_color := Color.WHITE
	match customer.current_mood:
		Enums.CustomerMood.HAPPY:
			mood_text = "😊 سعيد - مستعد للشراء"
			mood_color = UITheme.SUCCESS
		Enums.CustomerMood.NEUTRAL:
			mood_text = "😐 محايد"
			mood_color = UITheme.TEXT_SECONDARY
		Enums.CustomerMood.ANNOYED:
			mood_text = "😠 منزعج - حذر!"
			mood_color = UITheme.WARNING
		Enums.CustomerMood.ANGRY:
			mood_text = "😡 غاضب جداً!"
			mood_color = UITheme.ERROR

	_customer_mood.text = mood_text
	_customer_mood.add_theme_color_override("font_color", mood_color)

func _on_price_changed(value: float) -> void:
	asking_price = int(value)

func _on_offer_pressed() -> void:
	var result := CustomerSystem.attempt_purchase(customer, inventory_item, asking_price)
	negotiation_round += 1

	_response_label.text = "\"%s\"" % result.message

	if result.success:
		_response_label.add_theme_color_override("font_color", UITheme.SUCCESS)
		_show_accept_mode(result.final_price)
	elif result.negotiated:
		_response_label.add_theme_color_override("font_color", UITheme.WARNING)
		_response_label.text += "\n(سعر مقترح: %d ذهب)" % result.final_price
		_show_negotiation_mode(result.final_price)
	else:
		_response_label.add_theme_color_override("font_color", UITheme.ERROR)
		if customer.current_mood == Enums.CustomerMood.ANGRY:
			_offer_button.disabled = true
			customer_left_angry.emit()
			await get_tree().create_timer(1.5).timeout
			queue_free()

	_update_mood_display()

func _show_accept_mode(final_price: int) -> void:
	asking_price = final_price
	_offer_button.visible = false
	_accept_button.visible = true
	_reject_button.visible = false

func _show_negotiation_mode(suggested_price: int) -> void:
	if negotiation_round >= max_negotiations:
		_response_label.text += "\n(آخر فرصة للتفاوض!)"

	_offer_button.visible = negotiation_round < max_negotiations
	_accept_button.visible = true
	_reject_button.visible = true
	asking_price = suggested_price

func _on_accept_pressed() -> void:
	CustomerSystem.complete_transaction(customer, inventory_item, asking_price)
	sale_completed.emit(inventory_item, asking_price)
	queue_free()

func _on_reject_pressed() -> void:
	customer.update_mood(-1)
	_update_mood_display()

	if customer.current_mood == Enums.CustomerMood.ANGRY:
		customer_left_angry.emit()
		await get_tree().create_timer(1.0).timeout
		queue_free()
	else:
		_response_label.text = "الزبون لم يعجبه الرفض..."
		_response_label.add_theme_color_override("font_color", UITheme.WARNING)
		_offer_button.visible = true
		_accept_button.visible = false
		_reject_button.visible = false
