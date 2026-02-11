extends CanvasLayer

const VU_COUNT = 40
const FREQ_MAX = 2000.0
const MIN_DB = 40
const ANIMATION_SPEED = 0.1
const HEIGHT_SCALE = 2.0

@onready var color_rect = $ColorRect

var spectrum
var min_values = []
var max_values = []
var global_peak := 0.001

func _ready():
	spectrum = AudioServer.get_bus_effect_instance(1, 0)
	min_values.resize(VU_COUNT)
	min_values.fill(0.0)
	max_values.resize(VU_COUNT)
	max_values.fill(0.0)

func _process(delta):
	var prev_hz = 0.0
	var data = []

	for i in range(1, VU_COUNT + 1):
		var hz = i * FREQ_MAX / VU_COUNT
		var f = spectrum.get_magnitude_for_frequency_range(prev_hz, hz)
		var db = linear_to_db(f.length())
		var energy = clamp((MIN_DB + db) / MIN_DB, 0.0, 1.0)
		data.append(energy * HEIGHT_SCALE)
		prev_hz = hz

	var frame_peak := 0.001
	for v in data:
		frame_peak = max(frame_peak, v)

	global_peak = max(frame_peak, lerp(global_peak, frame_peak, 0.02))

	for i in range(VU_COUNT):
		if data[i] > max_values[i]:
			max_values[i] = data[i]
		else:
			max_values[i] = lerp(max_values[i], data[i], ANIMATION_SPEED)

	var fft = []
	for i in range(VU_COUNT):
		fft.append(clamp(max_values[i] / global_peak, 0.0, 1.0) * 0.5)
		
	color_rect.material.set_shader_parameter("freq_data", fft)
