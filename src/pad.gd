extends Node
## Game controller support (autoload "Pad").
##
## Like the touch layer, a controller is just another keyboard: buttons and
## the left stick press and release the same keys the game already handles
## (Input.parse_input_event), so menus, the precision power repeat and the
## weapon tap-vs-hold work verbatim. Button names follow the Xbox layout;
## other pads map by position (bottom face button = A).
##
##   D-pad / left stick   arrows: angle + power, menu navigation
##   A                    fire / confirm / next      (SPACE)
##   B                    back (SOLA, splash)        (ESC; never quits)
##   X / Y                weapon: tap = cycle, hold = wind flag (TAB)
##                        on the title: X = hard, Y = assist
##   LB / RB / triggers   fine adjustment            (SHIFT)
##   START                battle: menu (ESC), elsewhere confirm
##   SELECT (BACK)        title: picture SLIKA toggle (S)

const SYNTH_DEVICE := 77    # marks our synthesized key events
const STICK_ON := 0.5       # left-stick hysteresis: press beyond ON,
const STICK_OFF := 0.3      # release inside OFF

var active := false   # last input came from a controller: hints follow it
var sources := {}     # "device:control" -> keycode that control holds
var down := {}        # keycode -> true while we hold it pressed


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.joy_connection_changed.connect(_on_joy_connection)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		release_all()


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		active = true
		var id := "%d:b%d" % [event.device, event.button_index]
		if event.pressed:
			var k := _key_for_button(event.button_index)
			if k != KEY_NONE:
				_hold(id, k)
		else:
			_drop(id)
	elif event is InputEventJoypadMotion:
		_motion(event)
	elif event is InputEventKey:
		if event.device != SYNTH_DEVICE and event.pressed:
			active = false
	elif event is InputEventScreenTouch or event is InputEventMouseButton:
		active = false


func _motion(e: InputEventJoypadMotion) -> void:
	var neg := KEY_NONE
	var pos := KEY_NONE
	match e.axis:
		JOY_AXIS_LEFT_X:
			neg = KEY_LEFT
			pos = KEY_RIGHT
		JOY_AXIS_LEFT_Y:
			neg = KEY_UP
			pos = KEY_DOWN
		JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT:
			pos = KEY_SHIFT
		_:
			return
	var id := "%d:a%d" % [e.device, e.axis]
	var v := e.axis_value
	if absf(v) < STICK_OFF:
		_drop(id)
	elif v <= -STICK_ON and neg != KEY_NONE:
		active = true
		_hold(id, neg)
	elif v >= STICK_ON and pos != KEY_NONE:
		active = true
		_hold(id, pos)


## Buttons that mean different things per screen are resolved at press
## time; the release always lets go of the same key.
func _key_for_button(b: int) -> int:
	var scr := _screen()
	match b:
		JOY_BUTTON_DPAD_UP:
			return KEY_UP
		JOY_BUTTON_DPAD_DOWN:
			return KEY_DOWN
		JOY_BUTTON_DPAD_LEFT:
			return KEY_LEFT
		JOY_BUTTON_DPAD_RIGHT:
			return KEY_RIGHT
		JOY_BUTTON_A:
			return KEY_SPACE
		JOY_BUTTON_B:
			# ESC quits on the title and abandons a battle: B never does that
			return KEY_NONE if scr == "title" or scr == "battle" else KEY_ESCAPE
		JOY_BUTTON_X:
			return KEY_H if scr == "title" else KEY_TAB
		JOY_BUTTON_Y:
			return KEY_P if scr == "title" else KEY_TAB
		JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER:
			return KEY_SHIFT
		JOY_BUTTON_START:
			return KEY_ESCAPE if scr == "battle" else KEY_SPACE
		JOY_BUTTON_BACK:
			return KEY_S if scr == "title" else KEY_NONE
	return KEY_NONE


func _screen() -> String:
	var scene := get_tree().current_scene
	var cur = scene.get("current") if scene != null else null
	if cur == null:
		return ""
	if cur.has_signal("start_game"):
		return "title"
	if cur.get("guns") != null:
		return "battle"
	return "other"


func _hold(id: String, k: int) -> void:
	if sources.get(id, KEY_NONE) == k:
		return
	_drop(id)
	sources[id] = k
	_sync(k)


func _drop(id: String) -> void:
	if not sources.has(id):
		return
	var k: int = sources[id]
	sources.erase(id)
	_sync(k)


## A key stays down while ANY control holds it (D-pad and stick, two pads).
func _sync(k: int) -> void:
	var want: bool = k in sources.values()
	if want == down.has(k):
		return
	if want:
		down[k] = true
	else:
		down.erase(k)
	_synth(k, want)


func release_all() -> void:
	sources.clear()
	for k in down.keys():
		_synth(k, false)
	down.clear()


func _on_joy_connection(_device: int, connected: bool) -> void:
	if not connected:
		release_all()


func _synth(key: int, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = key
	ev.physical_keycode = key
	ev.pressed = pressed
	ev.device = SYNTH_DEVICE
	Input.parse_input_event(ev)
