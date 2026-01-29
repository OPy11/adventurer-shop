extends Node

## Manages the Adventurer's Guild and material gathering missions

signal adventurer_hired(adventurer: AdventurerData)
signal mission_started(adventurer: AdventurerData, dungeon: Dictionary)
signal mission_completed(adventurer: AdventurerData, success: bool, rewards: Dictionary)

const ADVENTURER_NAMES: Array[String] = [
	"سيف الليل", "الصياد الصامت", "نجمة الفجر", "ظل الموت",
	"فارس العاصفة", "ملكة الغابة", "صائد التنانين", "حارس البوابة"
]

var available_adventurers: Array[AdventurerData] = []
var hired_adventurers: Array[AdventurerData] = []
var active_missions: Dictionary = {} # adventurer_id: mission_data

func _ready() -> void:
	print("[GuildSystem] Initialized")
	_generate_initial_adventurers()

func _generate_initial_adventurers() -> void:
	# Generate some starting adventurers
	for i in range(5):
		var adventurer := _create_random_adventurer()
		available_adventurers.append(adventurer)

func _create_random_adventurer() -> AdventurerData:
	var adv := AdventurerData.new()
	adv.id = "adv_%d" % randi()
	adv.name_ar = ADVENTURER_NAMES[randi() % ADVENTURER_NAMES.size()]
	adv.rank = randi_range(1, 3)
	adv.hire_cost = 30 + adv.rank * 40
	adv.success_rate = 0.5 + adv.rank * 0.1
	adv.speed = 0.8 + randf() * 0.4
	adv.portrait_char = ["⚔", "🏹", "🪄", "🛡"][randi() % 4]

	# Random specialty
	var dungeons := DataRegistry.dungeons.keys()
	if not dungeons.is_empty():
		adv.specialty = dungeons[randi() % dungeons.size()]

	return adv

func refresh_available_adventurers() -> void:
	# Add new adventurers occasionally
	if available_adventurers.size() < 8:
		var new_adv := _create_random_adventurer()
		# Higher rank adventurers appear based on reputation
		if GameManager.reputation > 70:
			new_adv.rank = randi_range(2, 5)
		elif GameManager.reputation > 40:
			new_adv.rank = randi_range(1, 3)
		else:
			new_adv.rank = randi_range(1, 2)

		new_adv.hire_cost = 30 + new_adv.rank * 40
		new_adv.success_rate = 0.5 + new_adv.rank * 0.1
		available_adventurers.append(new_adv)
		GameManager.notify("مغامر جديد وصل للنقابة: %s" % new_adv.name_ar, "info")

func hire_adventurer(adventurer: AdventurerData) -> bool:
	if adventurer not in available_adventurers:
		return false

	if not GameManager.remove_gold(adventurer.hire_cost):
		GameManager.notify("لا يوجد ذهب كافٍ لتوظيف %s" % adventurer.name_ar, "error")
		return false

	available_adventurers.erase(adventurer)
	hired_adventurers.append(adventurer)
	adventurer_hired.emit(adventurer)
	GameManager.notify("تم توظيف %s!" % adventurer.name_ar, "success")
	return true

func fire_adventurer(adventurer: AdventurerData) -> bool:
	if adventurer not in hired_adventurers:
		return false

	if not adventurer.is_available:
		GameManager.notify("%s في مهمة حالياً!" % adventurer.name_ar, "error")
		return false

	hired_adventurers.erase(adventurer)
	available_adventurers.append(adventurer)
	GameManager.notify("تم إقالة %s" % adventurer.name_ar, "warning")
	return true

func can_start_mission(adventurer: AdventurerData, dungeon_id: String) -> Dictionary:
	var result := {"can_start": true, "reason": ""}

	if adventurer not in hired_adventurers:
		result.can_start = false
		result.reason = "المغامر غير موظف"
		return result

	if not adventurer.is_available:
		result.can_start = false
		result.reason = "المغامر في مهمة أخرى"
		return result

	var dungeon := DataRegistry.get_dungeon(dungeon_id)
	if dungeon.is_empty():
		result.can_start = false
		result.reason = "الدنجن غير موجود"
		return result

	# Check if adventurer rank is sufficient
	var min_rank := 1
	match dungeon.difficulty:
		Enums.MissionDifficulty.MEDIUM:
			min_rank = 2
		Enums.MissionDifficulty.HARD:
			min_rank = 3
		Enums.MissionDifficulty.DEADLY:
			min_rank = 4

	if adventurer.rank < min_rank:
		result.can_start = false
		result.reason = "رتبة المغامر منخفضة جداً (مطلوب: %s)" % _get_rank_name(min_rank)
		return result

	return result

func _get_rank_name(rank: int) -> String:
	match rank:
		1: return "مبتدئ"
		2: return "فضي"
		3: return "ذهبي"
		4: return "بلاتيني"
		5: return "أسطوري"
		_: return "غير معروف"

func start_mission(adventurer: AdventurerData, dungeon_id: String) -> bool:
	var check := can_start_mission(adventurer, dungeon_id)
	if not check.can_start:
		GameManager.notify(check.reason, "error")
		return false

	var dungeon := DataRegistry.get_dungeon(dungeon_id)

	adventurer.is_available = false
	var current_time := GameManager.current_day * 24 + TimeManager.current_hour
	var duration := adventurer.get_mission_duration(dungeon.duration_hours)
	var return_time := current_time + int(ceil(duration))

	var success_rate := adventurer.calculate_mission_success(
		dungeon.difficulty,
		dungeon_id
	)

	var mission := {
		"adventurer": adventurer,
		"dungeon": dungeon,
		"dungeon_id": dungeon_id,
		"success_rate": success_rate,
		"return_time": return_time,
		"rewards": dungeon.rewards.duplicate(),
		"started_day": GameManager.current_day
	}

	active_missions[adventurer.id] = mission
	TimeManager.schedule_mission(mission)

	mission_started.emit(adventurer, dungeon)
	GameManager.notify("%s انطلق إلى %s" % [adventurer.name_ar, dungeon.name_ar], "info")

	return true

func complete_mission(adventurer_id: String, success: bool, actual_rewards: Dictionary) -> void:
	if adventurer_id not in active_missions:
		return

	var mission: Dictionary = active_missions[adventurer_id]
	var adventurer: AdventurerData = mission.adventurer

	adventurer.is_available = true
	active_missions.erase(adventurer_id)

	mission_completed.emit(adventurer, success, actual_rewards)

func get_mission_progress(adventurer_id: String) -> float:
	if adventurer_id not in active_missions:
		return 0.0

	var mission: Dictionary = active_missions[adventurer_id]
	var current_time := GameManager.current_day * 24 + TimeManager.current_hour
	var start_time := mission.started_day * 24
	var total_time := mission.return_time - start_time
	var elapsed := current_time - start_time

	return clampf(float(elapsed) / float(total_time), 0.0, 1.0)

func get_mission_info(adventurer: AdventurerData, dungeon_id: String) -> Dictionary:
	var dungeon := DataRegistry.get_dungeon(dungeon_id)
	if dungeon.is_empty():
		return {}

	var success_rate := adventurer.calculate_mission_success(
		dungeon.difficulty,
		dungeon_id
	)
	var duration := adventurer.get_mission_duration(dungeon.duration_hours)

	return {
		"dungeon_name": dungeon.name_ar,
		"difficulty": dungeon.difficulty,
		"duration_hours": duration,
		"success_rate": success_rate,
		"risk": dungeon.risk,
		"potential_rewards": dungeon.rewards
	}

func get_available_dungeons() -> Array[Dictionary]:
	var dungeons: Array[Dictionary] = []
	for dungeon in DataRegistry.dungeons.values():
		dungeons.append(dungeon)
	return dungeons

func get_active_missions() -> Array[Dictionary]:
	var missions: Array[Dictionary] = []
	for mission in active_missions.values():
		missions.append(mission)
	return missions
