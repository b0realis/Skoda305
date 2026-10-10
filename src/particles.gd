extends Node2D
## Pixel debris, smoke and expanding explosion flashes. Also draws the shells
## in flight (it lives inside the shaken "world" node, so everything jolts
## together). All marks are chunky 1-2 px rects — no alpha gradients, no AA.

var battle: Node = null
var parts: Array = []   # {pos, vel, g, life, t, col, size}
var rings: Array = []   # {pos, maxr, life, t}
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()


func explosion(pos: Vector2, r: float) -> void:
	rings.append({"pos": pos, "maxr": r * 1.6, "life": 0.3 + r * 0.012, "t": 0.0})
	var n := int(r * 4)
	for i in n:
		var ang := rng.randf_range(PI, TAU)  # up half-dome bias
		if rng.randf() < 0.35:
			ang = rng.randf_range(0.0, TAU)
		var spd := rng.randf_range(26.0, 60.0 + r * 5.0)
		var col: Color
		var roll := rng.randf()
		if roll < 0.35:
			col = Color(Vga.FIRE[rng.randi_range(1, 4)])
		elif roll < 0.75:
			col = Color(Vga.ROCK_MID) if rng.randf() < 0.5 else Color(Vga.ROCK_DARK)
		else:
			col = Color(Vga.SCORCH)
		parts.append({
			"pos": pos, "vel": Vector2.from_angle(ang) * spd, "g": 150.0,
			"life": rng.randf_range(0.4, 1.1), "t": 0.0, "col": col,
			"size": 1 if rng.randf() < 0.7 else 2,
		})
	for i in 6:
		parts.append({
			"pos": pos + Vector2(rng.randf_range(-r, r) * 0.4, 0),
			"vel": Vector2(rng.randf_range(-4, 4), rng.randf_range(-16, -7)),
			"g": -3.0, "life": rng.randf_range(1.4, 2.4), "t": 0.0,
			"col": Color(Vga.SMOKE_HI) if rng.randf() < 0.5 else Color(Vga.SMOKE_LO),
			"size": 2,
		})


func muzzle_dust(pos: Vector2, dirv: Vector2) -> void:
	for i in 8:
		parts.append({
			"pos": pos,
			"vel": dirv.rotated(rng.randf_range(-0.5, 0.5)) * rng.randf_range(20.0, 55.0),
			"g": 60.0, "life": rng.randf_range(0.2, 0.45), "t": 0.0,
			"col": Color(Vga.SMOKE_HI), "size": 1,
		})


func dust(pos: Vector2, n: int) -> void:
	for i in n:
		parts.append({
			"pos": pos + Vector2(rng.randf_range(-6, 6), rng.randf_range(-2, 0)),
			"vel": Vector2(rng.randf_range(-14, 14), rng.randf_range(-24, -6)),
			"g": 120.0, "life": rng.randf_range(0.3, 0.7), "t": 0.0,
			"col": Color(Vga.ROCK_MID), "size": 1,
		})


func _process(delta: float) -> void:
	var dt := delta
	if G.autotest:
		dt = 1.0 / 30.0
	for i in range(parts.size() - 1, -1, -1):
		var p: Dictionary = parts[i]
		p.t += dt
		if p.t >= p.life:
			parts.remove_at(i)
			continue
		p.vel.y += p.g * dt
		p.pos += p.vel * dt
	for i in range(rings.size() - 1, -1, -1):
		rings[i].t += dt
		if rings[i].t >= rings[i].life:
			rings.remove_at(i)
	queue_redraw()


func _draw() -> void:
	for ring in rings:
		var ph: float = ring.t / ring.life
		var r: float = lerpf(2.0, ring.maxr, 1.0 - (1.0 - ph) * (1.0 - ph))
		var ci := mini(int(ph * Vga.FIRE.size()), Vga.FIRE.size() - 1)
		draw_circle(ring.pos, r, Color(Vga.FIRE[ci]))
	for p in parts:
		var sz: int = p.size
		draw_rect(Rect2((p.pos as Vector2).round() - Vector2(sz / 2.0, sz / 2.0),
			Vector2(sz, sz)), p.col)
	if battle != null:
		for s in battle.shells:
			var px: int = battle.WEAPONS[s.w].px
			draw_rect(Rect2((s.pos as Vector2).round() - Vector2(px / 2.0, px / 2.0),
				Vector2(px, px)), Color(Vga.SHELL))
