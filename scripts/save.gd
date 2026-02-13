extends Node

## TODO -- more in depth Implementation of this needs further breakdown to 
##         decide how to implment this

var save_file : ConfigFile = ConfigFile.new()
const SAVE_PATH : String = "user://save.cfg"

func save_all():
	save_settings()

func save_settings():
	var sfx_value := Global.sfx_volume
	var msfx_value := Global.music_volume
	var e_high_score = Global.e_high_score
	var n_high_score = Global.n_high_score
	var h_high_score = Global.h_high_score
	
	save_file.set_value("Audio", "SFX_VOLUME", sfx_value)
	save_file.set_value("Audio", "MSFX_VOLUME", msfx_value)
	save_file.set_value("Score", "E_HIGH_SCORE", e_high_score)
	save_file.set_value("Score", "N_HIGH_SCORE", n_high_score)
	save_file.set_value("Score", "H_HIGH_SCORE", h_high_score)
	
	# Save the file
	save_file.save(SAVE_PATH)

func load_settings():
	var err = save_file.load(SAVE_PATH)
	if err != OK:
		return
	
	var sfx_value := float(save_file.get_value("Audio", "SFX_VOLUME", 0.45))
	var msfx_value := float(save_file.get_value("Audio", "MSFX_VOLUME", 0.45))
	var e_high_score = int(save_file.get_value("Score", "E_HIGH_SCORE", 0))
	var n_high_score = int(save_file.get_value("Score", "N_HIGH_SCORE", 0))
	var h_high_score = int(save_file.get_value("Score", "H_HIGH_SCORE", 0))
	
	Global.sfx_volume = sfx_value
	Global.music_volume = msfx_value
	Global.e_high_score = e_high_score
	Global.e_high_score = n_high_score
	Global.e_high_score = h_high_score
	
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx_value))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(msfx_value))
