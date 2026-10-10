extends Node2D
## Top status bar (DOS style) + center banners. Reads state straight from the
## battle node. Deliberately outside the shaken "world" so the bar stays put.

var battle: Node
var _calc_bottom := 16.0   # soldier line docks under the calc panel


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var b := battle
	if b == null:
		return
	var bar_h: int = b.HUD_H
	draw_rect(Rect2(0, 0, 320, bar_h), Color(Vga.UI_BG))
	draw_rect(Rect2(0, 0, 320, 1), Color(Vga.UI_HI))
	draw_rect(Rect2(0, bar_h - 1, 320, 1), Color(Vga.UI_LO))

	var accents := [Color(Vga.P1_ACCENT), Color(Vga.P2_ACCENT)]
	var g0: Node = b.guns[0]
	var g1: Node = b.guns[1]

	# row 1: names, hp bars, round + score
	if b.cur == 0 and b.state != b.St.ROUND_OVER:
		_marker(4, 2, accents[0])
	Pix.draw(self, Vector2(9, 2), L.t("team0"), accents[0])
	_hp_bar(Vector2(56, 3), g0.hp)
	Pix.draw_c(self, 160, 2, "%s %d  %d:%d" % [L.t("round"), G.round_num,
		G.scores[0], G.scores[1]], Color(Vga.UI_DIM))
	_hp_bar(Vector2(236, 3), g1.hp)
	var n1 := L.t("team1")
	Pix.draw(self, Vector2(312 - Pix.width(n1), 2), n1, accents[1])
	if b.cur == 1 and b.state != b.St.ROUND_OVER:
		_marker(305 - Pix.width(n1), 2, accents[1])

	# row 2: aim readout, weapon, wind
	var g: Node = b.guns[b.cur]
	var txt := Color(Vga.UI_TEXT)
	if G.hard and b.rx[b.cur] == null:
		Pix.draw(self, Vector2(9, 8), "%s %d  %s %d" % [L.t("angle"),
			g.display_angle(), L.t("charge"), g.charge + 1], txt)
	else:
		Pix.draw(self, Vector2(9, 8), "%s %d  %s %d" % [L.t("angle"),
			g.display_angle(), L.t("power"), roundi(g.power)], txt)
	var wtxt := L.t("w%d" % g.weapon)
	if g.ammo[g.weapon] >= 0:
		wtxt += " X%d" % g.ammo[g.weapon]
	Pix.draw_c(self, 172, 8, wtxt, txt)
	_wind_gauge(b)

	# advanced ballistic calculator (assist mode, human turns only —
	# the prescription software never reads it)
	_calc_bottom = 16.0
	if G.assist and b.state == b.St.AIM and b.rx[b.cur] == null:
		_calc_panel(b)

	# the touch MENU button also sits under the bar: dock below it too
	_calc_bottom = maxf(_calc_bottom, Touch.top_reserved())

	# wind helper: fluttering flag above the gun + the soldier's estimate
	if b.wind_helper():
		_wind_flag(b)

	# banner
	if not b.banner_lines.is_empty():
		_banner(b.banner_lines, b.state_t)


## Analog wind gauge: center tick, fill extends downwind 1 px per unit,
## colored by severity (green / amber / red), number alongside.
func _wind_gauge(b: Node) -> void:
	var w: int = b.wind
	var label := L.t("wind")
	var num := str(absi(w))
	var total: int = Pix.width(label) + 4 + 21 + 4 + Pix.width(num)
	var x := 312.0 - total
	Pix.draw(self, Vector2(x, 8), label, Color(Vga.UI_DIM))
	var gx := x + Pix.width(label) + 4
	draw_rect(Rect2(gx, 8, 21, 5), Color(Vga.UI_LO))
	draw_rect(Rect2(gx + 10, 9, 1, 3), Color(Vga.UI_DIM))
	if w != 0:
		var col := Color(Vga.HP_GOOD)
		if absi(w) >= 7:
			col = Color(Vga.HP_BAD)
		elif absi(w) >= 4:
			col = Color(Vga.HP_WARN)
		# bar tapers into an arrowhead at its leading edge, pointing downwind
		var body := absi(w) - 1
		if w > 0:
			if body > 0:
				draw_rect(Rect2(gx + 11, 9, body, 3), col)
			draw_rect(Rect2(gx + 11 + body, 10, 1, 1), col)
		else:
			if body > 0:
				draw_rect(Rect2(gx + 10 - body, 9, body, 3), col)
			draw_rect(Rect2(gx + 9 - body, 10, 1, 1), col)
	Pix.draw(self, Vector2(gx + 25, 8), num, Color(Vga.UI_DIM))


## Live drift computation from the same constants battle.gd integrates:
## flat-ground flight time T = 2 v0 sin(th) / g, drift DX = (WIND_ACC/2) W T^2.
## Accounts for the selected weapon's muzzle-velocity multiplier.
func _calc_panel(b: Node) -> void:
	var g: Node = b.guns[b.cur]
	var w: Dictionary = b.WEAPONS[g.weapon]
	var v0: float = (30.0 + g.power * 2.2) * w.vmul
	var th: float = deg_to_rad(g.angle)
	var tf: float = 2.0 * v0 * sin(th) / b.GRAV
	var dx: int = roundi(0.5 * b.WIND_ACC * b.wind * tf * tf)

	var has_fb: bool = b.last_pred[b.cur] != null
	var aim_line := dx != 0
	var bh := 27 + (8 if aim_line else 0) + (16 if has_fb else 0)
	var box := Rect2(3, 17, 100, bh)
	_calc_bottom = 17.0 + bh
	draw_rect(box, Color(Vga.UI_BG))
	draw_rect(Rect2(box.position, Vector2(box.size.x, 1)), Color(Vga.UI_HI))
	draw_rect(Rect2(box.position, Vector2(1, box.size.y)), Color(Vga.UI_HI))
	draw_rect(Rect2(box.position + Vector2(0, box.size.y - 1), Vector2(box.size.x, 1)), Color(Vga.UI_LO))
	draw_rect(Rect2(box.position + Vector2(box.size.x - 1, 0), Vector2(1, box.size.y)), Color(Vga.UI_LO))

	Pix.draw(self, Vector2(7, 20), L.t("calc_title"), Color(Vga.UI_DIM))
	Pix.draw(self, Vector2(7, 27), "T = %.1f S  W = %+d" % [tf, b.wind], Color("e8e4dc"))
	Pix.draw(self, Vector2(7, 35), "DX = %s" % _fmt_px(dx), Color(Vga.UI_TEXT))
	var yy := 43
	if aim_line:
		# the actionable line: aim upwind by the drift amount
		Pix.draw(self, Vector2(7, yy), "%s %s" % [L.t("calc_aim"),
			_fmt_px(-dx)], Color(Vga.HP_GOOD))
		yy += 8
	if has_fb:
		Pix.draw(self, Vector2(7, yy), "%s: %s" % [L.t("calc_pred"),
			_fmt_px(b.last_pred[b.cur])], Color(Vga.UI_DIM))
		Pix.draw(self, Vector2(7, yy + 8), "%s: %s" % [L.t("calc_meas"),
			_fmt_px(b.last_meas[b.cur])], Color("e8e4dc"))


func _fmt_px(v: int) -> String:
	if v > 0:
		return "> %d PX" % v
	if v < 0:
		return "< %d PX" % -v
	return "0 PX"


func _wind_flag(b: Node) -> void:
	var g: Node = b.guns[b.cur]
	var t: float = b.state_t
	var mag: float = absi(b.wind)
	var dir := signi(b.wind)
	var top := Vector2(floorf(g.position.x) + 8.0, g.position.y - g.body_h - 16.0)

	# wooden pole with a brass finial
	draw_rect(Rect2(top.x, top.y, 1, 16), Color("6a5e48"))
	draw_rect(Rect2(top.x, top.y - 1, 1, 1), Color("d8a838"))

	var white := Color("e8e4dc")
	var red := Color("c03830")
	if dir == 0:
		# dead calm: the flag hangs limp, barely swaying
		for i in 6:
			var sway := sin(t * 1.5 + i * 0.4) * 0.5 * (i / 6.0)
			draw_rect(Rect2(top.x + 1 + sway, top.y + 1 + i, 2, 1),
				white if i < 2 else red)
	else:
		# the flag lifts with the wind: sagging near-vertical in a breeze,
		# stiff and horizontal in a gale; flutter grows with strength too
		var th := deg_to_rad(lerpf(20.0, 86.0, mag / 9.0))
		var fdir := Vector2(sin(th) * dir, cos(th))
		var perp := Vector2(cos(th) * dir, -sin(th))
		var amp := 0.4 + mag * 0.3
		var spd := 3.5 + mag * 1.5
		for i in 9:
			var flut := sin(t * spd - i * 0.85) * amp * (0.15 + i / 9.0)
			var p := Vector2(top.x + dir, top.y + 1) + fdir * (1 + i) + perp * flut
			var h := 5 - i / 3
			draw_rect(Rect2(floorf(p.x), floorf(p.y), 2, h), white if i < 2 else red)

	# the soldier's estimate, docked under the bar / calc panel / MENU button
	var dir_key := "wind_0"
	if b.wind > 0:
		dir_key = "wind_l"
	elif b.wind < 0:
		dir_key = "wind_r"
	var line: String
	if b.wind == 0:
		line = L.t("soldier0") % L.t(dir_key)
	else:
		line = L.t("soldier") % [L.t(dir_key), absi(b.wind), b.wind_est]
	Pix.draw_shadow_c(self, 160, _calc_bottom + 4.0, line,
		Color(Vga.UI_TEXT), Color(Vga.UI_LO))


func _marker(x: float, y: float, col: Color) -> void:
	draw_rect(Rect2(x, y + 1, 1, 3), col)
	draw_rect(Rect2(x + 1, y + 2, 1, 1), col)


func _hp_bar(pos: Vector2, hp: float) -> void:
	draw_rect(Rect2(pos - Vector2(1, 1), Vector2(28, 5)), Color(Vga.UI_LO))
	var col := Color(Vga.HP_GOOD)
	if hp <= 30:
		col = Color(Vga.HP_BAD)
	elif hp <= 60:
		col = Color(Vga.HP_WARN)
	if hp > 0:
		draw_rect(Rect2(pos, Vector2(maxf(hp * 26.0 / 100.0, 1.0), 3)), col)


func _banner(lines: Array, t: float) -> void:
	var w := 0
	for i in lines.size():
		var sc := 2 if i == 0 else 1
		w = maxi(w, Pix.width(lines[i], sc))
	var h := 0
	for i in lines.size():
		h += (12 if i == 0 else 7)
	var box := Rect2(160 - w / 2.0 - 9, 92 - h / 2.0 - 7, w + 18, h + 14)
	draw_rect(box, Color(Vga.UI_BG))
	draw_rect(Rect2(box.position, Vector2(box.size.x, 1)), Color(Vga.UI_HI))
	draw_rect(Rect2(box.position, Vector2(1, box.size.y)), Color(Vga.UI_HI))
	draw_rect(Rect2(box.position + Vector2(0, box.size.y - 1), Vector2(box.size.x, 1)), Color(Vga.UI_LO))
	draw_rect(Rect2(box.position + Vector2(box.size.x - 1, 0), Vector2(1, box.size.y)), Color(Vga.UI_LO))
	var y := box.position.y + 7
	for i in lines.size():
		var sc := 2 if i == 0 else 1
		var col := Color(Vga.UI_TEXT)
		if lines[i] == L.t("press_key") and fmod(t, 0.8) > 0.4:
			col = Color(Vga.UI_DIM)
		Pix.draw_c(self, 160, y, lines[i], col, sc)
		y += (12 if i == 0 else 7)
