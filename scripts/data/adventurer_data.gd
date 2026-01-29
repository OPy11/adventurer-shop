class_name AdventurerData
extends Resource

@export var id: String = ""
@export var name_ar: String = ""
@export var rank: int = 1 # 1-5, determines mission capability
@export var hire_cost: int = 50
@export var success_rate: float = 0.7 # Base success rate
@export var speed: float = 1.0 # Mission time multiplier
@export var portrait_char: String = "A"
@export var specialty: String = "" # Dungeon type they excel at

var is_available: bool = true
var current_mission: Dictionary = {}
var return_time: float = 0.0

func get_rank_name() -> String:
	match rank:
		1: return "مبتدئ"
		2: return "فضي"
		3: return "ذهبي"
		4: return "بلاتيني"
		5: return "أسطوري"
		_: return "غير مصنف"

func get_rank_color() -> Color:
	match rank:
		1: return Color.GRAY
		2: return Color.SILVER
		3: return Color.GOLD
		4: return Color.CYAN
		5: return Color.MEDIUM_PURPLE
		_: return Color.WHITE

func calculate_mission_success(difficulty: Enums.MissionDifficulty, dungeon_type: String) -> float:
	var base := success_rate
	var rank_bonus := (rank - 1) * 0.1
	var specialty_bonus := 0.15 if dungeon_type == specialty else 0.0

	var difficulty_penalty := 0.0
	match difficulty:
		Enums.MissionDifficulty.EASY: difficulty_penalty = 0.0
		Enums.MissionDifficulty.MEDIUM: difficulty_penalty = 0.15
		Enums.MissionDifficulty.HARD: difficulty_penalty = 0.3
		Enums.MissionDifficulty.DEADLY: difficulty_penalty = 0.5

	return clampf(base + rank_bonus + specialty_bonus - difficulty_penalty, 0.1, 0.95)

func get_mission_duration(base_hours: float) -> float:
	return base_hours / speed
