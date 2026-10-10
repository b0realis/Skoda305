extends Node
## Global match state (autoload "G").

const WIN_SCORE := 3

var mode := 1              # 1 = vs computer, 2 = hotseat
var scores := [0, 0]
var round_num := 1
var match_over := false
var last_winner := -1
var autotest := false      # headless smoke-test mode (--autotest)
var demo_rx := false       # both sides run by the prescription software (demo mode)
var assist := false        # advanced ballistic calculator (toggled with P)
var scale_full := false    # false = integer (sharp), true = fractional (fills)
var hard := false          # historical charges: 5 discrete power settings


func _ready() -> void:
	# smart default: phones fill the screen, desktops stay pixel-perfect
	scale_full = DisplayServer.is_touchscreen_available()
	var cfg := ConfigFile.new()
	if cfg.load("user://settings.cfg") == OK:
		assist = cfg_bool(cfg, "assist", false)
		scale_full = cfg_bool(cfg, "scale_full", scale_full)
		hard = cfg_bool(cfg, "hard", false)


## A hand-edited or foreign settings file must not break loading: values of
## the wrong type fall back to the default instead of raising.
func cfg_bool(cfg: ConfigFile, key: String, default: bool) -> bool:
	var v = cfg.get_value("game", key, default)
	return v if typeof(v) == TYPE_BOOL else default


## "Press any key" means a real key: a lone modifier (Shift, Alt of Alt+Tab,
## Ctrl, Super) must not flip pages or dismiss banners.
func is_any_key(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed and not event.echo \
		and not event.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META, KEY_CAPSLOCK]


func apply_scale(win: Window) -> void:
	win.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL \
		if scale_full else Window.CONTENT_SCALE_STRETCH_INTEGER


func toggle_scale(win: Window) -> void:
	scale_full = not scale_full
	apply_scale(win)
	save_pref("scale_full", scale_full)


func save_pref(key: String, value) -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://settings.cfg")
	cfg.set_value("game", key, value)
	cfg.save("user://settings.cfg")


func save_assist() -> void:
	save_pref("assist", assist)


func reset() -> void:
	scores = [0, 0]
	round_num = 1
	match_over = false
	last_winner = -1
