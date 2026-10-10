extends Node
## Dev tool: checks every localized string against the pixel font.
##   godot --headless --path . res://tools/text_check.tscn
## Reports glyphs missing from pixfont.gd and text wider than its slot
## (default: the 316 px screen at 1x; tighter slots listed in LIMITS).

# key -> [scale, max width px, suffix appended at runtime]
const LIMITS := {
	"flag_title": [2, 272, ""], "flag_title_pad": [2, 272, ""], "touch_title": [2, 272, ""],
	"hard_title": [2, 272, ""], "help_title": [2, 272, ""], "gun_skoda_t": [2, 272, ""],
	"btn_fire": [2, 52, ""], "btn_menu": [1, 31, ""],
	"btn_hold_wind": [1, 64, ""],
	"w0": [1, 64, ""], "w1": [1, 64, " X2"], "w2": [1, 64, " X2"],
	"st_rate": [1, 54, ""], "st_cal": [1, 54, ""], "st_shell": [1, 54, ""],
	"st_range": [1, 54, ""], "st_crew": [1, 54, ""], "st_weight": [1, 54, ""],
	"st_maker": [1, 54, ""], "st_service": [1, 54, ""], "st_powder": [1, 54, ""],
	"st_charges": [1, 54, ""], "st_v0": [1, 54, ""],
}
# what %s may stand for (the longest one is measured); %d -> "9"
const ARGS := ["wind_l", "wind_r", "wind_0", "team0", "team1"]


func _ready() -> void:
	var problems := 0
	for key in L.T:
		for lang in L.LANGS:
			var s: String = L.T[key].get(lang, "")
			if s.is_empty():
				print("MISSING  %s [%s]" % [key, lang])
				problems += 1
				continue
			var arg := ""
			for a in ARGS:
				var v: String = L.T[a][lang]
				if v.length() > arg.length():
					arg = v
			s = s.replace("%+d", "+9").replace("%d", "9").replace("%s", arg)
			for ch in s.to_upper():
				if ch != " " and not Pix.glyphs.has(ch):
					print("GLYPH    %s [%s] '%s' in: %s" % [key, lang, ch, s])
					problems += 1
			var lim: Array = LIMITS.get(key, [1, 316, ""])
			var w: int = Pix.width(s + lim[2], lim[0])
			if w > lim[1]:
				print("WIDTH    %s [%s] %d > %d px: %s" % [key, lang, w, lim[1], s])
				problems += 1
	print("text_check: %d problem(s)" % problems)
	get_tree().quit(1 if problems > 0 else 0)
