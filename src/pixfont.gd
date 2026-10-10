extends Node
## Tiny variable-width pixel font (5 px tall), DOS-HUD style (autoload "Pix").
## Uppercase + digits + punctuation, rendered from a white atlas with modulate.
## Diacritic-free on purpose: CP437 never had čšž either.

const H := 5
const SPACE_W := 3

const DATA := {
	"A": [".##.", "#..#", "####", "#..#", "#..#"],
	"B": ["###.", "#..#", "###.", "#..#", "###."],
	"C": [".###", "#...", "#...", "#...", ".###"],
	"D": ["###.", "#..#", "#..#", "#..#", "###."],
	"E": ["####", "#...", "###.", "#...", "####"],
	"F": ["####", "#...", "###.", "#...", "#..."],
	"G": [".###", "#...", "#.##", "#..#", ".##."],
	"H": ["#..#", "#..#", "####", "#..#", "#..#"],
	"I": ["###", ".#.", ".#.", ".#.", "###"],
	"J": ["..##", "...#", "...#", "#..#", ".##."],
	"K": ["#..#", "#.#.", "##..", "#.#.", "#..#"],
	"L": ["#...", "#...", "#...", "#...", "####"],
	"M": ["#...#", "##.##", "#.#.#", "#...#", "#...#"],
	"N": ["#..#", "##.#", "#.##", "#..#", "#..#"],
	"O": [".##.", "#..#", "#..#", "#..#", ".##."],
	"P": ["###.", "#..#", "###.", "#...", "#..."],
	"Q": [".##.", "#..#", "#..#", ".##.", "...#"],
	"R": ["###.", "#..#", "###.", "#.#.", "#..#"],
	"S": [".###", "#...", ".##.", "...#", "###."],
	"T": ["###", ".#.", ".#.", ".#.", ".#."],
	"U": ["#..#", "#..#", "#..#", "#..#", ".##."],
	"V": ["#.#", "#.#", "#.#", "#.#", ".#."],
	"W": ["#...#", "#...#", "#.#.#", "##.##", "#...#"],
	"X": ["#.#", "#.#", ".#.", "#.#", "#.#"],
	"Y": ["#.#", "#.#", ".#.", ".#.", ".#."],
	"Z": ["####", "...#", ".##.", "#...", "####"],
	"0": [".##.", "#..#", "#.##", "##.#", ".##."],
	"1": [".#.", "##.", ".#.", ".#.", "###"],
	"2": ["###.", "...#", ".##.", "#...", "####"],
	"3": ["###.", "...#", ".##.", "...#", "###."],
	"4": ["#..#", "#..#", "####", "...#", "...#"],
	"5": ["####", "#...", "###.", "...#", "###."],
	"6": [".###", "#...", "###.", "#..#", ".##."],
	"7": ["####", "...#", "..#.", ".#..", ".#.."],
	"8": [".##.", "#..#", ".##.", "#..#", ".##."],
	"9": [".##.", "#..#", ".###", "...#", "###."],
	".": [".", ".", ".", ".", "#"],
	",": [".", ".", ".", "#", "#"],
	":": [".", "#", ".", "#", "."],
	"!": ["#", "#", "#", ".", "#"],
	"?": ["###.", "...#", ".##.", "....", ".#.."],
	"-": ["...", "...", "###", "...", "..."],
	"+": ["...", ".#.", "###", ".#.", "..."],
	"=": ["...", "###", "...", "###", "..."],
	"<": ["..#", ".#.", "#..", ".#.", "..#"],
	">": ["#..", ".#.", "..#", ".#.", "#.."],
	"/": ["..#", "..#", ".#.", "#..", "#.."],
	"*": ["...", "#.#", ".#.", "#.#", "..."],
	"(": [".#", "#.", "#.", "#.", ".#"],
	")": ["#.", ".#", ".#", ".#", "#."],
	"'": ["#", "#", ".", ".", "."],
	"^": [".#.", "#.#", "...", "...", "..."],
	"~": ["....", ".#.#", "#.#.", "....", "...."],
}

var atlas: ImageTexture
var glyphs := {}  # char -> [x_offset, width]


func _ready() -> void:
	var total := 0
	for ch in DATA:
		total += DATA[ch][0].length() + 1
	var img := Image.create_empty(maxi(total, 1), H, false, Image.FORMAT_RGBA8)
	var ox := 0
	for ch in DATA:
		var rows: Array = DATA[ch]
		var w: int = rows[0].length()
		for y in H:
			for x in w:
				if rows[y][x] == "#":
					img.set_pixel(ox + x, y, Color.WHITE)
		glyphs[ch] = [ox, w]
		ox += w + 1
	atlas = ImageTexture.create_from_image(img)


func width(text: String, scale: int = 1) -> int:
	var w := 0
	for ch in text.to_upper():
		if ch == " ":
			w += SPACE_W + 1
		elif glyphs.has(ch):
			w += glyphs[ch][1] + 1
		else:
			w += 5
	return maxi(w - 1, 0) * scale


func draw(ci: CanvasItem, pos: Vector2, text: String, color: Color, scale: int = 1) -> void:
	var x := floorf(pos.x)
	var y := floorf(pos.y)
	for ch in text.to_upper():
		if ch == " ":
			x += (SPACE_W + 1) * scale
			continue
		if not glyphs.has(ch):
			ci.draw_rect(Rect2(x, y, 4 * scale, H * scale), color, false)
			x += 5 * scale
			continue
		var g: Array = glyphs[ch]
		ci.draw_texture_rect_region(atlas,
			Rect2(x, y, g[1] * scale, H * scale),
			Rect2(g[0], 0, g[1], H), color)
		x += (g[1] + 1) * scale


## Centered on cx.
func draw_c(ci: CanvasItem, cx: float, y: float, text: String, color: Color, scale: int = 1) -> void:
	draw(ci, Vector2(cx - width(text, scale) / 2.0, y), text, color, scale)


## Chunky title text with a dark drop shadow.
func draw_shadow(ci: CanvasItem, pos: Vector2, text: String, color: Color,
		shadow: Color, scale: int = 1) -> void:
	draw(ci, pos + Vector2(scale, scale), text, shadow, scale)
	draw(ci, pos, text, color, scale)


func draw_shadow_c(ci: CanvasItem, cx: float, y: float, text: String, color: Color,
		shadow: Color, scale: int = 1) -> void:
	draw_shadow(ci, Vector2(cx - width(text, scale) / 2.0, y), text, color, shadow, scale)
