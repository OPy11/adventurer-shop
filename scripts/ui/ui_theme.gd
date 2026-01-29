class_name UITheme
extends RefCounted

## Medieval Fantasy theme colors and styles

# Colors
const BG_DARK := Color("#1a1a2e")
const BG_MEDIUM := Color("#16213e")
const BG_LIGHT := Color("#0f3460")
const BG_PANEL := Color("#1f2937")
const BG_HOVER := Color("#2d3748")

const ACCENT_GOLD := Color("#d4af37")
const ACCENT_BRONZE := Color("#cd7f32")
const ACCENT_SILVER := Color("#c0c0c0")

const TEXT_PRIMARY := Color("#f5f5f5")
const TEXT_SECONDARY := Color("#9ca3af")
const TEXT_MUTED := Color("#8b95a5")

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

# Standard sizes
const DIALOG_PADDING := 24
const PANEL_PADDING := 16
const CARD_PADDING := 12
const BUTTON_PADDING := 12
const CORNER_RADIUS := 8
const BORDER_WIDTH := 2

# Font sizes
const FONT_TITLE := 22
const FONT_HEADER := 18
const FONT_BODY := 15
const FONT_SMALL := 13
const FONT_TINY := 11

static func create_panel_stylebox(bg_color: Color = BG_PANEL, border_width: int = BORDER_WIDTH) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = BORDER
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(CORNER_RADIUS)
	style.set_content_margin_all(PANEL_PADDING)
	return style

static func create_dialog_stylebox(bg_color: Color = BG_MEDIUM) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = ACCENT_GOLD
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(DIALOG_PADDING)
	# Add shadow effect
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	return style

static func create_button_stylebox(bg_color: Color = BG_LIGHT, pressed: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color.darkened(0.15) if pressed else bg_color
	style.border_color = ACCENT_GOLD if pressed else BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(BUTTON_PADDING)
	style.content_margin_left = 16
	style.content_margin_right = 16
	return style

static func create_button_hover_stylebox(bg_color: Color = BG_LIGHT) -> StyleBoxFlat:
	var style := create_button_stylebox(bg_color)
	style.bg_color = bg_color.lightened(0.15)
	style.border_color = ACCENT_GOLD
	return style

static func create_button_disabled_stylebox(bg_color: Color = BG_LIGHT) -> StyleBoxFlat:
	var style := create_button_stylebox(bg_color)
	style.bg_color = bg_color.darkened(0.4)
	style.border_color = BORDER.darkened(0.3)
	return style

static func create_flat_stylebox(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	return style

static func create_card_stylebox(bg_color: Color = BG_PANEL, selected: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = ACCENT_GOLD if selected else BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(CORNER_RADIUS)
	style.set_content_margin_all(CARD_PADDING)
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

static func style_button(btn: Button, color: Color = BG_LIGHT) -> void:
	btn.add_theme_stylebox_override("normal", create_button_stylebox(color))
	btn.add_theme_stylebox_override("hover", create_button_hover_stylebox(color))
	btn.add_theme_stylebox_override("pressed", create_button_stylebox(color, true))
	btn.add_theme_stylebox_override("disabled", create_button_disabled_stylebox(color))
	btn.add_theme_color_override("font_color", TEXT_PRIMARY)
	btn.add_theme_color_override("font_hover_color", ACCENT_GOLD)
	btn.add_theme_color_override("font_pressed_color", ACCENT_GOLD)
	btn.add_theme_color_override("font_disabled_color", TEXT_MUTED)
	btn.add_theme_font_size_override("font_size", FONT_BODY)

static func style_label(label: Label, size: int = FONT_BODY, color: Color = TEXT_PRIMARY) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)

static func style_scroll_container(scroll: ScrollContainer) -> void:
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Style scrollbars
	var v_scroll := scroll.get_v_scroll_bar()
	var h_scroll := scroll.get_h_scroll_bar()

	var scroll_style := StyleBoxFlat.new()
	scroll_style.bg_color = BG_DARK
	scroll_style.set_corner_radius_all(4)

	var grabber_style := StyleBoxFlat.new()
	grabber_style.bg_color = BG_LIGHT
	grabber_style.set_corner_radius_all(4)

	var grabber_hover := StyleBoxFlat.new()
	grabber_hover.bg_color = ACCENT_GOLD.darkened(0.3)
	grabber_hover.set_corner_radius_all(4)

	if v_scroll:
		v_scroll.add_theme_stylebox_override("scroll", scroll_style)
		v_scroll.add_theme_stylebox_override("grabber", grabber_style)
		v_scroll.add_theme_stylebox_override("grabber_highlight", grabber_hover)

	if h_scroll:
		h_scroll.add_theme_stylebox_override("scroll", scroll_style)
		h_scroll.add_theme_stylebox_override("grabber", grabber_style)
		h_scroll.add_theme_stylebox_override("grabber_highlight", grabber_hover)

static func create_title_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_TITLE)
	label.add_theme_color_override("font_color", ACCENT_GOLD)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

static func create_section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_BODY)
	label.add_theme_color_override("font_color", TEXT_PRIMARY)
	return label

static func create_muted_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SMALL)
	label.add_theme_color_override("font_color", TEXT_MUTED)
	return label
