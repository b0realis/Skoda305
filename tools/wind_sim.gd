extends SceneTree
## Wind-walk design tool: compares boundary handling variants.
## Run: godot --headless --path . --script res://tools/wind_sim.gd
func _initialize() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for variant in ["clamp (old)", "reflect", "reflect+pull"]:
		var hist := {}
		var total := 0
		var extreme := 0
		var runs := 0
		var run_sum := 0
		for round_i in 20000:
			var wind := rng.randi_range(-8, 8)
			var side := signi(wind)
			var run_len := 0
			for turn in 30:
				var drift := rng.randi_range(-3, 3)
				if rng.randf() < 0.12:
					drift += 5 if rng.randf() < 0.5 else -5
				if variant == "reflect+pull" and absi(wind) >= 6:
					drift -= signi(wind)
				wind += drift
				if variant == "clamp (old)":
					wind = clampi(wind, -9, 9)
				elif wind > 9:
					wind = 18 - wind
				elif wind < -9:
					wind = -18 - wind
				total += 1
				hist[wind] = hist.get(wind, 0) + 1
				if absi(wind) == 9:
					extreme += 1
				if signi(wind) == side and side != 0:
					run_len += 1
				else:
					if run_len > 0:
						runs += 1
						run_sum += run_len
					side = signi(wind)
					run_len = 1
		var mid: float = (hist.get(2, 0) + hist.get(-2, 0)) / 2.0
		print("%-14s at-max: %4.1f%%  (vs mid value %4.1f%%)  avg same-side run: %.1f turns" %
			[variant, 100.0 * extreme / total, 100.0 * mid / total, float(run_sum) / maxi(runs, 1)])
	quit()
