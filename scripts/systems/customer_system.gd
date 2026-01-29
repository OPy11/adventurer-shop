extends Node

## Manages customer generation, behavior, and transactions

signal customer_spawned(customer: CustomerData)
signal customer_left(customer: CustomerData, result: Enums.TransactionResult)
signal negotiation_started(customer: CustomerData, item: InventoryItem)

const CUSTOMER_NAMES: Array[String] = [
	"خالد", "محمد", "أحمد", "عمر", "سعيد", "يوسف", "علي", "حسن",
	"فاطمة", "عائشة", "مريم", "سارة", "نور", "ليلى", "هند", "زينب"
]

var spawn_timer: float = 0.0
var spawn_interval: float = 30.0 # Seconds between customer spawns
var max_customers: int = 3
var current_customers: Array[CustomerData] = []

func _ready() -> void:
	print("[CustomerSystem] Initialized")
	TimeManager.shop_hours_changed.connect(_on_shop_hours_changed)

func _process(delta: float) -> void:
	if not GameManager.is_shop_open:
		return

	spawn_timer += delta
	if spawn_timer >= spawn_interval and current_customers.size() < max_customers:
		spawn_timer = 0.0
		_spawn_customer()

func _spawn_customer() -> void:
	var customer := _generate_customer()
	current_customers.append(customer)
	customer_spawned.emit(customer)
	GameManager.notify("دخل زبون جديد: %s" % customer.name_ar, "info")

func _generate_customer() -> CustomerData:
	var customer := CustomerData.new()
	customer.id = "customer_%d" % randi()
	customer.name_ar = CUSTOMER_NAMES[randi() % CUSTOMER_NAMES.size()]

	# Determine customer type based on shop reputation
	var type_roll := randf()
	if GameManager.reputation > 80:
		# High reputation attracts better customers
		if type_roll < 0.2:
			customer.customer_type = Enums.CustomerType.VETERAN_ADVENTURER
		elif type_roll < 0.5:
			customer.customer_type = Enums.CustomerType.KNIGHT
		elif type_roll < 0.7:
			customer.customer_type = Enums.CustomerType.MAGE
		else:
			customer.customer_type = Enums.CustomerType.EXPERIENCED_ADVENTURER
	elif GameManager.reputation > 50:
		if type_roll < 0.3:
			customer.customer_type = Enums.CustomerType.EXPERIENCED_ADVENTURER
		elif type_roll < 0.5:
			customer.customer_type = Enums.CustomerType.KNIGHT
		else:
			customer.customer_type = Enums.CustomerType.BEGINNER_ADVENTURER
	else:
		# Low reputation mostly gets beginners
		if type_roll < 0.7:
			customer.customer_type = Enums.CustomerType.BEGINNER_ADVENTURER
		else:
			customer.customer_type = Enums.CustomerType.EXPERIENCED_ADVENTURER

	# Set budget based on customer type
	var budget_range := customer.get_budget_range()
	customer.budget = randi_range(budget_range.min, budget_range.max)

	# Set other attributes
	customer.patience = randf_range(0.5, 1.5)
	customer.haggle_skill = randf_range(0.1, 0.7)
	customer.portrait_char = _get_portrait_for_type(customer.customer_type)

	# Determine what they want
	customer.wanted_items = _generate_wanted_items(customer.customer_type, customer.budget)

	# Set price tolerance based on type
	match customer.customer_type:
		Enums.CustomerType.BEGINNER_ADVENTURER:
			customer.price_tolerance = 1.1
		Enums.CustomerType.MERCHANT:
			customer.price_tolerance = 1.05
		Enums.CustomerType.KNIGHT:
			customer.price_tolerance = 1.3
		_:
			customer.price_tolerance = 1.2

	return customer

func _get_portrait_for_type(type: Enums.CustomerType) -> String:
	match type:
		Enums.CustomerType.BEGINNER_ADVENTURER: return "🧑"
		Enums.CustomerType.EXPERIENCED_ADVENTURER: return "🧔"
		Enums.CustomerType.VETERAN_ADVENTURER: return "🦸"
		Enums.CustomerType.KNIGHT: return "🤴"
		Enums.CustomerType.MAGE: return "🧙"
		Enums.CustomerType.MERCHANT: return "👔"
		_: return "👤"

func _generate_wanted_items(type: Enums.CustomerType, budget: int) -> Array[String]:
	var wanted: Array[String] = []
	var all_items := DataRegistry.items.values()

	# Filter by budget and appropriateness
	var affordable: Array[ItemData] = []
	for item: ItemData in all_items:
		if item.base_price <= budget * 0.8:
			affordable.append(item)

	if affordable.is_empty():
		return wanted

	# Pick 1-3 items based on customer type
	var num_items := 1
	match type:
		Enums.CustomerType.MERCHANT:
			num_items = randi_range(2, 3)
		Enums.CustomerType.VETERAN_ADVENTURER, Enums.CustomerType.KNIGHT:
			num_items = randi_range(1, 2)
		_:
			num_items = 1

	affordable.shuffle()
	for i in range(mini(num_items, affordable.size())):
		wanted.append(affordable[i].id)

	return wanted

func attempt_purchase(customer: CustomerData, item: InventoryItem, asking_price: int) -> Dictionary:
	var fair_price := EconomyManager.get_fair_price(item.item_data, item.quality)
	var evaluation := customer.evaluate_price(asking_price, fair_price, GameManager.reputation)

	var result := {
		"success": false,
		"negotiated": false,
		"final_price": asking_price,
		"message": evaluation.message,
		"reputation_change": 0
	}

	if evaluation.will_buy:
		result.success = true
		result.final_price = asking_price
		if evaluation.mood_change > 0:
			result.reputation_change = 2
		elif evaluation.mood_change < 0:
			result.reputation_change = -1
	elif evaluation.will_negotiate:
		result.negotiated = true
		# Calculate negotiated price
		var discount := randf_range(0.05, 0.15) * customer.haggle_skill
		result.final_price = int(asking_price * (1.0 - discount))

	customer.update_mood(evaluation.mood_change)

	return result

func complete_transaction(customer: CustomerData, item: InventoryItem, final_price: int) -> void:
	GameManager.add_gold(final_price)
	GameManager.remove_from_inventory(item, 1)
	GameManager.record_sale(final_price, customer.current_mood <= Enums.CustomerMood.NEUTRAL)

	var rep_change := 0
	match customer.current_mood:
		Enums.CustomerMood.HAPPY:
			rep_change = 3
		Enums.CustomerMood.NEUTRAL:
			rep_change = 1
		Enums.CustomerMood.ANNOYED:
			rep_change = -1
		Enums.CustomerMood.ANGRY:
			rep_change = -3

	GameManager.modify_reputation(rep_change)
	remove_customer(customer, Enums.TransactionResult.PURCHASED)

func customer_leaves_angry(customer: CustomerData) -> void:
	GameManager.modify_reputation(-5)
	GameManager.stats.angry_customers += 1
	remove_customer(customer, Enums.TransactionResult.LEFT_ANGRY)
	GameManager.notify("%s غادر غاضباً!" % customer.name_ar, "error")

func remove_customer(customer: CustomerData, result: Enums.TransactionResult) -> void:
	var idx := current_customers.find(customer)
	if idx >= 0:
		current_customers.remove_at(idx)
	customer_left.emit(customer, result)

func _on_shop_hours_changed(is_open: bool) -> void:
	if not is_open:
		# Clear all customers when shop closes
		for customer in current_customers.duplicate():
			remove_customer(customer, Enums.TransactionResult.REJECTED)
		spawn_timer = 0.0

func get_waiting_customers() -> Array[CustomerData]:
	return current_customers

func set_spawn_interval(seconds: float) -> void:
	spawn_interval = maxf(5.0, seconds)
