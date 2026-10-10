extends Sprite2D
## Destructible alpine terrain: midpoint-displacement ridge painted into a
## 320x200 image. Craters carve circles, scorch the rim and collapse the
## affected columns (classic Scorched Earth sand-fall).

const W := 320
const H := 200

var img: Image
var tex: ImageTexture
var hud_h := 14
var snowline := 84.0


func generate(rng: RandomNumberGenerator, hud_height: int, gun_xs: Array) -> void:
	hud_h = hud_height
	snowline = 80.0 + rng.randf() * 10.0
	centered = false
	position = Vector2.ZERO

	# --- heightline: midpoint displacement, remapped to screen space ---
	var n := 257
	var a := PackedFloat32Array()
	a.resize(n)
	a[0] = rng.randf()
	a[n - 1] = rng.randf()
	_displace(a, 0, n - 1, 0.55, rng)
	var lo := 1e9
	var hi := -1e9
	for v in a:
		lo = minf(lo, v)
		hi = maxf(hi, v)
	var span := maxf(hi - lo, 0.001)
	var amp := rng.randf_range(92.0, 122.0)
	var lift := rng.randf_range(0.0, 10.0)
	var heights := PackedInt32Array()
	heights.resize(W)
	for x in W:
		var f := float(x) * (n - 1) / (W - 1)
		var i := mini(int(f), n - 2)
		var v: float = lerpf(a[i], a[i + 1], f - i)
		var y := 184.0 - ((v - lo) / span) * amp - lift
		heights[x] = clampi(int(y), 48, 186)

	# flat firing pads under the guns, blended at the edges
	for gx in gun_xs:
		var pad: int = heights[gx]
		for x in range(gx - 7, gx + 8):
			if x >= 0 and x < W:
				heights[x] = pad
		for k in 3:
			var xl: int = gx - 8 - k
			var xr: int = gx + 8 + k
			if xl >= 1:
				heights[xl] = int(lerpf(heights[xl], pad, 0.6 - k * 0.2))
			if xr < W - 1:
				heights[xr] = int(lerpf(heights[xr], pad, 0.6 - k * 0.2))

	# --- paint ---
	img = Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	for x in W:
		var h := heights[x]
		for y in range(hud_h, H):
			if y < h:
				continue
			var d := y - h
			var nz: float = Vga.hash01(x, y)
			var col: Color
			if y < snowline + nz * 5.0 and d < 3 + int(nz * 2.0):
				col = Color(Vga.SNOW_HI) if (d == 0 or nz > 0.35) else Color(Vga.SNOW_LO)
			elif h > 150 and d < 3:
				col = Color(Vga.GRASS_HI) if (d == 0 or nz > 0.4) else Color(Vga.GRASS_LO)
			elif d < 2:
				col = Color(Vga.ROCK_HI) if nz > 0.3 else Color(Vga.ROCK_MID)
			elif d < 7:
				col = Color(Vga.ROCK_HI) if nz < 0.12 else Color(Vga.ROCK_MID)
			elif d < 16:
				col = Color(Vga.ROCK_MID) if nz < 0.1 else Color(Vga.ROCK_DARK)
			elif d > 44 or y > 194:
				col = Color(Vga.ROCK_BOTTOM)
			else:
				col = Color(Vga.ROCK_DARK) if nz < 0.08 else Color(Vga.ROCK_DEEP)
			img.set_pixel(x, y, col)

	tex = ImageTexture.create_from_image(img)
	texture = tex


func _displace(a: PackedFloat32Array, l: int, r: int, disp: float,
		rng: RandomNumberGenerator) -> void:
	if r - l < 2:
		return
	var m := (l + r) / 2
	a[m] = (a[l] + a[r]) / 2.0 + rng.randf_range(-disp, disp)
	_displace(a, l, m, disp * 0.58, rng)
	_displace(a, m, r, disp * 0.58, rng)


func solid(x: int, y: int) -> bool:
	if x < 0 or x >= W or y < hud_h or y >= H:
		return false
	return img.get_pixel(x, y).a > 0.5


## First solid y in column x (200 if the column is empty).
func height_at(x: int) -> int:
	if x < 0 or x >= W:
		return H
	for y in range(hud_h, H):
		if img.get_pixel(x, y).a > 0.5:
			return y
	return H


## Highest ground over a footprint (smallest y).
func ground_at(x0: int, x1: int) -> int:
	var best := H
	for x in range(x0, x1 + 1):
		best = mini(best, height_at(x))
	return best


func crater(p: Vector2, r: float) -> void:
	var cx := int(p.x)
	var cy := int(p.y)
	var rr := int(ceil(r)) + 2
	# scorched rim first, then carve, then collapse
	for y in range(cy - rr, cy + rr + 1):
		for x in range(cx - rr, cx + rr + 1):
			if x < 0 or x >= W or y < hud_h or y >= H:
				continue
			var d := Vector2(x - cx, y - cy).length()
			if d > r and d <= r + 2.0 and img.get_pixel(x, y).a > 0.5:
				img.set_pixel(x, y, Color(Vga.SCORCH))
	for y in range(cy - rr, cy + rr + 1):
		for x in range(cx - rr, cx + rr + 1):
			if x < 0 or x >= W or y < hud_h or y >= H:
				continue
			if Vector2(x - cx, y - cy).length() <= r:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	for x in range(maxi(cx - rr, 0), mini(cx + rr + 1, W)):
		_collapse_column(x)
	tex.update(img)


## Drop floating pixels: compact the column to the bottom, preserving order.
func _collapse_column(x: int) -> void:
	var cols: Array[Color] = []
	for y in range(hud_h, H):
		var c := img.get_pixel(x, y)
		if c.a > 0.5:
			cols.append(c)
	var y_write := H - 1
	for i in range(cols.size() - 1, -1, -1):
		img.set_pixel(x, y_write, cols[i])
		y_write -= 1
	for y in range(hud_h, y_write + 1):
		img.set_pixel(x, y, Color(0, 0, 0, 0))


## Dig out the gun emplacement so a settled gun is never buried.
func carve_rect(rect: Rect2) -> void:
	for y in range(int(rect.position.y), int(rect.end.y)):
		for x in range(int(rect.position.x), int(rect.end.x)):
			if x >= 0 and x < W and y >= hud_h and y < H:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	tex.update(img)
