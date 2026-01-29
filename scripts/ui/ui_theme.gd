class_name UITheme
extends RefCounted

## Medieval Fantasy theme colors and styles

# Colors
const BG_DARK := Color("#1a1a2e")
const BG_MEDIUM := Color("#16213e")
const BG_LIGHT := Color("#0f3460")
const BG_PANEL := Color("#1f2937")

const ACCENT_GOLD := Color("#d4af37")
const ACCENT_BRONZE := Color("#cd7f32")
const ACCENT_SILVER := Color("#c0c0c0")

const TEXT_PRIMARY := Color("#f5f5f5")
const TEXT_SECONDARY := Color("#9ca3af")
const TEXT_MUTED := Color("#6b7280")

const SUCCESS := Color("#10b981")
const WARNING := Color("#f59e0b")
const ERROR := Color("#ef4444")
const INFO := Color("#3b82f6")

const BORDER := Color("#374151")
const BORDER_HIGHLIGHT := Color("#4b5563")

# Rarity colors
const RARITY_COMMON := Color("#9ca3af")
const RARITY_UNCOMMON := Color("#22c55e")
const RARITY_RARE := Color("#3b82f6")
const RARITY_EPIC := Color("#a855f7")
const RARITY_LEGENDARY := Color("#f59e0b")

static func create_panel_stylebox(bg_color: Color = BG_PANEL, border_width: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = BORDER
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	return style

static func create_button_stylebox(bg_color: Color = BG_LIGHT, pressed: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color.darkened(0.1) if pressed else bg_color
	style.border_color = ACCENT_GOLD if pressed else BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	return style

static func create_button_hover_stylebox(bg_color: Color = BG_LIGHT) -> StyleBoxFlat:
	var style := create_button_stylebox(bg_color)
	style.bg_color = bg_color.lightened(0.1)
	style.border_color = ACCENT_GOLD
	return style

static func create_flat_stylebox(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	return style

static func get_rarity_color(rarity: Enums.Rarity) -> Color:
	match rarity:
		Enums.Rarity.COMMON: return RARITY_COMMON
		Enums.Rarity.UNCOMMON: return RARITY_UNCOMMON
		Enums.Rarity.RARE: return RARITY_RARE
		Enums.Rarity.EPIC: return RARITY_EPIC
		Enums.Rarity.LEGENDARY: return RARITY_LEGENDARY
		_: return RARITY_COMMON

static func get_quality_color(quality: Enums.Quality) -> Color:
	match quality:
		Enums.Quality.POOR: return Color("#6b7280")
		Enums.Quality.STANDARD: return Color("#9ca3af")
		Enums.Quality.GOOD: return Color("#22c55e")
		Enums.Quality.EXCELLENT: return Color("#3b82f6")
		Enums.Quality.MASTERWORK: return Color("#f59e0b")
		_: return Color.WHITE

static func style_progress_bar(bar: ProgressBar, fill_color: Color = SUCCESS, bg_color: Color = BG_DARK) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = bg_color
	bg.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg)

	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)
