extends RefCounted
class_name WivoriCharacterMotion

# Role/species-responsive animation policy, separated from the authored GLB
# animations. These values never affect movement physics, stamina, upgrades,
# joystick input or save state. They only determine animation presentation.
const IDLE_VARIATION={
	"hero":.13,
	"fox":.47,
	"pig":1.41,
	"duck":2.20,
	"rabbit":2.90,
	"raccoon":3.55
}
const FOOTSTEP_CADENCE={
	"hero":1.00,
	"fox":1.04,
	"pig":.88,
	"duck":1.14,
	"rabbit":1.20,
	"raccoon":1.12
}

static func phase_for(species_id: String) -> float:
	return float(IDLE_VARIATION.get(species_id,.7))

static func cadence_for(species_id: String) -> float:
	return float(FOOTSTEP_CADENCE.get(species_id,1.0))

static func target_gait(speed: float) -> float:
	return clampf(speed/4.2,0.0,1.0)

static func choose_clip(walk: float,speed: float,carrying: int,turn_error: float) -> String:
	if walk<=.06:
		return "turn" if absf(turn_error)>.19 else "idle"
	if carrying>0:return "carry"
	return "run" if speed>6.8 else "walk"

static func playback_rate(speed: float,clip: String,species_id: String) -> float:
	if clip not in ["walk","run","carry"]:return 1.0
	var base:float=6.5 if clip=="run" else 4.3
	return clampf(speed/base*cadence_for(species_id),.55,1.85)

static func head_scan(time_seconds: float,phase: float,walking: float) -> float:
	# Subtle alertness for idle dogs and varying species. Scans get quieter
	# while moving to avoid unrealistic rapid facial swaying.
	var attention:float=1.0-clampf(walking*.82,0.0,.82)
	return .085*sin(time_seconds*.71+phase)*attention

static func blink_factor(time_seconds: float,phase: float) -> float:
	# The Blender-authored idle clip already closes the eyes. Moving clips
	# do not, so a sparse, brief paired blink prevents staring during travel.
	var moment:float=fposmod(time_seconds+phase*.7,4.7)
	return 1.0-.86*exp(-pow((moment-3.35)/.065,2.0))

static func tail_response(time_seconds: float,phase: float,walking: float,role: String) -> float:
	# A recovering parcel thief wags differently from the happy player.
	var amplitude:float=.14 if role=="player" else .09 if role=="helper" else .11
	return amplitude*(.35+.65*walking)*sin(time_seconds*3.1+phase)

static func ear_follow(time_seconds: float,phase: float,side: float) -> float:
	return .055*sin(time_seconds*2.0+phase+side*1.6)

static func turn_blend(current_yaw: float,wanted_yaw: float,delta: float,role: String) -> float:
	var response:float=11.8 if role=="player" else 8.5 if role in ["customer","resident"] else 10.0
	return lerp_angle(current_yaw,wanted_yaw,1.0-exp(-response*delta))
