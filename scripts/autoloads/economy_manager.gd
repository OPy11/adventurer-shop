extends Node

## Manages market prices, scarcity, and economic simulation

signal market_updated()
signal price_changed(item_id: String, new_price: int)

# Market state
var base_prices: Dictionary = {} # item_id: base_price
var current_prices: Dictionary = {} # item_id: current_price
var material_scarcity: Dictionary = {} # material_id: scarcity (0.5-2.0)
var demand_levels: Dictionary = {} # item_id: demand (0.5-2.0)

# Market trends
var trend_direction: int = 0 # -1, 0, 1
var season: String = "normal" # normal, war, festival, plague

# Price history for graphs
var price_history: Dictionary = {} # item_id: [prices]
const MAX_HISTORY := 30

func _ready() -> void:
	print("[EconomyManager] Initialized")
	_initialize_market()

func _initialize_market() -> void:
	# Will be populated from DataRegistry
	material_scarcity = {}
	demand_levels = {}

func register_item(item_id: String, base_price: int) -> void:
	base_prices[item_id] = base_price
	current_prices[item_id] = base_price
	demand_levels[item_id] = 1.0
	price_history[item_id] = [base_price]

func register_material(material_id: String) -> void:
	material_scarcity[material_id] = 1.0

func update_market() -> void:
	# Daily market fluctuation
	_apply_random_fluctuation()
	_apply_season_effects()
	_update_scarcity()
	_record_history()
	market_updated.emit()

func _apply_random_fluctuation() -> void:
	for item_id in base_prices:
		var fluctuation := randf_range(-0.1, 0.1)
		var demand := demand_levels.get(item_id, 1.0)
		var new_price := base_prices[item_id] * (1.0 + fluctuation) * demand
		current_prices[item_id] = int(clampf(new_price, base_prices[item_id] * 0.5, base_prices[item_id] * 2.0))

func _apply_season_effects() -> void:
	match season:
		"war":
			# Weapons more valuable
			for item_id in current_prices:
				if "sword" in item_id or "armor" in item_id or "shield" in item_id:
					current_prices[item_id] = int(current_prices[item_id] * 1.5)
		"festival":
			# Potions and accessories popular
			for item_id in current_prices:
				if "potion" in item_id or "ring" in item_id:
					current_prices[item_id] = int(current_prices[item_id] * 1.3)
		"plague":
			# Healing items skyrocket
			for item_id in current_prices:
				if "heal" in item_id or "cure" in item_id:
					current_prices[item_id] = int(current_prices[item_id] * 2.0)

func _update_scarcity() -> void:
	for mat_id in material_scarcity:
		var current_stock := GameManager.materials.get(mat_id, 0)
		# Scarcity increases when stock is low
		if current_stock < 5:
			material_scarcity[mat_id] = minf(material_scarcity[mat_id] + 0.1, 2.0)
		elif current_stock > 20:
			material_scarcity[mat_id] = maxf(material_scarcity[mat_id] - 0.05, 0.5)

func _record_history() -> void:
	for item_id in current_prices:
		if item_id not in price_history:
			price_history[item_id] = []
		price_history[item_id].append(current_prices[item_id])
		if price_history[item_id].size() > MAX_HISTORY:
			price_history[item_id].pop_front()

func get_market_price(item_id: String) -> int:
	return current_prices.get(item_id, base_prices.get(item_id, 100))

func get_material_price(material_id: String, base_price: int) -> int:
	var scarcity := material_scarcity.get(material_id, 1.0)
	return int(base_price * scarcity)

func get_fair_price(item: ItemData, quality: Enums.Quality) -> int:
	var market_price := get_market_price(item.id)
	var quality_mult := Enums.get_quality_multiplier(quality)
	return int(market_price * quality_mult)

func set_demand(item_id: String, demand: float) -> void:
	demand_levels[item_id] = clampf(demand, 0.5, 2.0)

func change_season(new_season: String) -> void:
	season = new_season
	update_market()
	GameManager.notify("تغير الموسم: %s" % _get_season_name(new_season), "info")

func _get_season_name(s: String) -> String:
	match s:
		"war": return "موسم الحرب"
		"festival": return "موسم الاحتفالات"
		"plague": return "موسم الوباء"
		_: return "موسم عادي"

func get_price_trend(item_id: String) -> int:
	if item_id not in price_history:
		return 0
	var history: Array = price_history[item_id]
	if history.size() < 2:
		return 0
	var recent := history[-1]
	var previous := history[-2]
	if recent > previous * 1.05:
		return 1 # Rising
	elif recent < previous * 0.95:
		return -1 # Falling
	return 0 # Stable

func get_trend_icon(item_id: String) -> String:
	var trend := get_price_trend(item_id)
	match trend:
		1: return "↑"
		-1: return "↓"
		_: return "→"

func simulate_competition() -> void:
	# Competitors affect demand
	for item_id in demand_levels:
		if randf() < 0.1: # 10% chance of competition event
			var change := randf_range(-0.2, 0.2)
			demand_levels[item_id] = clampf(demand_levels[item_id] + change, 0.5, 2.0)
			if change < -0.1:
				GameManager.notify("المنافسون يخفضون أسعار بعض البضائع!", "warning")
