extends Node2D
## Media-kit renderer (dev tool): renders the game wordmark and the
## Prescription Games logo to transparent PNGs using the real in-game font
## and caduceus art, so press assets are pixel-identical to the game.
## Run:  MEDIA_DIR=/path godot --path . tools/media.tscn

var out := ""
var cad_tex: ImageTexture   # must outlive the draw call until rendering


func _ready() -> void:
	out = OS.get_environment("MEDIA_DIR")
	if out.is_empty():
		out = "user://"
	var spl := preload("res://src/splash.gd").new()
	cad_tex = spl._make_caduceus()
	spl.free()
	await _render(Vector2i(256, 40), _draw_wordmark, "logo-game-wordmark.png")
	await _render(Vector2i(140, 150), _draw_studio, "logo-prescription-games.png")
	print("[media] done")
	get_tree().quit()


func _render(size: Vector2i, painter: Callable, file: String) -> void:
	var vp := SubViewport.new()
	vp.size = size
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var n := Node2D.new()
	# SubViewports do not inherit the project's default canvas filter —
	# without this the scaled glyphs come out linear-filtered (soft edges)
	n.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	vp.add_child(n)
	n.draw.connect(func(): painter.call(n))
	n.queue_redraw()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.save_png(out.path_join(file))
	print("[media] wrote ", file)
	vp.queue_free()


func _draw_wordmark(n: Node2D) -> void:
	var dark := Color(Vga.UI_LO)
	Pix.draw_shadow_c(n, 128, 2, L.t("subtitle"), Color(Vga.UI_DIM), dark)
	Pix.draw_shadow_c(n, 128, 10, L.t("title"), Color(Vga.UI_TEXT), dark, 3)
	Pix.draw_shadow_c(n, 128, 28, L.t("subtitle2"), Color(Vga.UI_DIM), dark)


func _draw_studio(n: Node2D) -> void:
	n.draw_texture_rect(cad_tex, Rect2(29, 2, 82, 124), false)
	Pix.draw_shadow_c(n, 70, 132, "PRESCRIPTION GAMES", Color("d8a838"), Color(Vga.UI_LO))
	Pix.draw_c(n, 70, 142, "EST. 1994", Color("8a6a24"))
