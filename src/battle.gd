extends Node2D
## One round of the duel: two mortars on destructible alpine terrain.
## Turn flow: INTRO banner -> TURN_START -> AIM (input or Rx) -> FIRING
## (pixel-marched ballistics with wind) -> RESOLVE (settle, deaths) -> next
## turn, until a gun dies -> ROUND_OVER banner -> finished(winner).

signal finished(winner: int)
signal aborted

const TerrainScript := preload("res://src/terrain.gd")
const CannonScript := preload("res://src/cannon.gd")
const ParticlesScript := preload("res://src/particles.gd")
const HudScript := preload("res://src/hud.gd")
const RxScript := preload("res://src/prescription.gd")

const W := 320
const H := 200
const HUD_H := 14
const GRAV := 110.0
const WIND_ACC := 4.0
const SIM_DT := 1.0 / 120.0   # shell flight is integrated in fixed slices

# hard mode: the five historical propellant charges as power presets
# (charges 1-4 for all shells, the 5th only for light ones — not the 380KG)
const CHARGES := [32.0, 50.0, 66.0, 82.0, 96.0]

const WEAPONS := [
	{"label": "GRANATA", "r": 7.0, "dmg": 32.0, "ammo": -1, "vmul": 1.0, "px": 2, "split": 0},
	{"label": "380KG", "r": 14.0, "dmg": 65.0, "ammo": 2, "vmul": 0.88, "px": 3, "split": 0},
	{"label": "SRAPNEL", "r": 5.0, "dmg": 16.0, "ammo": 2, "vmul": 1.0, "px": 2, "split": 5},
]

enum St {INTRO, TURN_START, AIM, FIRING, RESOLVE, DEATH, ROUND_OVER}

var state: int = St.INTRO
var state_t := 0.0
var rng := RandomNumberGenerator.new()

var world: Node2D
var terrain: Node
var guns: Array = []
var parts: Node
var hud: Node
var trail_img: Array = []   # one trail per player: you aim over YOUR last arc
var trail_tex: Array = []
var trail_spr: Sprite2D

var wind := 0
var wind_est := 0     # soldier's (slightly fuzzy) estimate in knots
var cur := 0
var tab_held := 0.0
var tab_down := false # TAB went down during this human aim (tap vs hold)
var pow_dir := 0      # discrete key-repeat state for power keys
var pow_hold := 0.0
var pow_rep := 0.0
var shells: Array = []
var volley_best_x := 1e9
var volley_best_d := 1e9
var volley_pred := 0.0          # calculator's drift forecast for this volley
var volley_fb_done := false
var last_pred := [null, null]   # per player: forecast vs measured drift of
var last_meas := [null, null]   # their previous shot (assist feedback)
var shake_t := 0.0
var shake_mag := 0.0
var banner_lines: Array = []
var winner := -1
var rx: Array = [null, null]   # prescription software (the computer gunner)
var rx_plan := {}


func _ready() -> void:
	rng.randomize()
	world = Node2D.new()
	add_child(world)

	var sky := Sprite2D.new()
	sky.centered = false
	sky.texture = Vga.make_sky(rng)
	world.add_child(sky)

	var gx0 := rng.randi_range(20, 84)
	var gx1 := rng.randi_range(236, 300)
	terrain = TerrainScript.new()
	world.add_child(terrain)
	terrain.generate(rng, HUD_H, [gx0, gx1])

	for i in 2:
		var timg := Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
		trail_img.append(timg)
		trail_tex.append(ImageTexture.create_from_image(timg))
	trail_spr = Sprite2D.new()
	trail_spr.centered = false
	trail_spr.texture = trail_tex[0]
	world.add_child(trail_spr)

	for i in 2:
		var c: Node2D = CannonScript.new()
		world.add_child(c)
		c.setup(i, terrain, gx0 if i == 0 else gx1)
		guns.append(c)

	parts = ParticlesScript.new()
	parts.battle = self
	world.add_child(parts)

	hud = HudScript.new()
	hud.battle = self
	add_child(hud)

	wind = rng.randi_range(-8, 8)
	cur = (G.round_num - 1) % 2
	if G.mode == 1:
		rx[1] = RxScript.new(rng)
	if G.autotest or G.demo_rx:
		rx[0] = RxScript.new(rng)
		rx[1] = RxScript.new(rng)

	if G.hard:
		for i in 2:
			if rx[i] == null:
				guns[i].power = CHARGES[guns[i].charge]

	banner_lines = ["%s %d" % [L.t("round"), G.round_num],
		"%d : %d" % [G.scores[0], G.scores[1]]]
	state = St.INTRO
	state_t = 0.0


func _process(delta: float) -> void:
	# a stall (hidden browser tab, window drag) must not teleport the game
	var dt := minf(delta, 0.1)
	if G.autotest:
		dt = 1.0 / 30.0
	state_t += dt

	if shake_t > 0.0:
		shake_t -= dt
		world.position = Vector2(rng.randi_range(-1, 1), rng.randi_range(-1, 1)) * shake_mag
		if shake_t <= 0.0:
			world.position = Vector2.ZERO
			shake_mag = 0.0   # the next shake starts from its own strength

	match state:
		St.INTRO:
			if state_t > (0.2 if G.autotest else 1.4):
				banner_lines = []
				_begin_turn()
		St.TURN_START:
			if state_t > (0.05 if G.autotest else 0.5):
				_set_state(St.AIM)
				if rx[cur] != null:
					rx_plan = rx[cur].plan(self, cur)
					guns[cur].weapon = rx_plan.weapon
		St.AIM:
			if rx[cur] != null:
				_rx_aim(dt)
			else:
				_human_aim(dt)
		St.FIRING:
			_step_shells(dt)
		St.RESOLVE:
			if state_t > (0.1 if G.autotest else 0.55):
				_resolve()
		St.DEATH:
			if state_t > (0.3 if G.autotest else 1.6):
				_round_over()
		St.ROUND_OVER:
			if G.autotest and state_t > 0.3:
				finished.emit(winner)


func _set_state(s: int) -> void:
	state = s
	state_t = 0.0


func _begin_turn() -> void:
	_set_state(St.TURN_START)
	# wind drifts every shot, with occasional gusts — no firing solution
	# stays valid for long. Reflect at the bounds instead of clamping
	# (a clamped walk is sticky: it camps at max strength 4x too often),
	# and strong winds tend to ease back toward calm. See tools/wind_sim.gd.
	var drift := rng.randi_range(-3, 3)
	if rng.randf() < 0.12:
		drift += 5 if rng.randf() < 0.5 else -5
	if absi(wind) >= 6:
		drift -= signi(wind)
	wind += drift
	if wind > 9:
		wind = 18 - wind
	elif wind < -9:
		wind = -18 - wind
	wind_est = 0
	if wind != 0:
		wind_est = maxi(1, roundi(absi(wind) * 3.0 + rng.randf_range(-2.0, 2.0)))
	tab_held = 0.0
	tab_down = false
	pow_dir = 0
	# show this player's own previous arc, faintly, while they aim
	trail_spr.texture = trail_tex[cur]
	trail_spr.modulate = Color(1, 1, 1, 0.55)
	Sfx.play("beep", -8.0, 1.0 if cur == 0 else 0.85)


## Polls hardware keys OR the touch overlay's on-screen buttons.
func _pressed_key(k: int) -> bool:
	return Input.is_key_pressed(k) or Touch.held.has(k)


func _human_aim(dt: float) -> void:
	var g: Node = guns[cur]
	var mul := 0.25 if Input.is_key_pressed(KEY_SHIFT) else 1.0
	if _pressed_key(KEY_LEFT):
		g.angle = clampf(g.angle + 32.0 * mul * dt, 8.0, 172.0)
	if _pressed_key(KEY_RIGHT):
		g.angle = clampf(g.angle - 32.0 * mul * dt, 8.0, 172.0)
	_power_input(dt)
	if _pressed_key(KEY_TAB):
		tab_held += dt
	else:
		tab_held = 0.0


## Power moves in exact single units: a tap is +-1, holding repeats slowly
## after a delay and speeds up later. Shift halves the repeat rate.
## The first step is taken on the key-press EVENT (_unhandled_input), so a
## tap shorter than a frame still counts; polling only drives the repeat.
func _power_input(dt: float) -> void:
	var up := _pressed_key(KEY_UP)
	var dn := _pressed_key(KEY_DOWN)
	var dir := 0
	if up and dn:
		dir = pow_dir   # both held: the latest press wins
	elif up:
		dir = 1
	elif dn:
		dir = -1
	if dir != pow_dir:
		pow_dir = dir
		pow_hold = 0.0
		pow_rep = 0.0
		return
	if dir == 0:
		return
	if G.hard:
		return  # charges step one per press, no hold-repeat
	pow_hold += dt
	if pow_hold < 0.35:
		return
	var rate := 8.0 if pow_hold < 1.3 else 18.0
	if Input.is_key_pressed(KEY_SHIFT):
		rate *= 0.5
	pow_rep += dt * rate
	while pow_rep >= 1.0:
		pow_rep -= 1.0
		_step_power(dir)


func _max_charge(g: Node) -> int:
	return 3 if g.weapon == 1 else 4   # the 380KG never takes charge 5


func _step_power(dir: int) -> void:
	var g: Node = guns[cur]
	if G.hard:
		g.charge = clampi(g.charge + dir, 0, _max_charge(g))
		g.power = CHARGES[g.charge]
		return
	g.power = clampf(roundf(g.power) + dir, 10.0, 100.0)


## The wind helper (flag + soldier's estimate) shows while a human holds TAB.
func wind_helper() -> bool:
	return state == St.AIM and rx[cur] == null and tab_held >= 0.3


func _rx_aim(dt: float) -> void:
	var g: Node = guns[cur]
	g.angle = move_toward(g.angle, rx_plan.angle, 55.0 * dt)
	g.power = move_toward(g.power, rx_plan.power, 60.0 * dt)
	if g.angle == rx_plan.angle and g.power == rx_plan.power \
			and state_t > (0.05 if G.autotest else rx_plan.delay):
		_fire()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var human_aim: bool = state == St.AIM and rx[cur] == null
	# TAB works on release: a short tap cycles the weapon, a long hold only
	# shows the wind helper (so checking the wind never switches weapons).
	# The press is an event too, so a tap shorter than a frame still counts.
	if event.keycode == KEY_TAB:
		if event.echo or event.alt_pressed:   # Alt+Tab is the window manager's
			return
		if event.pressed:
			tab_down = human_aim
		else:
			if tab_down and human_aim and tab_held < 0.3:
				_cycle_weapon()
			tab_down = false
			tab_held = 0.0
		return
	if not G.is_any_key(event):
		return
	var key: int = event.keycode
	match state:
		St.AIM:
			if key == KEY_ESCAPE:
				aborted.emit()   # also while the prescription software aims
			elif not human_aim:
				return
			elif key == KEY_SPACE or key == KEY_ENTER or key == KEY_KP_ENTER:
				_fire()
			elif key == KEY_UP or key == KEY_DOWN:
				var dir := 1 if key == KEY_UP else -1
				pow_dir = dir
				pow_hold = 0.0
				pow_rep = 0.0
				_step_power(dir)
		St.ROUND_OVER:
			finished.emit(winner)
		_:
			if key == KEY_ESCAPE:
				aborted.emit()


func _cycle_weapon() -> void:
	_select_loaded(guns[cur])
	Sfx.play("click", -6.0)


## Next weapon that still has ammo (GRANATA never runs out).
func _select_loaded(g: Node) -> void:
	for i in range(1, WEAPONS.size() + 1):
		var w: int = (g.weapon + i) % WEAPONS.size()
		if g.ammo[w] != 0:
			g.weapon = w
			break
	if G.hard and rx[g.idx] == null and g.charge > _max_charge(g):
		g.charge = _max_charge(g)
		g.power = CHARGES[g.charge]


func _fire() -> void:
	var g: Node = guns[cur]
	var w: Dictionary = WEAPONS[g.weapon]
	if g.ammo[g.weapon] == 0:
		Sfx.play("click")
		return
	var fired_w: int = g.weapon
	if g.ammo[g.weapon] > 0:
		g.ammo[g.weapon] -= 1
	# the calculator's forecast for this volley, from nominal (pre-dispersion)
	# values — exactly what the assist panel showed the player
	var v0_nom: float = (30.0 + g.power * 2.2) * w.vmul
	var t_nom: float = 2.0 * v0_nom * sin(deg_to_rad(g.angle)) / GRAV
	volley_pred = 0.5 * WIND_ACC * wind * t_nom * t_nom
	# per-shot dispersion: real artillery never lands twice in the same hole
	var aim := deg_to_rad(g.angle + rng.randf_range(-0.6, 0.6))
	var dirv := Vector2(cos(aim), -sin(aim))
	var v0: float = (30.0 + g.power * 2.2) * w.vmul * rng.randf_range(0.99, 1.01)
	shells = [{
		"pos": g.muzzle(), "vel": dirv * v0, "w": g.weapon,
		"split": w.split, "from": cur, "age": 0.0, "wvx": 0.0, "wdisp": 0.0,
	}]
	volley_best_x = 1e9
	volley_best_d = 1e9
	volley_fb_done = false
	trail_img[cur].fill(Color(0, 0, 0, 0))
	trail_tex[cur].update(trail_img[cur])
	trail_spr.texture = trail_tex[cur]
	trail_spr.modulate = Color.WHITE
	g.fire_anim()
	parts.muzzle_dust(g.muzzle(), dirv)
	Sfx.play("shot", 0.0, rng.randf_range(0.92, 1.08))
	_shake(0.15, 1.0)
	if G.autotest:
		print("[autotest] P%d fires w=%d angle=%.0f power=%.0f wind=%d" %
			[cur, fired_w, g.angle, g.power, wind])
	# that was the last special shell: back to one that can fire
	if g.ammo[fired_w] == 0:
		_select_loaded(g)
	_set_state(St.FIRING)


## Shell flight runs in fixed SIM_DT slices: the arc, and so where a shot
## lands, must not depend on the frame rate.
func _step_shells(dt: float) -> void:
	var n := maxi(ceili(dt / SIM_DT - 0.001), 1)
	var trail_dirty := false
	for k in n:
		if _advance_shells(dt / n):
			trail_dirty = true
		if shells.is_empty():
			break
	if trail_dirty:
		trail_tex[cur].update(trail_img[cur])
	if shells.is_empty():
		_set_state(St.RESOLVE)


## One slice of flight; returns true if the trail image changed.
func _advance_shells(dt: float) -> bool:
	var trail_dirty := false
	var foe: Node = guns[1 - cur]
	for i in range(shells.size() - 1, -1, -1):
		var s: Dictionary = shells[i]
		s.age += dt
		s.vel.x += wind * WIND_ACC * dt
		s.vel.y += GRAV * dt
		# integrate the wind's own contribution for the assist feedback
		s.wvx += wind * WIND_ACC * dt
		s.wdisp += s.wvx * dt

		# shrapnel splits at apex
		if s.split > 0 and s.vel.y >= 0.0:
			shells.remove_at(i)
			for k in s.split:
				shells.append({
					"pos": s.pos, "vel": Vector2(s.vel.x + (k - 2) * 16.0, s.vel.y),
					"w": s.w, "split": 0, "from": s.from, "age": s.age,
					"wvx": s.wvx, "wdisp": s.wdisp,
				})
			Sfx.play("click", -4.0, 0.6)
			continue

		var from_p: Vector2 = s.pos
		var to_p: Vector2 = s.pos + s.vel * dt
		var steps := maxi(ceili(from_p.distance_to(to_p)), 1)   # <= 1 px apart
		var hit := false
		for st in range(1, steps + 1):
			var p := from_p.lerp(to_p, float(st) / steps)
			var xi := int(floorf(p.x))
			var yi := int(floorf(p.y))
			if xi < -40 or xi > 360 or yi > 240:
				_record_impact(360.0 if xi > 0 else -40.0, foe)
				_record_feedback(s)
				shells.remove_at(i)
				hit = true
				break
			if yi >= H - 2:
				_explode(Vector2(p.x, H - 2), s)
				_record_feedback(s)
				shells.remove_at(i)
				hit = true
				break
			if xi >= 0 and xi < W and yi >= HUD_H:
				if terrain.solid(xi, yi):
					_explode(p, s)
					_record_feedback(s)
					shells.remove_at(i)
					hit = true
					break
				var gun_hit := false
				for g in guns:
					if not g.alive:
						continue
					if g.idx == s.from and s.age < 0.3:
						continue
					if g.hit_rect().has_point(p):
						_explode(p, s)
						_record_feedback(s)
						shells.remove_at(i)
						gun_hit = true
						break
				if gun_hit:
					hit = true
					break
				if yi < H:
					trail_img[cur].set_pixel(xi, yi, Color(Vga.TRAIL, 0.5))
					trail_dirty = true
		if not hit:
			s.pos = to_p
	return trail_dirty


## First shell of the volley to land fixes the assist feedback pair:
## the panel's forecast vs the wind displacement the shell really picked up.
func _record_feedback(s: Dictionary) -> void:
	if volley_fb_done:
		return
	volley_fb_done = true
	last_pred[s.from] = roundi(volley_pred)
	last_meas[s.from] = roundi(s.wdisp)


func _record_impact(x: float, foe: Node) -> void:
	var d := absf(x - foe.position.x)
	if d < volley_best_d:
		volley_best_d = d
		volley_best_x = x


func _explode(p: Vector2, s: Dictionary) -> void:
	var w: Dictionary = WEAPONS[s.w]
	terrain.crater(p, w.r)
	parts.explosion(p, w.r)
	_shake(0.12 + w.r * 0.012, minf(1.0 + w.r * 0.15, 3.0))
	Sfx.play("boom2" if w.r >= 10.0 else "boom1", 0.0, rng.randf_range(0.9, 1.1))
	for g in guns:
		if not g.alive:
			continue
		var d: float = (g.center() as Vector2).distance_to(p)
		var reach: float = w.r * 2.2
		if d < reach:
			var dmg: float = w.dmg if d < w.r * 0.6 else w.dmg * (1.0 - d / reach)
			g.take_damage(dmg)
			if G.autotest:
				print("[autotest] P%d hit for %.0f -> hp %.0f" % [g.idx, dmg, g.hp])
	_record_impact(p.x, guns[1 - s.from])


func _shake(t: float, mag: float) -> void:
	shake_t = maxf(shake_t, t)
	shake_mag = maxf(shake_mag, mag)


func _resolve() -> void:
	for g in guns:
		if not g.alive:
			continue
		var drop: float = g.settle()
		if drop > 4.0:
			g.take_damage((drop - 4.0) * 2.0)
			parts.dust(g.position, 10)
			Sfx.play("thud", -4.0)

	if rx[cur] != null and guns[1 - cur].hp > 0.0:
		var foe: Node = guns[1 - cur]
		var dir := 1.0 if foe.position.x > guns[cur].position.x else -1.0
		if volley_best_x < 1e8:
			rx[cur].report((volley_best_x - foe.position.x) * dir)

	var dead: Array = []
	for g in guns:
		if g.alive and g.hp <= 0.0:
			dead.append(g)
	if dead.is_empty():
		cur = 1 - cur
		_begin_turn()
		return

	for g in dead:
		g.alive = false
		terrain.crater(g.center(), 15.0)
		parts.explosion(g.center(), 18.0)
		g.visible = false
	Sfx.play("destroy")
	_shake(0.5, 3.0)
	if guns[0].alive == guns[1].alive:
		winner = -1
	else:
		winner = 0 if guns[0].alive else 1
	if G.autotest:
		print("[autotest] round over, winner=%d" % winner)
	_set_state(St.DEATH)


func _round_over() -> void:
	if winner < 0:
		banner_lines = [L.t("draw_r"), "", L.t("press_key")]
	else:
		var s := [G.scores[0], G.scores[1]]
		s[winner] += 1
		banner_lines = [
			L.t("wins_round") % L.t("team%d" % winner),
			"%d : %d" % [s[0], s[1]],
			"",
			L.t("press_key"),
		]
		if s[winner] >= G.WIN_SCORE:
			banner_lines[2] = L.t("wins_war")
			Sfx.play("win")
	_set_state(St.ROUND_OVER)
