extends Node2D
## Root state machine: title <-> battle rounds until someone wins the match.

const TitleScript := preload("res://src/title.gd")
const BattleScript := preload("res://src/battle.gd")
const SplashScript := preload("res://src/splash.gd")
const HelpScript := preload("res://src/help.gd")

var current: Node = null
# scene switches are deferred to the end of the frame; until the new scene
# exists, further requests (two keys or two fingers in one frame) are
# ignored — otherwise a round-over banner could award the point twice
var _switching := false

# --shots: muted demo (prescription software plays both sides) that
# saves screenshots (dev tool)
var shots := false
var shot_frame := 0
var shot_dir := ""
var _aim_captured := false
var matches_left := 1   # --autotest --matches=N plays N matches in a row


func _ready() -> void:
	randomize()
	_set_window_icon()
	G.apply_scale(get_window())
	var args := OS.get_cmdline_user_args()
	if "--autotest" in args:
		G.autotest = true
		# headless idles ~7 ms a frame; the fixed-dt simulation needs no rest
		OS.low_processor_usage_mode_sleep_usec = 1
		for a in args:
			if a.begins_with("--matches="):
				matches_left = maxi(int(a.substr(10)), 1)
		print("[autotest] starting, mode=1")
		_start_match(1)
		return
	if "--shots" in args:
		shots = true
		shot_dir = OS.get_environment("SHOT_DIR")
		if shot_dir.is_empty():
			shot_dir = "user://"
		AudioServer.set_bus_mute(0, true)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 60
		G.demo_rx = true
		G.assist = true
	_show_splash()


func _process(_delta: float) -> void:
	if not shots:
		return
	shot_frame += 1
	if shot_frame == 30:
		_capture("splash1")
	elif shot_frame == 45:
		_advance_splash()
	elif shot_frame == 110:
		_capture("splash2")
	elif shot_frame == 120:
		_advance_splash()
	elif shot_frame == 160:
		_capture("title")
	elif shot_frame == 170:
		_show_help()
	elif shot_frame == 200:
		_capture("help")
	elif shot_frame == 210 or shot_frame == 235 or shot_frame == 260:
		# by name: the touch page (touchscreens) shifts the indices
		var want: String = {210: "flag", 235: "charges", 260: "gun"}[shot_frame]
		if current != null and current.get("pages") != null:
			current.page = current.pages.find(want)
	elif shot_frame == 225:
		_capture("help2")
	elif shot_frame == 250:
		_capture("help3")
	elif shot_frame == 275:
		_capture("help4")
	elif shot_frame == 285:
		_start_match(1)
	elif shot_frame == 325:
		_capture("banner")
	elif shot_frame > 325 and shot_frame % 240 == 0:
		_capture("battle_%04d" % shot_frame)
	# dense burst for the gameplay GIF (tools/make_media.py)
	if shot_frame >= 400 and shot_frame <= 700 and shot_frame % 4 == 0:
		_capture("g%04d" % shot_frame)
	if shot_frame > 300 and not _aim_captured and current != null \
			and current.get("state") != null and current.state == 2 \
			and current.state_t > 0.5 \
			and current.get("last_pred") != null and current.last_pred[current.cur] != null:
		_aim_captured = true
		_capture("aim")
	if shot_frame >= 3400:
		get_tree().quit()


func _advance_splash() -> void:
	if current != null and current.has_method("_advance"):
		current._advance()


func _set_window_icon() -> void:
	if DisplayServer.get_name() == "headless" or OS.has_feature("web"):
		return
	var tex := load("res://icon.png") as Texture2D
	if tex == null:
		return
	var img := tex.get_image()
	img.convert(Image.FORMAT_RGBA8)
	DisplayServer.set_icon(img)


func _capture(name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.resize(640, 400, Image.INTERPOLATE_NEAREST)
	img.save_png(shot_dir.path_join("shot_%s.png" % name))


func _clear_current() -> void:
	_switching = false
	if current != null:
		current.queue_free()
		current = null


func _show_splash() -> void:
	_clear_current()
	var s: Node = SplashScript.new()
	s.done.connect(func(): _switch_to("_show_title"))
	current = s
	add_child(s)


func _show_title() -> void:
	_clear_current()
	var t: Node = TitleScript.new()
	t.start_game.connect(_on_start_game)
	t.show_help.connect(func(): _switch_to("_show_help"))
	current = t
	add_child(t)
	Sfx.play_music("title_theme")


func _show_help() -> void:
	_clear_current()
	var h: Node = HelpScript.new()
	h.closed.connect(func(): _switch_to("_show_title"))
	current = h
	add_child(h)


## Claims the pending switch; false if one is already scheduled.
func _claim_switch() -> bool:
	if _switching:
		return false
	_switching = true
	return true


func _switch_to(method: String) -> void:
	if _claim_switch():
		call_deferred(method)


func _on_start_game(mode: int) -> void:
	if _claim_switch():
		call_deferred("_start_match", mode)


func _start_match(mode: int) -> void:
	G.reset()
	G.mode = mode
	Sfx.stop_music()
	_start_round()


func _start_round() -> void:
	_clear_current()
	var b: Node = BattleScript.new()
	b.finished.connect(_on_round_finished)
	b.aborted.connect(_on_battle_aborted)
	current = b
	add_child(b)


func _on_battle_aborted() -> void:
	if not _claim_switch():
		return
	G.match_over = false
	call_deferred("_show_title")


func _on_round_finished(winner: int) -> void:
	if not _claim_switch():
		return
	if winner >= 0:
		G.scores[winner] += 1
		if G.scores[winner] >= G.WIN_SCORE:
			G.match_over = true
			G.last_winner = winner
			if G.autotest:
				# objects + memory per match: a long batch exposes any leak
				print("[autotest] MATCH OVER winner=%d score=%s objects=%d mem=%.1fMB" % [
					winner, str(G.scores), Performance.get_monitor(Performance.OBJECT_COUNT),
					OS.get_static_memory_usage() / 1048576.0])
				matches_left -= 1
				if matches_left > 0:
					call_deferred("_start_match", 1)
				else:
					get_tree().quit()
				return
			call_deferred("_show_title")
			return
	G.round_num += 1
	call_deferred("_start_round")
