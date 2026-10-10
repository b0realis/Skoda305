extends Node2D
## One siege gun. Each side fields its historical piece:
##   0 — Škoda 30.5 cm Mörser M.11 (k.u.k.): squat kettle mount, fat stubby barrel.
##   1 — Obice da 305 (Regio Esercito): tall A-frame box mount, longer thinner barrel.
## Bodies are pixel sprites from ASCII art ('1' dark, '2' mid, '3' light,
## '4'/'5' team ribbon); the barrel is drawn as chunky rects so it can rotate.
## Origin = bottom-center of the platform on the ground.

const TEAMS := [
	{
		"body": [
			".....1221.....",
			"....122221....",
			"...12233221...",
			"..1223333221..",
			".122222222221.",
			"14522222222541",
			"11111111111111",
		],
		"pivot": Vector2(0, -5),
		"barrel_len": 9,
		"barrel_w": 3,
		"colors": {"1": "22262c", "2": "3a4048", "3": "5c646e", "4": "d2504a", "5": "e8e4dc"},
	},
	{
		"body": [
			".....1221.....",
			"....122321....",
			"....122321....",
			"...12223221...",
			"...12222221...",
			"..1222222221..",
			".122222222221.",
			"14522222222541",
			"11111111111111",
		],
		"pivot": Vector2(0, -6),
		"barrel_len": 11,
		"barrel_w": 2,
		"colors": {"1": "2c4426", "2": "48703c", "3": "6ca05a", "4": "4e9a50", "5": "c03830"},
	},
]

var idx := 0
var terrain: Node
var angle := 60.0     # degrees, 0 = right, 90 = up, 180 = left
var power := 52.0     # 10..100
var hp := 100.0
var alive := true
var weapon := 0
var charge := 1       # hard mode: index into battle's CHARGES ladder
var ammo: Array = [-1, 2, 2]
var recoil := 0.0
var flash := 0.0
var body_tex: ImageTexture
var body_h := 7
var barrel_len := 9
var barrel_w := 3


func setup(i: int, terr: Node, x: int) -> void:
	idx = i
	terrain = terr
	position = Vector2(x, 0)
	angle = 60.0 if i == 0 else 120.0
	var team: Dictionary = TEAMS[i]
	var body: Array = team.body
	body_h = body.size()
	barrel_len = team.barrel_len
	barrel_w = team.barrel_w
	var pal: Dictionary = team.colors
	var w: int = body[0].length()
	var img := Image.create_empty(w, body_h, false, Image.FORMAT_RGBA8)
	for y in body_h:
		for x2 in w:
			var ch: String = body[y][x2]
			if ch != ".":
				img.set_pixel(x2, y, Color(pal[ch]))
	body_tex = ImageTexture.create_from_image(img)
	settle()


func center() -> Vector2:
	return position + Vector2(0, -body_h * 0.5)


func pivot() -> Vector2:
	return position + (TEAMS[idx].pivot as Vector2)


## Elevation as the player reads it: 0 = flat toward the enemy, 90 = up —
## the same scale on both sides (the right gun fires leftward).
func display_angle() -> int:
	return roundi(angle if idx == 0 else 180.0 - angle)


func barrel_dir() -> Vector2:
	var a := deg_to_rad(angle)
	return Vector2(cos(a), -sin(a))


func muzzle() -> Vector2:
	return pivot() + barrel_dir() * (barrel_len + 1)


func hit_rect() -> Rect2:
	return Rect2(position.x - 7, position.y - body_h, 14, body_h)


## Drop onto the terrain; returns fall distance in pixels.
func settle() -> float:
	var ground: int = terrain.ground_at(int(position.x) - 5, int(position.x) + 5)
	ground = mini(ground, 198)
	var drop := ground - position.y
	if drop > 0.0:
		position.y = ground
	terrain.carve_rect(Rect2(position.x - 7, position.y - body_h, 14, body_h - 1))
	return maxf(drop, 0.0)


func take_damage(d: float) -> void:
	hp = maxf(hp - d, 0.0)


func fire_anim() -> void:
	recoil = 2.0
	flash = 0.12


func _process(delta: float) -> void:
	recoil = maxf(recoil - delta * 12.0, 0.0)
	flash = maxf(flash - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	if not alive:
		return
	var pv: Vector2 = TEAMS[idx].pivot
	var kick := barrel_dir() * -recoil
	# barrel: tapered chunky tube
	var mid := Color(TEAMS[idx].colors["2"])
	var lit := Color(TEAMS[idx].colors["3"])
	for i in range(2, barrel_len + 1):
		var p := pv + kick + barrel_dir() * i
		var s := barrel_w if i <= int(barrel_len * 0.66) else barrel_w - 1
		s = maxi(s, 1)
		draw_rect(Rect2(p - Vector2(s / 2.0, s / 2.0), Vector2(s, s)), mid)
	draw_rect(Rect2(pv + kick + barrel_dir() * 3 - Vector2(0.5, 0.5), Vector2(1, 1)), lit)
	# body
	draw_texture(body_tex, Vector2(-7, -body_h) + kick * 0.4)
	# muzzle flash
	if flash > 0.0:
		var t := flash / 0.12
		var m := pv + barrel_dir() * (barrel_len + 2)
		draw_circle(m, 1.0 + 3.0 * t, Color(Vga.FIRE[1]))
		draw_circle(m, 1.0 + 1.5 * t, Color(Vga.FIRE[0]))
