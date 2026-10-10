extends Node2D
## Field-manual page: how wind bends the trajectory. Both curves in the
## diagram are plotted from the very equations battle.gd integrates
## (g = 110 px/s2, wind acceleration = 4*W px/s2, v0 = 30 + 2.2*power),
## so the manual is always telling the truth. Any key returns to the menu.

signal closed

const GRAV := 110.0     # must match battle.gd
const WIND_ACC := 4.0   # must match battle.gd
const DEMO_W := 8.0     # wind used in the diagram
const DEMO_V0 := 130.0
const DEMO_TH := 62.0

# weapon fact sheets (sources: en.wikipedia.org, Skoda 305 mm Model 1911 /
# Obice da 305/17); values shared across languages, labels localized
const GUNS := [
	{
		"title": "SKODA 30.5CM MOZNAR M.11",
		"img": "res://assets/img/help_skoda.png",
		"cap": "cap_skoda",
		"accent": Vga.P1_ACCENT,
		"stats": [
			["st_caliber", "305 MM (L/10)"],
			["st_weight", "20830 KG"],
			["st_shell", "287 / 384 KG"],
			["st_powder", "RINGPULVER M.97"],
			["st_charges", "1-4 (+5)"],
			["V0", "340 M/S"],
			["st_range", "MAX 11.3 KM"],
			["st_elev", "+40 .. +70"],
			["st_rate", "10-12 / H"],
			["st_crew", "15-17"],
			["st_service", "1911"],
		],
	},
	{
		"title": "OBICE DA 305/17",
		"img": "res://assets/img/help_obice.png",
		"cap": "cap_obice",
		"accent": Vga.P2_ACCENT,
		"stats": [
			["st_caliber", "305 MM (L/17)"],
			["st_weight", "33700 KG"],
			["st_shell", "295 - 442 KG"],
			["V0", "545 M/S"],
			["st_range", "MAX 17.6 KM"],
			["st_elev", "-20 .. +65"],
			["st_rate", "5-12 / H"],
			["st_crew", "10"],
			["st_service", "1914"],
		],
	},
]

var t := 0.0
var page := 0
var pages: Array = []   # page order; "touch" only when touch controls are on
var gun_texs: Array = []


func _ready() -> void:
	pages = ["wind", "flag"]
	if Touch.active():
		pages.append("touch")
	pages += ["charges", "gun", "gun"]
	for g in GUNS:
		gun_texs.append(load(g.img) if ResourceLoader.exists(g.img) else null)


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


## Direct taps (touch or mouse): left edge = previous page,
## the rest = next page (past the last page = back to the menu).
func tap_at(p: Vector2) -> void:
	Sfx.play("click", -6.0)
	if p.x < 80.0:
		if page > 0:
			page -= 1
	else:
		_next_page()


## Past the last page = back to the menu. The page index never runs past
## the list: the screen still draws once before main frees it.
func _next_page() -> void:
	if page + 1 >= pages.size():
		closed.emit()
	else:
		page += 1


func _unhandled_input(event: InputEvent) -> void:
	if not G.is_any_key(event):
		return
	match event.keycode:
		KEY_ESCAPE:
			Sfx.play("click", -6.0)
			closed.emit()
		KEY_LEFT:
			if page > 0:
				page -= 1
				Sfx.play("click", -6.0)
		_:
			# right / space / enter / anything: next page, out after the last
			Sfx.play("click", -6.0)
			_next_page()


## Closed-form of the integrated motion (constant accelerations):
##   x(t) = v0 cos(th) t + (WIND_ACC*W/2) t^2
##   y(t) = v0 sin(th) t - (g/2) t^2
func _traj(w: float, tt: float) -> Vector2:
	var th := deg_to_rad(DEMO_TH)
	return Vector2(
		DEMO_V0 * cos(th) * tt + 0.5 * WIND_ACC * w * tt * tt,
		DEMO_V0 * sin(th) * tt - 0.5 * GRAV * tt * tt)


func _flight_time() -> float:
	return DEMO_V0 * sin(deg_to_rad(DEMO_TH)) / (0.5 * GRAV)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 320, 200), Color("14161c"))
	var amber := Color(Vga.UI_TEXT)
	var dim := Color(Vga.UI_DIM)

	Pix.draw(self, Vector2(298, 6), "%d/%d" % [page + 1, pages.size()], dim)
	var kind: String = pages[page]
	if kind == "wind":
		_draw_manual()
	elif kind == "flag":
		_draw_flag_page()
	elif kind == "touch":
		_draw_touch_page()
	elif kind == "charges":
		_draw_charges_page()
	else:
		var gi: int = page - pages.find("gun")
		_draw_gun_page(GUNS[gi], gun_texs[gi])

	var col := amber if fmod(t, 0.8) > 0.4 else dim
	Pix.draw_c(self, 160, 188, L.t("help_nav"), col)


## Page 2: the TAB wind helper — three live flags at different strengths
## (same math the HUD uses) and the unit conversion.
func _draw_flag_page() -> void:
	var amber := Color(Vga.UI_TEXT)
	var white := Color("e8e4dc")
	var dim := Color(Vga.UI_DIM)
	var dark := Color(Vga.UI_LO)

	Pix.draw_shadow_c(self, 160, 5, L.t("flag_title"), amber, dark, 2)

	# ground strip with three demo flags: calm, breeze, gale
	draw_rect(Rect2(24, 92, 272, 2), Color(Vga.ROCK_MID))
	draw_rect(Rect2(24, 94, 272, 4), Color(Vga.ROCK_DEEP))
	var demos := [0, 3, 9]
	for k in 3:
		var x := 76.0 + k * 84.0
		_demo_flag(Vector2(x, 92), demos[k])
		Pix.draw_c(self, x, 102, "W = %d" % demos[k], white)
		Pix.draw_c(self, x, 110, "~%d" % (demos[k] * 3), dim)

	Pix.draw_c(self, 160, 128, L.t("flag_l1"), white)
	Pix.draw_c(self, 160, 140, L.t("flag_l2"), dim)
	Pix.draw_c(self, 160, 152, L.t("flag_l3"), amber)
	Pix.draw_c(self, 160, 164, L.t("flag_l4"), dim)


func _demo_flag(base: Vector2, w: int) -> void:
	var mag: float = absi(w)
	var dir := signi(w)
	draw_rect(Rect2(base.x, base.y - 24, 1, 24), Color("6a5e48"))
	draw_rect(Rect2(base.x, base.y - 25, 1, 1), Color("d8a838"))
	var top := Vector2(base.x, base.y - 24.0)
	var white := Color("e8e4dc")
	var red := Color("c03830")
	if w == 0:
		for i in 6:
			var sway := sin(t * 1.5 + i * 0.4) * 0.5 * (i / 6.0)
			draw_rect(Rect2(top.x + 1 + sway, top.y + 1 + i, 2, 1),
				white if i < 2 else red)
	else:
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


## Touch page (touchscreens only): the controls, shown as replica buttons.
func _draw_touch_page() -> void:
	var amber := Color(Vga.UI_TEXT)
	var white := Color("e8e4dc")
	var dim := Color(Vga.UI_DIM)
	var dark := Color(Vga.UI_LO)

	Pix.draw_shadow_c(self, 160, 5, L.t("touch_title"), amber, dark, 2)

	# replica button row, exactly as it appears in battle
	_mock_btn(Rect2(34, 40, 26, 28), "<", white, 2)
	_mock_btn(Rect2(62, 40, 26, 28), ">", white, 2)
	_mock_btn(Rect2(94, 41, 68, 26), L.t("w0"), white, 1)
	_mock_btn(Rect2(166, 41, 56, 26), L.t("btn_fire"), Color(Vga.P1_ACCENT), 2)
	_mock_btn(Rect2(228, 40, 26, 28), "+", white, 2)
	_mock_btn(Rect2(256, 40, 26, 28), "-", white, 2)
	Pix.draw_c(self, 61, 74, L.t("angle"), dim)
	Pix.draw_c(self, 128, 74, L.t("lbl_weapon"), dim)
	Pix.draw_c(self, 194, 74, L.t("btn_fire"), dim)
	Pix.draw_c(self, 255, 74, L.t("power"), dim)

	Pix.draw_c(self, 160, 96, L.t("touch_l1"), white)
	Pix.draw_c(self, 160, 110, L.t("touch_l2"), white)
	Pix.draw_c(self, 160, 124, L.t("touch_l3"), dim)
	Pix.draw_c(self, 160, 138, L.t("touch_l4"), dim)
	Pix.draw_c(self, 160, 152, L.t("touch_l5"), amber)


func _mock_btn(r: Rect2, label: String, col: Color, sc: int) -> void:
	draw_rect(r, Color(Vga.UI_BG))
	draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), Color(Vga.UI_HI))
	draw_rect(Rect2(r.position, Vector2(1, r.size.y)), Color(Vga.UI_HI))
	draw_rect(Rect2(r.position + Vector2(0, r.size.y - 1), Vector2(r.size.x, 1)), Color(Vga.UI_LO))
	draw_rect(Rect2(r.position + Vector2(r.size.x - 1, 0), Vector2(1, r.size.y)), Color(Vga.UI_LO))
	var cy := r.position.y + r.size.y / 2.0 - (5 * sc) / 2.0
	Pix.draw_c(self, r.position.x + r.size.x / 2.0, cy, label, col, sc)


## Charges page: hard mode and its history — the M.11's incremental propellant
## charges, drawn as a powder-charge ladder using the game's actual presets.
func _draw_charges_page() -> void:
	var amber := Color(Vga.UI_TEXT)
	var white := Color("e8e4dc")
	var dim := Color(Vga.UI_DIM)
	var dark := Color(Vga.UI_LO)
	var green := Color(Vga.P2_ACCENT)

	Pix.draw_shadow_c(self, 160, 5, L.t("hard_title"), amber, dark, 2)

	# charge ladder: bar height follows the in-game power presets
	var presets := [32.0, 50.0, 66.0, 82.0, 96.0]  # battle.gd CHARGES
	var base_y := 86.0
	for i in 5:
		var bx := 70.0 + i * 40.0
		var bh: float = roundf(presets[i] * 0.42)
		var col := amber if i < 4 else green
		draw_rect(Rect2(bx, base_y - bh, 22, bh), col)
		draw_rect(Rect2(bx, base_y - bh, 22, 1), Color("fff8e0"))
		Pix.draw_c(self, bx + 11, base_y + 4, str(i + 1), white)
		Pix.draw_c(self, bx + 11, base_y - bh - 8, str(int(presets[i])), dim)
	draw_rect(Rect2(58, base_y + 1, 216, 1), Color(Vga.UI_HI))

	Pix.draw_c(self, 160, 104, L.t("hard_h1"), white)
	Pix.draw_c(self, 160, 114, L.t("hard_h2"), white)
	Pix.draw_c(self, 160, 124, L.t("hard_h3"), dim)
	Pix.draw_c(self, 160, 134, L.t("hard_h4"), dim)
	Pix.draw_c(self, 160, 150, L.t("hard_h5"), amber)
	Pix.draw_c(self, 160, 160, L.t("hard_h6"), green)
	Pix.draw_c(self, 160, 172, L.t("hard_hint"), dim)


func _draw_gun_page(gun: Dictionary, tex: Texture2D) -> void:
	var amber := Color(Vga.UI_TEXT)
	var white := Color("e8e4dc")
	var dim := Color(Vga.UI_DIM)
	var dark := Color(Vga.UI_LO)

	Pix.draw_shadow_c(self, 160, 5, gun.title, amber, dark, 2)

	# photograph with an archive-plate frame
	if tex != null:
		var pw := tex.get_width()
		var ph := tex.get_height()
		var px := 10.0
		var py := 24.0
		draw_rect(Rect2(px - 2, py - 2, pw + 4, ph + 4), Color(Vga.UI_LO))
		draw_rect(Rect2(px - 1, py - 1, pw + 2, ph + 2), Color("d8cfc0"))
		draw_texture(tex, Vector2(px, py))
		Pix.draw_c(self, px + pw / 2.0, py + ph + 6, L.t(gun.cap), dim)

	# fact sheet
	var y := 30
	for row in gun.stats:
		var label: String = row[0]
		if L.T.has(label):
			label = L.t(label)
		Pix.draw(self, Vector2(194, y), label, dim)
		Pix.draw(self, Vector2(250, y), row[1], white)
		y += 11


func _draw_manual() -> void:
	var amber := Color(Vga.UI_TEXT)
	var white := Color("e8e4dc")
	var dim := Color(Vga.UI_DIM)
	var dark := Color(Vga.UI_LO)

	Pix.draw_shadow_c(self, 160, 5, L.t("help_title"), amber, dark, 2)

	# --- diagram box ---
	var box := Rect2(10, 20, 300, 96)
	draw_rect(box, Color("1c2028"))
	draw_rect(Rect2(box.position, Vector2(box.size.x, 1)), Color(Vga.UI_HI))
	draw_rect(Rect2(box.position + Vector2(0, box.size.y - 1), Vector2(box.size.x, 1)), dark)
	draw_rect(Rect2(box.position, Vector2(1, box.size.y)), Color(Vga.UI_HI))
	draw_rect(Rect2(box.position + Vector2(box.size.x - 1, 0), Vector2(1, box.size.y)), dark)

	# ground and gun
	var oy := 104.0
	draw_rect(Rect2(12, oy, 296, 3), Color(Vga.ROCK_MID))
	draw_rect(Rect2(12, oy + 3, 296, 9), Color(Vga.ROCK_DEEP))
	var origin := Vector2(32, oy)
	draw_rect(Rect2(origin.x - 5, origin.y - 4, 10, 4), Color("4a5058"))
	for i in 6:
		var p := origin + Vector2(0, -4) + Vector2.from_angle(deg_to_rad(-DEMO_TH)) * i
		draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), Color("6a7078"))

	# wind arrows, top of the box
	for i in 3:
		Pix.draw(self, Vector2(216 + i * 8, 26), ">", amber)
	Pix.draw(self, Vector2(244, 26), "W = 8", amber)

	# trajectories: dashed = calm, solid amber = wind (same equations as play)
	var tf := _flight_time()
	var k := 0
	var tt := 0.0
	while tt <= tf:
		var p0 := _traj(0.0, tt)
		var pw := _traj(DEMO_W, tt)
		if k % 3 != 0:
			draw_rect(Rect2(origin.x + p0.x, origin.y - p0.y, 1, 1), dim)
		draw_rect(Rect2(origin.x + pw.x, origin.y - pw.y, 1, 1), amber)
		tt += 0.03
		k += 1

	# impact ticks and the drift bracket DX between them
	var x0 := origin.x + _traj(0.0, tf).x
	var x1 := origin.x + _traj(DEMO_W, tf).x
	draw_rect(Rect2(x0, oy - 3, 1, 3), dim)
	draw_rect(Rect2(x1, oy - 3, 1, 3), amber)
	draw_rect(Rect2(x0, oy + 5, x1 - x0, 1), white)
	draw_rect(Rect2(x0, oy + 4, 1, 3), white)
	draw_rect(Rect2(x1, oy + 4, 1, 3), white)
	Pix.draw_c(self, (x0 + x1) / 2.0, oy + 7, "DX", white)

	# curve labels
	Pix.draw(self, Vector2(x0 - 40, 40), L.t("help_nowind"), dim)
	Pix.draw(self, Vector2(mini(int(x1 - 20), 250), 66), L.t("help_wind"), amber)

	# animated shell riding the wind curve
	var ta := fmod(t * 0.45, 1.15) * tf
	var sp := _traj(DEMO_W, ta)
	if ta <= tf:
		draw_rect(Rect2(origin.x + sp.x - 1, origin.y - sp.y - 1, 2, 2), Color(Vga.SHELL))

	# --- formulas (the game's real constants) ---
	var fy := 122
	Pix.draw(self, Vector2(14, fy), "V0 = 30 + 2.2*%s      G = 110 PX/S^2" % L.t("power"), white)
	Pix.draw(self, Vector2(14, fy + 8), "X(T) = V0*COS(%s)*T + 2*W*T^2" % L.t("angle"), white)
	Pix.draw(self, Vector2(14, fy + 16), "Y(T) = V0*SIN(%s)*T - 55*T^2" % L.t("angle"), white)
	Pix.draw(self, Vector2(14, fy + 24), "%s: DX = 2*W*T^2   (W = %s -9..9)" %
		[L.t("help_drift"), L.t("wind")], amber)

	# --- in words ---
	Pix.draw_c(self, 160, 156, L.t("help_w1"), dim)
	Pix.draw_c(self, 160, 164, L.t("help_w2"), dim)
	Pix.draw_c(self, 160, 172, L.t("help_w3"), dim)
