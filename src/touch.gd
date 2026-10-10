extends CanvasLayer
## Touch controls overlay (autoload "Touch").
##
## Battle buttons synthesize the same keys the keyboard uses, so all the
## existing input logic (precision power repeat, TAB tap-vs-hold, fire on
## press) works unchanged. Menu screens are handled natively: any scene
## with a tap_at(pos) method gets direct taps. Buttons appear only when a
## touchscreen is present (or with the --touchui flag, for testing); on
## desktops the mouse still gets the direct menu taps.

var enabled := false   # a touchscreen is present (or --touchui)
var used := false      # a finger has touched it: only then buttons appear
var held := {}         # keycode -> number of fingers holding its button
var by_index := {}     # touch finger index (-1 = mouse) -> keycode
var draw_node: Node2D
var t := 0.0
var _first_tap := true

# fire and menu act once on touch-down; the others are held keys (arrows
# repeat, TAB decides tap-vs-hold on release) and are let go on finger-up
const EDGE_KEYS := [KEY_SPACE, KEY_ESCAPE]


func _ready() -> void:
	layer = 10
	var forced := "--touchui" in OS.get_cmdline_user_args()
	enabled = DisplayServer.is_touchscreen_available() or forced
	# keyboard players on touchscreen laptops never see the buttons
	used = forced
	draw_node = Node2D.new()
	draw_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(draw_node)
	draw_node.draw.connect(_draw_ui)


func _process(delta: float) -> void:
	t += delta
	# buttons vanish mid-hold (shot fired, turn over): let go of their keys
	# so nothing carries over into the next player's turn
	if not by_index.is_empty() and _buttons().is_empty():
		release_all()
	draw_node.queue_redraw()


func _notification(what: int) -> void:
	# a finger or mouse button held while the app loses focus never sends
	# its release
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		release_all()


## True while the touch layer is in play (SOLA shows its touch page).
func active() -> bool:
	return enabled and used


## Bottom edge of the MENU button while it is shown: overlays that dock
## at the top of the screen go below it.
func top_reserved() -> float:
	return 30.0 if not _buttons().is_empty() else 0.0


func _battle() -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	var cur = scene.get("current")
	if cur != null and cur.get("guns") != null:
		return cur
	return null


## On-screen buttons for the current moment (battle aim only).
func _buttons() -> Array:
	if not active():
		return []
	var b := _battle()
	if b == null:
		return []
	if b.state == b.St.AIM and b.rx[b.cur] == null:
		return [
			{"rect": Rect2(2, 166, 26, 28), "kind": "left", "key": KEY_LEFT},
			{"rect": Rect2(30, 166, 26, 28), "kind": "right", "key": KEY_RIGHT},
			{"rect": Rect2(84, 168, 68, 26), "kind": "weapon", "key": KEY_TAB},
			{"rect": Rect2(156, 168, 56, 26), "kind": "fire", "key": KEY_SPACE},
			{"rect": Rect2(262, 166, 26, 28), "kind": "up", "key": KEY_UP},
			{"rect": Rect2(290, 166, 26, 28), "kind": "down", "key": KEY_DOWN},
			{"rect": Rect2(283, 17, 35, 12), "kind": "menu", "key": KEY_ESCAPE},
		]
	return []


func _input(event: InputEvent) -> void:
	# a real key press is a user gesture too: the browser has unlocked
	# audio, so a later first tap must not restart the music
	if event is InputEventKey and event.pressed and event.device != Pad.SYNTH_DEVICE:
		_first_tap = false


func _unhandled_input(event: InputEvent) -> void:
	var pos := Vector2.ZERO
	var down := false
	var index := -1
	if event is InputEventScreenTouch:
		pos = event.position
		down = event.pressed
		index = event.index
		used = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
		down = event.pressed
	else:
		return
	if down:
		if _first_tap:
			_first_tap = false
			if OS.has_feature("web"):   # native builds never lock audio
				Sfx.unlock_retrigger()
		_press_at(pos, index)
	else:
		_release(index)


func _press_at(pos: Vector2, index: int) -> void:
	if by_index.has(index):
		_release(index)   # its release got lost: never leave a key stuck
	for btn in _buttons():
		if btn.rect.has_point(pos):
			var k: int = btn.key
			by_index[index] = k
			held[k] = held.get(k, 0) + 1
			if held[k] == 1:
				_synth(k, true)
				if k in EDGE_KEYS:
					_synth(k, false)
			return
	# no button hit: menus take direct taps, banners take any-key
	var scene := get_tree().current_scene
	if scene == null:
		return
	var cur = scene.get("current")
	if cur == null:
		return
	if cur.has_method("tap_at"):
		cur.tap_at(pos)
		return
	var b := _battle()
	if b != null and b.state == b.St.ROUND_OVER:
		_synth(KEY_SPACE, true)
		_synth(KEY_SPACE, false)


## A key stays down until the LAST finger on its button lifts.
func _release(index: int) -> void:
	if not by_index.has(index):
		return
	var k: int = by_index[index]
	by_index.erase(index)
	held[k] = held.get(k, 1) - 1
	if held[k] <= 0:
		held.erase(k)
		if not k in EDGE_KEYS:
			_synth(k, false)


func release_all() -> void:
	for index in by_index.keys():
		_release(index)


func _synth(key: int, down: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = key
	ev.physical_keycode = key
	ev.pressed = down
	Input.parse_input_event(ev)


func _draw_ui() -> void:
	var btns := _buttons()
	if btns.is_empty():
		return
	var b := _battle()
	var gun_rects: Array = []
	for g in b.guns:
		if g.alive:   # body plus barrel sweep
			gun_rects.append(Rect2(g.position.x - 16, g.position.y - g.body_h - 14,
				32, g.body_h + 16))
	for btn in btns:
		var r: Rect2 = btn.rect
		var down: bool = held.has(btn.key)
		# a gun standing behind a button must stay visible: go see-through
		var a := 1.0
		for gr in gun_rects:
			if r.intersects(gr):
				a = 0.4
		var bg := Color("2c3038") if down else Color(Vga.UI_BG)
		draw_node.draw_rect(r, Color(bg, a))
		var hi := Color(Color(Vga.UI_LO) if down else Color(Vga.UI_HI), a)
		var lo := Color(Color(Vga.UI_HI) if down else Color(Vga.UI_LO), a)
		draw_node.draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), hi)
		draw_node.draw_rect(Rect2(r.position, Vector2(1, r.size.y)), hi)
		draw_node.draw_rect(Rect2(r.position + Vector2(0, r.size.y - 1), Vector2(r.size.x, 1)), lo)
		draw_node.draw_rect(Rect2(r.position + Vector2(r.size.x - 1, 0), Vector2(1, r.size.y)), lo)
		var cx := r.position.x + r.size.x / 2.0
		var cy := r.position.y + r.size.y / 2.0
		match btn.kind:
			"left":
				Pix.draw_c(draw_node, cx, cy - 5, "<", Color(Vga.UI_TEXT), 2)
			"right":
				Pix.draw_c(draw_node, cx, cy - 5, ">", Color(Vga.UI_TEXT), 2)
			"up":
				Pix.draw_c(draw_node, cx, cy - 5, "+", Color(Vga.UI_TEXT), 2)
			"down":
				Pix.draw_c(draw_node, cx, cy - 5, "-", Color(Vga.UI_TEXT), 2)
			"fire":
				Pix.draw_c(draw_node, cx, cy - 5, L.t("btn_fire"), Color(Vga.P1_ACCENT), 2)
			"menu":
				Pix.draw_c(draw_node, cx, cy - 2, L.t("btn_menu"), Color(Vga.UI_DIM))
			"weapon":
				if b != null:
					var g: Node = b.guns[b.cur]
					var wtxt := L.t("w%d" % g.weapon)
					if g.ammo[g.weapon] >= 0:
						wtxt += " X%d" % g.ammo[g.weapon]
					Pix.draw_c(draw_node, cx, cy - 5, wtxt, Color(Vga.UI_TEXT))
					Pix.draw_c(draw_node, cx, cy + 3, L.t("btn_hold_wind"), Color(Vga.UI_DIM))
