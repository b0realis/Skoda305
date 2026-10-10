extends Node
## VGA palette, ordered dithering and background painting (autoload "Vga").
## Everything on screen uses these colors — DOS 6.22 / Bitmap Brothers mood:
## dusty sepia sky, steel-blue alpine ridges, muted rock and snow.

# --- sky gradient bands, top -> horizon ---
const SKY_BANDS: Array[String] = ["6e6a78", "8a8078", "a69684", "c2ae94", "dcc8a8", "eedebc"]
const SUN := "f4e8c8"
const CLOUD := "d8ccb4"
const RIDGE_FAR := "8a8496"
const RIDGE_FAR_SNOW := "cfceda"
const RIDGE_NEAR := "6f6a7c"
const RIDGE_NEAR_SNOW := "c4c4ce"

# --- terrain ---
const SNOW_HI := "e6e6ee"
const SNOW_LO := "c6c8d6"
const GRASS_HI := "6a7048"
const GRASS_LO := "565c3c"
const ROCK_HI := "9a8e7c"
const ROCK_MID := "786c5c"
const ROCK_DARK := "5a5044"
const ROCK_DEEP := "423a30"
const ROCK_BOTTOM := "2e2820"
const SCORCH := "201a14"

# --- fire / explosions ---
const FIRE: Array[String] = ["ffffff", "ffe890", "ffb040", "e06020", "a03020"]
const SMOKE_HI := "9a9490"
const SMOKE_LO := "6e6a66"
const TRAIL := "d8c8a0"
const SHELL := "fff8e0"

# --- HUD / UI ---
const UI_BG := "23262c"
const UI_HI := "4e5560"
const UI_LO := "121418"
const UI_TEXT := "e4d8ac"
const UI_DIM := "8a8578"
const P1_ACCENT := "d2504a"   # Austro-Hungarian red
const P2_ACCENT := "4e9a50"   # Italian green
const HP_GOOD := "4e9a50"
const HP_WARN := "d8a838"
const HP_BAD := "c03830"

const BAYER4 := [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]

const FADE_LEVELS := 6
var _fade_masks: Array = []


static func c(hex: String) -> Color:
	return Color(hex)


func bayer(x: int, y: int) -> float:
	return (BAYER4[y % 4][x % 4] + 0.5) / 16.0


func hash01(x: int, y: int) -> float:
	var n: int = x * 374761393 + y * 668265263
	n = (n ^ (n >> 13)) * 1274126177
	return float(absi(n) % 4096) / 4096.0


## Ordered-dither fade masks (built lazily, half res drawn 2x for chunk).
## Level i blacks out pixels with bayer < (i+1)/FADE_LEVELS; the last level
## covers everything.
func fade_mask(level: int) -> ImageTexture:
	if _fade_masks.is_empty():
		for i in FADE_LEVELS:
			var frac := float(i + 1) / FADE_LEVELS
			var img := Image.create_empty(160, 100, false, Image.FORMAT_RGBA8)
			for y in 100:
				for x in 160:
					if bayer(x, y) < frac:
						img.set_pixel(x, y, Color.BLACK)
			_fade_masks.append(ImageTexture.create_from_image(img))
	return _fade_masks[clampi(level, 0, FADE_LEVELS - 1)]


## Paint the 320x200 background: dithered sky gradient, low sun, dithered
## clouds and two distant alpine ridge silhouettes with snow caps.
func make_sky(rng: RandomNumberGenerator) -> ImageTexture:
	var img := Image.create_empty(320, 200, false, Image.FORMAT_RGBA8)
	var bands: Array[Color] = []
	for h in SKY_BANDS:
		bands.append(Color(h))

	for y in 200:
		var t := float(y) / 199.0
		var f := t * (bands.size() - 1)
		var i := mini(int(f), bands.size() - 2)
		var frac := f - i
		for x in 320:
			var col := bands[i + 1] if frac > bayer(x, y) else bands[i]
			img.set_pixel(x, y, col)

	# sun disc with dithered halo
	var sun := Color(SUN)
	var sx := rng.randi_range(50, 270)
	var sy := rng.randi_range(28, 52)
	for y in range(sy - 13, sy + 14):
		for x in range(sx - 13, sx + 14):
			if x < 0 or x >= 320 or y < 0 or y >= 200:
				continue
			var d := Vector2(x - sx, y - sy).length()
			if d < 8.0:
				img.set_pixel(x, y, sun)
			elif d < 12.0 and bayer(x, y) > (d - 8.0) / 4.0:
				img.set_pixel(x, y, sun)

	# distant ridges (far light, near darker) with snow caps
	_ridge(img, rng, 96.0, 26.0, Color(RIDGE_FAR), Color(RIDGE_FAR_SNOW), 88.0)
	_ridge(img, rng, 122.0, 30.0, Color(RIDGE_NEAR), Color(RIDGE_NEAR_SNOW), 104.0)

	# dithered cloud streaks
	var cloud := Color(CLOUD)
	for i in 3:
		var cx := rng.randi_range(30, 290)
		var cy := rng.randi_range(22, 62)
		var w := rng.randi_range(34, 80)
		var h := rng.randi_range(3, 6)
		for y in range(cy - h, cy + h + 1):
			for x in range(cx - w, cx + w + 1):
				if x < 0 or x >= 320 or y < 0 or y >= 200:
					continue
				var dx := float(x - cx) / w
				var dy := float(y - cy) / h
				if dx * dx + dy * dy < 1.0 and bayer(x, y) < 0.55:
					img.set_pixel(x, y, cloud)

	return ImageTexture.create_from_image(img)


func _ridge(img: Image, rng: RandomNumberGenerator, base: float, amp: float,
		col: Color, snow: Color, snowline: float) -> void:
	var p1 := rng.randf_range(0.0, TAU)
	var p2 := rng.randf_range(0.0, TAU)
	var p3 := rng.randf_range(0.0, TAU)
	for x in 320:
		var ry := base \
			+ sin(x * 0.018 + p1) * amp \
			+ sin(x * 0.051 + p2) * amp * 0.45 \
			+ sin(x * 0.113 + p3) * amp * 0.18
		var top := maxi(int(ry), 0)
		for y in range(top, 200):
			var d := y - top
			if y < int(snowline) and d < 3 + int(hash01(x, y) * 3.0):
				img.set_pixel(x, y, snow)
			else:
				img.set_pixel(x, y, col)
