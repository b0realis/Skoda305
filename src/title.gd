extends Node2D
## Title screen: dithered alpine backdrop, chunky title, a sepia "archive
## photograph" of the Skoda 30.5 cm M.11 (painted in code, framed like a
## museum plate — after the Santa Lucia assembly photo), menu and language
## selection with pixel flags.

signal start_game(mode: int)
signal show_help

const PH_W := 46
const PH_H := 30
const FLAG_W := 12
const FLAG_H := 9
const MENU_ITEMS := 4   # 1P, 2P, help, language

var sel := 0
var t := 0.0
var sky_tex: ImageTexture
var photo_tex: ImageTexture
var flag_texs := {}
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	sky_tex = Vga.make_sky(rng)
	photo_tex = _make_photo()
	for lang in L.LANGS:
		flag_texs[lang] = _make_flag(lang)


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_UP:
			sel = (sel + MENU_ITEMS - 1) % MENU_ITEMS
			Sfx.play("click", -6.0)
		KEY_DOWN:
			sel = (sel + 1) % MENU_ITEMS
			Sfx.play("click", -6.0)
		KEY_LEFT:
			if sel == 3:
				L.cycle(-1)
				Sfx.play("click", -6.0)
		KEY_RIGHT:
			if sel == 3:
				L.cycle(1)
				Sfx.play("click", -6.0)
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			if sel == 3:
				L.cycle(1)
				Sfx.play("click", -6.0)
			elif sel == 2:
				Sfx.play("beep")
				show_help.emit()
			else:
				Sfx.play("beep")
				start_game.emit(sel + 1)
		KEY_1:
			Sfx.play("beep")
			start_game.emit(1)
		KEY_2:
			Sfx.play("beep")
			start_game.emit(2)
		KEY_P:
			G.assist = not G.assist
			G.save_assist()
			Sfx.play("beep", -4.0, 1.2 if G.assist else 0.8)
		KEY_H:
			G.hard = not G.hard
			G.save_pref("hard", G.hard)
			Sfx.play("beep", -4.0, 0.7 if G.hard else 1.1)
		KEY_S:
			G.toggle_scale(get_window())
			Sfx.play("click", -4.0)
		KEY_ESCAPE:
			# a browser tab cannot quit itself
			if not OS.has_feature("web"):
				get_tree().quit()


## Direct taps (touch or mouse): menu rows, flags, assist/hard hints.
## Menu rows are only ~3.6 mm tall on a phone, so they use select-then-
## confirm: the first tap moves the highlight, tapping the highlighted row
## activates it.
func tap_at(p: Vector2) -> void:
	for i in 3:
		if Rect2(180, 78 + i * 12, 136, 12).has_point(p):
			if sel != i:
				sel = i
				Sfx.play("click", -6.0)
				return
			Sfx.play("beep")
			match i:
				0: start_game.emit(1)
				1: start_game.emit(2)
				2: show_help.emit()
			return
	for k in L.LANGS.size():
		var fx := 192.0 + k * (FLAG_W + 5)
		if Rect2(fx - 2, 126, FLAG_W + 5, 14).has_point(p):
			sel = 3
			L.set_lang(L.LANGS[k])
			Sfx.play("click", -6.0)
			return
	if Rect2(180, 116, 136, 10).has_point(p):
		sel = 3
		L.cycle(1)
		Sfx.play("click", -6.0)
		return
	if Rect2(0, 186, 104, 14).has_point(p):
		G.assist = not G.assist
		G.save_assist()
		Sfx.play("beep", -4.0, 1.2 if G.assist else 0.8)
		return
	if Rect2(106, 186, 110, 14).has_point(p):
		G.hard = not G.hard
		G.save_pref("hard", G.hard)
		Sfx.play("beep", -4.0, 0.7 if G.hard else 1.1)
		return
	if Rect2(220, 0, 100, 12).has_point(p):
		G.toggle_scale(get_window())
		Sfx.play("click", -4.0)


func _draw() -> void:
	draw_texture(sky_tex, Vector2.ZERO)
	var dim := Color(Vga.UI_DIM)
	var txt := Color(Vga.UI_TEXT)
	var dark := Color(Vga.UI_LO)

	Pix.draw_shadow_c(self, 160, 7, L.t("subtitle"), dim, dark)
	Pix.draw_shadow_c(self, 160, 15, L.t("title"), txt, dark, 3)
	Pix.draw_shadow_c(self, 160, 33, L.t("subtitle2"), dim, dark)

	if G.match_over and G.last_winner >= 0:
		var acc := Color(Vga.P1_ACCENT) if G.last_winner == 0 else Color(Vga.P2_ACCENT)
		Pix.draw_shadow_c(self, 160, 44, L.t("victor") % L.t("team%d" % G.last_winner)
			+ "  %d:%d" % [G.scores[0], G.scores[1]], acc, dark)

	var sy := 52
	if G.assist:
		Pix.draw_shadow_c(self, 160, sy, L.t("assist_on"), txt, dark)
		sy += 8
	if G.hard:
		Pix.draw_shadow_c(self, 160, sy, L.t("hard_on"), Color(Vga.P1_ACCENT), dark)

	# framed photograph
	var px := 30.0
	var py := 72.0
	var pw := PH_W * 2.0
	var ph := PH_H * 2.0
	draw_rect(Rect2(px - 4, py - 4, pw + 8, ph + 8), Color(Vga.UI_LO))
	draw_rect(Rect2(px - 3, py - 3, pw + 6, ph + 6), Color("d8cfc0"))
	draw_texture_rect(photo_tex, Rect2(px, py, pw, ph), false)
	Pix.draw_shadow_c(self, px + pw / 2.0, py + ph + 8, L.t("title_cap"), dim, dark)

	# menu
	var mx := 192.0
	var labels := [L.t("menu_1p"), L.t("menu_2p"), L.t("menu_help")]
	for i in 3:
		var col := txt if i == sel else dim
		if i == sel and fmod(t, 0.5) > 0.25:
			Pix.draw_shadow(self, Vector2(mx - 10, 80 + i * 12), ">", txt, dark)
		Pix.draw_shadow(self, Vector2(mx, 80 + i * 12), labels[i], col, dark)

	# language row: label + current name, flags underneath
	var lcol := txt if sel == 3 else dim
	if sel == 3 and fmod(t, 0.5) > 0.25:
		Pix.draw_shadow(self, Vector2(mx - 10, 118), ">", txt, dark)
	Pix.draw_shadow(self, Vector2(mx, 118), "%s: %s" % [L.t("lang_label"),
		L.LANG_NAMES[L.cur]], lcol, dark)
	for k in L.LANGS.size():
		var lang: String = L.LANGS[k]
		var fx := mx + k * (FLAG_W + 5)
		var fy := 128.0
		draw_rect(Rect2(fx - 1, fy - 1, FLAG_W + 2, FLAG_H + 2), dark)
		draw_texture(flag_texs[lang], Vector2(fx, fy))
		if lang == L.cur:
			draw_rect(Rect2(fx - 2, fy - 2, FLAG_W + 4, FLAG_H + 4), txt, false)
		else:
			draw_rect(Rect2(fx, fy, FLAG_W, FLAG_H), Color(0, 0, 0, 0.4))

	if not OS.has_feature("web"):
		Pix.draw_shadow(self, Vector2(mx, 146), L.t("esc_quit"), dim, dark)

	Pix.draw_shadow_c(self, 160, 172, L.t("controls1"), dim, dark)
	Pix.draw_shadow_c(self, 160, 180, L.t("controls2"), dim, dark)

	Pix.draw_shadow(self, Vector2(4, 193), L.t("assist_hint"),
		txt if G.assist else dim, dark)
	Pix.draw_shadow_c(self, 160, 193, L.t("hard_hint"),
		Color(Vga.P1_ACCENT) if G.hard else dim, dark)
	var sc := "%s (%s): %s" % [L.t("scale_label"), L.t("scale_key"),
		L.t("scale_full_v") if G.scale_full else L.t("scale_sharp")]
	Pix.draw_shadow(self, Vector2(316 - Pix.width(sc), 2), sc, dim, dark)
	var ver := "V%s" % ProjectSettings.get_setting("application/config/version", "?")
	Pix.draw_shadow(self, Vector2(316 - Pix.width(ver), 193), ver, dim, dark)

	# film grain flicker
	for i in 160:
		var gx := rng.randi_range(0, 319)
		var gy := rng.randi_range(0, 199)
		var g := 0.0 if rng.randf() < 0.5 else 1.0
		draw_rect(Rect2(gx, gy, 1, 1), Color(g, g, g, 0.05))


## 12x9 pixel flags in muted VGA tones.
func _make_flag(lang: String) -> ImageTexture:
	var img := Image.create_empty(FLAG_W, FLAG_H, false, Image.FORMAT_RGBA8)
	var white := Color("e8e4dc")
	var red := Color("c03830")
	var blue := Color("3a4a8a")
	var green := Color("4e9a50")
	var black := Color("202020")
	var gold := Color("d8a838")
	match lang:
		"en":  # Union Jack, simplified
			img.fill(blue)
			for y in FLAG_H:
				for x in FLAG_W:
					var dx := x / float(FLAG_W - 1)
					var dy := y / float(FLAG_H - 1)
					if absf(dx - dy) < 0.16 or absf(dx - (1.0 - dy)) < 0.16:
						img.set_pixel(x, y, white)
			for y in range(3, 6):
				for x in FLAG_W:
					img.set_pixel(x, y, white)
			for y in FLAG_H:
				for x in range(4, 8):
					img.set_pixel(x, y, white)
			for x in FLAG_W:
				img.set_pixel(x, 4, red)
			for y in FLAG_H:
				img.set_pixel(5, y, red)
				img.set_pixel(6, y, red)
		"sl":  # white-blue-red tricolor with a tiny Triglav shield
			for y in FLAG_H:
				var c := white if y < 3 else (blue if y < 6 else red)
				for x in FLAG_W:
					img.set_pixel(x, y, c)
			var shield := Color("2a3a6a")
			for y in range(1, 5):
				for x in range(2, 5):
					img.set_pixel(x, y, shield)
			img.set_pixel(3, 2, white)
			for x in range(2, 5):
				img.set_pixel(x, 3, white)
		"de":  # black-red-gold
			for y in FLAG_H:
				var c := black if y < 3 else (red if y < 6 else gold)
				for x in FLAG_W:
					img.set_pixel(x, y, c)
		"it":  # green-white-red
			for y in FLAG_H:
				for x in FLAG_W:
					img.set_pixel(x, y, green if x < 4 else (white if x < 8 else red))
	return ImageTexture.create_from_image(img)


## Paint the little sepia photograph: sky, ground, the mortar in profile
## (platform, cradle, fat barrel at ~60 degrees, recoil cylinder) and two
## crew silhouettes. Chunky and underexposed, like a 1916 glass plate.
func _make_photo() -> ImageTexture:
	var img := Image.create_empty(PH_W, PH_H, false, Image.FORMAT_RGBA8)
	var paper := Color("c8bca0")
	var paper_hi := Color("d4c8ac")
	var ground := Color("8a7c60")
	var ground_lo := Color("6a5e48")
	var dark := Color("3a3226")
	var mid := Color("5c5044")
	var hi := Color("8a7c68")

	for y in PH_H:
		for x in PH_W:
			var nz: float = Vga.hash01(x + 91, y + 17)
			var c := paper
			if y < 6 and nz > 0.4:
				c = paper_hi
			if y >= 22:
				c = ground if y < 27 else ground_lo
				if nz > 0.8:
					c = c.lightened(0.08)
			# corner vignette
			var cd := minf(minf(x, PH_W - 1 - x), minf(y, PH_H - 1 - y))
			if cd < 3 and nz > cd / 3.0:
				c = c.darkened(0.18)
			img.set_pixel(x, y, c)

	# platform
	_rect(img, 9, 19, 22, 4, dark)
	_rect(img, 9, 19, 22, 1, mid)
	# cradle
	for y in range(14, 21):
		for x in range(14, 22):
			if Vector2(x - 17.5, y - 17).length() < 3.6:
				img.set_pixel(x, y, dark)
	# barrel at ~62 degrees, 4 px thick, with a lighter top edge
	var dirv := Vector2(0.48, -0.88)
	var perp := Vector2(-dirv.y, dirv.x)
	for i in 17:
		var p := Vector2(17.5, 16.5) + dirv * i
		for j in range(-2, 2):
			var q := (p + perp * j).round()
			if q.x >= 0 and q.x < PH_W and q.y >= 0 and q.y < PH_H:
				img.set_pixel(int(q.x), int(q.y), mid if j == -1 or j == 0 else dark)
		if i > 4 and i < 15:
			var e := (p + perp * -2).round()
			if e.x >= 0 and e.x < PH_W and e.y >= 0 and e.y < PH_H:
				img.set_pixel(int(e.x), int(e.y), hi)
	# recoil cylinder under the barrel
	for i in 9:
		var p := (Vector2(20.0, 19.0) + dirv * i).round()
		if p.x < PH_W and p.y < PH_H:
			img.set_pixel(int(p.x), int(p.y), mid)
	# crew silhouettes (caps on)
	_figure(img, 4, 16, dark)
	_figure(img, 34, 16, dark)
	_rect(img, 39, 20, 4, 2, dark)  # shell crate

	return ImageTexture.create_from_image(img)


func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			if xx >= 0 and xx < PH_W and yy >= 0 and yy < PH_H:
				img.set_pixel(xx, yy, c)


func _figure(img: Image, x: int, y: int, c: Color) -> void:
	_rect(img, x, y, 2, 1, c)        # cap
	_rect(img, x, y + 1, 2, 2, c)    # head
	_rect(img, x - 1, y + 3, 4, 4, c)  # coat
	_rect(img, x, y + 7, 1, 2, c)    # legs
	_rect(img, x + 2, y + 7, 1, 2, c)
