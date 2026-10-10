extends Node2D
## Boot splash sequence, DOS style with ordered-dither fades:
##   1. "Prescription Games" studio logo — a gold caduceus on black.
##   2. The 1916 LOC photograph of the Skoda 305 mm M.11, in VGA sepia.
## Any key skips ahead.

signal done

const GOLD := "d8a838"
const GOLD_DARK := "8a6a24"
const GOLD_LIGHT := "f0d080"

var phase := 0
var t := 0.0
var durations := [3.2, 3.6]
var cad_tex: ImageTexture
var photo_tex: Texture2D


func _ready() -> void:
	cad_tex = _make_caduceus()
	if ResourceLoader.exists("res://assets/img/splash_photo.png"):
		photo_tex = load("res://assets/img/splash_photo.png")
	Sfx.play("sting", -4.0)


func _process(delta: float) -> void:
	if phase >= 2:
		return
	# clamp: texture generation makes the first frames slow, and a huge
	# delta would fast-forward the whole splash
	t += minf(delta, 0.05)
	if t > durations[phase]:
		_advance()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if G.is_any_key(event):
		_advance()


## Direct taps (touch or mouse): skip ahead.
func tap_at(_p: Vector2) -> void:
	_advance()


func _advance() -> void:
	if phase >= 2:
		return
	phase += 1
	t = 0.0
	if phase == 2:
		done.emit()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 320, 200), Color.BLACK)
	if phase == 0:
		draw_texture(cad_tex, Vector2(160 - 20, 20))
		Pix.draw_shadow_c(self, 160, 128, "PRESCRIPTION GAMES",
			Color(GOLD), Color(GOLD_DARK) * Color(0.4, 0.4, 0.4), 2)
		Pix.draw_c(self, 160, 146, L.t("presents"), Color(Vga.UI_DIM))
		Pix.draw_c(self, 160, 188, "(C) 1994 PRESCRIPTION GAMES", Color(GOLD_DARK))
	elif phase == 1 and photo_tex != null:
		draw_texture(photo_tex, Vector2.ZERO)
		draw_rect(Rect2(0, 184, 320, 16), Color.BLACK)
		Pix.draw_c(self, 160, 189, L.t("photo_cap"), Color(Vga.UI_DIM))

	# dithered fade in/out — logo phase only; the photograph cuts in clean
	if phase != 0:
		return
	var dur: float = durations[0]
	var cover := 0.0
	if t < 0.5:
		cover = 1.0 - t / 0.5
	elif t > dur - 0.5:
		cover = (t - (dur - 0.5)) / 0.5
	if cover > 0.0:
		var lvl := int(ceil(cover * Vga.FADE_LEVELS)) - 1
		if lvl >= 0:
			draw_texture_rect(Vga.fade_mask(lvl), Rect2(0, 0, 320, 200), false)


## Gold caduceus, 41x62: orb, upswept wings, staff, two crossing snakes.
func _make_caduceus() -> ImageTexture:
	var w := 41
	var h := 62
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var gold := Color(GOLD)
	var dark := Color(GOLD_DARK)
	var light := Color(GOLD_LIGHT)
	var cx := 20

	# orb
	for y in range(0, 7):
		for x in range(cx - 3, cx + 4):
			var d := Vector2(x - cx, y - 3).length()
			if d < 2.6:
				img.set_pixel(x, y, light if d < 1.4 else gold)

	# staff with pointed tip
	for y in range(7, h - 4):
		img.set_pixel(cx - 1, y, gold)
		img.set_pixel(cx, y, dark)
	img.set_pixel(cx - 1, h - 4, dark)
	img.set_pixel(cx - 1, h - 3, dark)

	# wings fanning up and outward
	for k in 6:
		var y := 15 - k
		var span := 4 + k * 2
		for j in span:
			var x1 := cx + 3 + j
			var x2 := cx - 3 - j
			if x1 < w:
				img.set_pixel(x1, y, gold if j % 3 != 2 else dark)
			if x2 >= 0:
				img.set_pixel(x2, y, gold if j % 3 != 2 else dark)

	# two snakes: cosine weave crossing the staff, tapering downward
	for y in range(17, 56):
		var ph := (y - 17) * 0.30
		var amp := 8.0 * (1.0 - (y - 17) / 39.0 * 0.55)
		var off := int(round(cos(ph) * amp))
		for s: int in [1, -1]:
			var x: int = cx + off * s
			if x >= 0 and x < w - 1:
				img.set_pixel(x, y, gold if s == 1 else dark)
				img.set_pixel(x + 1, y, dark if s == 1 else gold)

	# snake heads at the top, facing inward
	for s: int in [1, -1]:
		var hx: int = cx + 8 * s
		for y in range(14, 17):
			for x in range(hx - 1, hx + 2):
				if x >= 0 and x < w:
					img.set_pixel(x, y, light if y == 15 else gold)

	return ImageTexture.create_from_image(img)
