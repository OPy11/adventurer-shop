extends Node

## Manages supplier contracts and crafting orders

signal order_placed(supplier: SupplierData, item: ItemData, quantity: int)
signal order_completed(supplier: SupplierData, item: ItemData, success: bool)
signal supplier_available(supplier: SupplierData)

var active_orders: Dictionary = {} # supplier_id: order_data

func _ready() -> void:
	print("[SupplierSystem] Initialized")

func get_available_suppliers() -> Array[SupplierData]:
	var available: Array[SupplierData] = []
	for supplier: SupplierData in DataRegistry.suppliers.values():
		if supplier.is_available:
			available.append(supplier)
	return available

func get_supplier_for_item(item: ItemData) -> Array[SupplierData]:
	var suitable: Array[SupplierData] = []
	for supplier: SupplierData in DataRegistry.suppliers.values():
		# Check if supplier type matches item category
		var type_matches := false
		match item.category:
			Enums.ItemCategory.WEAPON, Enums.ItemCategory.ARMOR:
				type_matches = supplier.supplier_type == Enums.SupplierType.BLACKSMITH
			Enums.ItemCategory.POTION:
				type_matches = supplier.supplier_type == Enums.SupplierType.ALCHEMIST
			Enums.ItemCategory.ACCESSORY:
				type_matches = supplier.supplier_type in [Enums.SupplierType.ENCHANTER, Enums.SupplierType.BLACKSMITH]
			_:
				type_matches = true

		if type_matches and supplier.is_available:
			suitable.append(supplier)

	return suitable

func calculate_order_cost(supplier: SupplierData, item: ItemData, quantity: int) -> Dictionary:
	var material_cost := 0
	for mat_id in item.required_materials:
		var mat: MaterialData = DataRegistry.get_material(mat_id)
		if mat:
			var qty: int = item.required_materials[mat_id] * quantity
			material_cost += EconomyManager.get_material_price(mat_id, mat.base_price) * qty

	var labor_cost := supplier.calculate_order_cost(item, quantity)
	var craft_time := supplier.get_crafting_time(item.crafting_time_hours) * quantity

	return {
		"material_cost": material_cost,
		"labor_cost": labor_cost,
		"total_cost": material_cost + labor_cost,
		"craft_time_hours": craft_time,
		"expected_quality": supplier.get_effective_quality(),
		"success_rate": _calculate_success_rate(supplier, item)
	}

func _calculate_success_rate(supplier: SupplierData, item: ItemData) -> float:
	var base := supplier.mastery
	var specialty_bonus := 0.1 if item.id in supplier.specialties else 0.0
	var rarity_penalty := item.rarity * 0.05
	return clampf(base + specialty_bonus - rarity_penalty, 0.3, 0.99)

func can_place_order(supplier: SupplierData, item: ItemData, quantity: int) -> Dictionary:
	var result := {"can_order": true, "reason": ""}

	if not supplier.is_available:
		result.can_order = false
		result.reason = "المورد مشغول حالياً"
		return result

	# Check materials
	for mat_id in item.required_materials:
		var required: int = item.required_materials[mat_id] * quantity
		var available: int = GameManager.materials.get(mat_id, 0)
		if available < required:
			result.can_order = false
			var mat: MaterialData = DataRegistry.get_material(mat_id)
			result.reason = "لا يوجد مواد كافية: %s (متوفر: %d، مطلوب: %d)" % [
				mat.name_ar if mat else mat_id, available, required
			]
			return result

	# Check gold
	var cost := calculate_order_cost(supplier, item, quantity)
	if GameManager.gold < cost.total_cost:
		result.can_order = false
		result.reason = "لا يوجد ذهب كافٍ (مطلوب: %d)" % cost.total_cost
		return result

	return result

func place_order(supplier: SupplierData, item: ItemData, quantity: int) -> bool:
	var check := can_place_order(supplier, item, quantity)
	if not check.can_order:
		GameManager.notify(check.reason, "error")
		return false

	var cost := calculate_order_cost(supplier, item, quantity)

	# Consume materials
	for mat_id in item.required_materials:
		var required: int = item.required_materials[mat_id] * quantity
		GameManager.remove_material(mat_id, required)

	# Pay cost
	GameManager.remove_gold(cost.total_cost)

	# Mark supplier as busy
	supplier.is_available = false

	# Schedule completion
	var current_time := GameManager.current_day * 24 + TimeManager.current_hour
	var completion_time := current_time + int(ceil(cost.craft_time_hours))

	var order := {
		"supplier": supplier,
		"item": item,
		"quantity": quantity,
		"quality": cost.expected_quality,
		"cost": cost.total_cost,
		"success_rate": cost.success_rate,
		"completion_time": completion_time,
		"placed_day": GameManager.current_day
	}

	active_orders[supplier.id] = order
	TimeManager.schedule_order(order)

	supplier.current_order = order
	order_placed.emit(supplier, item, quantity)
	GameManager.notify("تم طلب %d × %s من %s" % [quantity, item.name_ar, supplier.name_ar], "success")

	return true

func complete_order(supplier_id: String, success: bool) -> void:
	if supplier_id not in active_orders:
		return

	var order: Dictionary = active_orders[supplier_id]
	var supplier: SupplierData = order.supplier

	supplier.is_available = true
	supplier.current_order = {}
	active_orders.erase(supplier_id)

	order_completed.emit(supplier, order.item, success)
	supplier_available.emit(supplier)

func get_active_orders() -> Array[Dictionary]:
	var orders: Array[Dictionary] = []
	for order in active_orders.values():
		orders.append(order)
	return orders

func get_order_progress(supplier_id: String) -> float:
	if supplier_id not in active_orders:
		return 0.0

	var order: Dictionary = active_orders[supplier_id]
	var current_time := GameManager.current_day * 24 + TimeManager.current_hour
	var start_time := order.placed_day * 24
	var total_time := order.completion_time - start_time
	var elapsed := current_time - start_time

	return clampf(float(elapsed) / float(total_time), 0.0, 1.0)

func cancel_order(supplier_id: String) -> bool:
	if supplier_id not in active_orders:
		return false

	var order: Dictionary = active_orders[supplier_id]
	var supplier: SupplierData = order.supplier

	# Partial refund (50%)
	var refund := int(order.cost * 0.5)
	GameManager.add_gold(refund)

	supplier.is_available = true
	supplier.current_order = {}
	active_orders.erase(supplier_id)

	GameManager.notify("تم إلغاء الطلب. استرداد %d ذهب" % refund, "warning")
	return true
