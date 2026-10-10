extends RefCounted
## The prescription software (Rx) — the computer gunner.
## Opens with a ballistic estimate, then walks its power
## onto the target from each miss. If shots keep landing in the same spot
## (a mountain is in the way) it raises the arc; at full charge and still
## short it flattens toward 45 degrees instead. It always fires toward the
## foe. Error noise shrinks every shot, so it gets scary if you let the
## duel drag on.

var rng: RandomNumberGenerator
var fired := false
var last_power := 0.0
var last_angle := 0.0
var last_err := 1e9   # signed miss distance along firing direction
var stuck := 0
var noise := 13.0


func _init(r: RandomNumberGenerator) -> void:
	rng = r


func plan(battle: Node, me_idx: int) -> Dictionary:
	var me: Node = battle.guns[me_idx]
	var foe: Node = battle.guns[1 - me_idx]
	var dir := 1.0 if foe.position.x > me.position.x else -1.0
	var dist: float = absf(foe.position.x - me.position.x)
	var angle: float
	var power: float

	if not fired:
		angle = 90.0 - dir * 30.0 + rng.randf_range(-6.0, 6.0)
		var v_needed := sqrt(maxf(dist, 40.0) * battle.GRAV / 0.87)
		power = (v_needed - 30.0) / 2.2 + rng.randf_range(-noise, noise)
		power -= battle.wind * dir * 0.5
	else:
		angle = last_angle
		power = last_power
		if stuck >= 2:
			if last_power < 99.0:
				# lob higher over the obstacle
				angle += (90.0 - angle) * 0.35 + rng.randf_range(-3.0, 3.0)
				power += rng.randf_range(2.0, 8.0)
			else:
				# already at full charge (a headwind eats the range): lobbing
				# would only shorten it — flatten toward the 45-degree arc
				angle += (90.0 - dir * 45.0 - angle) * 0.5
			stuck = 0
		elif last_power >= 99.0 and last_err < -12.0:
			# full charge and still short: only a flatter arc reaches further
			angle += (90.0 - dir * 45.0 - angle) * 0.35
		else:
			power += -last_err * 0.17 + rng.randf_range(-noise, noise) * 0.4

	power = clampf(power, 15.0, 100.0)
	# always fire toward the foe: a lob never tips past the vertical
	angle = clampf(angle, 15.0, 80.0) if dir > 0.0 else clampf(angle, 100.0, 165.0)
	noise = maxf(noise * 0.55, 1.5)
	last_angle = angle
	last_power = power
	fired = true

	return {
		"angle": angle,
		"power": power,
		"weapon": _pick_weapon(me),
		"delay": rng.randf_range(0.7, 1.4),
	}


func report(err_along_dir: float) -> void:
	if last_err < 1e8 and absf(err_along_dir - last_err) < 7.0 and absf(err_along_dir) > 12.0:
		stuck += 1
	else:
		stuck = 0   # only CONSECUTIVE repeats mean an obstacle
	last_err = err_along_dir


func _pick_weapon(me: Node) -> int:
	if absf(last_err) < 14.0 and me.ammo[1] != 0:
		return 1  # 380 kg — confident, drop the big one
	if absf(last_err) < 30.0 and me.ammo[2] != 0 and rng.randf() < 0.5:
		return 2  # shrapnel — close enough to straddle
	return 0
