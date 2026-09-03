extends Node3D

const WORLD_SIZE := 2048.0
const WATER_Y := 0.0
const TERRAIN_NEAR_STEP := 2.6
const TERRAIN_FAR_STEP := 15.0
const TREE_COL_RADIUS := 400.0
const VILLAGE_MIN_DIST := 420.0
const VILLAGE_MAX_DIST := 900.0
const VILLAGE_HOUSE_RADIUS := 90.0
const VILLAGE_PLAZA_RADIUS := 150.0

const QUALITY_NAMES := ["Low", "Medium", "High", "Ultra"]
const QUALITY_PRESETS := [
	{
		"sdfgi": false, "sdfgi_cascades": 0, "cascade0": 0.0, "sdfgi_max": 0.0,
		"volumetric": false, "glow": false, "ssr": false, "ssao": false,
		"dof": false, "autoexp": false, "fog": true,
		"msaa": 0, "scale": 0.75, "shadow": 260.0,
		"trees": 0.35, "rocks": 0.35, "grass": 0.4, "sakura": 0.5,
		"pine": 0.4, "bush": 0.4, "flower": 0.4,
	},
	{
		"sdfgi": false, "sdfgi_cascades": 0, "cascade0": 0.0, "sdfgi_max": 0.0,
		"volumetric": false, "glow": true, "ssr": false, "ssao": true,
		"dof": false, "autoexp": false, "fog": true,
		"msaa": 1, "scale": 1.0, "shadow": 320.0,
		"trees": 0.6, "rocks": 0.6, "grass": 0.6, "sakura": 0.7,
		"pine": 0.6, "bush": 0.6, "flower": 0.6,
	},
	{
		"sdfgi": true, "sdfgi_cascades": 2, "cascade0": 24.0, "sdfgi_max": 160.0,
		"volumetric": true, "glow": true, "ssr": false, "ssao": true,
		"dof": true, "autoexp": false, "fog": true,
		"msaa": 1, "scale": 1.0, "shadow": 380.0,
		"trees": 0.85, "rocks": 0.85, "grass": 0.8, "sakura": 0.9,
		"pine": 0.85, "bush": 0.85, "flower": 0.85,
	},
	{
		"sdfgi": true, "sdfgi_cascades": 4, "cascade0": 34.0, "sdfgi_max": 220.0,
		"volumetric": true, "glow": true, "ssr": true, "ssao": true,
		"dof": true, "autoexp": false, "fog": true,
		"msaa": 2, "scale": 1.0, "shadow": 480.0,
		"trees": 1.0, "rocks": 1.0, "grass": 1.0, "sakura": 1.0,
		"pine": 1.0, "bush": 1.0, "flower": 1.0,
	},
]

var _n1 := FastNoiseLite.new()
var _n2 := FastNoiseLite.new()
var _n3 := FastNoiseLite.new()
var _detail := FastNoiseLite.new()
var _heights := PackedFloat32Array()
var _axis := PackedFloat32Array()
var _grid := 0
var _defer_terrain := false
var _terrain_dirty := false
var _half := 0.0
var _villages: Array[Vector2] = []
var _reactors: Array = []
var _reactor_panel_open := false
var _phone_open := false
var _phone: Node
var _news_log: Array = []
var _meltdown_done := {}
var _rad_overlay: ColorRect
var _rad_overlay_alpha := 0.0
var _unit_wire_mesh: ArrayMesh
var _sun: DirectionalLight3D
var _moon: DirectionalLight3D
var _moon_disc: MeshInstance3D
var _moon_mat: StandardMaterial3D
var _stars: GPUParticles3D
var _water_mat: ShaderMaterial
var _env: Environment
var _cam_attr: CameraAttributesPractical
var _pause_menu: Control
var _shot := false
var _walk := false
var _drive := false
var _ztest := false
var _sanity := false
var _rooftest := false
var _launcher_mode := false
var _zombies_active := false
var _hp_bar: ProgressBar
var _stamina_bar: ProgressBar
var _thirst_bar: ProgressBar
var _horror_viy: TextureRect
var _horror_viy_t := 0.0
var _player: Node3D
var _spawn_pos := Vector3.ZERO
var _grass_mi: MultiMeshInstance3D
var _tree_mi: MultiMeshInstance3D
var _fol_mi: MultiMeshInstance3D
var _rock_mi: MultiMeshInstance3D
var _sakura_trunk_mi: MultiMeshInstance3D
var _sakura_fol_mi: MultiMeshInstance3D
var _pine_trunk_mi: MultiMeshInstance3D
var _pine_fol_mi: MultiMeshInstance3D
var _bush_mi: MultiMeshInstance3D
var _flower_mi: MultiMeshInstance3D
var _quality := 2
var _main_menu: Control
var _mangohud_on := false
var _video_width := 1920
var _video_height := 1080
var _video_mode := "windowed"
var _ui_scale := 1.0
var _touch_controls: Control
var _hud_layer: CanvasLayer
var _hud_root: Control
var _config := ConfigFile.new()
var _config_path := "user://settings.cfg"
var _world_seed := 2024
var _auto_start := false
var _season := "summer"

var _server := false
var _client := false
var _world_ready := false
var _net_test := false
var _night_test := false
var _net_port := Net.DEFAULT_PORT
var _max_players := Net.DEFAULT_MAX_PLAYERS
var _server_name := "Pico Peaks Server"
var _join_host := "127.0.0.1"
var _player_name := "Player"
var _ram_mb := 0
var _seed_set := false
var _player_name_set := false
var _mem_scale_cached := -1.0
var _net_players := {}
var _remote_bodies := {}
var _player_names := {}
var _npc_list: Array[Node3D] = []
var _cars_list: Array[Node3D] = []
var _bikes_list: Array[Node3D] = []
var _village_path_counter := 0
var _wolves: Array = []
var _wildlife: Array = []
var _wildlife_counter := 0
var _wolf_active := false
var _craters: Array = []
var _meteor_t := 200.0
var _farm_plots: Array = []
var _wells_loaded: Array = []
var _pickups := {}
var _next_pickup_id := 0
var _zombie_nodes := {}
var _pickup_nodes := {}
var _net_state_t := 0.0
var _net_target_pos := Vector3.ZERO

var _grass_base := Color(0.30, 0.48, 0.28)
var _sand := Color(0.68, 0.62, 0.47)
var _meadow := Color(0.27, 0.45, 0.25)
var _rock_col := Color(0.38, 0.38, 0.42)
var _snow_col := Color(0.93, 0.94, 0.96)
var _snow_line := 19.0
var _snow_top := 26.0
var _foliage := Color(0.14, 0.30, 0.13)
var _grass_bottom := Color(0.16, 0.33, 0.13)
var _grass_top := Color(0.45, 0.62, 0.30)
var _sakura := Color(0.93, 0.68, 0.80)
var _sky_top_day := Color(0.32, 0.52, 0.85)
var _sky_horizon_day := Color(0.58, 0.62, 0.70)
var _sky_ground_day := Color(0.18, 0.15, 0.12)
var _sky_ground_horizon_day := Color(0.52, 0.47, 0.43)
var _sun_col := Color(1.0, 0.91, 0.79)

var _time_of_day := 9.0
var _day_length := 1200.0
var _sky_mat: ProceduralSkyMaterial
var _clouds_mat: ShaderMaterial
var _hud_clock: Label
var _hud_prompt: Label
var _hud_ammo: Label
var _turbo_bar: ProgressBar
var _turbo_label: Label
var _chat_box: Control
var _console: Control
var _current_target: Node3D
var _sleep_fade: ColorRect
var _sleep_zzz: Label
var _hurt_flash: ColorRect
var _sleeping := false
var _crosshair: Array[Control] = []
var _loading: CanvasLayer

var _village_window_mats: Array = []
var _village_lamps: Array = []
var _fireflies: GPUParticles3D
var _village_powered: Array[bool] = []
var _village_outage: Array[float] = []
var _crisis_t := 90.0
var _quake_t := 0.0
var _quake_rpc_sent := false
var _tornadoes: Array = []
var _tornado_t := 160.0
var _tornado_shake := 0.0
var _sky_tick := 0
var _grid_status := ""
var _grid_blackout := false
var _grid_warned := false
var _tasks := {
	"reach_plant": false,
	"grid_powered": false,
	"cool": false,
	"storm": false,
	"refuel": false,
	"upgrade": false,
	"car": false,
	"sleep": false,
	"fish": false,
	"spring": false,
	"garden": false,
	"boat": false,
	"shop": false,
	"shrine": false,
	"koi": false,
	"wolf": false,
	"bunker": false,
	"bike": false,
	"meteor": false,
	"crop": false,
	"thirst": false,
	"bear": false,
	"boar": false,
	"mushroom": false,
	"grapple": false,
}
var _in_storm := false
var _prev_reactor_types := {}
var _prev_fuels := {}
var _task_count := 0
var _last_day := 1
var _fireworks: GPUParticles3D
var _game_over := false
var _game_over_layer: CanvasLayer
var _gazette_layer: CanvasLayer

var _weather := 0
var _weather_t := 0.0
var _wind_speed := 0.35
var _wind_target := 0.35
var _wind_dir := 0.0
var _wind_dir_target := 0.5
var _rain_density := 0.0
var _storm_flash_t := 0.0
var _flash_strength := 0.0
var _rain_noise_lp := 0.0
var _rain_audio: AudioStreamPlayer
var _thunder_audio: AudioStreamPlayer
var _thunder_wav: AudioStreamWAV
var _owl_audio: AudioStreamPlayer
var _owl_wav: AudioStreamWAV
var _owl_timer := 8.0
var _rain_particles: GPUParticles3D
var _snow_particles: GPUParticles3D
var _cricket_audio: AudioStreamPlayer
var _cricket_t := 0.0
var _cricket_chirp := 0.0
var _cricket_phase := 0.0
var _plant_hum_audio: AudioStreamPlayer
var _hum_phase := 0.0
var _radio_audio: AudioStreamPlayer
var _radio_on := false
var _radio_step_i := 0
var _radio_song_i := 0
var _radio_jingle_steps := 0
var _radio_note_t := 0.0
var _radio_phase := 0.0
var _radio_bass_phase := 0.0
var _bird_flocks: Array[Node3D] = []
var _birdsong_audio: AudioStreamPlayer
var _birdsong_t := 0.0
var _star_node: Node3D
var _star_mesh_mat: StandardMaterial3D
var _star_vel := Vector3.ZERO
var _star_life := 0.0
var _star_active := false
var _star_timer := 15.0
var _star_land := Vector3.ZERO
var _shards_night := 0
var _bird_chirp := 0.0
var _bird_phase := 0.0
var _siren_audio: AudioStreamPlayer3D
var _siren_wav: AudioStreamWAV
var _siren_t := 0.0
var _shooting_stars: GPUParticles3D
var _prev_weather := 0
var _blizzard_warned := false
var _freak_snow := false
var _campfires: Array[Node3D] = []
var _balloon: Node3D
var _balloon_ang := 0.0
var _beacon_light: OmniLight3D
var _zombie_audio: AudioStreamPlayer
var _zombie_moan_t := 0.0
var _zombie_phase := 0.0
var _zombie_growl := 0.0
var _dread_audio: AudioStreamPlayer
var _dread_phase := 0.0
var _dread_whisper_t := 0.0
var _dread_vol := 0.0
var _wraith: Node3D
var _wraith_t := 0.0
var _radio_muted := false
var _dock: Node3D
var _boat: CharacterBody3D
var _lighthouse_light: SpotLight3D
var _lighthouse_ang := 0.0
var _berry_bushes: Array = []
var _mushrooms: Array = []
var _shrine: Node3D
var _shrine_used_day := -1
var _windmill_blades: Node3D
var _windmill_ang := 0.0
var _dock_base := Vector3.ZERO
var _dock_shore := Vector3.ZERO
var _dock_dir := Vector3.FORWARD
var _highways: Array = []
var _rivers: Array = []
var _bell_audio: AudioStreamPlayer
var _bell_wav: AudioStreamWAV
var _bell_hour := -1
var _bell_swing_t := 0.0
var _bell_node: Node3D
var _bell_tower: Node3D
var _weather_vane: Node3D
var _bolt_nodes: Array[MeshInstance3D] = []
var _fishing := false
var _fishing_boat := false
var _fish_timer := 0.0
var _fish_basket := 0
var _bobber: MeshInstance3D
var _fish_status: Label
var _hot_spring: Node3D
var _ducks: Array[Node3D] = []
var _gardens: Array[Node3D] = []
var _turbines: Array[Node3D] = []
var _turbine_hubs: Array[Node3D] = []
var _hud_weather: Label
var _hud_day: Label
var _hud_rad: Label
var _tornado_warn: Label
var _weather_flash: ColorRect
var _phone_widget: Button
var _phone_widget_body: Label
var _phone_accent := Color(0.6, 0.9, 0.6)
var _phone_battery := 1.0
var _phone_batt_warned := false
var _compass: Control
var _chargers: Array[Node3D] = []
var _lamp_battery_label: Label
var _charged_once := false

const NIGHT_TOP := Color(0.03, 0.04, 0.10)
const NIGHT_HORIZON := Color(0.08, 0.10, 0.16)
const NIGHT_GROUND := Color(0.02, 0.02, 0.03)
const NIGHT_GROUND_H := Color(0.05, 0.06, 0.10)
var _fx := {
	"--fx-sdfgi": false, "--fx-volumetric": false, "--fx-glow": false,
	"--fx-ssr": false, "--fx-ssao": false, "--fx-dof": false,
	"--fx-autoexp": false, "--fx-fog": false,
}


func _ready() -> void:
	_launcher_mode = OS.get_cmdline_user_args().has("--launcher")
	if _launcher_mode:
		get_tree().call_deferred("change_scene_to_file", "res://scenes/server_launcher.tscn")
		return
	_shot = OS.get_cmdline_user_args().has("--shot")
	_walk = OS.get_cmdline_user_args().has("--walk")
	_drive = OS.get_cmdline_user_args().has("--drive")
	_ztest = OS.get_cmdline_user_args().has("--ztest")
	_sanity = OS.get_cmdline_user_args().has("--sanity")
	_rooftest = OS.get_cmdline_user_args().has("--rooftest")
	for a in ["--fx-sdfgi", "--fx-volumetric", "--fx-glow", "--fx-ssr", "--fx-ssao", "--fx-dof", "--fx-autoexp", "--fx-fog"]:
		_fx[a] = OS.get_cmdline_user_args().has(a)
	_parse_net_args()
	_config.load(_config_path)
	if not _seed_set:
		_world_seed = int(_config.get_value("world", "seed", 2024))
	_season = String(_config.get_value("world", "season", "summer"))
	_auto_start = bool(_config.get_value("world", "start_now", false))
	if _config.has_section_key("graphics", "quality"):
		_quality = clampi(int(_config.get_value("graphics", "quality", 2)), 0, QUALITY_PRESETS.size() - 1)
	else:
		_quality = _default_quality()
	if not _player_name_set:
		_player_name = String(_config.get_value("net", "player_name", "Player"))
	if _server:
		_ready_server()
	elif _client:
		await _ready_client()
	else:
		_normal_start()


func _normal_start() -> void:
	_build_loading()
	_loading_step("Seeding world", 0.02)
	_apply_season()
	_setup_noise()
	_loading_step("Skies & lighting", 0.06)
	_build_environment()
	await _loading_frame()
	_loading_step("Terraforming", 0.13)
	_build_terrain()
	await _loading_frame()
	_loading_step("Waterways", 0.21)
	_build_water()
	_build_fireflies()
	_loading_step("Villages", 0.29)
	_build_villages()
	_build_houses()
	_build_village_paths()
	_build_dock()
	_build_hot_spring()
	_build_chargers()
	await _loading_frame()
	_loading_step("Foliage & props", 0.41)
	_build_props()
	_build_japan()
	_build_structures()
	await _loading_frame()
	_loading_step("Power plants", 0.56)
	_build_power_plants()
	_loading_step("Power grid", 0.66)
	_build_power_grid()
	_build_wind_farm()
	await _loading_frame()
	_loading_step("Roads & rivers", 0.74)
	_build_highways()
	_build_rivers()
	_build_groundcover()
	_flush_terrain()
	await _loading_frame()
	_loading_step("Cars & pickups", 0.8)
	_build_cars()
	_build_bikes()
	_build_bunkers()
	_build_wildlife()
	_build_farm_plots()
	_build_ammo_pickups()
	_build_grapple_pickups()
	_loading_step("Villagers", 0.82)
	_build_npcs()
	_build_plant_workers()
	_loading_step("Weather", 0.87)
	_init_weather()
	await _loading_frame()
	_loading_step("Player", 0.91)
	var player := _build_player()
	_restore_world_state()
	_build_clouds(player)
	_loading_step("Interface", 0.97)
	_build_hud()
	_finish_loading()
	if not _server and not _client and _reactors.size() > 0:
		var r0: Node3D = _reactors[0]
		var dp := Vector2(r0.global_position.x - player.global_position.x,
			r0.global_position.z - player.global_position.z)
		var dist := int(dp.length())
		var ang := rad_to_deg(atan2(dp.x, -dp.y))
		var dirs := ["north", "north-east", "east", "south-east", "south", "south-west", "west", "north-west"]
		var di := int(round((wrapf(ang, 0.0, 360.0) / 45.0))) % 8
		_post_chat("System", "Nuclear plant %dm to the %s. Head for the blinking red beacon." % [dist, dirs[di]])
	_build_debug_menu(player)
	_build_pause_menu(player)
	_build_phone()
	_load_settings()
	_apply_ui_scale()
	_build_main_menu(player)
	_build_touch_controls()
	if _shot:
		_build_shot_camera()
		_shot_capture()
		print("[shot] ready")
	elif _walk:
		_walk_capture()
		print("[walk] ready")
	elif _drive:
		_drive_test()
		print("[drive] ready")
	elif _ztest:
		_zombie_test()
		print("[ztest] ready")
	elif _rooftest:
		_roof_test()
		print("[rooftest] ready")


func _build_loading() -> void:
	if _loading != null:
		return
	var l := preload("res://scripts/loading_screen.gd").new()
	add_child(l)
	l.build()
	_loading = l


func _loading_step(text: String, frac: float) -> void:
	if _loading and _loading.has_method("set_progress"):
		_loading.call("set_progress", frac, text)


func _loading_frame() -> void:
	await get_tree().process_frame


func _finish_loading() -> void:
	if _loading:
		_loading.finish()
		_loading = null


func _parse_net_args() -> void:
	var args := OS.get_cmdline_user_args()
	_server = args.has("--server")
	_net_test = args.has("--net-test")
	_night_test = args.has("--night")
	_client = args.has("--connect")
	for i in range(args.size()):
		var a := args[i]
		if a == "--port" and i + 1 < args.size():
			_net_port = int(args[i + 1])
		elif a == "--max-players" and i + 1 < args.size():
			_max_players = clampi(int(args[i + 1]), 1, 64)
		elif a == "--server-name" and i + 1 < args.size():
			_server_name = String(args[i + 1])
		elif a == "--ram-mb" and i + 1 < args.size():
			_ram_mb = clampi(int(args[i + 1]), 128, 65536)
		elif a == "--host" and i + 1 < args.size():
			_join_host = String(args[i + 1])
		elif a == "--player-name" and i + 1 < args.size():
			_player_name = String(args[i + 1])
			_player_name_set = true
		elif a == "--seed" and i + 1 < args.size():
			_world_seed = clampi(int(args[i + 1]), 0, 2147483647)
			_seed_set = true
	if not _client and Net.pending_join_host != "":
		_client = true
		_join_host = Net.pending_join_host
		_net_port = Net.pending_join_port


func _ram_scale() -> float:
	if _mem_scale_cached < 0.0:
		if _ram_mb <= 0:
			_mem_scale_cached = 1.0
		else:
			_mem_scale_cached = clampf(float(_ram_mb) / 2048.0, 0.4, 3.0)
	return _mem_scale_cached


func _build_world_common() -> void:
	_apply_season()
	_setup_noise()
	_loading_step("Skies & lighting", 0.08)
	_build_environment()
	await _loading_frame()
	_loading_step("Terraforming", 0.18)
	_build_terrain()
	await _loading_frame()
	_loading_step("Waterways", 0.28)
	_build_water()
	_build_fireflies()
	_loading_step("Villages", 0.38)
	_build_villages()
	_build_houses()
	_build_village_paths()
	_build_dock()
	_build_hot_spring()
	_build_chargers()
	await _loading_frame()
	_loading_step("Foliage & props", 0.52)
	_build_props()
	_build_japan()
	_build_structures()
	_loading_step("Power plants", 0.66)
	_build_power_plants()
	_build_power_grid()
	_build_wind_farm()
	_loading_step("Roads & rivers", 0.74)
	_build_highways()
	_build_rivers()
	_build_groundcover()
	_flush_terrain()
	await _loading_frame()
	_loading_step("Cars & villagers", 0.82)
	_build_cars()
	_build_bikes()
	_build_bunkers()
	_build_wildlife()
	_build_farm_plots()
	_build_npcs()
	_build_plant_workers()
	_loading_step("Weather", 0.88)
	_init_weather()


func _ready_server() -> void:
	if not Net.start_server(_net_port, _max_players):
		get_tree().quit(1)
		return
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	await _build_world_common()
	_build_ammo_pickups()
	_build_grapple_pickups()
	_spawn_pos = Vector3(0.0, _height_at(0.0, 0.0) + 2.2, 0.0)
	if _night_test:
		_time_of_day = 18.2
	_world_ready = true
	print("[server] DEDICATED SERVER ready  port=%d  max_players=%d  seed=%d  ram_mb=%d  name=%s" % [
		_net_port, _max_players, _world_seed, _ram_mb, _server_name])


func _ready_client() -> void:
	if not Net.start_client(_join_host, _net_port):
		_net_error("Could not connect to %s:%d" % [_join_host, _net_port])
		return
	_build_loading()
	_loading_step("Connecting to %s:%d" % [_join_host, _net_port], 0.05)
	multiplayer.connected_to_server.connect(_on_client_connected)
	multiplayer.connection_failed.connect(func() -> void:
		_net_error("Connection failed. Check the server IP/port and firewall."))
	multiplayer.server_disconnected.connect(func() -> void:
		print("[net] server disconnected"))
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	Net.pending_join_host = ""
	Net.pending_join_port = 0
	var waited := 0.0
	while not _world_ready and waited < 15.0:
		await get_tree().create_timer(0.1).timeout
		waited += 0.1
		_loading_step("Handshaking... %d" % int(waited * 10.0), 0.05 + waited * 0.01)
	if not _world_ready:
		_net_error("Timed out waiting for server handshake. Check that the server is running and the port is open.")
		return
	await _build_world_common()
	_finish_loading()
	var player := _build_player()
	player.set("net_slave", true)
	_build_clouds(player)
	_build_hud()
	_build_debug_menu(player)
	_build_pause_menu(player)
	_build_phone()
	_load_settings()
	_apply_ui_scale()
	_build_touch_controls()
	var hello_peer := multiplayer.multiplayer_peer
	if hello_peer is ENetMultiplayerPeer and hello_peer.get_connection_status() == ENetMultiplayerPeer.CONNECTION_CONNECTED:
		_sv_hello.rpc_id(1, _player_name)
	print("[net] client ready  host=%s:%d  player=%s" % [_join_host, _net_port, _player_name])
	if _net_test:
		_net_self_test()

func _net_error(text: String) -> void:
	print("[net] %s" % text)
	var layer := CanvasLayer.new()
	layer.layer = 100
	var panel := Panel.new()
	panel.color = Color(0.1, 0.1, 0.12, 0.96)
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var label := Label.new()
	label.text = text + "\n\nClose the game to try again."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(label)
	layer.add_child(panel)
	add_child(layer)


func _process(delta: float) -> void:
	if _launcher_mode:
		return
	_check_day()
	_check_game_over()
	if _server:
		_advance_time(delta)
		_zombie_watch()
		_wolf_watch()
		_tick_grid(delta)
		_tick_crisis(delta)
		_tick_weather(delta)
		_tick_tornadoes(delta)
		_tick_wolves(delta)
		_tick_meteors(delta)
		_net_state_t -= delta
		if _net_state_t <= 0.0:
			_net_state_t = 1.0 / 15.0
			_broadcast_state()
		return
	if _client and _world_ready:
		_render_sky()
		_tick_grid(delta)
		_update_weather(delta)
		_tick_chargers(delta)
		_apply_quake(delta)
		_apply_client_state(delta)
		_update_hud(delta)
		_tick_bell(delta)
		_tick_fishing(delta)
		_tick_shrine(delta)
		_tick_windmill(delta)
		_tick_lighthouse(delta)
		_tick_berries(delta)
		_tick_shooting_stars(delta)
		return
	if _client:
		return
	_advance_time(delta)
	_render_sky()
	_zombie_watch()
	_wolf_watch()
	_tick_grid(delta)
	_tick_crisis(delta)
	_tick_weather(delta)
	_tick_tornadoes(delta)
	_update_weather(delta)
	_tick_chargers(delta)
	_apply_quake(delta)
	_update_hud(delta)
	_tick_horror_viy(delta)
	_tick_bell(delta)
	_tick_fishing(delta)
	_tick_shrine(delta)
	_tick_windmill(delta)
	_tick_lighthouse(delta)
	_tick_berries(delta)
	_tick_shooting_stars(delta)
	_tick_wolves(delta)
	_tick_meteors(delta)
	_tick_wraith(delta)
	_update_tasks(delta)


func _advance_time(delta: float) -> void:
	_time_of_day += delta / _day_length * 24.0


func _check_day() -> void:
	var day := int(floor(_time_of_day / 24.0)) + 1
	if day == _last_day:
		return
	var prev := _last_day
	_last_day = day
	_shards_night = 0
	if day <= prev:
		return
	var healthy := not _grid_blackout and _grid_status in ["SATISFIED", "SURPLUS"]
	if healthy:
		_launch_fireworks()
	_gazette(day)
	if _server:
		_alert("System", "Day %d dawned. %s" % [day, "The grid held through the night — fireworks over the plant!" if healthy else "The grid flickered in the dark last night."])
	elif not _client:
		_post_chat("System", "Day %d dawned." % day)


func _gazette(day: int) -> void:
	if _server and not multiplayer.get_peers().is_empty():
		_alert("System", "GAZETTE — Pico Peaks, Day %d: %s" % [day, _gazette_headline(day)])
		return
	var headline := _gazette_headline(day)
	var sub_head := ""
	match _weather:
		3:
			sub_head = "STORM FRONT SLAMS THE RANGE — villagers bolt their doors"
		2:
			sub_head = "RAIN BLANKETS THE VALLEY — catchment reservoirs rising"
		1:
			sub_head = "CLOUDY SKIES TODAY — weak sun expected for the gardens"
		_:
			sub_head = "CLEAR SKIES OVER PICO PEAKS — a good day for the dock"
	if _grid_blackout:
		sub_head = "BLACKOUT WARNING — operators scramble to balance the load"
	var body: Array[String] = [
		_gazette_plant_par(),
		_gazette_weather_par(_weather),
		_gazette_life_par(),
	]
	var tod := fmod(_time_of_day, 24.0)
	_news_log.append({"t": "%02d:%02d" % [int(floor(tod)), int(floor(fmod(tod, 1.0) * 60.0))], "m": "GAZETTE: %s" % headline})
	if _news_log.size() > 60:
		_news_log.pop_front()
	_show_gazette(day, headline, sub_head, body)


func _gazette_headline(day: int) -> String:
	if _grid_blackout:
		return "DARK DAWN — plant output falls short as Day %d breaks" % day
	var healthy := not _grid_blackout and _grid_status in ["SATISFIED", "SURPLUS"]
	if healthy:
		return "POWER GRID HOLDS OVERNIGHT — Day %d dawns bright over Pico Peaks" % day
	return "GRID TEETERS AS DAY %d BREAKS — operators race the clock" % day


func _gazette_plant_par() -> String:
	if _grid_blackout:
		return "Rolling blackouts struck before dawn as plant output sagged. Operators urge residents to conserve power while crews work the boards."
	if _grid_status in ["SATISFIED", "SURPLUS"]:
		var par: Array[String] = [
			"Plant output exceeded demand through the night, keeping every village lit. Engineers called the evening 'boring' — their highest praise.",
			"Reactor readings held steady across all units as the valley slept. Thermals were calm; the turbines hummed contentedly.",
			"With the grid balanced and reserves healthy, Pico Peaks enjoys its most settled stretch since the crisis began.",
		]
		return par.pick_random()
	return "Generation fell shy of demand overnight, straining the network to its limits. Inspectors warn the next sag could trigger blackouts."


func _gazette_weather_par(w: int) -> String:
	match w:
		3:
			return "Meteorologists expect thunderstorms to roll through the range today. Secure loose objects; the dogs at the inn are already hiding under the bell."
		2:
			return "A steady rain is set to soak the valley gardens — good news for the crops, less so for the ducks at the dock, who have opinions."
		1:
			return "Cloud cover will linger through midday, dimming the sun just as the gardens reach their ripening stage. Patience is advised."
		_:
			return "Bright sunshine is forecast across Pico Peaks. A fine day to row out on the lake, check the beacon, or nap in the bell-tower shade."


func _gazette_life_par() -> String:
	var tasks_done := 0
	for t in _tasks:
		if _tasks[t]:
			tasks_done += 1
	var par: Array[String] = [
		"Settlement reporter counts %d of %d community goals complete, from the hot spring soak to the rowboat on the lake." % [tasks_done, _tasks.size()],
		"The radio tower at the north ridge still carries FM 98.7's signal, though the DJ admits the storm knocked the transmitter off-song for a night.",
		"Dockside sources confirm the ducks remain impartial on all matters of power policy. The cat, reached for comment, declined gracefully.",
	]
	return par.pick_random()


func _show_gazette(day: int, headline: String, sub_head: String, body: Array[String]) -> void:
	if _game_over:
		return
	if _gazette_layer != null and is_instance_valid(_gazette_layer):
		_gazette_layer.queue_free()
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	_gazette_layer = layer
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.4)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dim)
	var paper := PanelContainer.new()
	paper.set_anchors_preset(Control.PRESET_CENTER)
	paper.grow_horizontal = Control.GROW_DIRECTION_BOTH
	paper.grow_vertical = Control.GROW_DIRECTION_BOTH
	paper.custom_minimum_size = Vector2(560.0, 430.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.96, 0.93, 0.86)
	sb.set_corner_radius_all(6)
	sb.set_border_width_all(4)
	sb.border_color = Color(0.85, 0.8, 0.68)
	sb.set_content_margin_all(28)
	paper.add_theme_stylebox_override("panel", sb)
	layer.add_child(paper)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	paper.add_child(vb)
	var masthead := Label.new()
	masthead.text = "THE PICO PEAKS GAZETTE"
	masthead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	masthead.add_theme_font_size_override("font_size", 30)
	masthead.add_theme_color_override("font_color", Color(0.12, 0.08, 0.04))
	vb.add_child(masthead)
	var rule := ColorRect.new()
	rule.color = Color(0.7, 0.15, 0.1)
	rule.custom_minimum_size = Vector2(0.0, 3.0)
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(rule)
	var tod := fmod(_time_of_day, 24.0)
	var dateline := Label.new()
	dateline.text = "PICO PEAKS EDITION   —   DAY %d   —   %02d:%02d" % [day, int(floor(tod)), int(floor(fmod(tod, 1.0) * 60.0))]
	dateline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dateline.add_theme_font_size_override("font_size", 13)
	dateline.add_theme_color_override("font_color", Color(0.3, 0.25, 0.18))
	vb.add_child(dateline)
	var headline_l := Label.new()
	headline_l.text = headline
	headline_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	headline_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	headline_l.add_theme_font_size_override("font_size", 21)
	headline_l.add_theme_color_override("font_color", Color(0.1, 0.06, 0.03))
	vb.add_child(headline_l)
	var sub := Label.new()
	sub.text = sub_head
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(0.35, 0.3, 0.22))
	vb.add_child(sub)
	var body_l := Label.new()
	body_l.text = "\n\n".join(body)
	body_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_l.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_l.add_theme_font_size_override("font_size", 14)
	body_l.add_theme_color_override("font_color", Color(0.18, 0.13, 0.08))
	vb.add_child(body_l)
	var close_hint := Label.new()
	close_hint.text = "press E to fold the paper"
	close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_hint.add_theme_font_size_override("font_size", 12)
	close_hint.add_theme_color_override("font_color", Color(0.5, 0.45, 0.38))
	vb.add_child(close_hint)
	var t := get_tree().create_timer(16.0)
	t.timeout.connect(_close_gazette)


func _close_gazette() -> void:
	if _gazette_layer != null and is_instance_valid(_gazette_layer):
		_gazette_layer.queue_free()
	_gazette_layer = null


func _check_game_over() -> void:
	if _game_over or _reactors.is_empty() or _client:
		return
	var all_lost := true
	for r in _reactors:
		if is_instance_valid(r) and not bool(r.get("exploded")):
			all_lost = false
			break
	if all_lost:
		_trigger_game_over()
		if _server:
			_net_crisis.rpc("melt", 0, 1.0)


func _trigger_game_over() -> void:
	if _game_over:
		return
	_game_over = true
	if _player:
		_player.set("_freeze", true)
	if _phone and _phone.has_method("close"):
		_phone.call("close")
	_game_over_layer = CanvasLayer.new()
	_game_over_layer.layer = 60
	var dim := ColorRect.new()
	dim.color = Color(0.12, 0.0, 0.02, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_game_over_layer.add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(460.0, 320.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.02, 0.03, 0.97)
	sb.set_corner_radius_all(18)
	sb.set_border_width_all(3)
	sb.border_color = Color(1.0, 0.25, 0.2)
	sb.set_content_margin_all(26)
	panel.add_theme_stylebox_override("panel", sb)
	_game_over_layer.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)
	var title := Label.new()
	title.text = "PLANT LOST"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(1.0, 0.35, 0.3))
	vb.add_child(title)
	var sub := Label.new()
	sub.text = "Every reactor has melted down.\nThe villages are dark. The valley burns."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", Color(1.0, 0.9, 0.9, 0.9))
	vb.add_child(sub)
	var stats := Label.new()
	var days := int(floor(_time_of_day / 24.0)) + 1
	stats.text = "Days survived: %d\nTasks completed: %d / %d" % [days, _task_count, _tasks.size()]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 15)
	stats.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 0.85))
	vb.add_child(stats)
	var restart := Button.new()
	restart.text = "RESTART"
	restart.custom_minimum_size = Vector2(0.0, 40.0)
	restart.pressed.connect(func() -> void: get_tree().reload_current_scene())
	vb.add_child(restart)
	var quit := Button.new()
	quit.text = "QUIT"
	quit.custom_minimum_size = Vector2(0.0, 36.0)
	quit.pressed.connect(func() -> void: get_tree().quit())
	vb.add_child(quit)
	add_child(_game_over_layer)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _zombie_watch() -> void:
	if _is_night():
		if not _zombies_active:
			_zombies_active = true
			_build_zombies()
			_alert("System", "The dead are stirring... get inside a house!")
	else:
		if _zombies_active:
			_zombies_active = false
			_despawn_zombies()
			_alert("System", "Dawn breaks. The dead sink back into the earth.")


func _tick_grid(delta: float) -> void:
	if _reactors.is_empty() or _villages.is_empty():
		return
	var night := _is_night()
	var per_village := 480.0 if night else 210.0
	var demand := float(_villages.size()) * per_village
	for vi in _village_outage.size():
		if _village_outage[vi] > 0.0:
			_village_outage[vi] = maxf(0.0, _village_outage[vi] - delta)
			demand -= per_village
	var supply := _total_supply()
	demand = maxf(demand, 0.0)
	var ratio := supply / maxf(demand, 1.0)
	var blackout: bool = demand > 0.0 and ratio < 0.75
	if blackout != _grid_blackout:
		_grid_blackout = blackout
		if not _client:
			if blackout:
				_alert("System", "GRID BLACKOUT: plant output is below village demand! Raise reactor power.")
			else:
				_alert("System", "Grid demand satisfied — power restored to the villages.")
	for vi in _village_powered.size():
		_village_powered[vi] = not blackout
	if blackout:
		_grid_status = "BLACKOUT"
	elif ratio < 0.95:
		_grid_status = "SHORTFALL"
	elif ratio < 1.05:
		_grid_status = "SATISFIED"
	else:
		_grid_status = "SURPLUS"
	_apply_village_lighting()


func _apply_village_lighting() -> void:
	var night := _is_night()
	for vi in _village_window_mats.size():
		var lit: bool = night and _village_powered[vi] and _village_outage[vi] <= 0.0
		var em := Color(0.3, 0.4, 0.6) * (0.4 if lit else 0.0)
		for mat in _village_window_mats[vi]:
			mat.emission = em
		if vi < _village_lamps.size():
			var lamp_em := Color(1.0, 0.72, 0.3) * (2.2 if lit else 0.0)
			for mat in _village_lamps[vi]:
				mat.emission = lamp_em


func grid_demand() -> Array:
	var demand := 0.0
	if not _villages.is_empty():
		var per_village := 480.0 if _is_night() else 210.0
		demand = float(_villages.size()) * per_village
		for vi in _village_outage.size():
			if _village_outage[vi] > 0.0:
				demand -= per_village
	var supply := _total_supply()
	return [maxf(demand, 0.0), supply, _grid_status, _grid_blackout]


func _tick_crisis(delta: float) -> void:
	if _client:
		return
	_crisis_t -= delta
	if _crisis_t <= 0.0:
		_crisis_t = randf_range(90.0, 170.0)
		_trigger_crisis()
	if _quake_t > 0.0:
		_quake_t = maxf(0.0, _quake_t - delta)


func _trigger_crisis() -> void:
	_play_siren(7.0)
	var kinds := ["grid", "decay", "quake"]
	var kind: String = kinds[randi() % kinds.size()]
	match kind:
		"grid":
			if _villages.size() <= 1:
				return
			var vi: int = 1 + (randi() % (_villages.size() - 1))
			_village_outage[vi] = randf_range(12.0, 20.0)
			_alert("System", "GRID FAILURE: distribution fault at village %d. Estimated outage %ds." % [vi + 1, int(_village_outage[vi])])
			if _server:
				_net_crisis.rpc("grid", vi, _village_outage[vi])
		"decay":
			if _reactors.is_empty():
				return
			var r: Node3D = _reactors[randi() % _reactors.size()]
			if is_instance_valid(r):
				r.set("decay_factor", randf_range(0.5, 0.85))
				_alert("System", "EQUIPMENT DECAY: coolant degradation at Reactor %d. Cooling efficiency reduced!" % (int(r.get("plant_idx")) + 1))
		"quake":
			_quake_t = 3.0
			_alert("System", "EARTHQUAKE! The ground is shaking.")
			if _server:
				_net_crisis.rpc("quake", 0, _quake_t)
			for r in _reactors:
				if is_instance_valid(r):
					r.set("damage", float(r.get("damage")) + randf_range(2.0, 6.0))
	_alert("System", "GAZETTE — SIRENS OVER PICO PEAKS: emergency services on alert")


func _apply_quake(delta: float) -> void:
	if _player == null:
		return
	_tornado_shake = maxf(0.0, _tornado_shake - delta * 0.6)
	var t := maxf(_quake_t, _tornado_shake)
	if t <= 0.0:
		return
	var cam := _player.get_node_or_null("CameraRig/Camera") as Camera3D
	if cam:
		cam.h_offset = sin(t * 40.0) * 0.04 * t
		cam.v_offset = cos(t * 33.0) * 0.03 * t


@rpc("authority", "call_remote", "reliable")
func _net_crisis(kind: String, vi: int, value: float) -> void:
	match kind:
		"grid":
			if vi >= 0 and vi < _village_outage.size():
				_village_outage[vi] = value
		"quake":
			_quake_t = value
		"melt":
			_trigger_game_over()
	_play_siren(7.0)


func _tick_weather(delta: float) -> void:
	if _client:
		return
	_weather_t -= delta
	if _weather_t <= 0.0:
		_weather_t = randf_range(40.0, 80.0)
		var roll := randf()
		var new_weather := 0 if roll < 0.35 else (1 if roll < 0.6 else (2 if roll < 0.9 else 3))
		if new_weather != _weather:
			if new_weather >= 3:
				if _season == "winter":
					_alert("System", "WHITEOUT WARNING: a blizzard is rolling down from the peaks.")
				elif randf() < 0.25:
					_alert("System", "A freak snow squall funnels down from the high peaks.")
					_freak_snow = true
				_alert("System", "GAZETTE — STORM ON THE RANGE: Pico Peaks braces for the worst")
				_play_siren(9.0)
			else:
				_freak_snow = false
				if new_weather >= 2:
					_alert("System", "Rain is moving in — catchment ponds will refill cooling water.")
		_weather = new_weather
	if _weather >= 3 and _prev_weather < 3:
		_play_siren(9.0)
	_prev_weather = _weather
	_wind_speed = move_toward(_wind_speed, _wind_target, delta * 0.04)
	_wind_dir = move_toward(_wind_dir, _wind_dir_target, delta * 0.05)
	if _weather_vane != null and is_instance_valid(_weather_vane):
		_weather_vane.rotation.y = _wind_dir
	if randf() < delta * 0.15:
		_wind_target = clampf(_wind_target + randf_range(-0.35, 0.35), 0.0, 1.0)
	if randf() < delta * 0.1:
		_wind_dir_target = wrapf(_wind_dir_target + randf_range(-1.2, 1.2), 0.0, TAU)
	if _weather >= 2:
		_wind_target = maxf(_wind_target, 0.55)
	_rain_density = move_toward(_rain_density, 1.0 if _weather >= 2 else 0.0, delta * 0.2)
	if _rain_density > 0.2:
		for r in _reactors:
			if is_instance_valid(r) and not bool(r.get("exploded")):
				var w := float(r.get("water"))
				if w < 1.0:
					r.set("water", minf(1.0, w + _rain_density * 0.005 * delta))


func _is_blizzard() -> bool:
	return _weather >= 3 and (_season == "winter" or _freak_snow)


func _tick_blizzard(delta: float) -> void:
	if _server or _client:
		return
	if _player == null or not is_instance_valid(_player):
		return
	if bool(_player.get("in_car")) or bool(_player.get("in_boat")):
		return
	var heat := float(_player.get("lamp_battery"))
	var hp := float(_player.get("health"))
	var thirst := float(_player.get("thirst"))
	_player.set("thirst", maxf(0.0, thirst - delta * 0.8))
	_player.set("health", maxf(0.0, hp - delta * (0.25 if heat > 0.05 else 0.5)))
	if _blizzard_warned == false:
		_blizzard_warned = true
		_alert("System", "A whiteout blizzard howls off the range. Find shelter!")


func _build_snow_particles() -> void:
	var p := GPUParticles3D.new()
	p.name = "Snow"
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(500.0, 90.0, 500.0)
	pm.direction = Vector3(0.0, -1.0, 0.0)
	pm.spread = 18.0
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 5.0
	pm.gravity = Vector3(0.0, -6.0, 0.0)
	pm.scale_min = 1.2
	pm.scale_max = 2.6
	pm.color = Color(0.96, 0.97, 0.98, 0.85)
	p.process_material = pm
	p.amount = 3000
	p.lifetime = 3.2
	pm.lifetime_randomness = 0.35
	p.one_shot = false
	p.emitting = false
	p.visible = false
	p.position = Vector3(0.0, 150.0, 0.0)
	var flake := SphereMesh.new()
	flake.radius = 0.04
	flake.height = 0.08
	var flake_mat := StandardMaterial3D.new()
	flake_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flake_mat.albedo_color = Color(0.96, 0.97, 0.98, 0.9)
	p.draw_pass_1 = flake
	flake.material = flake_mat
	add_child(p)
	p.global_position.y = 0.0
	_snow_particles = p


func _update_weather(delta: float) -> void:
	_rain_density = move_toward(_rain_density, 1.0 if _weather >= 2 else 0.0, delta * 0.2)
	var blizzard := _is_blizzard()
	if _snow_particles:
		_snow_particles.emitting = blizzard
		_snow_particles.visible = blizzard
		if _player:
			_snow_particles.global_position = _player.global_position + Vector3(0.0, 150.0, 0.0)
	if blizzard:
		_tick_blizzard(delta)
	for hub in _turbine_hubs:
		if is_instance_valid(hub):
			hub.rotation.x += _wind_speed * delta * 3.0
	if _weather >= 3:
		_storm_flash_t -= delta
		if _storm_flash_t <= 0.0:
			_storm_flash_t = randf_range(4.0, 11.0)
			_trigger_lightning()
	_flash_strength = maxf(0.0, _flash_strength - delta * 1.6)
	if _rain_particles:
		var raining := _rain_density > 0.02
		_rain_particles.emitting = raining
		_rain_particles.visible = raining
		_rain_particles.amount = int(800.0 + _rain_density * 3200.0)
		if _player:
			_rain_particles.global_position = _player.global_position + Vector3(0.0, 140.0, 0.0)
	if _weather_flash:
		_weather_flash.color = Color(0.95, 0.98, 1.0, clampf(_flash_strength, 0.0, 0.45))
	_fill_rain_audio(delta)
	_fill_ambience_audio(delta)
	_update_birds(delta)
	_update_siren(delta)
	_update_shooting_stars()
	_update_campfires(delta)
	_update_gardens()
	_update_balloon(delta)
	_update_beacon(delta)
	_update_dock(delta)
	_update_hot_spring(delta)
	_tick_drink(delta)
	_update_fireflies(delta)
	_update_lightning_bolts(delta)
	if _hud_weather:
		var names := ["CLEAR", "CLOUDY", "RAIN", "STORM"]
		_hud_weather.text = "%s   WIND %d%%" % [names[_weather], int(_wind_speed * 100.0)]


func _trigger_lightning() -> void:
	_flash_strength = 1.0
	_spawn_lightning_bolt()
	if _thunder_audio == null:
		return
	var delay := randf_range(0.3, 1.8)
	get_tree().create_timer(delay).timeout.connect(func() -> void:
		if is_instance_valid(_thunder_audio) and _thunder_wav:
			_thunder_audio.stream = _thunder_wav
			_thunder_audio.volume_db = -8.0 - randf() * 6.0
			_thunder_audio.play())


func _spawn_lightning_bolt() -> void:
	var base := Vector3.ZERO
	if _player:
		base = _player.global_position
	elif not _villages.is_empty():
		base = Vector3(_villages[0].x, 0.0, _villages[0].y)
	var ang := randf() * TAU
	var dist := randf_range(180.0, 750.0)
	var gx := clampf(base.x + cos(ang) * dist, -950.0, 950.0)
	var gz := clampf(base.z + sin(ang) * dist, -950.0, 950.0)
	var gh := _height_at(gx, gz)
	var target := Vector3(gx, maxf(gh, WATER_Y + 1.0), gz)
	var mi := MeshInstance3D.new()
	mi.name = "LightningBolt"
	var mesh := ImmediateMesh.new()
	var top := target + Vector3(0.0, 240.0, 0.0)
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var prev := top
	var fork := top
	for i in 10:
		var t := float(i + 1) / 10.0
		var spread := (1.0 - t) * 30.0
		var np := top.lerp(target, t) + Vector3(randf_range(-spread, spread), 0.0, randf_range(-spread, spread))
		mesh.surface_add_vertex(prev)
		mesh.surface_add_vertex(np)
		prev = np
		if i >= 4 and i < 8:
			var foff := np.lerp(fork, 0.35)
			mesh.surface_add_vertex(np)
			mesh.surface_add_vertex(foff)
			fork = foff
	mesh.surface_end()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.85, 0.92, 1.0, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.7, 0.85, 1.0)
	mat.emission_energy_multiplier = 2.0
	mi.material_override = mat
	add_child(mi)
	_bolt_nodes.append(mi)


func _update_lightning_bolts(delta: float) -> void:
	for b in _bolt_nodes:
		if b == null or not is_instance_valid(b):
			continue
		var m := b.material_override as StandardMaterial3D
		m.albedo_color.a -= delta * 2.4
		if m.albedo_color.a <= 0.0:
			b.queue_free()


func _tick_tornadoes(delta: float) -> void:
	_tornado_t -= delta
	if _tornado_t <= 0.0 and _tornadoes.size() < 2:
		_tornado_t = randf_range(60.0, 140.0) if _weather >= 2 else randf_range(140.0, 280.0)
		_spawn_tornado()
	for i in range(_tornadoes.size() - 1, -1, -1):
		if not is_instance_valid(_tornadoes[i]):
			_tornadoes.remove_at(i)
			continue
		var tn: Node3D = _tornadoes[i]
		if float(tn.get("_age")) >= float(tn.get("lifetime")):
			tn.queue_free()
			_tornadoes.remove_at(i)


func _nearest_tornado() -> Node3D:
	var best: Node3D = null
	var best_d := INF
	for tn in _tornadoes:
		if tn == null or not is_instance_valid(tn):
			continue
		if _player != null and is_instance_valid(_player):
			var d := (tn as Node3D).global_position.distance_to(_player.global_position)
			if d < best_d:
				best_d = d
				best = tn
	return best


func _spawn_tornado() -> void:
	var ang := randf() * TAU
	var dist := randf_range(260.0, 720.0)
	var x := clampf(cos(ang) * dist, -940.0, 940.0)
	var z := clampf(sin(ang) * dist, -940.0, 940.0)
	_spawn_tornado_at(Vector2(x, z))


func _spawn_tornado_at(at: Vector2) -> bool:
	var x := clampf(at.x, -940.0, 940.0)
	var z := clampf(at.y, -940.0, 940.0)
	if _ground_height(x, z) < 1.2:
		return false
	var t: Node3D = preload("res://scripts/tornado.gd").new()
	t.name = "Tornado"
	t.set("world", self)
	t.position = Vector3(x, _ground_height(x, z) + 3.0, z)
	add_child(t)
	_tornadoes.append(t)
	if _player and is_instance_valid(_player):
		if Vector2(x, z).distance_to(Vector2(_player.global_position.x, _player.global_position.z)) < 650.0:
			_alert("System", "TORNADO WARNING: a twister is on the ground nearby. Take cover!")
	elif not _villages.is_empty():
		if Vector2(x, z).distance_to(_villages[0]) < 650.0:
			_alert("System", "TORNADO WARNING: a twister is approaching the village. Take cover!")
	return true


func _apply_tornado_states(tornadoes: Array) -> void:
	while _tornadoes.size() < tornadoes.size():
		var t: Node3D = preload("res://scripts/tornado.gd").new()
		t.name = "Tornado"
		t.set("world", self)
		t.set("slave", true)
		add_child(t)
		_tornadoes.append(t)
	while _tornadoes.size() > tornadoes.size():
		var extra: Node3D = _tornadoes.pop_back()
		if is_instance_valid(extra):
			extra.queue_free()
	for i in tornadoes.size():
		var tn: Node3D = _tornadoes[i]
		var row: Array = tornadoes[i]
		tn.set("net_target", Vector3(row[0], row[1], row[2]))


func _fill_rain_audio(delta: float) -> void:
	if _rain_audio == null or not _rain_audio.playing:
		return
	var pb := _rain_audio.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		return
	var frames := int(pb.get_frames_available())
	var amp := _rain_density * 0.15
	while frames > 0:
		var s := randf() * 2.0 - 1.0
		_rain_noise_lp = lerpf(_rain_noise_lp, s, 0.5)
		var v := _rain_noise_lp * amp
		pb.push_frame(Vector2(v, v))
		frames -= 1


func _fill_ambience_audio(delta: float) -> void:
	_fill_cricket_audio(delta)
	_fill_owl_audio(delta)
	_fill_plant_hum_audio(delta)
	_fill_radio_audio(delta)
	_fill_birdsong_audio(delta)
	_fill_zombie_audio(delta)
	_fill_dread_audio(delta)


func _fill_cricket_audio(delta: float) -> void:
	if _cricket_audio == null:
		return
	var night := _is_night()
	_cricket_audio.volume_db = lerpf(_cricket_audio.volume_db, -18.0 if night else -60.0, delta * 2.0)
	if not night:
		return
	var pb := _cricket_audio.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		return
	var frames := int(pb.get_frames_available())
	_cricket_t -= delta
	while frames > 0:
		if _cricket_chirp > 0.0:
			_cricket_chirp -= 1.0 / 22050.0
			var env := clampf(_cricket_chirp * 30.0, 0.0, 1.0)
			_cricket_phase += TAU * 4200.0 / 22050.0
			var s := sin(_cricket_phase) * env * 0.35
			pb.push_frame(Vector2(s, s))
		else:
			if _cricket_t <= 0.0:
				_cricket_t = randf_range(0.3, 0.9)
				_cricket_chirp = randf_range(0.05, 0.12)
				_cricket_phase = randf() * TAU
			pb.push_frame(Vector2.ZERO)
		frames -= 1


func _fill_plant_hum_audio(delta: float) -> void:
	if _plant_hum_audio == null or _player == null:
		return
	var vol := -60.0
	for r in _reactors:
		if r == null or not is_instance_valid(r) or bool(r.get("exploded")):
			continue
		var d := _player.global_position.distance_to((r as Node3D).global_position)
		vol = maxf(vol, -60.0 + clampf(1.0 - d / 320.0, 0.0, 1.0) * 44.0)
	_plant_hum_audio.volume_db = lerpf(_plant_hum_audio.volume_db, vol, delta * 3.0)
	if vol < -50.0:
		return
	var pb := _plant_hum_audio.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		return
	var frames := int(pb.get_frames_available())
	while frames > 0:
		_hum_phase += TAU * 58.0 / 22050.0
		var s := sin(_hum_phase) * 0.5 + sin(_hum_phase * 2.0) * 0.22 + sin(_hum_phase * 3.0) * 0.12
		var thrum := 0.8 + 0.2 * sin(_hum_phase * 0.25)
		pb.push_frame(Vector2(s * thrum * 0.35, s * thrum * 0.35))
		frames -= 1


const RADIO_SONG_0 := [0, 3, 7, 10, 7, 10, 12, 7, 0, 3, 5, 7, 3, 5, 10, 3, 0, 3, 7, 10, 7, 12, 10, 7, 0, 3, 5, 7, 10, 12, 10, 7]
const RADIO_SONG_1 := [0, 5, 10, 12, 10, 5, 7, 9, 0, 4, 7, 9, 7, 4, 5, 7, 0, 5, 10, 12, 10, 7, 5, 3, 0, 4, 7, 9, 10, 9, 7, 5]
const RADIO_SONG_2 := [0, 7, 12, 15, 12, 7, 10, 12, 0, 7, 12, 15, 17, 15, 12, 10, 0, 7, 12, 15, 12, 7, 10, 12, 0, 7, 10, 12, 15, 12, 10, 7]
const RADIO_SONGS := [RADIO_SONG_0, RADIO_SONG_1, RADIO_SONG_2]
const RADIO_BPM := [104.0, 96.0, 120.0]
const RADIO_JINGLE := [0, 7, 12, 16, 12, 7, 0, 7]


func _fill_radio_audio(delta: float) -> void:
	if _radio_audio == null:
		return
	var in_car := _player != null and bool(_player.get("in_car"))
	var in_boat := _player != null and bool(_player.get("in_boat"))
	var in_vehicle := in_car or in_boat
	if in_vehicle and not _radio_muted and not _radio_on:
		_radio_on = true
		_radio_audio.play()
	elif (not in_vehicle or _radio_muted) and _radio_on:
		_radio_on = false
		_radio_audio.stop()
	if not in_vehicle or _radio_muted:
		return
	var pb := _radio_audio.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		return
	var song: Array = RADIO_SONGS[_radio_song_i]
	var beat: float = 60.0 / float(RADIO_BPM[_radio_song_i])
	var note_len: float = beat / 4.0
	var frames := int(pb.get_frames_available())
	while frames > 0:
		var semi: int
		if _radio_jingle_steps > 0:
			_radio_jingle_steps -= 1
			semi = RADIO_JINGLE[(RADIO_JINGLE.size() - 1 - _radio_jingle_steps) % RADIO_JINGLE.size()]
		else:
			semi = song[_radio_step_i]
		var freq := 110.0 * pow(2.0, semi / 12.0)
		_radio_phase += TAU * freq / 22050.0
		var decay := exp(-_radio_note_t / note_len * 3.2)
		var s := sin(_radio_phase) * 0.5 + sin(_radio_phase * 2.0) * 0.15 + sin(_radio_phase * 3.0) * 0.05
		_radio_bass_phase += TAU * 55.0 / 22050.0
		var bass := 0.0
		if _radio_step_i % 4 == 0:
			bass = sin(_radio_bass_phase) * 0.35 * decay
		var v := (s * 0.7 + bass) * 0.3
		pb.push_frame(Vector2(v, v))
		_radio_note_t += 1.0 / 22050.0
		if _radio_note_t >= note_len:
			_radio_note_t = 0.0
			_radio_step_i = (_radio_step_i + 1) % song.size()
			if _radio_step_i == 0:
				_radio_song_i = (_radio_song_i + 1) % RADIO_SONGS.size()
				_radio_jingle_steps = RADIO_JINGLE.size()
		frames -= 1


func _fill_birdsong_audio(delta: float) -> void:
	if _birdsong_audio == null:
		return
	var tod := fmod(_time_of_day, 24.0)
	var chorus := (tod >= 5.0 and tod <= 8.5) or (tod >= 17.0 and tod <= 19.5)
	_birdsong_audio.volume_db = lerpf(_birdsong_audio.volume_db, -16.0 if chorus else -60.0, delta * 2.0)
	if not chorus:
		return
	var pb := _birdsong_audio.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		return
	var frames := int(pb.get_frames_available())
	_birdsong_t -= delta
	while frames > 0:
		if _bird_chirp > 0.0:
			_bird_chirp -= 1.0 / 22050.0
			_bird_phase += TAU * 3800.0 / 22050.0
			var env := clampf(_bird_chirp * 14.0, 0.0, 1.0)
			var s := sin(_bird_phase) * env * 0.5
			pb.push_frame(Vector2(s, s))
		else:
			if _birdsong_t <= 0.0:
				_birdsong_t = randf_range(0.5, 1.6)
				_bird_chirp = randf_range(0.05, 0.18)
				_bird_phase = randf() * TAU
			pb.push_frame(Vector2.ZERO)
		frames -= 1


func _build_birds() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.1, 0.13)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for f in 3:
		var flock := Node3D.new()
		flock.name = "BirdFlock%d" % f
		var ang := f * TAU / 3.0
		flock.set_meta("ang", ang)
		flock.position = Vector3(cos(ang) * 140.0, 34.0 + f * 9.0, sin(ang) * 140.0)
		for b in 9:
			var m := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.5, 0.06, 0.12)
			m.mesh = bm
			m.material_override = mat
			m.position = Vector3(b * 0.7 - 2.8, 0.0, 0.0)
			flock.add_child(m)
		add_child(flock)
		_bird_flocks.append(flock)


func _update_birds(delta: float) -> void:
	var day_light := not _is_night()
	for i in _bird_flocks.size():
		var flock := _bird_flocks[i]
		if flock == null or not is_instance_valid(flock):
			continue
		flock.visible = day_light
		var ang := float(flock.get_meta("ang")) + delta * 0.06
		flock.set_meta("ang", ang)
		flock.position = Vector3(cos(ang) * 140.0, 34.0 + sin(ang * 2.0) * 3.0 + float(i) * 9.0, sin(ang) * 140.0)
		flock.rotation.y = -ang - PI / 2.0
		var flap := sin(Time.get_ticks_msec() / 1000.0 * 8.0 + float(i) * 1.7)
		for c in flock.get_children():
			(c as MeshInstance3D).rotation.z = flap * 0.35


func _build_shooting_star() -> void:
	_star_node = Node3D.new()
	_star_node.name = "ShootingStar"
	_star_mesh_mat = StandardMaterial3D.new()
	_star_mesh_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_star_mesh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_star_mesh_mat.albedo_color = Color(1.0, 0.98, 0.9, 1.0)
	_star_mesh_mat.emission_enabled = true
	_star_mesh_mat.emission = Color(1.0, 0.98, 0.9)
	_star_mesh_mat.emission_energy_multiplier = 3.0
	var streak := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.1, 0.1, 7.0)
	streak.mesh = sm
	streak.material_override = _star_mesh_mat
	_star_node.add_child(streak)
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.95, 0.95, 1.0)
	glow.light_energy = 6.0
	glow.omni_range = 14.0
	_star_node.add_child(glow)
	_star_node.visible = false
	add_child(_star_node)


func _spawn_shooting_star() -> void:
	var center := _player.global_position if _player != null else Vector3.ZERO
	var lx := center.x + randf_range(-28.0, 28.0)
	var lz := center.z + randf_range(-28.0, 28.0)
	var lh := maxf(_height_at(lx, lz), 1.0)
	_star_land = Vector3(lx, lh, lz)
	var start := Vector3(lx + randf_range(-95.0, 95.0), randf_range(110.0, 150.0), lz + randf_range(-95.0, 95.0))
	_star_life = randf_range(2.2, 3.0)
	_star_vel = (_star_land + Vector3(0.0, 2.0, 0.0) - start) / _star_life
	_star_node.global_position = start
	_star_node.look_at(start + _star_vel, Vector3.UP)
	_star_active = true
	_star_node.visible = true
	_star_mesh_mat.albedo_color = Color(1.0, 0.98, 0.9, 1.0)


func _tick_shooting_stars(delta: float) -> void:
	if not _star_node:
		_build_shooting_star()
	if not _is_night():
		if _star_active:
			_star_active = false
			_star_node.visible = false
		return
	if _star_active:
		_star_life -= delta
		_star_node.global_position += _star_vel * delta
		var a := clampf(_star_life / 0.5, 0.0, 1.0)
		_star_mesh_mat.albedo_color.a = a
		_star_node.visible = a > 0.01
		if _star_life <= 0.0 or _star_node.global_position.y < _star_land.y + 3.0:
			_star_active = false
			_star_node.visible = false
			_make_star_shard(_star_land)
	else:
		_star_timer -= delta
		if _star_timer <= 0.0:
			_star_timer = randf_range(25.0, 55.0)
			if randf() < 0.18 and _craters.size() < 6:
				_spawn_meteor()
			else:
				_spawn_shooting_star()


func _make_star_shard(pos: Vector3) -> void:
	if _server or _client:
		return
	if _shards_night >= 2:
		return
	_shards_night += 1
	var pickup := StaticBody3D.new()
	pickup.name = "StarShard"
	pickup.collision_layer = 2
	pickup.collision_mask = 0
	pickup.set_script(preload("res://scripts/star_shard.gd"))
	pickup.set("world", self)
	pickup.position = pos + Vector3(0.0, 0.25, 0.0)
	var pid := _next_pickup_id
	_next_pickup_id += 1
	pickup.set_meta("pickup_id", pid)
	pickup.add_to_group("pickups")
	_pickups[pid] = pickup
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.4, 0.4, 0.4)
	col.shape = bs
	pickup.add_child(col)
	var crystal_mat := StandardMaterial3D.new()
	crystal_mat.albedo_color = Color(0.72, 0.55, 1.0)
	crystal_mat.emission_enabled = true
	crystal_mat.emission = Color(0.72, 0.55, 1.0)
	crystal_mat.emission_energy_multiplier = 2.0
	crystal_mat.roughness = 0.3
	var crystal := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(0.24, 0.3, 0.24)
	crystal.mesh = cm
	crystal.material_override = crystal_mat
	crystal.position = Vector3(0.0, 0.2, 0.0)
	pickup.add_child(crystal)
	var glow_mat := StandardMaterial3D.new()
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow_mat.albedo_color = Color(0.72, 0.55, 1.0, 0.5)
	var glow := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(0.5, 0.5, 0.5)
	glow.mesh = gm
	glow.material_override = glow_mat
	glow.position = Vector3(0.0, 0.25, 0.0)
	pickup.add_child(glow)
	pickup.set("_glow", glow)
	var light := OmniLight3D.new()
	light.light_color = Color(0.72, 0.55, 1.0)
	light.light_energy = 2.0
	light.omni_range = 5.0
	pickup.add_child(light)
	add_child(pickup)
	_post_chat("System", "A falling star struck the ground nearby — something glitters where it landed.")


func _give_player_shard() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	_player.set("health", minf(float(_player.get("max_health")), float(_player.get("health")) + 15.0))
	_player.set("stamina", minf(float(_player.get("max_stamina")), float(_player.get("stamina")) + 40.0))
	_post_chat("System", "The star shard hums with warmth. +15 health, +40 stamina.")
	return true


func _build_siren_wav() -> AudioStreamWAV:
	var frames := int(22050.0 * 6.0)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in frames:
		var t := float(i) / 22050.0
		var cycle := fmod(t, 1.5)
		var freq := 660.0 if cycle < 0.75 else 495.0
		var env := 0.9 if t < 5.2 else 0.45
		var v := sin(TAU * freq * t) * env
		var sample := int(clampf(v, -1.0, 1.0) * 32000.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	return wav


func _build_siren() -> void:
	_siren_audio = AudioStreamPlayer3D.new()
	_siren_audio.unit_size = 26.0
	_siren_audio.max_distance = 600.0
	_siren_wav = _build_siren_wav()
	_siren_audio.stream = _siren_wav
	var pos := Vector3.ZERO
	if not _reactors.is_empty() and is_instance_valid(_reactors[0]):
		pos = (_reactors[0] as Node3D).global_position
	_siren_audio.position = pos + Vector3(0.0, 14.0, 0.0)
	add_child(_siren_audio)


func _play_siren(seconds: float) -> void:
	if _siren_audio == null:
		return
	_siren_t = maxf(_siren_t, seconds)
	if not _siren_audio.playing:
		_siren_audio.play()


func _update_siren(delta: float) -> void:
	if _siren_audio == null:
		return
	if _siren_t > 0.0:
		_siren_t -= delta
	if _siren_t <= 0.0 and _siren_audio.playing:
		_siren_audio.stop()


func _build_shooting_stars() -> void:
	var p := GPUParticles3D.new()
	p.name = "ShootingStars"
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(1200.0, 240.0, 1200.0)
	pm.direction = Vector3(0.3, -1.0, 0.2).normalized()
	pm.spread = 2.0
	pm.initial_velocity_min = 150.0
	pm.initial_velocity_max = 210.0
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.03
	pm.scale_max = 0.07
	pm.color = Color(0.9, 0.95, 1.0, 0.9)
	p.process_material = pm
	p.amount = 320
	p.lifetime = 0.9
	p.one_shot = false
	p.emitting = false
	p.visible = false
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.albedo_color = Color(0.85, 0.92, 1.0, 0.9)
	var streak := BoxMesh.new()
	streak.size = Vector3(0.05, 0.05, 1.8)
	streak.material = mat
	p.draw_pass_1 = streak
	add_child(p)
	_shooting_stars = p


func _update_shooting_stars() -> void:
	if _shooting_stars == null:
		return
	var night := _is_night()
	_shooting_stars.emitting = night
	_shooting_stars.visible = night
	if _player:
		_shooting_stars.global_position = _player.global_position


func _build_campfire(pos: Vector3) -> void:
	var grp := Node3D.new()
	grp.name = "Campfire"
	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.35, 0.32, 0.3)
	stone_mat.roughness = 1.0
	for i in 6:
		var stone := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.18
		sm.height = 0.16
		stone.mesh = sm
		stone.material_override = stone_mat
		stone.position = Vector3(cos(i * TAU / 6.0) * 0.45, 0.06, sin(i * TAU / 6.0) * 0.45)
		grp.add_child(stone)
	var log_mat := StandardMaterial3D.new()
	log_mat.albedo_color = Color(0.3, 0.18, 0.09)
	var fire_mat := StandardMaterial3D.new()
	fire_mat.albedo_color = Color(1.0, 0.62, 0.15)
	fire_mat.emission_enabled = true
	fire_mat.emission = Color(1.0, 0.5, 0.12)
	fire_mat.emission_energy_multiplier = 3.0
	fire_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in 3:
		var log := MeshInstance3D.new()
		var lm := CylinderMesh.new()
		lm.top_radius = 0.07
		lm.bottom_radius = 0.09
		lm.height = 0.6
		log.mesh = lm
		log.material_override = log_mat
		log.position = Vector3(0.0, 0.14, 0.0)
		log.rotation.y = i * PI / 3.0
		grp.add_child(log)
	var fire := MeshInstance3D.new()
	var fm := SphereMesh.new()
	fm.radius = 0.14
	fm.height = 0.3
	fire.mesh = fm
	fire.material_override = fire_mat
	fire.position = Vector3(0.0, 0.4, 0.0)
	grp.add_child(fire)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.55, 0.2)
	light.light_energy = 2.2
	light.omni_range = 14.0
	light.position = Vector3(0.0, 1.2, 0.0)
	grp.add_child(light)
	var embers := GPUParticles3D.new()
	var epm := ParticleProcessMaterial.new()
	epm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	epm.emission_sphere_radius = 0.12
	epm.direction = Vector3.UP
	epm.spread = 8.0
	epm.gravity = Vector3(0.0, 1.0, 0.0)
	epm.initial_velocity_min = 0.6
	epm.initial_velocity_max = 1.4
	epm.scale_min = 0.015
	epm.scale_max = 0.04
	epm.color = Color(1.0, 0.6, 0.2, 0.9)
	embers.process_material = epm
	embers.amount = 24
	embers.lifetime = 2.0
	embers.position = Vector3(0.0, 0.5, 0.0)
	embers.emitting = false
	embers.visible = false
	grp.add_child(embers)
	grp.set_meta("light", light)
	grp.set_meta("fire", fire)
	grp.set_meta("embers", embers)
	grp.position = pos
	add_child(grp)
	_campfires.append(grp)


func _build_campfires() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 81
	for vi in _villages.size():
		var c := _villages[vi]
		var px := c.x + rng.randf_range(-5.0, 5.0)
		var pz := c.y + rng.randf_range(-5.0, 5.0)
		_build_campfire(Vector3(px, _height_at(px, pz), pz))


func _build_gardens() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 71
	for house in get_tree().get_nodes_in_group("houses"):
		var h := house as Node3D
		if h == null or not is_instance_valid(h):
			continue
		var bp: Vector3 = h.global_position
		var side := Vector3(-sin(h.rotation.y), 0.0, cos(h.rotation.y))
		var ang := rng.randf_range(0.0, TAU)
		var ox := cos(ang) * 3.2
		var oz := sin(ang) * 3.2
		var gx := bp.x + ox
		var gz := bp.z + oz
		var gh := _height_at(gx, gz)
		if gh < 0.5 or gh > 10.0:
			continue
		var grad := _slope_at(gx, gz)
		if grad > 0.25:
			continue
		_build_garden(Vector3(gx, gh, gz), side, rng)


func _build_garden(base: Vector3, side: Vector3, rng: RandomNumberGenerator) -> void:
	var grp := Node3D.new()
	grp.name = "Garden"
	var soil_mat := StandardMaterial3D.new()
	soil_mat.albedo_color = Color(0.32, 0.21, 0.13)
	soil_mat.roughness = 1.0
	var soil := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(3.4, 0.18, 2.2)
	soil.mesh = sm
	soil.material_override = soil_mat
	soil.position = Vector3(0.0, 0.02, 0.0)
	grp.add_child(soil)
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.45, 0.32, 0.2)
	frame_mat.roughness = 0.8
	for fd in [[0.0, 1.0, 3.4, 0.14], [0.0, -1.0, 3.4, 0.14], [1.0, 0.0, 0.14, 2.2], [-1.0, 0.0, 0.14, 2.2]]:
		var rail := MeshInstance3D.new()
		var rm := BoxMesh.new()
		rm.size = Vector3(fd[2], 0.14, fd[3])
		rail.mesh = rm
		rail.material_override = frame_mat
		rail.position = Vector3(fd[0] * 1.7, 0.1, fd[1] * 1.1)
		grp.add_child(rail)
	var crops: Array[Node3D] = []
	for row in 2:
		for col in 2:
			var crop := _build_crop()
			crop.position = Vector3(-0.85 + col * 1.7, 0.2, -0.55 + row * 1.1)
			crop.rotation.y = rng.randf() * TAU
			grp.add_child(crop)
			crops.append(crop)
	grp.position = base
	add_child(grp)
	grp.set_meta("crops", crops)
	grp.set_meta("offset_h", rng.randf_range(0.0, 18.0))
	_gardens.append(grp)


func _build_crop() -> Node3D:
	var crop := Node3D.new()
	var stem_mat := StandardMaterial3D.new()
	stem_mat.albedo_color = Color(0.36, 0.5, 0.22)
	stem_mat.roughness = 0.9
	var stem := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.012
	sm.bottom_radius = 0.02
	sm.height = 0.32
	stem.mesh = sm
	stem.material_override = stem_mat
	stem.position = Vector3(0.0, 0.16, 0.0)
	crop.add_child(stem)
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.3, 0.55, 0.2)
	leaf_mat.roughness = 0.8
	var leaves := Node3D.new()
	for li in 3:
		var lf := MeshInstance3D.new()
		var lm := SphereMesh.new()
		lm.radius = 0.09
		lm.height = 0.14
		lf.mesh = lm
		lf.material_override = leaf_mat
		lf.position = Vector3(-0.08 + li * 0.08, 0.18, 0.05)
		lf.scale = Vector3(1.0, 0.7, 0.8)
		leaves.add_child(lf)
	crop.add_child(leaves)
	var fruit_mat := StandardMaterial3D.new()
	fruit_mat.albedo_color = Color(0.9, 0.35, 0.25)
	fruit_mat.roughness = 0.4
	fruit_mat.emission_enabled = true
	fruit_mat.emission = Color(0.0, 0.0, 0.0)
	fruit_mat.emission_energy_multiplier = 1.0
	var fruit := Node3D.new()
	for fi in 2:
		var fr := MeshInstance3D.new()
		var fm := SphereMesh.new()
		fm.radius = 0.07
		fm.height = 0.13
		fr.mesh = fm
		fr.material_override = fruit_mat
		fr.position = Vector3(-0.06 + fi * 0.12, 0.26, 0.0)
		fruit.add_child(fr)
	crop.add_child(fruit)
	crop.set_meta("stem", stem)
	crop.set_meta("leaves", leaves)
	crop.set_meta("fruit", fruit)
	crop.set_meta("leaf_mat", leaf_mat)
	crop.set_meta("fruit_mat", fruit_mat)
	return crop


func _update_gardens() -> void:
	for grp in _gardens:
		if grp == null or not is_instance_valid(grp):
			continue
		var offset_h := float(grp.get_meta("offset_h"))
		var days := int(floor((_time_of_day + offset_h) / 24.0))
		var ripe := _garden_ripe_days()
		var stage := clampi(int(days / float(ripe) * 3.0), 0, 3)
		var crops: Array = grp.get_meta("crops")
		for crop in crops:
			_crop_stage(crop, stage)


func _crop_stage(crop: Node3D, stage: int) -> void:
	var stem := crop.get_meta("stem") as MeshInstance3D
	var leaves := crop.get_meta("leaves") as Node3D
	var fruit := crop.get_meta("fruit") as Node3D
	var leaf_mat := crop.get_meta("leaf_mat") as StandardMaterial3D
	var fruit_mat := crop.get_meta("fruit_mat") as StandardMaterial3D
	var stem_sm := stem.mesh as CylinderMesh
	stem_sm.height = 0.12 + stage * 0.07
	stem.position.y = stem_sm.height * 0.5
	var leaf_scale := 0.3 + stage * 0.25
	leaves.scale = Vector3.ONE * leaf_scale
	if stage >= 2:
		leaves.visible = true
	else:
		leaves.visible = stage >= 1
	leaf_mat.albedo_color = Color(0.28 + stage * 0.02, 0.5 + stage * 0.04, 0.18)
	fruit.visible = stage >= 2
	if stage == 2:
		fruit_mat.albedo_color = Color(0.5, 0.72, 0.3)
		fruit_mat.emission = Color(0.0, 0.0, 0.0)
	elif stage == 3:
		fruit_mat.albedo_color = Color(0.92, 0.38, 0.22)
		fruit_mat.emission = Color(0.6, 0.12, 0.05)
		fruit_mat.emission_energy_multiplier = 1.0


func _update_campfires(delta: float) -> void:
	var night := _is_night()
	var t := Time.get_ticks_msec() / 1000.0
	for grp in _campfires:
		if grp == null or not is_instance_valid(grp):
			continue
		var light := grp.get_meta("light") as OmniLight3D
		var fire := grp.get_meta("fire") as MeshInstance3D
		var embers := grp.get_meta("embers") as GPUParticles3D
		var on := night and not _grid_blackout
		light.visible = on
		fire.visible = on
		embers.visible = on
		embers.emitting = on
		if on:
			light.light_energy = 1.8 + sin(t * 23.0) * 0.4 + sin(t * 37.0 + 1.3) * 0.25
			fire.scale = Vector3.ONE * (1.0 + sin(t * 19.0) * 0.12)


func _build_balloon() -> void:
	var grp := Node3D.new()
	grp.name = "HotAirBalloon"
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.35, 0.3)
	mat.roughness = 0.7
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.95, 0.88, 0.75)
	bmat.roughness = 0.8
	var balloon := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 4.2
	sph.height = 8.4
	balloon.mesh = sph
	balloon.material_override = mat
	grp.add_child(balloon)
	var stripe := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 4.3
	cyl.bottom_radius = 4.3
	cyl.height = 1.2
	stripe.mesh = cyl
	stripe.material_override = bmat
	stripe.position = Vector3(0.0, -1.0, 0.0)
	grp.add_child(stripe)
	var basket_mat := StandardMaterial3D.new()
	basket_mat.albedo_color = Color(0.45, 0.3, 0.16)
	var basket := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.4, 0.9, 1.4)
	basket.mesh = bm
	basket.material_override = basket_mat
	basket.position = Vector3(0.0, -6.0, 0.0)
	grp.add_child(basket)
	var rope_mat := StandardMaterial3D.new()
	rope_mat.albedo_color = Color(0.3, 0.22, 0.15)
	for i in 4:
		var rope := MeshInstance3D.new()
		var rm := CylinderMesh.new()
		rm.top_radius = 0.04
		rm.bottom_radius = 0.04
		rm.height = 4.5
		rope.mesh = rm
		rope.material_override = rope_mat
		var a := i * TAU / 4.0
		rope.position = Vector3(cos(a) * 2.8, -3.8, sin(a) * 2.8)
		rope.rotation.x = cos(a) * 0.4
		rope.rotation.z = -sin(a) * 0.4
		grp.add_child(rope)
	var beacon := OmniLight3D.new()
	beacon.name = "BalloonBeacon"
	beacon.light_color = Color(1.0, 0.4, 0.3)
	beacon.light_energy = 0.0
	beacon.omni_range = 34.0
	beacon.position = Vector3(0.0, -6.6, 0.0)
	grp.add_child(beacon)
	grp.set_meta("beacon", beacon)
	grp.position = Vector3(0.0, 140.0, 0.0)
	add_child(grp)
	_balloon = grp


func _update_balloon(delta: float) -> void:
	if _balloon == null:
		return
	_balloon_ang += delta * 0.025
	var t := Time.get_ticks_msec() / 1000.0
	var r := 190.0 + sin(t * 0.03) * 12.0
	_balloon.position = Vector3(cos(_balloon_ang) * r, 135.0 + sin(t * 0.15) * 6.0, sin(_balloon_ang) * r)
	_balloon.rotation.y = -_balloon_ang + PI / 2.0
	_balloon.rotation.z = sin(t * 0.5) * 0.03
	var beacon := _balloon.get_meta("beacon") as OmniLight3D
	if beacon:
		var night := _is_night()
		beacon.light_energy = (1.2 if fmod(Time.get_ticks_msec() / 1000.0 * 0.8, 2.0) < 0.6 else 0.15) if night else 0.0


func _build_beacon() -> void:
	if _reactors.is_empty():
		return
	var r0: Node3D = _reactors[0]
	var pos := r0.global_position + Vector3(0.0, 0.0, 40.0)
	var grp := Node3D.new()
	grp.name = "BeaconTower"
	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.35, 0.12, 0.1)
	var pole := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.4
	pm.bottom_radius = 0.7
	pm.height = 48.0
	pole.mesh = pm
	pole.material_override = pole_mat
	pole.position = Vector3(0.0, 24.0, 0.0)
	grp.add_child(pole)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.12, 0.08)
	light.light_energy = 6.0
	light.omni_range = 70.0
	light.position = Vector3(0.0, 50.0, 0.0)
	grp.add_child(light)
	var lens_mat := StandardMaterial3D.new()
	lens_mat.albedo_color = Color(1.0, 0.2, 0.1)
	lens_mat.emission_enabled = true
	lens_mat.emission = Color(1.0, 0.15, 0.05)
	lens_mat.emission_energy_multiplier = 4.0
	lens_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var lens := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.8
	sph.height = 1.2
	lens.mesh = sph
	lens.material_override = lens_mat
	lens.position = Vector3(0.0, 49.2, 0.0)
	grp.add_child(lens)
	grp.position = pos
	add_child(grp)
	_beacon_light = light


func _update_beacon(delta: float) -> void:
	if _beacon_light == null:
		return
	var night := _is_night()
	_beacon_light.visible = night
	if not night:
		return
	var on := fmod(Time.get_ticks_msec() / 1000.0, 1.2) < 0.4
	_beacon_light.light_energy = 6.0 if on else 0.2


func _fill_zombie_audio(delta: float) -> void:
	if _zombie_audio == null:
		return
	var near := 0.0
	if _zombies_active and _player:
		for z in get_tree().get_nodes_in_group("zombies"):
			if z == null or not is_instance_valid(z):
				continue
			var d: float = _player.global_position.distance_to((z as Node3D).global_position)
			if d < 60.0:
				near = maxf(near, 1.0 - d / 60.0)
	var target := -60.0 if near <= 0.01 else lerpf(-34.0, -14.0, near)
	_zombie_audio.volume_db = lerpf(_zombie_audio.volume_db, target, delta * 3.0)
	if near <= 0.01:
		return
	var pb := _zombie_audio.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		return
	var frames := int(pb.get_frames_available())
	_zombie_moan_t -= delta
	while frames > 0:
		if _zombie_growl > 0.0:
			_zombie_growl -= 1.0 / 22050.0
			_zombie_phase += TAU * (55.0 + 40.0 * (1.0 - _zombie_growl)) / 22050.0
			var env := clampf(_zombie_growl * 10.0, 0.0, 1.0)
			var s := sin(_zombie_phase) * 0.6 + sin(_zombie_phase * 0.5) * 0.3
			pb.push_frame(Vector2(s * env * 0.3, s * env * 0.3))
		else:
			if _zombie_moan_t <= 0.0:
				_zombie_moan_t = randf_range(2.5, 7.0)
				_zombie_growl = randf_range(0.6, 1.5)
				_zombie_phase = randf() * TAU
			pb.push_frame(Vector2.ZERO)
		frames -= 1


func _fill_dread_audio(delta: float) -> void:
	if _dread_audio == null:
		return
	var night := _is_night()
	var tod := fmod(_time_of_day, 24.0)
	var deep := 0.0
	if night:
		if tod >= 23.0 or tod < 5.0:
			deep = 1.0
		else:
			deep = 0.55
	var dread := 0.0
	if night:
		dread = 0.5 + deep * 0.3
		if _zombies_active:
			dread += 0.35
	var target_db := -60.0
	if dread > 0.0:
		target_db = -30.0 - (1.0 - dread) * 12.0
	_dread_vol = lerpf(_dread_vol, dread, delta * 1.2)
	var tgt := -60.0 + _dread_vol * 30.0
	_dread_audio.volume_db = lerpf(_dread_audio.volume_db, tgt, delta * 2.0)
	if _dread_vol <= 0.01:
		return
	var pb := _dread_audio.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		return
	var frames := int(pb.get_frames_available())
	while frames > 0:
		_dread_phase += TAU * (48.0 + 3.0 * sin(_dread_phase * 0.7)) / 22050.0
		var a := sin(_dread_phase)
		var b := sin(_dread_phase * 0.5 + 1.7) * 0.6
		var c := sin(_dread_phase * 0.25 + 3.1) * 0.5
		var drone := (a + b + c) * 0.22
		var wob := 0.8 + 0.35 * sin(_dread_phase * 0.05)
		drone *= wob
		var whisper := 0.0
		if _dread_whisper_t < 0.0:
			if randf() < 0.06:
				_dread_whisper_t = randf_range(0.8, 1.8)
		else:
			_dread_whisper_t -= 1.0 / 22050.0
			var wh := randf() * 2.0 - 1.0
			wh *= lerpf(1.0, 0.0, clampf(_dread_whisper_t / 1.0, 0.0, 1.0))
			drone += wh * 0.12
		pb.push_frame(Vector2(drone, drone * 0.95))
		frames -= 1


func _tick_horror_viy(delta: float) -> void:
	if _horror_viy == null:
		return
	if _server or _client:
		return
	var night := _is_night()
	var tod := fmod(_time_of_day, 24.0)
	var deep := 0.0
	if night:
		if tod >= 23.0 or tod < 5.0:
			deep = 1.0
		else:
			deep = 0.45
	var strength := deep
	if _zombies_active:
		strength = minf(1.0, strength + 0.45)
	_horror_viy_t += delta
	var pulse := 0.06 * sin(_horror_viy_t * 2.1)
	var val := clampf(strength + pulse, 0.0, 1.0)
	_horror_viy.self_modulate.a = lerpf(_horror_viy.self_modulate.a, val, clampf(delta * 3.0, 0.0, 1.0))


func _tick_wraith(delta: float) -> void:
	if _server or _client:
		return
	var night := _is_night()
	if not night:
		if _wraith != null and is_instance_valid(_wraith):
			_wraith.call("despawn")
			_wraith = null
		return
	if _player == null or not is_instance_valid(_player):
		return
	if _wraith != null and is_instance_valid(_wraith):
		if _player.global_position.distance_to(_wraith.global_position) < 25.0:
			_wraith.call("despawn")
			_wraith = null
			_post_chat("You", "The figure vanishes the instant you get near...")
			_dread_whisper_t = -2.0
		return
	_wraith_t -= delta
	if _wraith_t > 0.0:
		return
	_wraith_t = randf_range(28.0, 70.0)
	if _zombies_active and randf() < 0.7:
		var ang := randf() * TAU
		var dist := randf_range(90.0, 210.0)
		var x := _player.global_position.x + cos(ang) * dist
		var z := _player.global_position.z + sin(ang) * dist
		var h := _height_at(x, z)
		if h < 1.0 or h > 30.0:
			return
		_wraith = preload("res://scripts/wraith.gd").new()
		_wraith.set("world", self)
		_wraith.setup(Vector3(x, h, z), _player.global_position)
		add_child(_wraith)


func _build_dock() -> void:
	if _villages.is_empty():
		return
	var center := _villages[0]
	var shore := Vector3.ZERO
	var dir := Vector3.FORWARD
	var found := false
	for a in 48:
		var ang := a * TAU / 48.0
		for d in range(160, 960, 40):
			var x := center.x + cos(ang) * d
			var z := center.y + sin(ang) * d
			if _height_at(x, z) < WATER_Y:
				shore = Vector3(x, WATER_Y, z)
				dir = Vector3(cos(ang), 0.0, sin(ang))
				found = true
				break
		if found:
			break
	if not found:
		return
	_dock_shore = shore
	_dock_dir = dir
	var grp := Node3D.new()
	grp.name = "Dock"
	var plank_mat := StandardMaterial3D.new()
	plank_mat.albedo_color = Color(0.5, 0.38, 0.22)
	plank_mat.roughness = 1.0
	for i in 8:
		var plank := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(3.0, 0.18, 3.0)
		plank.mesh = bm
		plank.material_override = plank_mat
		var p := shore + dir * (i * 3.0 + 1.5)
		plank.position = p + Vector3(0.0, 0.55 + sin(float(i) * 1.7) * 0.03, 0.0)
		plank.rotation.y = atan2(dir.x, dir.z)
		grp.add_child(plank)
	var dock_body := StaticBody3D.new()
	dock_body.name = "DockWalk"
	dock_body.collision_layer = 1
	for i in 8:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(3.0, 0.18, 3.0)
		cs.shape = bs
		var p := shore + dir * (i * 3.0 + 1.5)
		cs.position = p + Vector3(0.0, 0.55 + sin(float(i) * 1.7) * 0.03, 0.0)
		cs.rotation.y = atan2(dir.x, dir.z)
		dock_body.add_child(cs)
	grp.add_child(dock_body)
	var post_mat := StandardMaterial3D.new()
	post_mat.albedo_color = Color(0.32, 0.24, 0.14)
	for i in 6:
		var post := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.08
		cm.bottom_radius = 0.1
		cm.height = 2.2
		post.mesh = cm
		post.material_override = post_mat
		var p := shore + dir * (i * 3.0 + 1.5)
		post.position = p + Vector3(0.0, 1.1, 0.0)
		grp.add_child(post)
	var boat_mat := StandardMaterial3D.new()
	boat_mat.albedo_color = Color(0.75, 0.3, 0.22)
	boat_mat.roughness = 0.5
	var boat := CharacterBody3D.new()
	boat.name = "Rowboat"
	boat.set_script(preload("res://scripts/boat.gd"))
	boat.set("world", self)
	var hull := MeshInstance3D.new()
	var hbm := CylinderMesh.new()
	hbm.top_radius = 0.85
	hbm.bottom_radius = 0.85
	hbm.height = 3.4
	hull.mesh = hbm
	hull.material_override = boat_mat
	hull.rotation.x = PI / 2.0
	boat.add_child(hull)
	var seat_mat := StandardMaterial3D.new()
	seat_mat.albedo_color = Color(0.55, 0.42, 0.28)
	var seat := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(1.6, 0.1, 0.25)
	seat.mesh = sm
	seat.material_override = seat_mat
	seat.position = Vector3(0.0, 0.25, 0.0)
	boat.add_child(seat)
	var bcol := CollisionShape3D.new()
	var bcap := CapsuleShape3D.new()
	bcap.radius = 0.85
	bcap.height = 3.4
	bcol.shape = bcap
	bcol.rotation.x = PI / 2.0
	bcol.position = Vector3(0.0, 0.0, 0.0)
	boat.add_child(bcol)
	var bp := shore + dir * 24.0
	boat.position = bp + Vector3(0.0, WATER_Y + 0.45, 0.0)
	boat.rotation.y = atan2(dir.x, dir.z) + PI / 2.0
	grp.add_child(boat)
	add_child(grp)
	_dock = grp
	_boat = boat
	_dock_base = bp
	boat.set_meta("boat", true)
	boat.set_meta("dock_spot", bp)
	boat.set("speed_mult", _season_boat_speed())
	_build_lighthouse(shore, dir)
	var side := Vector3(-dir.z, 0.0, dir.x)
	for i in 3:
		_build_duck(bp + dir * 2.0 + side * (i * 2.4 - 2.4) + Vector3(0.0, WATER_Y + 0.12, 0.0))


func _build_duck(base: Vector3) -> void:
	var grp := Node3D.new()
	grp.name = "Duck"
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.92, 0.92, 0.88)
	body_mat.roughness = 0.6
	var body := MeshInstance3D.new()
	var bm := SphereMesh.new()
	bm.radius = 0.22
	bm.height = 0.4
	body.mesh = bm
	body.material_override = body_mat
	body.position = Vector3(0.0, 0.0, 0.0)
	body.scale = Vector3(1.0, 0.8, 1.3)
	grp.add_child(body)
	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.1
	hm.height = 0.2
	head.mesh = hm
	head.material_override = body_mat
	head.position = Vector3(0.0, 0.12, -0.26)
	grp.add_child(head)
	var beak_mat := StandardMaterial3D.new()
	beak_mat.albedo_color = Color(0.95, 0.55, 0.2)
	var beak := MeshInstance3D.new()
	var km := CylinderMesh.new()
	km.top_radius = 0.0
	km.bottom_radius = 0.05
	km.height = 0.12
	beak.mesh = km
	beak.material_override = beak_mat
	beak.position = Vector3(0.0, 0.12, -0.36)
	beak.rotation.x = -PI / 2.0
	grp.add_child(beak)
	grp.position = base
	add_child(grp)
	grp.set_meta("base", base)
	grp.set_meta("phase", randf() * TAU)
	_ducks.append(grp)


func _update_dock(delta: float) -> void:
	if _boat == null or not is_instance_valid(_boat):
		return
	for d in _ducks:
		if d == null or not is_instance_valid(d):
			continue
		var phase := float(d.get_meta("phase")) + delta * 0.45
		d.set_meta("phase", phase)
		var base: Vector3 = d.get_meta("base")
		var boat_pos := _boat.global_position
		var d2b := Vector2(boat_pos.x, boat_pos.z).distance_to(Vector2(d.position.x, d.position.z))
		if d2b < 15.0:
			var toward := boat_pos - d.position
			toward.y = 0.0
			if toward.length() > 0.01:
				var n := toward.normalized()
				var perp := Vector3(-n.z, 0.0, n.x) * sin(phase) * 1.1
				var target := boat_pos - n * 2.2 + perp
				target.y = WATER_Y + 0.12
				d.position = d.position.lerp(target, clampf(delta * 1.4, 0.0, 1.0))
				d.rotation.y = atan2(boat_pos.x - d.position.x, boat_pos.z - d.position.z)
		else:
			d.position = base + Vector3(sin(phase) * 1.2, sin(phase * 2.0) * 0.06, cos(phase * 0.7) * 1.2)
			d.position.y = WATER_Y + 0.12
			d.rotation.y = phase


func _build_lighthouse(shore: Vector3, dir: Vector3) -> void:
	var side := Vector3(-dir.z, 0.0, dir.x)
	var base := Vector3.ZERO
	for dist in [6.0, 10.0, 14.0, 18.0]:
		var cand: Vector3 = shore + side * dist
		var h := _height_at(cand.x, cand.z)
		if h > 0.9 and h < 16.0:
			base = Vector3(cand.x, h, cand.z)
			break
	if base == Vector3.ZERO:
		base = shore + side * 10.0
		base.y = maxf(_height_at(base.x, base.z), 0.1)
	var grp := Node3D.new()
	grp.name = "Lighthouse"
	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.88, 0.86, 0.8)
	stone_mat.roughness = 0.9
	var red_mat := StandardMaterial3D.new()
	red_mat.albedo_color = Color(0.75, 0.18, 0.16)
	red_mat.roughness = 0.9
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.95, 0.9, 0.55)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.emission_enabled = true
	glass_mat.emission = Color(1.0, 0.85, 0.4)
	glass_mat.emission_energy_multiplier = 0.6
	var tower := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 1.6
	tm.bottom_radius = 2.3
	tm.height = 11.0
	tower.mesh = tm
	tower.material_override = stone_mat
	tower.position = Vector3(0.0, 5.5, 0.0)
	grp.add_child(tower)
	var red_band := MeshInstance3D.new()
	var rbm := CylinderMesh.new()
	rbm.top_radius = 1.75
	rbm.bottom_radius = 1.85
	rbm.height = 1.4
	red_band.mesh = rbm
	red_band.material_override = red_mat
	red_band.position = Vector3(0.0, 8.2, 0.0)
	grp.add_child(red_band)
	var red_band2 := MeshInstance3D.new()
	var rbm2 := CylinderMesh.new()
	rbm2.top_radius = 2.15
	rbm2.bottom_radius = 2.3
	rbm2.height = 1.0
	red_band2.mesh = rbm2
	red_band2.material_override = red_mat
	red_band2.position = Vector3(0.0, 1.6, 0.0)
	grp.add_child(red_band2)
	var room := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 1.6
	rm.bottom_radius = 1.6
	rm.height = 2.4
	room.mesh = rm
	room.material_override = glass_mat
	room.position = Vector3(0.0, 11.8, 0.0)
	grp.add_child(room)
	var roof := MeshInstance3D.new()
	var rfm := CylinderMesh.new()
	rfm.top_radius = 0.15
	rfm.bottom_radius = 1.7
	rfm.height = 1.6
	roof.mesh = rfm
	roof.material_override = red_mat
	roof.position = Vector3(0.0, 13.4, 0.0)
	grp.add_child(roof)
	var lamp := MeshInstance3D.new()
	var lm := SphereMesh.new()
	lm.radius = 0.5
	lm.height = 1.0
	lamp.mesh = lm
	lamp.material_override = glass_mat
	lamp.position = Vector3(0.0, 11.8, 0.0)
	grp.add_child(lamp)
	var beam := SpotLight3D.new()
	beam.name = "LighthouseBeam"
	beam.light_color = Color(1.0, 0.92, 0.6)
	beam.light_energy = 0.0
	beam.spot_range = 150.0
	beam.spot_angle = 18.0
	beam.position = Vector3(0.0, 11.8, 0.0)
	beam.rotation_degrees = Vector3(-35.0, 0.0, 0.0)
	grp.add_child(beam)
	var glow := OmniLight3D.new()
	glow.name = "LighthouseGlow"
	glow.light_color = Color(1.0, 0.85, 0.5)
	glow.light_energy = 0.0
	glow.omni_range = 30.0
	glow.position = Vector3(0.0, 11.8, 0.0)
	grp.add_child(glow)
	grp.position = base
	add_child(grp)
	_lighthouse_light = beam
	grp.set_meta("glow", glow)


func _tick_berries(delta: float) -> void:
	if _berry_bushes.is_empty():
		return
	for bush in _berry_bushes:
		if bush == null or not is_instance_valid(bush):
			continue
		if int(bush.get("berries")) <= 0:
			var at := float(bush.get_meta("respawn_at", -1.0))
			if at >= 0.0 and _time_of_day >= at:
				bush.set("berries", 2)
				bush.call("_refresh_hint")
				var reds: Node = bush.get_node_or_null("Reds")
				if reds:
					reds.visible = true
	_tick_mushrooms()


func _build_berry_bushes() -> void:
	if _villages.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 96
	_berry_bushes = []
	var v := _villages[0]
	var placed := 0
	var tries := 0
	while placed < 6 and tries < 300:
		tries += 1
		var ang := rng.randf() * TAU
		var dist := rng.randf_range(16.0, 60.0)
		var x := v.x + cos(ang) * dist
		var z := v.y + sin(ang) * dist
		var h := _height_at(x, z)
		if h < 0.8 or h > 10.0:
			continue
		if _slope_at(x, z) > 0.2:
			continue
		var bush: StaticBody3D = preload("res://scripts/berry_bush.gd").new()
		bush.world = self
		bush.position = Vector3(x, h, z)
		bush.rotation.y = rng.randf() * TAU
		add_child(bush)
		_berry_bushes.append(bush)
		placed += 1


func _forage_berries(bush: Node3D) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if bush.global_position.distance_to(_player.global_position) > 4.5:
		return
	if int(bush.get("berries")) <= 0:
		_post_chat("Berries", "This bush is picked clean. It will regrow by tomorrow.")
		return
	var b := int(bush.get("berries")) - 1
	bush.set("berries", b)
	bush.call("_refresh_hint")
	_player.health = minf(_player.max_health, _player.health + 8.0)
	_player.stamina = minf(_player.max_stamina, _player.stamina + 10.0)
	_post_chat("You", "You picked some wild berries. +8 HP, +10 stamina.")
	if b <= 0:
		bush.set_meta("respawn_at", _time_of_day + 12.0)
		var reds: Node = bush.get_node_or_null("Reds")
		if reds:
			reds.visible = false


func _build_mushroom_forest() -> void:
	if _villages.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 173
	_mushrooms = []
	var v := _villages[0]
	var placed := 0
	var tries := 0
	while placed < 5 and tries < 300:
		tries += 1
		var ang := rng.randf() * TAU
		var dist := rng.randf_range(18.0, 70.0)
		var x := v.x + cos(ang) * dist
		var z := v.y + sin(ang) * dist
		var h := _height_at(x, z)
		if h < 1.0 or h > 16.0:
			continue
		if _slope_at(x, z) > 0.22:
			continue
		var m: StaticBody3D = preload("res://scripts/mushroom.gd").new()
		m.world = self
		m.position = Vector3(x, h, z)
		m.rotation.y = rng.randf() * TAU
		add_child(m)
		_mushrooms.append(m)
		placed += 1


func _forage_mushrooms(m: Node3D) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if m.global_position.distance_to(_player.global_position) > 4.5:
		return
	if int(m.get("shrooms")) <= 0:
		_post_chat("Mushrooms", "This patch is picked clean. It will regrow by tomorrow.")
		return
	var b := int(m.get("shrooms")) - 1
	m.set("shrooms", b)
	m.call("_refresh_hint")
	_player.health = minf(_player.max_health, _player.health + 10.0)
	_player.stamina = minf(_player.max_stamina, _player.stamina + 14.0)
	_player.thirst = minf(_player.max_thirst, _player.thirst + 8.0)
	_post_chat("You", "You foraged some glowing mushrooms. +10 HP, +14 stamina.")
	if not _tasks["mushroom"]:
		_complete_task("mushroom", "Foraged a cluster of glowing mushrooms")
	if b <= 0:
		m.set_meta("respawn_at", _time_of_day + 12.0)


func _tick_mushrooms() -> void:
	if _mushrooms.is_empty():
		return
	for m in _mushrooms:
		if m == null or not is_instance_valid(m):
			continue
		if int(m.get("shrooms")) <= 0:
			var r: float = float(m.get_meta("respawn_at", -1.0))
			if r >= 0.0 and _time_of_day >= r:
				m.set("shrooms", 2)
				m.call("_refresh_hint")


func _tick_lighthouse(delta: float) -> void:
	if _lighthouse_light == null or not is_instance_valid(_lighthouse_light):
		return
	_lighthouse_ang += delta * 1.1
	_lighthouse_light.rotation.y = _lighthouse_ang
	var night := _is_night()
	var t := Time.get_ticks_msec() / 1000.0
	var en := (2.6 if fmod(t * 1.2, 2.0) < 1.3 else 0.5) if night else 0.0
	_lighthouse_light.light_energy = en
	var glow := _lighthouse_light.get_parent().get_meta("glow") as OmniLight3D
	if glow:
		glow.light_energy = (0.9 if night else 0.0)


func _near_dock() -> bool:
	if _dock_base == Vector3.ZERO or _player == null:
		return false
	return Vector2(_player.global_position.x, _player.global_position.z).distance_to(Vector2(_dock_base.x, _dock_base.z)) < 9.0


func _try_fish() -> void:
	if _fishing or _player == null:
		return
	_fishing = true
	_fish_timer = randf_range(2.5, 5.5)
	_post_chat("You", "You cast a line off the dock...")
	if _fish_status:
		_fish_status.text = "FISHING... waiting for a bite"
		_fish_status.visible = true
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.95, 1.0, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.8, 0.9, 1.0)
	mat.emission_energy_multiplier = 1.5
	_bobber = MeshInstance3D.new()
	var bm := SphereMesh.new()
	bm.radius = 0.08
	bm.height = 0.14
	_bobber.mesh = bm
	_bobber.material_override = mat
	var p := _player.global_position
	_bobber.position = Vector3(p.x, WATER_Y + 0.12, p.z) + (_player.global_transform.basis * Vector3(0.0, 0.0, -5.0))
	_bobber.position.y = WATER_Y + 0.12
	add_child(_bobber)


func _try_boat_fish() -> void:
	if _fishing or _player == null:
		return
	if not bool(_player.get("in_boat")) or _boat == null or not is_instance_valid(_boat):
		return
	_fishing = true
	_fishing_boat = true
	_fish_timer = randf_range(2.0, 5.0)
	_post_chat("You", "You cast a line off the rowboat...")
	if _fish_status:
		_fish_status.text = "FISHING... waiting for a bite"
		_fish_status.visible = true
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.95, 1.0, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.8, 0.9, 1.0)
	mat.emission_energy_multiplier = 1.5
	_bobber = MeshInstance3D.new()
	var bm := SphereMesh.new()
	bm.radius = 0.08
	bm.height = 0.14
	_bobber.mesh = bm
	_bobber.material_override = mat
	var b := _boat.global_position
	_bobber.position = Vector3(b.x, WATER_Y + 0.12, b.z) + (_boat.global_transform.basis * Vector3(0.0, 0.0, -4.5))
	_bobber.position.y = WATER_Y + 0.12
	add_child(_bobber)


func _tick_fishing(delta: float) -> void:
	if not _fishing:
		return
	if _fishing_boat:
		if _player == null or not is_instance_valid(_player) or not bool(_player.get("in_boat")):
			_cancel_fishing()
			return
	_fish_timer -= delta
	if _bobber and is_instance_valid(_bobber):
		if _fishing_boat and _boat != null and is_instance_valid(_boat):
			var b := _boat.global_position
			_bobber.position.x = b.x + (_boat.global_transform.basis * Vector3(0.0, 0.0, -4.5)).x
			_bobber.position.z = b.z + (_boat.global_transform.basis * Vector3(0.0, 0.0, -4.5)).z
		var t := Time.get_ticks_msec() / 1000.0
		_bobber.position.y = WATER_Y + 0.12 + sin(t * 6.0) * 0.03
	if _fish_timer <= 0.0:
		_finish_fishing()


func _cancel_fishing() -> void:
	_fishing = false
	_fishing_boat = false
	if _fish_status:
		_fish_status.visible = false
	if _bobber and is_instance_valid(_bobber):
		_bobber.queue_free()
		_bobber = null


func _finish_fishing() -> void:
	_fishing = false
	var was_boat := _fishing_boat
	_fishing_boat = false
	if _fish_status:
		_fish_status.visible = false
	if _bobber and is_instance_valid(_bobber):
		_bobber.queue_free()
		_bobber = null
	if _player == null or not is_instance_valid(_player):
		return
	var bite := 0.8 if was_boat else 0.7
	if randf() < bite:
		var rare := randf() < 0.06
		var fish: String
		if rare:
			fish = "golden koi"
		else:
			var names := ["rainbow trout", "mountain carp", "silver bass", "squeaky boot"]
			fish = names[randi() % names.size()]
		if fish == "squeaky boot":
			_post_chat("You", "You fished up a squeaky boot. The market won't buy that.")
		elif fish == "golden koi":
			var koi_heal := 30
			_player.health = minf(_player.max_health, _player.health + koi_heal)
			_player.stamina = minf(_player.max_stamina, _player.stamina + 50.0)
			_post_chat("You", "!! You caught the RARE GOLDEN KOI! +%d health, it glimmers in the sun." % koi_heal)
			_complete_task("koi", "Catch the rare golden koi")
		else:
			var heal := randi_range(6, 15)
			_player.health = minf(_player.max_health, _player.health + heal)
			_player.stamina = minf(_player.max_stamina, _player.stamina + 20.0)
			_fish_basket += 1
			_post_chat("You", "You caught a %s! +%d health, stored in your market basket (%d)." % [fish, heal, _fish_basket])
		if was_boat:
			_complete_task("boat", "Row out on the lake")
		_complete_task("fish", "Caught a fish at the dock")
	else:
		_post_chat("You", "The fish got away. Maybe another cast.")


func _build_hot_spring() -> void:
	if _villages.is_empty():
		return
	var center := _villages[0]
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 77
	var pos := Vector2.ZERO
	var found := false
	for i in 200:
		var a := rng.randf() * TAU
		var d := rng.randf_range(30.0, 70.0)
		var x := center.x + cos(a) * d
		var z := center.y + sin(a) * d
		var h := _height_at(x, z)
		if h < 1.0 or h > 8.0:
			continue
		if _slope_at(x, z) > 0.12:
			continue
		var clear := true
		for hs in get_tree().get_nodes_in_group("houses"):
			if Vector2(x, z).distance_to(Vector2((hs as Node3D).global_position.x, (hs as Node3D).global_position.z)) < 12.0:
				clear = false
				break
		if not clear:
			continue
		pos = Vector2(x, z)
		found = true
		break
	if not found:
		return
	var h := _height_at(pos.x, pos.y)
	var grp := Node3D.new()
	grp.name = "HotSpring"
	grp.position = Vector3(pos.x, h, pos.y)
	var water_mat := StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.5, 0.85, 0.8, 0.75)
	water_mat.roughness = 0.1
	water_mat.metallic = 0.1
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_mat.emission_enabled = true
	water_mat.emission = Color(0.35, 0.7, 0.65)
	water_mat.emission_energy_multiplier = 1.4
	var water := MeshInstance3D.new()
	var wm := CylinderMesh.new()
	wm.top_radius = 4.6
	wm.bottom_radius = 4.6
	wm.height = 0.4
	water.mesh = wm
	water.material_override = water_mat
	water.position = Vector3(0.0, 0.25, 0.0)
	grp.add_child(water)
	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.45, 0.43, 0.4)
	stone_mat.roughness = 1.0
	for i in 18:
		var a := i * TAU / 18.0
		var stone := MeshInstance3D.new()
		var sm := SphereMesh.new()
		var s := rng.randf_range(0.35, 0.75)
		sm.radius = s
		sm.height = s * 1.8
		stone.mesh = sm
		stone.material_override = stone_mat
		stone.position = Vector3(cos(a) * 5.0, s * 0.6, sin(a) * 5.0)
		stone.scale = Vector3(rng.randf_range(0.8, 1.4), 0.6, rng.randf_range(0.8, 1.4))
		grp.add_child(stone)
	var steam := GPUParticles3D.new()
	var spm := ParticleProcessMaterial.new()
	spm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	spm.emission_sphere_radius = 3.0
	spm.direction = Vector3.UP
	spm.spread = 12.0
	spm.gravity = Vector3(0.0, -0.6, 0.0)
	spm.initial_velocity_min = 0.5
	spm.initial_velocity_max = 1.3
	spm.scale_min = 0.5
	spm.scale_max = 1.4
	spm.color = Color(1.0, 1.0, 1.0, 0.5)
	steam.process_material = spm
	steam.amount = 40
	steam.lifetime = 3.5
	steam.position = Vector3(0.0, 0.5, 0.0)
	grp.add_child(steam)
	var light := OmniLight3D.new()
	light.light_color = Color(0.9, 0.75, 0.5)
	light.light_energy = 2.0
	light.omni_range = 12.0
	light.position = Vector3(0.0, 2.0, 0.0)
	grp.add_child(light)
	grp.set_meta("light", light)
	add_child(grp)
	_hot_spring = grp


func _update_hot_spring(delta: float) -> void:
	if _hot_spring == null or not is_instance_valid(_hot_spring):
		return
	var light := _hot_spring.get_meta("light") as OmniLight3D
	light.visible = _is_night()
	if light.visible:
		var t := Time.get_ticks_msec() / 1000.0
		light.light_energy = 1.6 + sin(t * 3.0) * 0.4
	if _player == null or not is_instance_valid(_player):
		return
	var d := Vector2(_player.global_position.x, _player.global_position.z).distance_to(
		Vector2(_hot_spring.global_position.x, _hot_spring.global_position.z))
	if d < 5.0 and not bool(_player.get("in_car")):
		var mult := _spring_heal_mult()
		_player.health = minf(_player.max_health, _player.health + delta * 2.0 * mult)
		_player.stamina = minf(_player.max_stamina, _player.stamina + delta * 4.0 * mult)
		_player.thirst = minf(_player.max_thirst, _player.thirst + delta * 12.0 * mult)


func _tick_drink(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if bool(_player.get("in_car")) or bool(_player.get("in_boat")):
		return
	var thirst := float(_player.get("thirst"))
	if thirst >= float(_player.get("max_thirst")):
		return
	var drank := false
	if _wells_loaded == null:
		_wells_loaded = get_tree().get_nodes_in_group("wells")
	for w in _wells_loaded:
		if w == null or not is_instance_valid(w):
			continue
		var wp: Node3D = w as Node3D
		var d := Vector2(_player.global_position.x, _player.global_position.z).distance_to(
			Vector2(wp.global_position.x, wp.global_position.z))
		if d < 3.5:
			drank = true
			break
	if drank:
		_player.set("thirst", minf(float(_player.get("max_thirst")), thirst + delta * 25.0))
		if _player.global_position.y >= 0.0 and not _tasks["thirst"]:
			_complete_task("thirst", "Quenched your thirst at a well")


func _build_bell_wav() -> AudioStreamWAV:
	var frames := int(22050.0 * 2.5)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in frames:
		var t := float(i) / 22050.0
		var env := exp(-t * 2.2)
		var v := sin(TAU * 196.0 * t) + sin(TAU * 392.0 * t) * 0.45 + sin(TAU * 568.0 * t) * 0.22 + sin(TAU * 822.0 * t) * 0.1
		v *= env * 0.5
		var sample := int(clampf(v, -1.0, 1.0) * 32000.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	wav.data = data
	return wav


func _build_bell_tower() -> void:
	if _villages.is_empty():
		return
	var center := _villages[0]
	var grp := Node3D.new()
	grp.name = "BellTower"
	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.6, 0.58, 0.52)
	stone_mat.roughness = 1.0
	var dark_mat := StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.45, 0.43, 0.38)
	var tower := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(3.2, 11.0, 3.2)
	tower.mesh = tm
	tower.material_override = stone_mat
	tower.position = Vector3(0.0, 5.5, 0.0)
	grp.add_child(tower)
	var roof := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 0.0
	rm.bottom_radius = 2.6
	rm.height = 2.4
	roof.mesh = rm
	roof.material_override = dark_mat
	roof.position = Vector3(0.0, 11.5, 0.0)
	grp.add_child(roof)
	var bell_grp := Node3D.new()
	bell_grp.position = Vector3(0.0, 10.2, 0.0)
	grp.add_child(bell_grp)
	var bell_mat := StandardMaterial3D.new()
	bell_mat.albedo_color = Color(0.78, 0.66, 0.4)
	bell_mat.roughness = 0.4
	var bell := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.35
	bm.bottom_radius = 0.5
	bm.height = 0.9
	bell.mesh = bm
	bell.material_override = bell_mat
	bell_grp.add_child(bell)
	var clapper := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 0.09
	cm.height = 0.18
	clapper.mesh = cm
	clapper.material_override = bell_mat
	clapper.position = Vector3(0.0, -0.6, 0.0)
	bell_grp.add_child(clapper)
	var h := _height_at(center.x, center.y)
	grp.position = Vector3(center.x, h, center.y)
	add_child(grp)
	_bell_tower = grp
	_bell_node = bell_grp
	var vane_pole := MeshInstance3D.new()
	var vpm := CylinderMesh.new()
	vpm.top_radius = 0.03
	vpm.bottom_radius = 0.03
	vpm.height = 0.8
	vane_pole.mesh = vpm
	vane_pole.material_override = stone_mat
	vane_pole.position = Vector3(0.0, 12.6, 0.0)
	grp.add_child(vane_pole)
	var vane_grp := Node3D.new()
	vane_grp.position = Vector3(0.0, 13.0, 0.0)
	grp.add_child(vane_grp)
	var arrow := MeshInstance3D.new()
	var am := BoxMesh.new()
	am.size = Vector3(1.5, 0.06, 0.14)
	arrow.mesh = am
	arrow.material_override = dark_mat
	vane_grp.add_child(arrow)
	var tail := MeshInstance3D.new()
	var ttm := PrismMesh.new()
	ttm.size = Vector3(0.5, 0.08, 0.2)
	tail.mesh = ttm
	tail.material_override = dark_mat
	tail.position = Vector3(-0.7, 0.0, 0.0)
	vane_grp.add_child(tail)
	_weather_vane = vane_grp


func _strike_bell(count: int) -> void:
	if _bell_audio == null:
		return
	var vol := -8.0
	if _player and not _villages.is_empty():
		var d := _player.global_position.distance_to(Vector3(_villages[0].x, 0.0, _villages[0].y))
		vol = lerpf(-4.0, -26.0, clampf(d / 700.0, 0.0, 1.0))
	_bell_swing_t = 1.0
	for i in count:
		var delay := i * 1.9
		get_tree().create_timer(delay).timeout.connect(func() -> void:
			if is_instance_valid(_bell_audio) and _bell_wav:
				_bell_audio.stream = _bell_wav
				_bell_audio.volume_db = vol
				_bell_audio.play())


func _tick_bell(delta: float) -> void:
	if _bell_audio == null:
		return
	var h := int(floor(_time_of_day)) % 24
	if h != _bell_hour:
		_bell_hour = h
		var n := h % 12
		if n == 0:
			n = 12
		_strike_bell(n)
	if _bell_swing_t > 0.0:
		_bell_swing_t -= delta
		if _bell_node:
			_bell_node.rotation.z = sin(_bell_swing_t * 30.0) * 0.35 * _bell_swing_t
	elif _bell_node:
		_bell_node.rotation.z = 0.0


func _init_weather() -> void:
	var p := GPUParticles3D.new()
	p.name = "Rain"
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(500.0, 80.0, 500.0)
	pm.direction = Vector3(0.0, -1.0, 0.0)
	pm.spread = 4.0
	pm.initial_velocity_min = 18.0
	pm.initial_velocity_max = 22.0
	pm.gravity = Vector3(0.0, -40.0, 0.0)
	pm.scale_min = 0.9
	pm.scale_max = 1.4
	pm.color = Color(0.7, 0.75, 0.85, 0.35)
	p.process_material = pm
	p.amount = 2000
	p.lifetime = 1.5
	pm.lifetime_randomness = 0.3
	p.one_shot = false
	p.emitting = false
	p.visible = false
	p.position = Vector3(0.0, 140.0, 0.0)
	var streak := BoxMesh.new()
	streak.size = Vector3(0.04, 0.04, 1.6)
	var streak_mat := StandardMaterial3D.new()
	streak_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	streak_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	streak_mat.albedo_color = Color(0.75, 0.8, 0.9, 0.5)
	p.draw_pass_1 = streak
	streak.material = streak_mat
	add_child(p)
	_rain_particles = p
	_build_snow_particles()

	_rain_audio = AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = 0.3
	_rain_audio.stream = gen
	_rain_audio.volume_db = -16.0
	add_child(_rain_audio)
	_rain_audio.play()

	_thunder_audio = AudioStreamPlayer.new()
	add_child(_thunder_audio)
	_thunder_wav = _build_thunder_wav()

	_owl_audio = AudioStreamPlayer.new()
	_owl_wav = _build_owl_wav()
	_owl_audio.stream = _owl_wav
	_owl_audio.volume_db = -60.0
	add_child(_owl_audio)

	_cricket_audio = AudioStreamPlayer.new()
	var cgen := AudioStreamGenerator.new()
	cgen.mix_rate = 22050
	cgen.buffer_length = 0.3
	_cricket_audio.stream = cgen
	_cricket_audio.volume_db = -18.0
	add_child(_cricket_audio)
	_cricket_audio.play()

	_dread_audio = AudioStreamPlayer.new()
	var dgen := AudioStreamGenerator.new()
	dgen.mix_rate = 22050
	dgen.buffer_length = 0.3
	_dread_audio.stream = dgen
	_dread_audio.volume_db = -60.0
	add_child(_dread_audio)
	_dread_audio.play()

	_plant_hum_audio = AudioStreamPlayer.new()
	var hgen := AudioStreamGenerator.new()
	hgen.mix_rate = 22050
	hgen.buffer_length = 0.3
	_plant_hum_audio.stream = hgen
	_plant_hum_audio.volume_db = -30.0
	add_child(_plant_hum_audio)
	_plant_hum_audio.play()

	_radio_audio = AudioStreamPlayer.new()
	var rgen := AudioStreamGenerator.new()
	rgen.mix_rate = 22050
	rgen.buffer_length = 0.3
	_radio_audio.stream = rgen
	_radio_audio.volume_db = -14.0
	add_child(_radio_audio)

	_birdsong_audio = AudioStreamPlayer.new()
	var bgen := AudioStreamGenerator.new()
	bgen.mix_rate = 22050
	bgen.buffer_length = 0.3
	_birdsong_audio.stream = bgen
	_birdsong_audio.volume_db = -16.0
	add_child(_birdsong_audio)
	_birdsong_audio.play()

	_build_fireworks()
	_build_birds()
	_build_siren()
	_build_shooting_stars()
	_build_balloon()

	_bell_audio = AudioStreamPlayer.new()
	_bell_wav = _build_bell_wav()
	add_child(_bell_audio)

	_zombie_audio = AudioStreamPlayer.new()
	var zgen := AudioStreamGenerator.new()
	zgen.mix_rate = 22050
	zgen.buffer_length = 0.3
	_zombie_audio.stream = zgen
	_zombie_audio.volume_db = -60.0
	add_child(_zombie_audio)
	_zombie_audio.play()


func _build_fireworks() -> void:
	var p := GPUParticles3D.new()
	p.name = "Fireworks"
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 3.0
	pm.direction = Vector3(0.0, 1.0, 0.0)
	pm.spread = 180.0
	pm.initial_velocity_min = 6.0
	pm.initial_velocity_max = 26.0
	pm.gravity = Vector3(0.0, -3.0, 0.0)
	pm.scale_min = 0.10
	pm.scale_max = 0.30
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.35, 0.25))
	grad.set_color(1, Color(1.0, 0.85, 0.3))
	grad.add_point(0.5, Color(0.35, 0.9, 0.45))
	grad.add_point(0.75, Color(0.35, 0.6, 1.0))
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	pm.color_ramp = gt
	p.process_material = pm
	p.amount = 700
	p.lifetime = 2.6
	pm.lifetime_randomness = 0.5
	p.one_shot = true
	p.emitting = false
	p.position = Vector3(0.0, 42.0, 0.0)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	sphere.material = mat
	p.draw_pass_1 = sphere
	add_child(p)
	_fireworks = p


func _launch_fireworks() -> void:
	if _fireworks == null:
		return
	var base := Vector3.ZERO
	if not _reactors.is_empty() and is_instance_valid(_reactors[0]):
		base = (_reactors[0] as Node3D).global_position
	for i in 3:
		var burst := _fireworks.duplicate()
		burst.global_position = base + Vector3(randf_range(-24.0, 24.0), 36.0 + randf_range(0.0, 24.0), randf_range(-24.0, 24.0))
		burst.emitting = true
		add_child(burst)
		burst.get_tree().create_timer(2.8).timeout.connect(func() -> void:
			if is_instance_valid(burst):
				burst.queue_free())


func _build_owl_wav() -> AudioStreamWAV:
	var rate := 22050.0
	var frames := int(rate * 1.1)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var notes := [[0.05, 0.42, 330.0], [0.47, 0.42, 275.0]]
	for i in frames:
		var t := float(i) / rate
		var v := 0.0
		for note: Array in notes:
			var n0: float = note[0]
			var nd: float = note[1]
			var nf: float = note[2]
			if t >= n0 and t <= n0 + nd:
				var u := (t - n0) / nd
				var env := minf(u / 0.08, 1.0) * minf((1.0 - u) / 0.12, 1.0)
				v += sin(TAU * nf * t) * env * 0.5
				v += sin(TAU * nf * 2.0 * t) * env * 0.12
		var sample := int(clampf(v, -1.0, 1.0) * 32767.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return wav


func _fill_owl_audio(delta: float) -> void:
	if _owl_audio == null:
		return
	var night := _is_night()
	_owl_audio.volume_db = lerpf(_owl_audio.volume_db, -12.0 if night else -60.0, delta * 2.0)
	if not night or _owl_audio.playing:
		return
	_owl_timer -= delta
	if _owl_timer <= 0.0:
		_owl_timer = randf_range(7.0, 18.0)
		if _owl_wav:
			_owl_audio.pitch_scale = randf_range(0.9, 1.1)
			_owl_audio.play()


func _build_thunder_wav() -> AudioStreamWAV:
	var frames := int(22050.0 * 2.6)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var lp := 0.0
	var lp2 := 0.0
	for i in frames:
		var s := randf() * 2.0 - 1.0
		lp = lerpf(lp, s, 0.1)
		lp2 = lerpf(lp2, lp, 0.02)
		var env := exp(-float(i) / float(frames) * 7.0) * (0.5 + 0.5 * randf())
		var v := clampf(lp2 * env * 0.95, -1.0, 1.0)
		var sample := int(v * 32767.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return wav


func _wind_mw() -> float:
	var wind := _wind_speed
	var eff := 1.0
	if wind < 0.55:
		eff = wind / 0.55
	else:
		eff = clampf(1.0 - (wind - 0.55) * 1.1, 0.15, 1.0)
	return float(_turbines.size()) * 110.0 * eff


func _total_supply() -> float:
	var s := 0.0
	for r in _reactors:
		if is_instance_valid(r):
			s += float(r.get("power01")) * 900.0
	s += _wind_mw()
	return s


func _make_charger(pos: Vector3, rng: RandomNumberGenerator) -> Node3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.95, 0.75)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.9, 0.6)
	mat.emission_energy_multiplier = 2.0
	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.18, 0.2, 0.24)
	pole_mat.roughness = 0.7
	var n := Node3D.new()
	n.name = "Charger"
	var pole := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.12, 1.1, 0.12)
	pole.mesh = pm
	pole.material_override = pole_mat
	n.add_child(pole)
	var head := MeshInstance3D.new()
	var hm := BoxMesh.new()
	hm.size = Vector3(0.34, 0.18, 0.22)
	head.mesh = hm
	head.position.y = 0.85
	head.material_override = mat
	n.add_child(head)
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.3, 1.0, 0.7)
	glow.light_energy = 1.6
	glow.omni_range = 6.0
	glow.shadow_enabled = false
	glow.position.y = 0.85
	n.add_child(glow)
	n.position = Vector3(pos.x, _height_at(pos.x, pos.z), pos.z)
	n.rotation_degrees = Vector3(0.0, rng.randf() * 360.0, 0.0)
	add_child(n)
	_chargers.append(n)
	return n


func _build_chargers() -> void:
	_chargers.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 55
	var houses := get_tree().get_nodes_in_group("houses")
	var spots: Array[Vector3] = []
	for house in houses:
		var h := house as Node3D
		var e: Vector3 = h.to_global(h.get_meta("entry_local"))
		spots.append(e + Vector3(0.0, 0.0, 2.2))
	for _i in 3:
		var pos := Vector3(rng.randf_range(-_half + 10.0, _half - 10.0), 0.0, rng.randf_range(-_half + 10.0, _half - 10.0))
		var h := _height_at(pos.x, pos.z)
		pos.y = h
		if h > 1.0 and h < 12.0:
			spots.append(pos)
	for s in spots:
		_make_charger(s, rng)


func _tick_chargers(delta: float) -> void:
	if _player == null or _chargers.is_empty():
		return
	var charged := false
	for c in _chargers:
		if c == null or not is_instance_valid(c):
			continue
		var d := _player.global_position.distance_to(c.global_position)
		if d < 2.4:
			var bat := float(_player.get("lamp_battery"))
			if bat < 1.0:
				_player.set("lamp_battery", minf(1.0, bat + delta * 0.25))
				charged = true
	if charged and not _charged_once:
		_charged_once = true
		_post_chat("System", "Charging station — flashlight battery restored.")


func _build_wind_farm() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 77
	var site := Vector3(260.0, _height_at(260.0, 0.0), 0.0)
	for tries in 300:
		var ang := rng.randf() * TAU
		var dist := rng.randf_range(380.0, 700.0)
		var x := cos(ang) * dist
		var z := sin(ang) * dist
		var h := _height_at(x, z)
		if h >= 8.0 and h <= 20.0 and _slope_at(x, z) < 0.3:
			site = Vector3(x, h, z)
			break
	var placed: Array[Vector3] = []
	for i in 5:
		var ok_pos := Vector3.ZERO
		for tries in 40:
			var off := Vector3(rng.randf_range(-70.0, 70.0), 0.0, rng.randf_range(-70.0, 70.0))
			var pos := site + off
			var spaced := true
			for p in placed:
				if p.distance_to(pos) < 55.0:
					spaced = false
					break
			if spaced:
				ok_pos = pos
				break
		if ok_pos == Vector3.ZERO:
			continue
		ok_pos.y = _height_at(ok_pos.x, ok_pos.z)
		placed.append(ok_pos)
		_build_turbine(ok_pos)


func _build_turbine(pos: Vector3) -> void:
	var node := Node3D.new()
	node.name = "WindTurbine"
	node.position = pos
	var tower_mat := StandardMaterial3D.new()
	tower_mat.albedo_color = Color(0.88, 0.88, 0.90)
	tower_mat.roughness = 0.7
	var tower_mesh := CylinderMesh.new()
	tower_mesh.bottom_radius = 0.42
	tower_mesh.top_radius = 0.16
	tower_mesh.height = 26.0
	tower_mesh.radial_segments = 8
	var tower := MeshInstance3D.new()
	tower.mesh = tower_mesh
	tower.material_override = tower_mat
	tower.position = Vector3(0.0, 13.0, 0.0)
	node.add_child(tower)
	var nacelle_mat := StandardMaterial3D.new()
	nacelle_mat.albedo_color = Color(0.75, 0.76, 0.80)
	nacelle_mat.roughness = 0.6
	var nacelle := MeshInstance3D.new()
	var nm := BoxMesh.new()
	nm.size = Vector3(2.4, 0.8, 0.9)
	nacelle.mesh = nm
	nacelle.material_override = nacelle_mat
	nacelle.position = Vector3(0.9, 26.0, 0.0)
	node.add_child(nacelle)
	var hub := Node3D.new()
	hub.position = Vector3(2.1, 26.0, 0.0)
	node.add_child(hub)
	var blade_mat := StandardMaterial3D.new()
	blade_mat.albedo_color = Color(0.94, 0.95, 0.97)
	blade_mat.roughness = 0.35
	for bi in 3:
		var blade := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.22, 0.28, 8.6)
		blade.mesh = bm
		blade.material_override = blade_mat
		var ang := TAU / 3.0 * bi
		blade.position = Vector3(0.0, cos(ang) * 4.3, sin(ang) * 4.3)
		blade.rotation.x = -ang
		hub.add_child(blade)
	var tip_mat := StandardMaterial3D.new()
	tip_mat.albedo_color = Color(1.0, 0.2, 0.15)
	tip_mat.emission_enabled = true
	tip_mat.emission = Color(1.0, 0.15, 0.1) * 0.8
	var tip := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(0.18, 0.18, 0.18)
	tip.mesh = tm
	tip.material_override = tip_mat
	tip.position = Vector3(2.1, 27.1, 0.0)
	node.add_child(tip)
	add_child(node)
	_turbines.append(node)
	_turbine_hubs.append(hub)


func _render_sky() -> void:
	var now := Time.get_ticks_msec()
	if now - _sky_tick < 150:
		return
	_sky_tick = now
	var elev := 60.0 * cos(TAU * (_time_of_day - 12.0) / 24.0)
	var k := clampf(sin(deg_to_rad(elev)) * 3.0 + 0.15, 0.0, 1.0)
	var night := 1.0 - k
	var rain := _rain_density
	if _sun:
		_sun.rotation_degrees = Vector3(-elev, -32.0, 0.0)
		_sun.light_energy = lerpf(0.03, 1.05, k) * (1.0 - rain * 0.4) + _flash_strength * 3.0
		_sun.light_color = _sun_col.lerp(Color(0.6, 0.7, 1.0), night)
	if _moon:
		var moon_elev := 60.0 * cos(TAU * _time_of_day / 24.0)
		_moon.rotation_degrees = Vector3(-moon_elev, 148.0, 0.0)
		var phase := fmod(float(int(floor(_time_of_day / 24.0)) + 1), 7.0)
		var full := absf(2.0 * (phase / 7.0) - 1.0)
		_moon.light_energy = lerpf(0.0, 0.3, night) * (1.0 - rain * 0.35) * (0.25 + full * 0.75)
	if _moon_disc:
		var night_on := night > 0.45
		if _moon_disc.visible != night_on:
			_moon_disc.visible = night_on
		if night_on:
			var moon_dir := (_moon.global_transform.basis * Vector3(0.0, 0.0, 1.0)).normalized()
			var cam: Camera3D = _moon_disc.get_parent() as Camera3D
			if cam:
				_moon_disc.global_position = cam.global_position + moon_dir * 2400.0
			var phase2 := fmod(float(int(floor(_time_of_day / 24.0)) + 1), 7.0)
			var full2 := absf(2.0 * (phase2 / 7.0) - 1.0)
			_moon_disc.scale = Vector3.ONE * (0.5 + full2 * 0.8)
			if _moon_mat:
				_moon_mat.emission_energy_multiplier = 0.35 + full2 * 1.1
	if _stars:
		var stars_on := night > 0.3
		if _stars.visible != stars_on:
			_stars.visible = stars_on
			_stars.emitting = stars_on
	if _sky_mat:
		var top := _sky_top_day.lerp(NIGHT_TOP, night)
		var horiz := _sky_horizon_day.lerp(NIGHT_HORIZON, night)
		var gbot := _sky_ground_day.lerp(NIGHT_GROUND, night)
		var ghor := _sky_ground_horizon_day.lerp(NIGHT_GROUND_H, night)
		_sky_mat.sky_top_color = top.lerp(Color(0.36, 0.40, 0.46), rain * 0.7)
		_sky_mat.sky_horizon_color = horiz.lerp(Color(0.42, 0.46, 0.52), rain * 0.8)
		_sky_mat.ground_bottom_color = gbot.lerp(Color(0.24, 0.26, 0.30), rain * 0.7)
		_sky_mat.ground_horizon_color = ghor.lerp(Color(0.30, 0.33, 0.38), rain * 0.8)
		_sky_mat.energy_multiplier = lerpf(0.85, 0.28, night) * (1.0 - rain * 0.25)
	if _env:
		_env.ambient_light_energy = lerpf(0.42, 0.07, night) * (1.0 - rain * 0.3)
		var tod := fmod(_time_of_day, 24.0)
		var mist := maxf(exp(-pow((tod - 7.0) / 2.2, 2.0)), exp(-pow((tod - 19.0) / 2.2, 2.0)))
		var blz := 1.0 if _is_blizzard() else 0.0
		_env.volumetric_fog_emission_energy = lerpf(0.16, 0.5, rain) + mist * 0.3 + blz * 0.9
		_env.volumetric_fog_density = (0.0055 + rain * 0.02) * (1.0 + mist * 2.2) * (1.0 + blz * 6.0)
	if _clouds_mat and _sun:
		var sun_dir := (_sun.global_transform.basis * Vector3(0.0, 0.0, 1.0)).normalized()
		_clouds_mat.set_shader_parameter("sun_dir", sun_dir)
		_clouds_mat.set_shader_parameter("night", night)
	if _water_mat:
		var sd := (_sun.global_transform.basis * Vector3(0.0, 0.0, 1.0)).normalized() if _sun else Vector3(0.3, 0.9, 0.1)
		_water_mat.set_shader_parameter("sun_dir", sd)
		_water_mat.set_shader_parameter("night", night)
	_hud_clock_color(k)


func _hud_clock_color(k: float) -> void:
	if _hud_clock:
		var tod := fmod(_time_of_day, 24.0)
		_hud_clock.text = "%02d:%02d" % [int(floor(tod)), int(floor(fmod(tod, 1.0) * 60.0))]
		_hud_clock.add_theme_color_override("font_color",
			Color(1.0, 1.0, 1.0, 0.85) if k > 0.45 else Color(0.85, 0.87, 1.0, 0.85))


func _update_hud(delta: float) -> void:
	_update_tasks(delta)
	if _hud_clock:
		var tod := fmod(_time_of_day, 24.0)
		_hud_clock.text = "%02d:%02d" % [int(floor(tod)), int(floor(fmod(tod, 1.0) * 60.0))]
	if _player and _hud_ammo:
		if _player.has_gun:
			_hud_ammo.text = "AMMO %02d/%02d   RESERVE %d" % [_player.ammo, _player.max_ammo, _player.reserve_ammo]
		else:
			_hud_ammo.text = "FISTS — punch an armed NPC (LMB)"
	var show: bool = false
	if _player and _crosshair:
		show = bool(_player.has_gun) and not bool(_player.get("in_car")) \
			and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	for part in _crosshair:
		part.visible = show
	if _hud_day:
		_hud_day.text = "DAY %d" % (int(floor(_time_of_day / 24.0)) + 1)
	if _tornado_warn:
		var tw := _nearest_tornado()
		if tw != null and _player:
			var dp := tw.global_position - _player.global_position
			var dist := int(dp.length())
			if dist < 300:
				var ang := rad_to_deg(atan2(dp.x, -dp.z))
				var dirs := ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
				var di := int(round(wrapf(ang, 0.0, 360.0) / 45.0)) % 8
				_tornado_warn.text = "TORNADO  %dm %s  — TAKE COVER" % [dist, dirs[di]]
				_tornado_warn.visible = true
			else:
				_tornado_warn.visible = false
		else:
			_tornado_warn.visible = false
	if _turbo_bar and _turbo_label:
		var in_car := _player != null and bool(_player.get("in_car")) \
			and not bool(_player.get("in_boat"))
		_turbo_bar.visible = in_car
		_turbo_label.visible = in_car
		if in_car:
			var cid: int = int(_player.get("in_car_id"))
			var boost_val := 0.0
			if cid >= 1000:
				var bidx := cid - 1000
				if bidx >= 0 and bidx < _bikes_list.size():
					var bk: Node3D = _bikes_list[bidx]
					if is_instance_valid(bk):
						boost_val = float(bk.get("boost"))
			elif cid >= 0 and cid < _cars_list.size():
				var car: Node3D = _cars_list[cid]
				if is_instance_valid(car):
					boost_val = float(car.get("boost"))
			_turbo_bar.value = clampf(boost_val, 0.0, 1.0) * 100.0
			_turbo_bar.add_theme_stylebox_override("fill", _boost_style(boost_val))
	if _hurt_flash and _hurt_flash.color.a > 0.0:
		var c: Color = _hurt_flash.color
		_hurt_flash.color = Color(c.r, c.g, c.b, maxf(0.0, c.a - delta * 1.5))
	if _phone_widget_body:
		var names := ["CLEAR", "CLOUDY", "RAIN", "STORM"]
		var bat := int(_phone_battery * 100.0)
		var g: Array = grid_demand() if has_method("grid_demand") else [0.0, 0.0, "OFFLINE", false]
		var st := str(g[2])
		if bool(g[3]):
			st = "BLACKOUT"
		var accent := Color(0.6, 0.9, 0.6)
		var ratio := float(g[1]) / float(g[0]) if float(g[0]) > 0.0 else 0.0
		if bool(g[3]):
			accent = Color(1.0, 0.35, 0.3)
		elif ratio < 0.85:
			accent = Color(1.0, 0.7, 0.3)
		_phone_widget_body.text = "PHONE  [P]   %02d:%02d   BAT %d%%\n%s   WIND %d%%   GRID %s" % [
			int(floor(fmod(_time_of_day, 24.0))), int(floor(fmod(fmod(_time_of_day, 24.0), 1.0) * 60.0)),
			bat, names[_weather], int(_wind_speed * 100.0), st]
		if accent != _phone_accent:
			_phone_accent = accent
			var sb: StyleBoxFlat = (_phone_widget.get_theme_stylebox("normal") as StyleBoxFlat).duplicate()
			sb.border_color = accent
			_phone_widget.add_theme_stylebox_override("normal", sb)
			var sbh: StyleBoxFlat = (_phone_widget.get_theme_stylebox("hover") as StyleBoxFlat).duplicate()
			sbh.border_color = accent.lightened(0.2)
			_phone_widget.add_theme_stylebox_override("hover", sbh)
	if _player and _lamp_battery_label:
		var lb := float(_player.get("lamp_battery"))
		var lamp_on: bool = bool(_player.get("_lamp_on"))
		var lcol := Color(0.55, 0.95, 1.0)
		if lb <= 0.0:
			lcol = Color(1.0, 0.35, 0.3)
		elif lb < 0.25:
			lcol = Color(1.0, 0.7, 0.3)
		_lamp_battery_label.text = "LAMP %s  %d%%" % ["ON" if lamp_on else "OFF", int(lb * 100.0)]
		_lamp_battery_label.add_theme_color_override("font_color", lcol)

func _physics_process(delta: float) -> void:
	if _launcher_mode or _shot or _walk or _drive or _ztest or _sanity:
		return
	if _server:
		return
	_tick_radiation_overlay(delta)
	_tick_phone_battery(delta)
	_update_interaction()

func _tick_phone_battery(delta: float) -> void:
	var was := _phone_battery
	if _phone_open:
		_phone_battery = maxf(0.0, _phone_battery - delta / 300.0)
	else:
		_phone_battery = minf(1.0, _phone_battery + delta / 2400.0)
	if was > 0.2 and _phone_battery <= 0.2:
		_phone_batt_warned = true
		_post_chat("Phone", "Low battery (20%). Put the phone away to charge.")
	if was > 0.0 and _phone_battery <= 0.0:
		_phone_battery = 0.0
		_post_chat("Phone", "Battery dead — phone switched off.")
		if _phone and _phone.has_method("close"):
			_phone.call("close")

func _update_interaction() -> void:
	if _reactor_panel_open or _phone_open:
		_current_target = null
		return
	if _player == null or bool(_player.get("in_car")):
		_current_target = null
		return
	var target: Node3D = null
	var cam := _player.get_node_or_null("CameraRig/Camera") as Camera3D
	if cam:
		var from := cam.global_position
		var dir := -cam.global_transform.basis.z
		var q := PhysicsRayQueryParameters3D.create(from, from + dir * 3.0, 1 | 2)
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		if hit and hit.collider is Node3D:
			var collider := hit.collider as Node3D
			if collider.collision_layer & 2:
				target = collider
	if target != _current_target:
		_current_target = target
	if _hud_prompt:
		_hud_prompt.text = ""
		if target:
			if "interact_hint" in target:
				var hint = target.get("interact_hint")
				if hint is String:
					_hud_prompt.text = hint

func _build_phone() -> void:
	var phone := preload("res://scripts/phone.gd").new()
	phone.world = self
	phone.name = "Phone"
	add_child(phone)
	_phone = phone
	if _phone_widget:
		_phone_widget.pressed.connect(func() -> void: phone.open())
	if _news_log.is_empty():
		_news_log.append({"t": "00:00", "m": "Welcome to Pico Peaks. The power plant needs a manager."})
		_news_log.append({"t": "00:00", "m": "Head for the blinking red beacon to find the nuclear plant."})
		_news_log.append({"t": "00:00", "m": "Tip: villages go dark when plant output falls short."})


func set_reactor_panel_open(open: bool) -> void:
	_reactor_panel_open = open

func _tick_radiation_overlay(delta: float) -> void:
	var target := 0.0
	if _player:
		var ppos := _player.global_position
		for r in _reactors:
			if r == null or not is_instance_valid(r) or not bool(r.get("exploded")):
				continue
			var d := ppos.distance_to((r as Node3D).global_position)
			if d < 260.0:
				target = maxf(target, 1.0 - d / 260.0)
		if bool(_player.get("hazmat")):
			target *= 0.5
	_rad_overlay_alpha = move_toward(_rad_overlay_alpha, target * 0.45, delta * 0.5)
	if _rad_overlay:
		_rad_overlay.color = Color(0.45, 1.0, 0.3, _rad_overlay_alpha)
	if _hud_rad:
		_hud_rad.text = "RAD %d%%" % int(round(_rad_overlay_alpha / 0.45 * 100.0))

func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if _game_over:
		return
	if _gazette_layer != null and is_instance_valid(_gazette_layer):
		if event.is_action_pressed("interact") or event.is_action_pressed("phone") \
				or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
			_close_gazette()
			get_viewport().set_input_as_handled()
			return
	if _reactor_panel_open:
		return
	if _phone_open:
		if event.is_action_pressed("phone") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
			if _phone and _phone.has_method("close"):
				_phone.call("close")
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("phone"):
		if _phone and _phone.has_method("open"):
			_phone.call("open")
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("radio_toggle"):
		if _player and (bool(_player.get("in_car")) or bool(_player.get("in_boat"))):
			_radio_muted = not _radio_muted
			_post_chat("Radio", "FM 98.7 — station muted." if _radio_muted else "FM 98.7 — back on air.")
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("fish"):
		if _player and bool(_player.get("in_boat")):
			_try_boat_fish()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact"):
		_do_interact()
		get_viewport().set_input_as_handled()

func _do_interact() -> void:
	if _player and _client and (bool(_player.get("in_car")) or bool(_player.get("in_boat"))):
		_net_exit_current_vehicle()
		return
	if _current_target:
		if _client and _world_ready:
			_net_interact(_current_target)
		elif _current_target.has_method("interact"):
			_current_target.interact()
		elif _current_target.has_method("say_line") and _chat_box:
			_chat_box.post_line(_current_target.display_name(), _current_target.random_line())
	elif _player != null and not bool(_player.get("in_car")) and not bool(_player.get("in_boat")) and _near_dock():
		_try_fish()


func _touch_action(act: String) -> void:
	if get_tree().paused:
		return
	match act:
		"interact":
			_do_interact()
		"phone":
			if _phone_open:
				if _phone and _phone.has_method("close"):
					_phone.call("close")
					get_viewport().set_input_as_handled()
			else:
				if _phone and _phone.has_method("open"):
					_phone.call("open")
					get_viewport().set_input_as_handled()
		_:
			Input.action_press(act)

func _is_night() -> bool:
	var tod := fmod(_time_of_day, 24.0)
	return tod >= 18.0 or tod < 6.0

func sleep_in_bed() -> void:
	if _sleeping:
		return
	if not _is_night():
		_post_chat("System", "You can only sleep at night.")
		return
	_sleeping = true
	_run_sleep()

func _run_sleep() -> void:
	if _player:
		_player.set("_freeze", true)
	_sleep_zzz.visible = true
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_sleep_fade, "color:a", 1.0, 0.6)
	tw.tween_property(_sleep_zzz, "modulate:a", 1.0, 0.6)
	tw.tween_property(_sleep_zzz, "position:y", _sleep_zzz.position.y - 40.0, 0.6)
	await tw.finished
	_time_of_day = (floor(_time_of_day / 24.0) + 1.0) * 24.0 + 6.0
	_complete_task("sleep", "Slept through the night")
	_post_chat("System", "You slept through the night until 06:00.")
	await get_tree().create_timer(1.2).timeout
	var tw2 := create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(_sleep_fade, "color:a", 0.0, 0.6)
	tw2.tween_property(_sleep_zzz, "modulate:a", 0.0, 0.6)
	await tw2.finished
	_sleep_zzz.visible = false
	if _player:
		_player.set("_freeze", false)
	_sleeping = false

func _complete_task(key: String, msg: String) -> void:
	if _tasks[key]:
		return
	_tasks[key] = true
	_task_count += 1
	_alert("System", "TASK COMPLETE: %s (%d/%d)" % [msg, _task_count, _tasks.size()])
	if _task_count >= _tasks.size():
		_alert("System", "ALL TASKS COMPLETE — Pico Peaks is thriving! Look up at dawn.")
		_launch_fireworks()
		_task_count = 0


func _update_tasks(_delta: float) -> void:
	if _player == null or _player.is_queued_for_deletion():
		return
	if not _tasks["reach_plant"]:
		for r in _reactors:
			if r != null and is_instance_valid(r):
				var d := _player.global_position.distance_to((r as Node3D).global_position)
				if d < 90.0:
					_complete_task("reach_plant", "Reached the nuclear plant")
					break
	if not _tasks["grid_powered"]:
		if not _grid_blackout and _grid_status in ["SATISFIED", "SURPLUS"]:
			_complete_task("grid_powered", "Power grid balanced")
	if not _tasks["cool"]:
		var all_cool := true
		for r in _reactors:
			if r != null and is_instance_valid(r) and not bool(r.get("exploded")):
				if float(r.get("temp")) >= 860.0:
					all_cool = false
					break
		if all_cool and not _reactors.is_empty():
			_complete_task("cool", "All reactors under 860 C")
	if _weather >= 3:
		_in_storm = true
	elif _in_storm:
		_in_storm = false
		_complete_task("storm", "Survived a thunderstorm")
	if not _tasks["car"]:
		if bool(_player.get("in_car")) and not bool(_player.get("in_boat")):
			_complete_task("car", "Drove a car")
	if not _tasks["boat"]:
		if bool(_player.get("in_boat")):
			_complete_task("boat", "Rowed out on the lake")
	if not _tasks["spring"]:
		if _hot_spring != null and is_instance_valid(_hot_spring):
			var dspring := Vector2(_player.global_position.x, _player.global_position.z).distance_to(
				Vector2(_hot_spring.global_position.x, _hot_spring.global_position.z))
			if dspring < 6.0:
				_complete_task("spring", "Relaxed in the hot spring")
	if not _tasks["garden"]:
		for grp in _gardens:
			if grp == null or not is_instance_valid(grp):
				continue
			var offset_h := float(grp.get_meta("offset_h"))
			if int(floor((_time_of_day + offset_h) / 24.0)) >= _garden_ripe_days():
				_complete_task("garden", "Watched the gardens ripen")
				break
	for r in _reactors:
		if r == null or not is_instance_valid(r):
			continue
		var idx := int(r.get("plant_idx"))
		var t := int(r.get("reactor_type"))
		if _prev_reactor_types.has(idx) and int(_prev_reactor_types[idx]) != t:
			_complete_task("upgrade", "Upgraded a reactor")
		_prev_reactor_types[idx] = t
		if not _tasks["refuel"]:
			var fuel := float(r.get("fuel"))
			if _prev_fuels.has(idx) and fuel > 0.95 and float(_prev_fuels[idx]) < 0.6:
				_complete_task("refuel", "Refueled a reactor")
			_prev_fuels[idx] = fuel
	if not _tasks["bike"]:
		if bool(_player.get("in_car")) and not bool(_player.get("in_boat")):
			for b in _bikes_list:
				if is_instance_valid(b) and Vector2(_player.global_position.x, _player.global_position.z).distance_to(Vector2(b.global_position.x, b.global_position.z)) < 3.0:
					_complete_task("bike", "Rode a dirt bike")
					break
	if not _tasks["bunker"]:
		for b in get_tree().get_nodes_in_group("bunkers"):
			if Vector2(_player.global_position.x, _player.global_position.z).distance_to(Vector2((b as Node3D).global_position.x, (b as Node3D).global_position.z)) < 8.0:
				_complete_task("bunker", "Found the hidden bunker")
				break


func _post_chat(from: String, text: String) -> void:
	if _chat_box:
		_chat_box.post_line(from, text)
	if (from == "System" or from == "ALARM") and not text.begins_with("You "):
		var tod := fmod(_time_of_day, 24.0)
		_news_log.append({"t": "%02d:%02d" % [int(floor(tod)), int(floor(fmod(tod, 1.0) * 60.0))], "m": text})
		if _news_log.size() > 60:
			_news_log.pop_front()


func _alert(from: String, text: String) -> void:
	if _server and not multiplayer.get_peers().is_empty():
		_broadcast_chat(from, text)
	else:
		_post_chat(from, text)

func _on_chat_sent(text: String) -> void:
	if _client:
		_sv_chat_msg.rpc_id(1, text)
		return
	if text.begins_with("/"):
		var resp := _run_command(text)
		if not resp.is_empty():
			_post_chat("System", resp)
		return
	if _chat_box:
		_chat_box.post_line("You", text)
		var npc := _nearest_npc(10.0)
		if npc:
			_chat_box.post_line(npc.display_name(), npc.random_line())

func _nearest_npc(radius: float) -> CharacterBody3D:
	var best: CharacterBody3D = null
	var best_d := radius
	for npc in get_tree().get_nodes_in_group("npc"):
		var d: float = _player.global_position.distance_to((npc as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = npc
	return best

# ---------------------------------------------------------------- network

func _ai_target(npc_node: Node3D) -> Node3D:
	if Net.is_server():
		var best: Node3D = null
		var best_d := INF
		for id in _net_players:
			var p: Node3D = _net_players[id]
			if not is_instance_valid(p) or float(p.get("health")) <= 0.0:
				continue
			var d: float = npc_node.global_position.distance_to(p.global_position)
			if d < best_d:
				best_d = d
				best = p
		return best
	return _player


func _on_peer_connected(id: int) -> void:
	if Net.is_server():
		_spawn_server_player(id)
		_sv_handshake.rpc_id(id, _world_seed, _ram_mb, _season, _time_of_day,
			_spawn_pos.x, _spawn_pos.y, _spawn_pos.z, _server_name, _player_names)
	else:
		_spawn_remote_body(id)


func _on_peer_disconnected(id: int) -> void:
	_player_names.erase(id)
	if Net.is_server():
		var p: Node3D = _net_players.get(id)
		if p:
			p.queue_free()
		_net_players.erase(id)
		_broadcast_chat("System", "A player left the game.")
	else:
		var r: Node3D = _remote_bodies.get(id)
		if r:
			r.queue_free()
		_remote_bodies.erase(id)


func _on_client_connected() -> void:
	print("[net] connected to server (peer id %d)" % Net.my_id())


func _spawn_server_player(id: int) -> CharacterBody3D:
	var p := CharacterBody3D.new()
	p.name = "NetPlayer%d" % id
	p.set_meta("is_player", true)
	p.set_meta("net_peer", id)
	p.script = preload("res://scripts/player.gd")
	p.set("world", self)
	p.set("net_controlled", true)
	p.position = _spawn_pos
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.7
	col.shape = cap
	col.position.y = 0.85
	p.add_child(col)
	var arm := SpringArm3D.new()
	arm.name = "CameraRig"
	arm.position = Vector3(0.0, 1.62, 0.0)
	arm.spring_length = 0.0
	arm.collision_mask = 1
	p.add_child(arm)
	var cam := Camera3D.new()
	cam.name = "Camera"
	cam.fov = 80.0
	cam.near = 0.05
	cam.far = 3200.0
	cam.current = false
	arm.add_child(cam)
	var lamp := SpotLight3D.new()
	lamp.name = "Headlamp"
	lamp.light_color = Color(1.0, 0.95, 0.82)
	lamp.light_energy = 2.8
	lamp.spot_range = 36.0
	lamp.spot_angle = 30.0
	cam.add_child(lamp)
	var body_mesh := MeshInstance3D.new()
	body_mesh.name = "Body"
	var cm := CapsuleMesh.new()
	cm.radius = 0.32
	cm.height = 1.6
	body_mesh.mesh = cm
	var bm := StandardMaterial3D.new()
	bm.albedo_color = Color(0.2, 0.25, 0.3)
	bm.roughness = 0.7
	body_mesh.material_override = bm
	body_mesh.position.y = 0.8
	p.add_child(body_mesh)
	p.died.connect(func() -> void:
		p.call("respawn", _spawn_pos)
		_broadcast_chat("System", "Player was killed and respawned."))
	add_child(p)
	_net_players[id] = p
	return p


func _spawn_remote_body(id: int) -> Node3D:
	var r := Node3D.new()
	r.name = "Remote%d" % id
	r.set_meta("remote_id", id)
	var body_mesh := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.32
	cm.height = 1.6
	body_mesh.mesh = cm
	var bm := StandardMaterial3D.new()
	bm.albedo_color = Color(0.30, 0.52, 0.78)
	bm.roughness = 0.7
	body_mesh.material_override = bm
	body_mesh.position.y = 0.8
	r.add_child(body_mesh)
	var label := Label3D.new()
	label.name = "Name"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.outline_modulate = Color(0, 0, 0, 0.8)
	label.outline_size = 8
	label.pixel_size = 0.005
	label.font_size = 40
	label.position = Vector3(0.0, 2.35, 0.0)
	r.add_child(label)
	if _player_names.has(id):
		label.text = String(_player_names[id])
	add_child(r)
	_remote_bodies[id] = r
	return r


func _pickup_type(pk: Node3D) -> int:
	if pk.has_meta("is_med"):
		return 3
	if pk.has_meta("is_hazmat"):
		return 2
	if pk.has_meta("is_gun"):
		return 1
	return 0


func _broadcast_state() -> void:
	if multiplayer.get_peers().is_empty():
		return
	var players: Array = []
	for id in _net_players:
		var p: Node3D = _net_players[id]
		if not is_instance_valid(p):
			continue
		var pp := p.global_position
		var pry := p.rotation.y
		if bool(p.get("in_car")):
			if bool(p.get("in_boat")) and _boat != null and is_instance_valid(_boat):
				pp = _boat.global_position
				pry = _boat.rotation.y
			else:
				var cid: int = int(p.get("in_car_id"))
				if cid >= 0 and cid < _cars_list.size() and is_instance_valid(_cars_list[cid]):
					var cc: Node3D = _cars_list[cid]
					pp = cc.global_position
					pry = cc.rotation.y
		players.append([id, pp.x, pp.y, pp.z, pry,
			float(p.get("health")), bool(p.get("has_gun")),
			bool(p.get("in_car")), int(p.get("ammo")), bool(p.get("hazmat"))])
	var npcs: Array = []
	for i in range(_npc_list.size()):
		var n: Node3D = _npc_list[i]
		if not is_instance_valid(n):
			npcs.append([i, 0.0, -999.0, 0.0, 0.0, 0.0, true])
			continue
		npcs.append([i, n.global_position.x, n.global_position.y, n.global_position.z,
			n.rotation.y, int(n.get("hp")), bool(n.get("_dead"))])
	var zombies: Array = []
	for z in get_tree().get_nodes_in_group("zombies"):
		var zn := z as Node3D
		zombies.append([int(zn.get_meta("net_id")), zn.global_position.x, zn.global_position.y,
			zn.global_position.z, zn.rotation.y, int(zn.get("_hp"))])
	var cars: Array = []
	for i in range(_cars_list.size()):
		var c: Node3D = _cars_list[i]
		if not is_instance_valid(c):
			continue
		cars.append([i, c.global_position.x, c.global_position.y, c.global_position.z,
			c.rotation.y, float(c.get("_speed"))])
	for b in _bikes_list:
		var bd := b as Node3D
		if not is_instance_valid(bd):
			continue
		var bid: int = int(bd.get_meta("car_id", -1))
		if bid < 0:
			continue
		cars.append([bid, bd.global_position.x, bd.global_position.y, bd.global_position.z,
			bd.rotation.y, float(bd.get("_speed"))])
	var pickups: Array = []
	for pid in _pickups:
		var pk: Node3D = _pickups[pid]
		if not is_instance_valid(pk):
			continue
		pickups.append([pid, _pickup_type(pk),
			pk.global_position.x, pk.global_position.y, pk.global_position.z])
	var reactors: Array = []
	for r in _reactors:
		if is_instance_valid(r):
			reactors.append(r.state_row())
	var boats: Array = []
	if _boat != null and is_instance_valid(_boat):
		boats = [_boat.global_position.x, _boat.global_position.y, _boat.global_position.z, _boat.rotation.y, float(_boat.get("_speed"))]
	var tornadoes: Array = []
	for tn in _tornadoes:
		if is_instance_valid(tn):
			tornadoes.append([tn.global_position.x, tn.global_position.y, tn.global_position.z])
	rpc("_sv_state", _time_of_day, players, npcs, zombies, cars, pickups, reactors, _weather, _wind_speed, boats, tornadoes)


@rpc("authority", "call_remote", "reliable")
func _sv_state(time: float, players: Array, npcs: Array, zombies: Array, cars: Array, pickups: Array, reactors: Array, weather: int, wind: float, boats: Array = [], tornadoes: Array = []) -> void:
	if not _client or not _world_ready:
		return
	_time_of_day = time
	_weather = clampi(weather, 0, 3)
	_wind_speed = clampf(wind, 0.0, 1.0)
	_apply_tornado_states(tornadoes)
	for row in players:
		var pid := int(row[0])
		var pos := Vector3(row[1], row[2], row[3])
		var ry := float(row[4])
		var hp := float(row[5])
		var has_gun := bool(row[6])
		var in_car := bool(row[7])
		var ammo := int(row[8])
		var hazmat := bool(row[9])
		if pid == Net.my_id():
			_net_target_pos = pos
			if _player:
				var was_in_car := bool(_player.get("in_car"))
				_player.set("health", hp)
				_player.set("has_gun", has_gun)
				_player.set("in_car", in_car)
				_player.set("ammo", ammo)
				_player.set("hazmat", hazmat)
				if was_in_car and not in_car:
					_restore_player_camera()
				if bool(_player.get("in_car")) and not is_instance_valid(_player.get("_gun")) and has_gun:
					_player.call("arm_gun")
		else:
			_apply_remote_player(pid, pos, ry, hp, has_gun, hazmat)
	_apply_npc_states(npcs)
	_apply_zombie_states(zombies)
	_apply_car_states(cars)
	_apply_pickup_states(pickups)
	_apply_reactor_states(reactors)
	_apply_boat_state(boats)


func _apply_client_state(delta: float) -> void:
	if _player:
		var p := _player as CharacterBody3D
		var t := p.global_position
		t = t.lerp(_net_target_pos, clampf(delta * 12.0, 0.0, 1.0))
		p.global_position = t
	for id in _remote_bodies:
		var r: Node3D = _remote_bodies[id]
		if r.has_meta("net_target"):
			var cur := r.global_position
			r.global_position = cur.lerp(r.get_meta("net_target"), clampf(delta * 12.0, 0.0, 1.0))
			r.rotation.y = lerp_angle(r.rotation.y, float(r.get_meta("net_rot")), clampf(delta * 12.0, 0.0, 1.0))


func _apply_remote_player(pid: int, pos: Vector3, ry: float, hp: float, has_gun: bool, hazmat: bool) -> void:
	var r: Node3D = _remote_bodies.get(pid)
	if not r:
		_spawn_remote_body(pid)
		r = _remote_bodies.get(pid)
	if not r:
		return
	r.set_meta("net_target", pos)
	r.set_meta("net_rot", ry)
	r.set("hazmat", hazmat)


func _apply_npc_states(npcs: Array) -> void:
	for row in npcs:
		var i := int(row[0])
		if i < 0 or i >= _npc_list.size():
			continue
		var n: Node3D = _npc_list[i]
		if not is_instance_valid(n):
			continue
		var dead := bool(row[6])
		if dead and not bool(n.get("_dead")):
			n.call("_die")
			continue
		n.set_meta("net_target", Vector3(row[1], row[2], row[3]))
		n.set_meta("net_rot", float(row[4]))
		var old_hp := int(n.get("hp"))
		n.set("hp", int(row[5]))
		if int(row[5]) < old_hp:
			n.set("_flash", 0.12)


func _apply_zombie_states(zombies: Array) -> void:
	var seen: Dictionary = {}
	for row in zombies:
		var zid := int(row[0])
		seen[zid] = true
		var node: Node3D = _zombie_nodes.get(zid)
		if not node or not is_instance_valid(node):
			node = _make_client_zombie(zid)
			_zombie_nodes[zid] = node
		if not node:
			continue
		node.set_meta("net_target", Vector3(row[1], row[2], row[3]))
		node.set_meta("net_rot", float(row[4]))
		node.set("_hp", int(row[5]))
	for zid in _zombie_nodes.keys():
		if not seen.has(zid):
			var z: Node3D = _zombie_nodes[zid]
			if is_instance_valid(z):
				z.queue_free()
			_zombie_nodes.erase(zid)


func _vehicle_by_cid(cid: int) -> Node3D:
	if cid >= 1000:
		var bidx := cid - 1000
		if bidx >= 0 and bidx < _bikes_list.size():
			return _bikes_list[bidx] as Node3D
		return null
	if cid >= 0 and cid < _cars_list.size():
		return _cars_list[cid] as Node3D
	return null


func _apply_car_states(cars: Array) -> void:
	for row in cars:
		var c := _vehicle_by_cid(int(row[0]))
		if c == null or not is_instance_valid(c):
			continue
		c.set_meta("net_target", Vector3(row[1], row[2], row[3]))
		c.set_meta("net_rot", float(row[4]))


func _apply_boat_state(boat: Array) -> void:
	if _boat == null or not is_instance_valid(_boat) or boat.size() < 4:
		return
	_boat.set_meta("net_target", Vector3(boat[0], boat[1], boat[2]))
	_boat.set_meta("net_rot", float(boat[3]))
	_boat.set("_speed", float(boat[4]) if boat.size() > 4 else 0.0)


func _apply_pickup_states(pickups: Array) -> void:
	var seen: Dictionary = {}
	for row in pickups:
		var pid := int(row[0])
		seen[pid] = true
		var node: Node3D = _pickup_nodes.get(pid)
		if not node or not is_instance_valid(node):
			node = _make_client_pickup(pid, int(row[1]), Vector3(row[2], row[3], row[4]))
			_pickup_nodes[pid] = node
	for pid in _pickup_nodes.keys():
		if not seen.has(pid):
			var node: Node3D = _pickup_nodes[pid]
			if is_instance_valid(node):
				node.queue_free()
			_pickup_nodes.erase(pid)


func _apply_reactor_states(reactors: Array) -> void:
	for row in reactors:
		var idx := int(row[0])
		if idx >= _reactors.size():
			continue
		var r: Node3D = _reactors[idx]
		if is_instance_valid(r) and r.has_method("apply_state"):
			r.call("apply_state", row)


@rpc("authority", "call_remote", "reliable")
func _sv_reactor_control(idx: int, rods: float, pump: bool, scram: bool) -> void:
	if not _world_ready:
		return
	if idx < 0 or idx >= _reactors.size():
		return
	var r: Node3D = _reactors[idx]
	if is_instance_valid(r) and r.has_method("set_control"):
		r.call("set_control", rods, pump, scram)


@rpc("authority", "call_remote", "reliable")
func _sv_reactor_action(idx: int, action: String, value: bool) -> void:
	if not _world_ready:
		return
	if idx < 0 or idx >= _reactors.size():
		return
	var r: Node3D = _reactors[idx]
	if is_instance_valid(r) and r.has_method("set_action"):
		r.call("set_action", action, value)


func _make_client_zombie(zid: int) -> Node3D:
	var z := CharacterBody3D.new()
	z.name = "NetZombie%d" % zid
	z.set_script(preload("res://scripts/zombie.gd"))
	z.set("world", self)
	z.set("net_slave", true)
	z.set_meta("net_id", zid)
	add_child(z)
	z.position = Vector3(0.0, -50.0, 0.0)
	return z


func _make_client_pickup(pid: int, type: int, pos: Vector3) -> Node3D:
	var pk := StaticBody3D.new()
	pk.name = "NetPickup%d" % pid
	pk.collision_layer = 2
	pk.collision_mask = 0
	pk.set_meta("is_pickup", true)
	pk.set_meta("pickup_id", pid)
	pk.set_meta("is_med", type == 3)
	pk.set_meta("is_gun", type == 1)
	pk.set_meta("is_hazmat", type == 2)
	if type == 3:
		pk.set("interact_hint", "[E] Pick up medkit")
	elif type == 2:
		pk.set("interact_hint", "[E] Take hazmat suit")
	elif type == 1:
		pk.set("interact_hint", "[E] Pick up gun")
	else:
		pk.set("interact_hint", "[E] Pick up ammo")
	var body_mat := StandardMaterial3D.new()
	if type == 3:
		body_mat.albedo_color = Color(0.9, 0.32, 0.32)
	elif type == 2:
		body_mat.albedo_color = Color(0.85, 0.65, 0.15)
	elif type == 1:
		body_mat.albedo_color = Color(0.13, 0.13, 0.15)
	else:
		body_mat.albedo_color = Color(0.72, 0.55, 0.22)
	body_mat.roughness = 0.6
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	if type == 3:
		bm.size = Vector3(0.3, 0.18, 0.2)
	elif type == 2:
		bm.size = Vector3(0.42, 0.42, 0.2)
	elif type == 1:
		bm.size = Vector3(0.06, 0.12, 0.5)
	else:
		bm.size = Vector3(0.3, 0.13, 0.2)
	body.mesh = bm
	body.material_override = body_mat
	pk.add_child(body)
	var glow_mat := StandardMaterial3D.new()
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow_mat.albedo_color = Color(1.0, 0.85, 0.4, 0.5)
	var glow := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(0.3, 0.3, 0.3)
	glow.mesh = gm
	glow.material_override = glow_mat
	glow.position = Vector3(0.0, 0.25, 0.0)
	pk.add_child(glow)
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.5, 0.25, 0.5)
	col.shape = bs
	pk.add_child(col)
	pk.position = pos
	add_child(pk)
	return pk


@rpc("any_peer", "call_local", "reliable")
func _sv_handshake(seed: int, ram: int, season: String, time: float,
		sx: float, sy: float, sz: float, sname: String, names: Dictionary) -> void:
	if not _client:
		return
	_world_seed = seed
	_ram_mb = ram
	_mem_scale_cached = -1.0
	_season = season
	_time_of_day = time
	_spawn_pos = Vector3(sx, sy, sz)
	_server_name = sname
	_player_names = names
	_world_ready = true
	print("[net] handshake seed=%d season=%s time=%.1f spawn=%s" % [_world_seed, _season, _time_of_day, _spawn_pos])


@rpc("any_peer", "call_remote", "reliable")
func _sv_hello(name: String) -> void:
	if not Net.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	_player_names[id] = name
	rpc("_sv_player_join", id, name)
	_broadcast_chat("System", "%s joined the game." % name)


@rpc("authority", "call_remote", "reliable")
func _sv_player_join(id: int, name: String) -> void:
	_player_names[id] = name
	if id == Net.my_id():
		return
	if _remote_bodies.has(id):
		var r: Node3D = _remote_bodies[id]
		var lab := r.get_node_or_null("Name")
		if lab:
			lab.text = name
	else:
		_spawn_remote_body(id)


func _broadcast_chat(from: String, text: String) -> void:
	_post_chat(from, text)
	rpc("_sv_chat", from, text)


@rpc("authority", "call_remote", "reliable")
func _sv_chat(from: String, text: String) -> void:
	_post_chat(from, text)


@rpc("any_peer", "call_remote", "reliable")
func _sv_chat_msg(text: String) -> void:
	if not Net.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	if text.begins_with("/"):
		var resp := _run_command(text, id)
		if not resp.is_empty():
			_broadcast_chat("System", resp)
		return
	var name := String(_player_names.get(id, "Player%d" % id))
	_broadcast_chat(name, text)


@rpc("any_peer", "call_remote", "unreliable")
func _sv_player_input(mx: float, my: float, sprint: bool, jump: bool, yaw: float, pitch: float) -> void:
	if not Net.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	var p: Node3D = _net_players.get(id)
	if p:
		p.set("net_input", {"move": Vector2(mx, my), "sprint": sprint, "jump": jump})
		p.set("net_yaw", yaw)
		p.set("net_pitch", pitch)


@rpc("any_peer", "call_remote", "unreliable")
func _sv_shoot() -> void:
	_server_shoot(multiplayer.get_remote_sender_id(), 120.0, 2)


@rpc("any_peer", "call_remote", "unreliable")
func _sv_punch() -> void:
	_server_shoot(multiplayer.get_remote_sender_id(), 2.6, 2, true)


func _server_shoot(id: int, range_m: float, dmg: int, is_punch := false) -> void:
	var p: Node3D = _net_players.get(id)
	if not p:
		return
	var in_car := bool(p.get("in_car"))
	if dmg > 0 and not is_punch:
		var has_gun := bool(p.get("has_gun"))
		var ammo: int = int(p.get("ammo"))
		var reload_t: float = float(p.get("_reload_timer"))
		if not has_gun or ammo <= 0 or reload_t > 0.0:
			return
		p.set("ammo", ammo - 1)
		if ammo - 1 <= 0:
			p.call("_start_reload")
	var yaw: float = float(p.get("net_yaw"))
	var pitch: float = float(p.get("net_pitch"))
	var from := p.global_position + Vector3(0.0, 1.5, 0.0)
	var b := Basis.from_euler(Vector3(pitch, yaw, 0.0))
	var dir := -(b * Vector3(0.0, 0.0, 1.0))
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * range_m, 1 | 2)
	q.exclude = [p.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var end := from + dir * range_m
	if hit:
		end = hit.position
		var collider: Object = hit.collider
		if collider is Node:
			var cn := collider as Node
			if cn.has_method("hit"):
				cn.hit(dmg)
			if is_punch and cn.has_method("punched"):
				cn.punched()
			if cn.is_in_group("npc"):
				_mark_crime(id)
	rpc("_sv_tracer", from.x, from.y, from.z, end.x, end.y, end.z)


@rpc("authority", "call_remote", "unreliable")
func _sv_tracer(ox: float, oy: float, oz: float, ex: float, ey: float, ez: float) -> void:
	if _client and _world_ready:
		_spawn_tracer(Vector3(ox, oy, oz), Vector3(ex, ey, ez))


func _mark_crime(id: int) -> void:
	var shooter: Node3D = _net_players.get(id)
	if not shooter:
		return
	var alerted := false
	for npc in get_tree().get_nodes_in_group("npc"):
		if bool(npc.get("is_police")) and (npc as Node3D).global_position.distance_to(shooter.global_position) < 50.0:
			npc.set("_aggro", true)
			npc.set("_warn_timer", 2.5)
			npc.set("_warned", false)
			alerted = true
	if alerted:
		_broadcast_chat("Police", "Stop right there!")


@rpc("any_peer", "call_remote", "reliable")
func _sv_reload() -> void:
	if not Net.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	var p: Node3D = _net_players.get(id)
	if p:
		p.call("_start_reload")


@rpc("any_peer", "call_remote", "reliable")
func _sv_talk(idx: int) -> void:
	if not Net.is_server() or idx < 0 or idx >= _npc_list.size():
		return
	var npc: Node3D = _npc_list[idx]
	if not is_instance_valid(npc):
		return
	_broadcast_chat(String(npc.call("display_name")), String(npc.call("random_line")))


@rpc("any_peer", "call_remote", "unreliable")
func _sv_car_input(idx: int, gas: float, turn: float, boost: bool) -> void:
	if not Net.is_server():
		return
	var c := _vehicle_by_cid(idx)
	if c == null or not is_instance_valid(c):
		return
	c.set("net_gas", gas)
	c.set("net_turn", turn)
	c.set("net_boost", boost)


@rpc("any_peer", "call_remote", "reliable")
func _sv_boat_input(gas: float, turn: float) -> void:
	if not Net.is_server() or _boat == null or not is_instance_valid(_boat):
		return
	_boat.set("net_gas", gas)
	_boat.set("net_turn", turn)


@rpc("any_peer", "call_remote", "reliable")
func _sv_enter_car(idx: int) -> void:
	if not Net.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	var p: Node3D = _net_players.get(id)
	var c := _vehicle_by_cid(idx)
	if not p or not c or bool(p.get("in_car")):
		return
	if c.get("_player_in") != null:
		return
	if p.global_position.distance_to(c.global_position) > 5.0:
		return
	_net_enter_car(p, c)


@rpc("any_peer", "call_remote", "reliable")
func _sv_exit_car(idx: int) -> void:
	if not Net.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	var p: Node3D = _net_players.get(id)
	var c := _vehicle_by_cid(idx)
	if p and c and bool(p.get("in_car")):
		_net_exit_car(p, c)


@rpc("any_peer", "call_remote", "reliable")
func _sv_enter_boat() -> void:
	if not Net.is_server() or _boat == null or not is_instance_valid(_boat):
		return
	var id := multiplayer.get_remote_sender_id()
	var p: Node3D = _net_players.get(id)
	if not p or bool(p.get("in_boat")):
		return
	if _boat.get("_player_in") != null:
		return
	if p.global_position.distance_to(_boat.global_position) > 6.0:
		return
	_net_enter_boat(p)


@rpc("any_peer", "call_remote", "reliable")
func _sv_exit_boat() -> void:
	if not Net.is_server() or _boat == null or not is_instance_valid(_boat):
		return
	var id := multiplayer.get_remote_sender_id()
	var p: Node3D = _net_players.get(id)
	if p and bool(p.get("in_boat")):
		_net_exit_boat(p)


func _net_enter_boat(p: Node3D) -> void:
	p.set("in_car", true)
	p.set("in_boat", true)
	p.set("in_car_id", -1)
	var boat := _boat as CharacterBody3D
	boat.set_player(p)
	p.global_position = boat.global_position + Vector3(0.0, 0.5, 0.0)
	boat.set("_enter_frame", Engine.get_physics_frames())
	_broadcast_chat("System", "%s boarded the rowboat." % String(_player_names.get(int(p.get_meta("net_peer")), "Player")))


func _net_exit_boat(p: Node3D) -> void:
	p.set("in_car", false)
	p.set("in_boat", false)
	p.set("in_car_id", -1)
	var boat := _boat as CharacterBody3D
	boat.set_player(null)
	p.global_position = _find_shore(boat.global_position)
	p.set("velocity", Vector3.ZERO)


func _net_enter_car(p: Node3D, c: Node3D) -> void:
	p.set("in_car", true)
	p.set("in_car_id", int(c.get_meta("car_id", -1)))
	var car_body := c as CharacterBody3D
	car_body.set_player(p)
	p.global_position = c.global_position + Vector3(0.0, 0.6, 0.0)
	c.set("_enter_frame", Engine.get_physics_frames())
	_broadcast_chat("System", "%s got in a car." % String(_player_names.get(int(p.get_meta("net_peer")), "Player")))


func _net_exit_car(p: Node3D, c: Node3D) -> void:
	p.set("in_car", false)
	p.set("in_car_id", -1)
	var car_body := c as CharacterBody3D
	car_body.set_player(null)
	var off: Vector3 = c.global_transform.basis * Vector3(0.0, 0.0, -2.4)
	p.global_position = c.global_position + off
	p.set("velocity", Vector3.ZERO)


@rpc("any_peer", "call_remote", "reliable")
func _sv_collect(pid: int) -> void:
	if not Net.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	var p: Node3D = _net_players.get(id)
	var pk: Node3D = _pickups.get(pid)
	if not p or not pk or not is_instance_valid(pk):
		return
	if p.global_position.distance_to(pk.global_position) > 4.0:
		return
	var name := String(_player_names.get(id, "Player"))
	if pk.has_meta("is_med"):
		if float(p.get("health")) >= float(p.get("max_health")):
			return
		p.set("health", minf(float(p.get("max_health")), float(p.get("health")) + 30.0))
		_broadcast_chat("System", "%s used a medkit." % name)
	elif pk.has_meta("is_hazmat"):
		if bool(p.get("hazmat")):
			return
		p.set("hazmat", true)
		_broadcast_chat("System", "%s put on a hazmat suit." % name)
	elif pk.has_meta("is_gun"):
		if bool(p.get("has_gun")):
			return
		p.call("arm_gun")
		_broadcast_chat("System", "%s picked up a gun." % name)
	else:
		p.set("reserve_ammo", int(p.get("reserve_ammo")) + 24)
		_broadcast_chat("System", "%s picked up ammo." % name)
	pk.queue_free()
	_pickups.erase(pid)


@rpc("any_peer", "call_remote", "reliable")
func _sv_sleep() -> void:
	if not Net.is_server() or not _is_night():
		return
	_time_of_day = (floor(_time_of_day / 24.0) + 1.0) * 24.0 + 6.0
	_broadcast_chat("System", "A player slept through the night until 06:00.")


func _net_exit_current_vehicle() -> void:
	if _player == null:
		return
	var in_boat := bool(_player.get("in_boat"))
	var cidx: int = int(_player.get("in_car_id"))
	_player.set("in_car", false)
	_player.set("in_boat", false)
	_player.set("in_car_id", -1)
	_restore_player_camera()
	_cancel_fishing()
	if in_boat:
		_sv_exit_boat.rpc_id(1)
	elif cidx >= 0:
		_sv_exit_car.rpc_id(1, cidx)


func _restore_player_camera() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var cam := _player.get_node_or_null("CameraRig/Camera") as Camera3D
	if cam:
		cam.current = true


func _net_interact(target: Node3D) -> void:
	if target.is_in_group("npc"):
		var idx := _npc_list.find(target)
		if idx >= 0:
			_sv_talk.rpc_id(1, idx)
	elif target.has_meta("car_id"):
		var cidx := int(target.get_meta("car_id"))
		if bool(_player.get("in_car")):
			_player.set("in_car_id", -1)
			_sv_exit_car.rpc_id(1, cidx)
		else:
			_player.set("in_car_id", cidx)
			_cancel_fishing()
			_sv_enter_car.rpc_id(1, cidx)
	elif target.has_meta("boat"):
		if bool(_player.get("in_boat")):
			_player.set("in_boat", false)
			_player.set("in_car", false)
			_sv_exit_boat.rpc_id(1)
		else:
			_player.set("in_boat", true)
			_player.set("in_car", true)
			_player.set("in_car_id", -1)
			_cancel_fishing()
			_sv_enter_boat.rpc_id(1)
	elif target.has_meta("is_pickup"):
		_sv_collect.rpc_id(1, int(target.get_meta("pickup_id")))
	elif target.is_in_group("beds"):
		_sv_sleep.rpc_id(1)
	elif target.has_method("get_reactor_index") and not bool(_player.get("in_car")):
		var ridx := int(target.call("get_reactor_index"))
		if ridx >= 0:
			if _reactor_panel_open:
				return
			var r: Node3D = _reactors[ridx] if ridx < _reactors.size() else null
			if r == null or not is_instance_valid(r) or bool(r.get("exploded")):
				return
			if r.has_method("interact"):
				r.call("interact")


func _net_self_test() -> void:
	print("[nettest] waiting for sync...")
	await get_tree().create_timer(4.0).timeout
	var n_players := 1
	for id in _remote_bodies:
		n_players += 1
	print("[nettest] remote_bodies=%d npc_count=%d cars=%d zombies=%d time=%.2f" % [
		_remote_bodies.size(), _npc_list.size(), _cars_list.size(), _zombie_nodes.size(), _time_of_day])
	print("[nettest] player_pos=%s target=%s" % [_player.global_position, _net_target_pos])
	var peer := multiplayer.multiplayer_peer
	if peer is ENetMultiplayerPeer and peer.get_connection_status() == ENetMultiplayerPeer.CONNECTION_CONNECTED:
		_sv_punch.rpc_id(1)
		_sv_punch.rpc_id(1)
		_sv_shoot.rpc_id(1)
	await get_tree().create_timer(1.0).timeout
	print("[nettest] DONE")
	get_tree().quit()

func _spawn_gun_pickup(pos: Vector3) -> void:
	var pickup := StaticBody3D.new()
	pickup.name = "GunPickup"
	pickup.collision_layer = 2
	pickup.collision_mask = 0
	pickup.set_script(preload("res://scripts/gun_pickup.gd"))
	pickup.set("world", self)
	pickup.position = pos + Vector3(0.0, 0.1, 0.0)
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.5, 0.25, 0.5)
	col.shape = bs
	pickup.add_child(col)
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.13, 0.13, 0.15)
	body_mat.roughness = 0.6
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.06, 0.12, 0.5)
	body.mesh = bm
	body.material_override = body_mat
	body.rotation_degrees = Vector3(15.0, randi() % 360, 0.0)
	pickup.add_child(body)
	var glow_mat := StandardMaterial3D.new()
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow_mat.albedo_color = Color(1.0, 0.85, 0.4, 0.5)
	var glow := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(0.3, 0.3, 0.3)
	glow.mesh = gm
	glow.material_override = glow_mat
	glow.position = Vector3(0.0, 0.25, 0.0)
	pickup.add_child(glow)
	pickup.set("_glow", glow)
	var pid := _next_pickup_id
	_next_pickup_id += 1
	pickup.set_meta("pickup_id", pid)
	pickup.set_meta("is_gun", true)
	pickup.add_to_group("pickups")
	_pickups[pid] = pickup
	add_child(pickup)

func _give_player_gun() -> void:
	if _server or _client:
		return
	if _player:
		_player.arm_gun()
	_post_chat("System", "You picked up a gun.")

func _build_ammo_pickups() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 13
	var placed := 0
	var tries := 0
	while placed < 10 and tries < 300:
		tries += 1
		var x := rng.randf_range(-70.0, 70.0)
		var z := rng.randf_range(-70.0, 70.0)
		var h := _height_at(x, z)
		if h < 0.5 or h > 12.0:
			continue
		if _slope_at(x, z) > 0.4:
			continue
		_make_ammo_pickup(Vector3(x, h, z))
		placed += 1
	for house in get_tree().get_nodes_in_group("houses"):
		var h := house as Node3D
		_make_ammo_pickup(h.to_global(h.get_meta("interior_local")) + Vector3(0.0, 0.2, 0.0))

func _make_ammo_pickup(pos: Vector3) -> void:
	var pickup := StaticBody3D.new()
	pickup.name = "AmmoPickup"
	pickup.collision_layer = 2
	pickup.collision_mask = 0
	pickup.set_script(preload("res://scripts/ammo_pickup.gd"))
	pickup.set("world", self)
	pickup.position = pos + Vector3(0.0, 0.15, 0.0)
	var pid := _next_pickup_id
	_next_pickup_id += 1
	pickup.set_meta("pickup_id", pid)
	pickup.add_to_group("pickups")
	_pickups[pid] = pickup
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.45, 0.2, 0.45)
	col.shape = bs
	pickup.add_child(col)
	var ammo_mat := StandardMaterial3D.new()
	ammo_mat.albedo_color = Color(0.72, 0.55, 0.22)
	ammo_mat.roughness = 0.5
	var ammo_box := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.3, 0.13, 0.2)
	ammo_box.mesh = bm
	ammo_box.material_override = ammo_mat
	ammo_box.position = Vector3(0.0, 0.02, 0.0)
	pickup.add_child(ammo_box)
	var glow_mat := StandardMaterial3D.new()
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow_mat.albedo_color = Color(1.0, 0.72, 0.25, 0.45)
	var glow := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(0.42, 0.42, 0.42)
	glow.mesh = gm
	glow.material_override = glow_mat
	glow.position = Vector3(0.0, 0.2, 0.0)
	pickup.add_child(glow)
	pickup.set("_glow", glow)
	add_child(pickup)

func _build_grapple_pickups() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 41
	var placed := 0
	var tries := 0
	while placed < 3 and tries < 400:
		tries += 1
		var x := rng.randf_range(-90.0, 90.0)
		var z := rng.randf_range(-90.0, 90.0)
		var h := _height_at(x, z)
		if h < 14.0:
			continue
		_make_grapple_pickup(Vector3(x, h, z))
		placed += 1

func _make_grapple_pickup(pos: Vector3) -> void:
	var pickup := StaticBody3D.new()
	pickup.name = "GrapplePickup"
	pickup.collision_layer = 2
	pickup.collision_mask = 0
	pickup.set_script(preload("res://scripts/grapple_pickup.gd"))
	pickup.set("world", self)
	pickup.position = pos + Vector3(0.0, 0.1, 0.0)
	var pid := _next_pickup_id
	_next_pickup_id += 1
	pickup.set_meta("pickup_id", pid)
	pickup.add_to_group("pickups")
	_pickups[pid] = pickup
	add_child(pickup)

func _make_hazmat_pickup(pos: Vector3) -> void:
	var pickup := StaticBody3D.new()
	pickup.name = "HazmatPickup"
	pickup.collision_layer = 2
	pickup.collision_mask = 0
	pickup.set_script(preload("res://scripts/hazmat_pickup.gd"))
	pickup.set("world", self)
	pickup.position = pos + Vector3(0.0, 0.15, 0.0)
	var pid := _next_pickup_id
	_next_pickup_id += 1
	pickup.set_meta("pickup_id", pid)
	pickup.set_meta("is_hazmat", true)
	pickup.add_to_group("pickups")
	_pickups[pid] = pickup
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.5, 0.55, 0.3)
	col.shape = bs
	pickup.add_child(col)
	var suit_mat := StandardMaterial3D.new()
	suit_mat.albedo_color = Color(0.85, 0.65, 0.15)
	suit_mat.roughness = 0.5
	var suit := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.42, 0.42, 0.2)
	suit.mesh = sm
	suit.material_override = suit_mat
	suit.position = Vector3(0.0, 0.25, 0.0)
	pickup.add_child(suit)
	var visor := MeshInstance3D.new()
	var vm := BoxMesh.new()
	vm.size = Vector3(0.26, 0.2, 0.1)
	visor.mesh = vm
	var visor_mat := StandardMaterial3D.new()
	visor_mat.albedo_color = Color(0.25, 0.5, 0.65)
	visor_mat.roughness = 0.1
	visor.material_override = visor_mat
	visor.position = Vector3(0.0, 0.42, 0.05)
	pickup.add_child(visor)
	var glow_mat := StandardMaterial3D.new()
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow_mat.albedo_color = Color(0.9, 0.8, 0.3, 0.4)
	var glow := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(0.7, 0.7, 0.5)
	glow.mesh = gm
	glow.material_override = glow_mat
	pickup.add_child(glow)
	pickup.set("_glow", glow)
	add_child(pickup)

func _give_player_hazmat() -> bool:
	if _server or _client:
		return false
	if _player == null:
		return false
	_player.set("hazmat", true)
	_post_chat("System", "You put on a hazmat suit. Radiation resistance boosted.")
	return true


func _give_player_ore() -> bool:
	if _server or _client:
		return false
	if _player == null or not is_instance_valid(_player):
		return false
	_player.health = minf(float(_player.get("max_health")), float(_player.get("health")) + 8.0)
	_player.stamina = minf(float(_player.get("max_stamina")), float(_player.get("stamina")) + 15.0)
	_post_chat("System", "You gathered meteor ore. +8 HP, +15 stamina.")
	return true

func _make_med_pickup(pos: Vector3) -> void:
	var pickup := StaticBody3D.new()
	pickup.name = "MedPickup"
	pickup.collision_layer = 2
	pickup.collision_mask = 0
	pickup.set_script(preload("res://scripts/med_pickup.gd"))
	pickup.set("world", self)
	pickup.position = pos + Vector3(0.0, 0.15, 0.0)
	var pid := _next_pickup_id
	_next_pickup_id += 1
	pickup.set_meta("pickup_id", pid)
	pickup.set_meta("is_med", true)
	pickup.add_to_group("pickups")
	_pickups[pid] = pickup
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.45, 0.2, 0.45)
	col.shape = bs
	pickup.add_child(col)
	var med_mat := StandardMaterial3D.new()
	med_mat.albedo_color = Color(0.9, 0.32, 0.32)
	med_mat.roughness = 0.5
	var kit := MeshInstance3D.new()
	var km := BoxMesh.new()
	km.size = Vector3(0.3, 0.18, 0.2)
	kit.mesh = km
	kit.material_override = med_mat
	pickup.add_child(kit)
	var cross_mat := StandardMaterial3D.new()
	cross_mat.albedo_color = Color(1.0, 1.0, 1.0)
	var cross := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(0.08, 0.14, 0.03)
	cross.mesh = cm
	cross.material_override = cross_mat
	cross.position = Vector3(0.0, 0.0, 0.11)
	pickup.add_child(cross)
	var cross2 := MeshInstance3D.new()
	var cm2 := BoxMesh.new()
	cm2.size = Vector3(0.14, 0.08, 0.03)
	cross2.mesh = cm2
	cross2.material_override = cross_mat
	cross2.position = Vector3(0.0, 0.0, 0.11)
	pickup.add_child(cross2)
	var glow_mat := StandardMaterial3D.new()
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow_mat.albedo_color = Color(1.0, 0.35, 0.35, 0.45)
	var glow := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(0.5, 0.4, 0.4)
	glow.mesh = gm
	glow.material_override = glow_mat
	glow.position = Vector3(0.0, 0.25, 0.0)
	pickup.add_child(glow)
	pickup.set("_glow", glow)
	add_child(pickup)

func _trade_fish(good := 0) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _server or _client:
		_post_chat("Market", "The market only trades with local folk today.")
		return
	var price: int = [1, 2, 3][clampi(good, 0, 2)]
	if _fish_basket < price:
		_post_chat("Market", "That'll cost %d fish — you've got %d. The dock's biting today." % [price, _fish_basket])
		return
	if good == 0:
		if _player.health >= _player.max_health:
			_post_chat("Market", "You look full of health. Come back when you're hurt.")
			return
		_player.health = minf(_player.max_health, _player.health + 30.0)
		_fish_basket -= price
		_post_chat("Market", "A medkit for %d fish. Fair trade. (%d fish left)" % [price, _fish_basket])
	elif good == 1:
		if not _player.has_gun:
			_post_chat("Market", "Buy a gun first — ammo's dead weight without one.")
			return
		_player.reserve_ammo += 24
		_fish_basket -= price
		_post_chat("Market", "A box of rounds for %d fish. (%d fish left)" % [price, _fish_basket])
	else:
		if _player.has_gun:
			_post_chat("Market", "You've already got a sidearm, friend.")
			return
		_player.call("arm_gun")
		_fish_basket -= price
		_post_chat("Market", "A sidearm for %d fish. Guard it well. (%d fish left)" % [price, _fish_basket])
	_complete_task("shop", "Traded fish at the market")


func _give_player_meds() -> bool:
	if _server or _client:
		return false
	if _player == null:
		return false
	if _player.health >= _player.max_health:
		_post_chat("System", "You're already at full health.")
		return false
	_player.health = minf(_player.max_health, _player.health + 30.0)
	_post_chat("System", "Medkit applied. Health restored to %d." % int(round(_player.health)))
	return true

func _give_player_ammo() -> bool:
	if _server or _client:
		return false
	if _player == null:
		return false
	if not _player.has_gun:
		_post_chat("System", "You need a gun before you can use ammo.")
		return false
	var amt := 8
	_player.reserve_ammo += amt
	_post_chat("System", "Found %d rounds. Reserve: %d." % [amt, _player.reserve_ammo])
	return true


func _give_player_grapple() -> bool:
	if _server or _client:
		return false
	if _player == null:
		return false
	if _player.has_grapple:
		_post_chat("System", "You already carry a grappling hook.")
		return false
	_player.has_grapple = true
	_post_chat("System", "You grab a compact grappling hook. Press [G] to swing up cliff faces.")
	if not _tasks["grapple"]:
		_complete_task("grapple", "Found a grappling hook")
	return true

func _on_player_crime(pos: Vector3) -> void:
	var alerted := false
	for npc in get_tree().get_nodes_in_group("npc"):
		if npc.get("is_police") == true:
			if (npc as Node3D).global_position.distance_to(pos) < 50.0:
				npc.set("_aggro", true)
				npc.set("_warn_timer", 2.5)
				npc.set("_warned", false)
				alerted = true
	if alerted:
		_post_chat("Police", "Stop right there!")

func _arrest_net_player(target: Node3D) -> void:
	if not _server:
		_arrest_player()
		return
	if target == null or not is_instance_valid(target):
		return
	target.set("_freeze", true)
	_broadcast_chat("Police", "You are under arrest!")
	if target.has_method("strip_gun"):
		target.call("strip_gun")
	if target.has_method("respawn"):
		target.call("respawn", _spawn_pos)
	for npc in get_tree().get_nodes_in_group("npc"):
		if bool(npc.get("is_police")):
			npc.set("_aggro", false)
	target.set("_freeze", false)

func _arrest_player() -> void:
	if _player == null or _sleeping:
		return
	_sleeping = true
	if _player:
		_player.set("_freeze", true)
	_post_chat("Police", "You are under arrest!")
	_sleep_fade.color = Color(0, 0, 0, 0)
	var tw := create_tween()
	tw.tween_property(_sleep_fade, "color:a", 1.0, 0.7)
	await tw.finished
	_player.strip_gun()
	_player.respawn(_spawn_pos)
	for npc in get_tree().get_nodes_in_group("npc"):
		if npc.get("is_police") == true:
			npc.set("_aggro", false)
	_post_chat("System", "The police confiscated your gun. Stay out of trouble!")
	await get_tree().create_timer(1.0).timeout
	var tw2 := create_tween()
	tw2.tween_property(_sleep_fade, "color:a", 0.0, 0.7)
	await tw2.finished
	if _player:
		_player.set("_freeze", false)
	_sleeping = false

func _enter_car(car: CharacterBody3D) -> void:
	if _server or _client:
		return
	if _player == null or bool(_player.get("in_car")):
		return
	_current_target = null
	_cancel_fishing()
	var p := _player as CharacterBody3D
	_player.set("in_car", true)
	_player.set("in_car_id", int(car.get_meta("car_id", -1)))
	_player.set("_freeze", true)
	_player.set("_third_person", false)
	if _player.has_method("_apply_view"):
		_player._apply_view()
	p.collision_layer = 0
	p.collision_mask = 0
	var cam := _player.get_node("CameraRig/Camera") as Camera3D
	if cam:
		cam.current = false
	var car_cam := car.get_node_or_null("Camera3D") as Camera3D
	if car_cam:
		car_cam.current = true
	car.set_player(_player)
	car.set("_enter_frame", Engine.get_physics_frames())
	_post_chat("System", "Driving — WASD to move, E to exit.")

func _exit_car(car: CharacterBody3D) -> void:
	if _server or _client:
		return
	if _player == null or not bool(_player.get("in_car")):
		return
	_player.set("in_car", false)
	_player.set("in_car_id", -1)
	_player.set("_freeze", false)
	var p := _player as CharacterBody3D
	p.collision_layer = 1
	p.collision_mask = 1
	var off: Vector3 = car.global_transform.basis * Vector3(0.0, 0.0, -2.4)
	p.global_position = car.global_position + off
	p.velocity = Vector3.ZERO
	var cam := p.get_node("CameraRig/Camera") as Camera3D
	if cam:
		cam.current = true
	var car_cam := car.get_node_or_null("Camera3D") as Camera3D
	if car_cam:
		car_cam.current = false
	car.set_player(null)
	_post_chat("System", "You got out of the car.")

func _enter_boat(boat: CharacterBody3D) -> void:
	if _server or _client:
		return
	if _player == null or bool(_player.get("in_car")) or bool(_player.get("in_boat")):
		return
	_current_target = null
	_cancel_fishing()
	var p := _player as CharacterBody3D
	_player.set("in_boat", true)
	_player.set("in_car", true)
	_player.set("in_car_id", -1)
	_player.set("_freeze", true)
	_player.set("_third_person", false)
	if _player.has_method("_apply_view"):
		_player._apply_view()
	p.collision_layer = 0
	p.collision_mask = 0
	var cam := _player.get_node("CameraRig/Camera") as Camera3D
	if cam:
		cam.current = false
	var boat_cam := boat.get_node_or_null("Camera3D") as Camera3D
	if boat_cam:
		boat_cam.current = true
	boat.set_player(_player)
	boat.set("_enter_frame", Engine.get_physics_frames())
	_post_chat("System", "Boating — WASD to row, E to disembark.")

func _exit_boat(boat: CharacterBody3D) -> void:
	if _server or _client:
		return
	if _player == null or not bool(_player.get("in_boat")):
		return
	_player.set("in_boat", false)
	_player.set("in_car", false)
	_player.set("_freeze", false)
	var p := _player as CharacterBody3D
	p.collision_layer = 1
	p.collision_mask = 1
	p.global_position = _find_shore(boat.global_position)
	p.velocity = Vector3.ZERO
	var cam := p.get_node("CameraRig/Camera") as Camera3D
	if cam:
		cam.current = true
	var boat_cam := boat.get_node_or_null("Camera3D") as Camera3D
	if boat_cam:
		boat_cam.current = false
	boat.set_player(null)
	_post_chat("System", "You stepped off the boat.")

func _find_shore(pos: Vector3) -> Vector3:
	for r: float in [2.5, 4.0, 6.0, 9.0, 14.0, 20.0, 30.0]:
		for i in 36:
			var a := i / 36.0 * TAU
			var x: float = pos.x + cos(a) * r
			var z: float = pos.z + sin(a) * r
			var h := _height_at(x, z)
			if h > WATER_Y + 0.35:
				return Vector3(x, h, z)
	if _dock_base != Vector3.ZERO:
		return _dock_base + Vector3(0.0, _height_at(_dock_base.x, _dock_base.z), 0.0)
	return pos + Vector3(0.0, 0.5, 0.0)

func _run_command(text: String, sender_id: int = 0) -> String:
	var parts := text.strip_edges().split(" ", false)
	if parts.is_empty():
		return ""
	var cmd := parts[0].to_lower()
	match cmd:
		"/help":
			return "/give <gun|ammo|health>    /time <0-23>    /quality <0-3>    /tornado    /help"
		"/quality":
			if parts.size() < 2 or not parts[1].is_valid_int():
				return "Usage: /quality <0-3>  (0=Low, 1=Medium, 2=High, 3=Ultra)"
			var q := clampi(int(parts[1]), 0, QUALITY_PRESETS.size() - 1)
			_on_quality_changed(q)
			return "Quality set to %s." % QUALITY_NAMES[q]
		"/give":
			if parts.size() < 2:
				return "Usage: /give <gun|ammo|health>"
			match parts[1].to_lower():
				"gun":
					if _player.has_gun:
						return "You already have a gun."
					_player.arm_gun()
					return "Gun given."
				"ammo":
					_player.ammo = _player.max_ammo
					_player.reserve_ammo += 48
					_player.set("_reload_timer", 0.0)
					return "Ammo refilled (+48 reserve)."
				"health":
					_player.health = _player.max_health
					_player.stamina = _player.max_stamina
					return "Health restored."
				_:
					return "Unknown item. Try gun, ammo, or health."
		"/time":
			if parts.size() < 2 or not parts[1].is_valid_int():
				return "Usage: /time <0-23>"
			var h := int(parts[1])
			if h >= 0 and h <= 23:
				_time_of_day = floor(_time_of_day / 24.0) * 24.0 + float(h)
				return "Time set to %02d:00." % h
			return "Invalid hour (0-23)."
		"/tornado":
			var target: Node3D = null
			var pid := 0
			if parts.size() >= 2 and parts[1].is_valid_int():
				pid = int(parts[1])
				if _net_players.has(pid) and is_instance_valid(_net_players[pid]):
					target = _net_players[pid] as Node3D
			if target == null and sender_id > 0 and _net_players.has(sender_id) and is_instance_valid(_net_players[sender_id]):
				pid = sender_id
				target = _net_players[sender_id] as Node3D
			if target == null and _player != null and is_instance_valid(_player):
				target = _player as Node3D
			if target == null:
				return "No player to target. Usage: /tornado [player_id]"
			var fwd := -(target.global_transform.basis.z)
			var pos := target.global_position + fwd * 10.0
			if _spawn_tornado_at(Vector2(pos.x, pos.z)):
				if target == _player:
					return "A tornado rips down near you. Take cover!"
				var who := String(_player_names.get(pid, "Player%d" % pid))
				return "A tornado rips down near %s." % who
			return "No room there — try open ground."
		_:
			return "Unknown command. Type /help."

func _on_player_damaged() -> void:
	if _hurt_flash:
		_hurt_flash.color = Color(0.9, 0.1, 0.1, 0.35)

func _on_player_shot(origin: Vector3, end: Vector3) -> void:
	_spawn_tracer(origin, end)

func _spawn_tracer(origin: Vector3, end: Vector3) -> void:
	var tracer := MeshInstance3D.new()
	var box := BoxMesh.new()
	var len := origin.distance_to(end)
	box.size = Vector3(0.018, 0.018, maxf(len, 0.1))
	tracer.mesh = box
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.3)
	mat.albedo_color = Color(1.0, 0.85, 0.3)
	tracer.material_override = mat
	add_child(tracer)
	tracer.global_position = origin + (end - origin) * 0.5
	tracer.look_at(end, Vector3.UP)
	var tw := create_tween()
	tw.tween_property(tracer, "transparency", 1.0, 0.15)
	tw.tween_callback(tracer.queue_free)

func _setup_noise() -> void:
	for n in [_n1, _n2, _n3, _detail]:
		n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_n1.seed = _world_seed - 687
	_n1.frequency = 0.0055
	_n2.seed = _world_seed + 97
	_n2.frequency = 0.045
	_n3.seed = _world_seed - 1947
	_n3.frequency = 0.0016
	_detail.seed = _world_seed - 1469
	_detail.frequency = 0.09

func _apply_season() -> void:
	if _boat != null and is_instance_valid(_boat):
		_boat.set("speed_mult", _season_boat_speed())
	match _season:
		"spring":
			_grass_base = Color(0.33, 0.53, 0.30)
			_sand = Color(0.70, 0.64, 0.48)
			_meadow = Color(0.30, 0.50, 0.27)
			_rock_col = Color(0.40, 0.40, 0.44)
			_foliage = Color(0.16, 0.36, 0.15)
			_grass_bottom = Color(0.20, 0.38, 0.16)
			_grass_top = Color(0.52, 0.68, 0.36)
			_sakura = Color(0.95, 0.71, 0.83)
			_sky_top_day = Color(0.36, 0.56, 0.88)
			_sky_horizon_day = Color(0.62, 0.66, 0.72)
			_sky_ground_day = Color(0.16, 0.18, 0.16)
			_sky_ground_horizon_day = Color(0.55, 0.50, 0.45)
			_sun_col = Color(1.0, 0.93, 0.82)
		"winter":
			_grass_base = Color(0.78, 0.82, 0.86)
			_sand = Color(0.76, 0.77, 0.80)
			_meadow = Color(0.85, 0.88, 0.91)
			_rock_col = Color(0.42, 0.44, 0.50)
			_snow_line = 1.5
			_snow_top = 30.0
			_foliage = Color(0.55, 0.63, 0.72)
			_grass_bottom = Color(0.72, 0.76, 0.80)
			_grass_top = Color(0.88, 0.90, 0.93)
			_sakura = Color(0.82, 0.87, 0.92)
			_sky_top_day = Color(0.45, 0.52, 0.62)
			_sky_horizon_day = Color(0.68, 0.70, 0.75)
			_sky_ground_day = Color(0.18, 0.18, 0.18)
			_sky_ground_horizon_day = Color(0.62, 0.60, 0.58)
			_sun_col = Color(0.85, 0.90, 1.0)
		_:
			pass


func _season_boat_speed() -> float:
	match _season:
		"winter":
			return 0.55
		_:
			return 1.0


func _garden_ripe_days() -> int:
	match _season:
		"spring":
			return 2
		"winter":
			return 5
		_:
			return 3


func _spring_heal_mult() -> float:
	match _season:
		"winter":
			return 1.5
		"spring":
			return 1.25
		_:
			return 1.0


func _height_at(wx: float, wz: float) -> float:
	var h := _n1.get_noise_2d(wx, wz) * 9.5
	h += _n2.get_noise_2d(wx, wz) * 1.4
	h -= _n3.get_noise_2d(wx + 33.0, wz - 11.0) * 11.0
	h += 6.0
	var r := Vector2(wx, wz).length() / (WORLD_SIZE * 0.5)
	h = lerpf(h, -6.0, smoothstep(0.72, 1.0, r))
	return clampf(h, -7.0, 30.0)

func _slope_at(wx: float, wz: float) -> float:
	var e := 1.2
	var h0 := _height_at(wx, wz)
	var hx := _height_at(wx + e, wz)
	var hz := _height_at(wx, wz + e)
	var n := Vector3(h0 - hx, e, h0 - hz).normalized()
	return 1.0 - clampf(n.y, 0.0, 1.0)

# ------------------------------------------------------------------ environment

func _build_environment() -> void:
	var sky := ProceduralSkyMaterial.new()
	_sky_mat = sky
	sky.sky_top_color = _sky_top_day
	sky.sky_horizon_color = _sky_horizon_day
	sky.ground_bottom_color = _sky_ground_day
	sky.ground_horizon_color = _sky_ground_horizon_day
	sky.sun_angle_max = 42.0
	sky.sun_curve = 0.09
	sky.energy_multiplier = 0.85

	var sky_res := Sky.new()
	sky_res.sky_material = sky

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky_res
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.42
	env.ambient_light_sky_contribution = 1.0
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY

	env.sdfgi_enabled = true
	env.sdfgi_use_occlusion = true
	env.sdfgi_bounce_feedback = 0.4
	env.sdfgi_cascades = 4
	env.sdfgi_cascade0_distance = 38.0
	env.sdfgi_max_distance = 240.0

	env.ssr_enabled = true
	env.ssr_max_steps = 32
	env.ssr_fade_in = 0.12
	env.ssr_fade_out = 0.45

	env.ssao_enabled = true
	env.ssao_intensity = 1.6
	env.ssao_radius = 1.1
	env.ssao_sharpness = 0.9

	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.0055
	env.volumetric_fog_albedo = Color(0.85, 0.87, 0.90)
	env.volumetric_fog_emission = Color(1.0, 0.93, 0.82)
	env.volumetric_fog_emission_energy = 0.16
	env.volumetric_fog_ambient_inject = 0.18
	env.volumetric_fog_gi_inject = 0.1
	env.volumetric_fog_detail_spread = 8.0

	env.fog_enabled = true
	env.fog_density = 0.00035
	env.fog_light_color = Color(0.75, 0.78, 0.86)
	env.fog_sky_affect = 0.0

	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_strength = 1.0
	env.glow_bloom = 0.12
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.set_glow_level(1, 0.6)
	env.set_glow_level(3, 0.9)

	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0

	env.adjustment_enabled = true
	env.adjustment_brightness = 1.0
	env.adjustment_contrast = 1.12
	env.adjustment_saturation = 1.2

	var we := WorldEnvironment.new()
	we.environment = env
	_env = env

	var cam_attr := CameraAttributesPractical.new()
	cam_attr.dof_blur_far_enabled = true
	cam_attr.dof_blur_far_distance = 85.0
	cam_attr.dof_blur_far_transition = 28.0
	cam_attr.dof_blur_amount = 0.55
	cam_attr.exposure_multiplier = 0.9
	cam_attr.auto_exposure_enabled = false
	cam_attr.auto_exposure_min_sensitivity = 0.15
	cam_attr.auto_exposure_max_sensitivity = 6.0
	cam_attr.auto_exposure_speed = 0.35

	if _sanity:
		env.sdfgi_enabled = false
		env.ssr_enabled = false
		env.ssao_enabled = false
		env.volumetric_fog_enabled = false
		env.glow_enabled = false
		env.fog_enabled = false
		env.adjustment_enabled = false
		cam_attr.dof_blur_far_enabled = false
		cam_attr.auto_exposure_enabled = false
		cam_attr.exposure_multiplier = 1.0
		if _fx["--fx-sdfgi"]:
			env.sdfgi_enabled = true
		if _fx["--fx-volumetric"]:
			env.volumetric_fog_enabled = true
		if _fx["--fx-glow"]:
			env.glow_enabled = true
		if _fx["--fx-ssr"]:
			env.ssr_enabled = true
		if _fx["--fx-ssao"]:
			env.ssao_enabled = true
		if _fx["--fx-fog"]:
			env.fog_enabled = true
		if _fx["--fx-dof"]:
			cam_attr.dof_blur_far_enabled = true
		if _fx["--fx-autoexp"]:
			cam_attr.auto_exposure_enabled = true

	we.camera_attributes = cam_attr
	_cam_attr = cam_attr

	if OS.get_cmdline_user_args().has("--no-sdfgi"):
		env.sdfgi_enabled = false
	if OS.get_cmdline_user_args().has("--no-volumetric"):
		env.volumetric_fog_enabled = false
	if OS.get_cmdline_user_args().has("--no-glow"):
		env.glow_enabled = false
	if OS.get_cmdline_user_args().has("--no-ssr"):
		env.ssr_enabled = false
	if OS.get_cmdline_user_args().has("--no-ssao"):
		env.ssao_enabled = false
	if OS.get_cmdline_user_args().has("--no-fog"):
		env.fog_enabled = false
	if OS.get_cmdline_user_args().has("--no-adjust"):
		env.adjustment_enabled = false
	if OS.get_cmdline_user_args().has("--no-dof"):
		cam_attr.dof_blur_far_enabled = false

	add_child(we)

	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-46.0, -32.0, 0.0)
	_sun.light_energy = 1.05
	_sun.light_color = _sun_col
	_sun.shadow_enabled = true
	_sun.shadow_bias = 0.03
	_sun.set("light_volumetric_fog_energy", 0.9)
	_sun.set("directional_shadow_max_distance", 560.0)
	add_child(_sun)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(72.0, 148.0, 0.0)
	fill.light_energy = 0.32
	fill.light_color = Color(0.55, 0.65, 1.0)
	add_child(fill)

	_moon = DirectionalLight3D.new()
	_moon.rotation_degrees = Vector3(-52.0, 148.0, 0.0)
	_moon.light_energy = 0.0
	_moon.light_color = Color(0.62, 0.72, 1.0)
	_moon.shadow_enabled = false
	_moon.set("light_volumetric_fog_energy", 0.3)
	add_child(_moon)

	_apply_quality()

# ------------------------------------------------------------------ terrain

func _build_axis() -> PackedFloat32Array:
	var pts := PackedFloat32Array([0.0])
	var p := 0.0
	var half := WORLD_SIZE / 2.0
	while p < half:
		var t := p / half
		var step := lerpf(TERRAIN_NEAR_STEP, TERRAIN_FAR_STEP, t * t)
		p = minf(half, p + step)
		pts.append(p)
	return pts


func _x_at(ix: int) -> float:
	var n := _axis.size()
	if ix >= n:
		return _axis[ix - n + 1]
	return -_axis[n - 1 - ix]


func _build_terrain() -> void:
	_half = WORLD_SIZE / 2.0
	_axis = _build_axis()
	_grid = _axis.size() * 2 - 1

	_heights.resize(_grid * _grid)
	for iz in _grid:
		var wz := _x_at(iz)
		for ix in _grid:
			_heights[iz * _grid + ix] = _height_at(_x_at(ix), wz)

	_defer_terrain = true
	_terrain_dirty = true

func _make_terrain_collision() -> ConcavePolygonShape3D:
	var stride := 2
	var m := _grid - 1
	var cols := int(ceil(float(m) / stride))
	var faces := PackedVector3Array()
	faces.resize(cols * cols * 6)
	var fi := 0
	for iz in cols:
		var gz := iz * stride
		var z0 := _x_at(gz)
		var z1 := _x_at(mini(gz + stride, m))
		for ix in cols:
			var gx := ix * stride
			var h00 := _heights[gz * _grid + gx]
			var h10 := _heights[gz * _grid + mini(gx + stride, m)]
			var h01 := _heights[mini(gz + stride, m) * _grid + gx]
			var h11 := _heights[mini(gz + stride, m) * _grid + mini(gx + stride, m)]
			var x0 := _x_at(gx)
			var x1 := _x_at(mini(gx + stride, m))
			var v00 := Vector3(x0, h00, z0)
			var v10 := Vector3(x1, h10, z0)
			var v01 := Vector3(x0, h01, z1)
			var v11 := Vector3(x1, h11, z1)
			faces[fi] = v00
			faces[fi + 1] = v10
			faces[fi + 2] = v01
			faces[fi + 3] = v10
			faces[fi + 4] = v11
			faces[fi + 5] = v01
			fi += 6
	var col := ConcavePolygonShape3D.new()
	col.set_faces(faces)
	return col

func _grid_normals() -> Array[Vector3]:
	var normals: Array[Vector3] = []
	normals.resize(_grid * _grid)
	for iz in _grid:
		for ix in _grid:
			var hl: float
			var hr: float
			var hu: float
			var hd: float
			var dx: float
			var dz: float
			if ix == 0:
				hl = _heights[iz * _grid + ix]
				hr = _heights[iz * _grid + ix + 1]
				dx = _x_at(1) - _x_at(0)
			elif ix == _grid - 1:
				hl = _heights[iz * _grid + ix - 1]
				hr = _heights[iz * _grid + ix]
				dx = _x_at(_grid - 1) - _x_at(_grid - 2)
			else:
				hl = _heights[iz * _grid + ix - 1]
				hr = _heights[iz * _grid + ix + 1]
				dx = _x_at(ix + 1) - _x_at(ix - 1)
			if iz == 0:
				hu = _heights[iz * _grid + ix]
				hd = _heights[(iz + 1) * _grid + ix]
				dz = _x_at(1) - _x_at(0)
			elif iz == _grid - 1:
				hu = _heights[(iz - 1) * _grid + ix]
				hd = _heights[iz * _grid + ix]
				dz = _x_at(_grid - 1) - _x_at(_grid - 2)
			else:
				hu = _heights[(iz - 1) * _grid + ix]
				hd = _heights[(iz + 1) * _grid + ix]
				dz = _x_at(iz + 1) - _x_at(iz - 1)
			var n := Vector3(hl - hr, dx, hu - hd).normalized()
			normals[iz * _grid + ix] = n
	return normals

func _terrain_color(h: float, slope: float, wx: float, wz: float) -> Color:
	var base := _grass_base
	base = _sand.lerp(base, smoothstep(0.1, 1.8, h - WATER_Y))
	base = base.lerp(_meadow, smoothstep(2.0, 7.0, h) * (1.0 - slope))
	base = base.lerp(_rock_col, smoothstep(9.0, 16.0, h) * (0.3 + 0.7 * slope))
	base = base.lerp(_snow_col, smoothstep(_snow_line, _snow_top, h))
	var tint := _detail.get_noise_2d(wx * 0.6 + 50.0, wz * 0.6) * 0.5 + 0.5
	base *= 0.82 + 0.34 * tint
	return base

# ------------------------------------------------------------------ water

func _build_water() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/water.gdshader")
	_water_mat = mat
	var plane := PlaneMesh.new()
	plane.size = Vector2(WORLD_SIZE * 3.0, WORLD_SIZE * 3.0)
	var mi := MeshInstance3D.new()
	mi.mesh = plane
	mi.material_override = mat
	mi.position.y = WATER_Y
	add_child(mi)


# ------------------------------------------------------------------ highways & rivers

func _build_highways() -> void:
	if _villages.is_empty():
		return
	_highways = []
	var nodes: Array[Vector2] = []
	nodes.append(_villages[0])
	for i in range(1, _villages.size()):
		nodes.append(_villages[i])
	for r in _reactors:
		if is_instance_valid(r):
			nodes.append(Vector2((r as Node3D).global_position.x, (r as Node3D).global_position.z))
	if _dock_base != Vector3.ZERO:
		var end := Vector2(_dock_base.x, _dock_base.z)
		if _dock_shore != Vector3.ZERO:
			end = Vector2(_dock_shore.x - _dock_dir.x * 12.0, _dock_shore.z - _dock_dir.z * 12.0)
		nodes.append(end)
	for i in range(1, nodes.size()):
		if nodes[0].distance_to(nodes[i]) < 150.0:
			continue
		_plan_highway(nodes[0], nodes[i])
	for i in nodes.size():
		var j := (i + 1) % nodes.size()
		if nodes[i].distance_to(nodes[j]) < 150.0:
			continue
		_plan_highway(nodes[i], nodes[j])
	_rebuild_terrain()
	for i in _highways.size():
		_build_road_mesh(_highways[i], i)


func _plan_highway(a: Vector2, b: Vector2) -> void:
	for p in _highways:
		if p.size() < 2:
			continue
		var q: Vector2 = p[0]
		var r: Vector2 = p[p.size() - 1]
		if (q.distance_to(a) < 24.0 and r.distance_to(b) < 24.0) or (q.distance_to(b) < 24.0 and r.distance_to(a) < 24.0):
			return
	var dist := a.distance_to(b)
	if dist < 30.0:
		return
	var segs := clampi(int(ceil(dist / 4.0)), 8, 900)
	var ctrl := (a + b) * 0.5
	var perp := Vector2(-(b - a).y, (b - a).x).normalized()
	if perp.length() < 0.5:
		perp = Vector2.UP
	var crng := RandomNumberGenerator.new()
	crng.seed = _world_seed + 777 + int(a.x * 13.0 + a.y * 7.0 + b.x * 3.0 + b.y * 11.0)
	ctrl += perp * crng.randf_range(-0.22, 0.22) * dist
	var path: Array = []
	for i in range(segs + 1):
		var t := float(i) / float(segs)
		var inv := 1.0 - t
		var p := a * inv * inv + ctrl * 2.0 * inv * t + b * t * t
		path.append(p)
	_avoid_houses(path)
	for p in path:
		_flatten_heights(p.x, p.y, 8.0, 2.0)
	_highways.append(path)


func _avoid_houses(path: Array) -> void:
	var houses := get_tree().get_nodes_in_group("houses")
	var avoid_r := 11.0
	for _pass in 3:
		for i in range(1, path.size() - 1):
			var p: Vector2 = path[i]
			var push := Vector2.ZERO
			for h in houses:
				if h == null or not is_instance_valid(h):
					continue
				var hc := Vector2((h as Node3D).global_position.x, (h as Node3D).global_position.z)
				var to := p - hc
				var d := to.length()
				if d < avoid_r and d > 0.01:
					push += to.normalized() * (avoid_r - d)
			if push.length() > 0.01:
				path[i] = p + push * 0.5


func _build_road_mesh(path: Array, idx: int) -> void:
	var road_node := Node3D.new()
	road_node.name = "Highway%02d" % idx
	add_child(road_node)
	var shoulder := StandardMaterial3D.new()
	shoulder.albedo_color = Color(0.46, 0.38, 0.28)
	shoulder.roughness = 1.0
	shoulder.cull_mode = BaseMaterial3D.CULL_DISABLED
	var asphalt := StandardMaterial3D.new()
	asphalt.albedo_color = Color(0.20, 0.205, 0.22)
	asphalt.roughness = 0.92
	asphalt.cull_mode = BaseMaterial3D.CULL_DISABLED
	var line := StandardMaterial3D.new()
	line.albedo_color = Color(0.90, 0.90, 0.86)
	line.roughness = 0.7
	line.cull_mode = BaseMaterial3D.CULL_DISABLED
	var dash := StandardMaterial3D.new()
	dash.albedo_color = Color(0.94, 0.94, 0.90)
	dash.roughness = 0.7
	dash.cull_mode = BaseMaterial3D.CULL_DISABLED
	var n := path.size()
	var pts: Array[Vector3] = []
	var perps: Array[Vector3] = []
	const ROAD_LIFT := 0.16
	for i in n:
		var p: Vector2 = path[i]
		var h := _ground_height(p.x, p.y) + ROAD_LIFT
		var dir := Vector2.ZERO
		if i < n - 1:
			dir = (path[i + 1] as Vector2) - p
		else:
			dir = p - (path[i - 1] as Vector2)
		var pr := Vector2(-dir.y, dir.x).normalized()
		if pr.length() < 0.5:
			pr = Vector2.UP
		pts.append(Vector3(p.x, h, p.y))
		perps.append(Vector3(pr.x, 0.0, pr.y))
	road_node.add_child(_make_ribbon_mesh(pts, perps, 4.9, 0.0, 0.02, shoulder))
	road_node.add_child(_make_ribbon_mesh(pts, perps, 3.0, 0.0, 0.06, asphalt))
	road_node.add_child(_make_ribbon_mesh(pts, perps, 0.20, 2.78, 0.08, line))
	road_node.add_child(_make_ribbon_mesh(pts, perps, 0.20, -2.78, 0.08, line))
	road_node.add_child(_make_dash_mesh(pts, perps, 0.18, 0.11, dash))


func _make_ribbon_mesh(pts: Array, perps: Array, half_w: float, offset: float, h_off: float, mat: Material) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var up := Vector3.UP
	for i in pts.size():
		var c: Vector3 = pts[i] + perps[i] * offset + up * h_off
		st.set_normal(up)
		st.add_vertex(c + perps[i] * half_w)
		st.set_normal(up)
		st.add_vertex(c - perps[i] * half_w)
	for i in pts.size() - 1:
		var a := i * 2
		var b := a + 1
		var c := a + 2
		var d := a + 3
		st.add_index(a)
		st.add_index(c)
		st.add_index(b)
		st.add_index(b)
		st.add_index(c)
		st.add_index(d)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mi


func _make_dash_mesh(pts: Array, perps: Array, half_w: float, h_off: float, mat: Material) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var up := Vector3.UP
	var n := pts.size()
	var added := false
	for i in range(0, n - 1, 4):
		var j := mini(i + 1, n - 1)
		var a: Vector3 = pts[i] + perps[i] * half_w + up * h_off
		var b: Vector3 = pts[j] + perps[j] * half_w + up * h_off
		var c: Vector3 = pts[i] - perps[i] * half_w + up * h_off
		var d: Vector3 = pts[j] - perps[j] * half_w + up * h_off
		st.set_normal(up)
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(c)
		st.set_normal(up)
		st.add_vertex(b)
		st.add_vertex(d)
		st.add_vertex(c)
		added = true
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit() if added else ArrayMesh.new()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func _build_rivers() -> void:
	_rivers = []
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 511
	var started := 0
	var tries := 0
	while started < 2 and tries < 240:
		tries += 1
		var a := rng.randf() * TAU
		var r := rng.randf_range(260.0, 620.0)
		var p := Vector2(cos(a), sin(a)) * r
		if _height_at(p.x, p.y) < 2.0:
			continue
		if _near_village(p, 210.0):
			continue
		_carve_river(p, rng, 4.2, 3.4)
		started += 1
	for vi in range(1, _villages.size()):
		var v: Vector2 = _villages[vi]
		var outward := v.normalized()
		if outward.length() < 0.5:
			outward = Vector2.RIGHT
		_carve_river(v + outward * 150.0, rng, 2.4, 2.0)
	for r in _reactors:
		if not is_instance_valid(r):
			continue
		var rp := Vector2((r as Node3D).global_position.x, (r as Node3D).global_position.z)
		var outward := rp.normalized()
		if outward.length() < 0.5:
			outward = Vector2.RIGHT
		_carve_river(rp + outward * 95.0, rng, 1.8, 1.6)
	_rebuild_terrain()


func _near_village(p: Vector2, radius: float) -> bool:
	for v in _villages:
		if (p - (v as Vector2)).length() < radius:
			return true
	return false


func _carve_river(start: Vector2, rng: RandomNumberGenerator, width: float, depth: float) -> void:
	var out_dir := start.normalized()
	if out_dir.length() < 0.5:
		out_dir = Vector2.RIGHT
	var end := out_dir * (WORLD_SIZE * 0.5 - 40.0)
	var segs := 48
	var perp := Vector2(-out_dir.y, out_dir.x)
	var phase := rng.randf() * TAU
	var freq := rng.randf_range(1.0, 2.2)
	var amp := rng.randf_range(8.0, 18.0)
	var path: Array = []
	for i in range(segs + 1):
		var t := float(i) / float(segs)
		var p := start.lerp(end, t) + perp * sin(t * TAU * freq + phase) * amp * t
		var rw := width + t * 2.5
		_carve_heights(p.x, p.y, rw, depth * (0.6 + t * 0.7))
		path.append(p)
	_rivers.append(path)


# ------------------------------------------------------------------ clouds

func _build_clouds(player: Node3D) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/clouds.gdshader")
	_clouds_mat = mat
	var sun_dir := (_sun.global_transform.basis * Vector3(0.0, 0.0, 1.0)).normalized()
	mat.set_shader_parameter("sun_dir", sun_dir)
	mat.set_shader_parameter("night", 0.0)
	var sphere := SphereMesh.new()
	sphere.radius = 2600.0
	sphere.height = 5200.0
	sphere.radial_segments = 48
	sphere.rings = 24
	var mi := MeshInstance3D.new()
	mi.mesh = sphere
	mi.material_override = mat
	mi.name = "Clouds"
	var cam := player.get_node("CameraRig/Camera") as Camera3D
	cam.add_child(mi)

	var star_mat := StandardMaterial3D.new()
	star_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	star_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	star_mat.no_depth_test = true
	star_mat.albedo_color = Color(0.95, 0.97, 1.0, 0.9)
	var stars := GPUParticles3D.new()
	stars.name = "Stars"
	var spm := ParticleProcessMaterial.new()
	spm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	spm.emission_sphere_radius = 2600.0
	spm.direction = Vector3(0.0, 0.0, 1.0)
	spm.spread = 180.0
	spm.gravity = Vector3.ZERO
	spm.initial_velocity_min = 0.0
	spm.initial_velocity_max = 0.0
	spm.scale_min = 1.2
	spm.scale_max = 3.6
	spm.color = Color(0.95, 0.97, 1.0, 0.9)
	stars.process_material = spm
	stars.amount = 650
	stars.lifetime = 25.0
	stars.visible = false
	var sq := QuadMesh.new()
	sq.size = Vector2(1.0, 1.0)
	stars.draw_pass_1 = sq
	stars.material_override = star_mat
	cam.add_child(stars)
	_stars = stars

	var moon_mat := StandardMaterial3D.new()
	moon_mat.albedo_color = Color(0.96, 0.95, 0.88)
	moon_mat.roughness = 1.0
	moon_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	moon_mat.emission_enabled = true
	moon_mat.emission = Color(0.98, 0.96, 0.86)
	moon_mat.emission_energy_multiplier = 1.2
	moon_mat.no_depth_test = true
	_moon_mat = moon_mat
	var moon_mi := MeshInstance3D.new()
	var moon_sph := SphereMesh.new()
	moon_sph.radius = 34.0
	moon_sph.height = 68.0
	moon_sph.radial_segments = 32
	moon_sph.rings = 16
	moon_mi.mesh = moon_sph
	moon_mi.material_override = moon_mat
	moon_mi.name = "Moon"
	moon_mi.visible = false
	moon_mi.position = Vector3(0.0, 0.0, -2400.0)
	cam.add_child(moon_mi)
	_moon_disc = moon_mi

# ------------------------------------------------------------------ props

func _build_props() -> void:
	var p: Dictionary = QUALITY_PRESETS[_quality]
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed

	var trunk_mesh := _make_cylinder(0.16, 0.09, 2.3, 7, Color(0.36, 0.27, 0.19))
	var foliage_mesh := _make_tree_foliage()
	var rock_mesh := _make_rock_mesh()
	var pine_meshes := _make_pine_mesh()
	var bush_mesh := _make_bush_mesh()
	var flower_mesh := _make_flower_mesh()

	var spawn := Vector3(0.0, _height_at(0.0, 0.0) + 2.0, 0.0)

	var tree_target := int(9000.0 * float(p["trees"]))
	var tree_positions := _scatter(rng, tree_target, 1.3, 15.0, 0.0, 0.5, 12.0, 8.0, spawn, -1.0, 0.75, 1.5, true)
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.vertex_color_use_as_albedo = true
	trunk_mat.roughness = 1.0
	_tree_mi = _add_multimesh(trunk_mesh, tree_positions, trunk_mat)
	var fol_mat := StandardMaterial3D.new()
	fol_mat.vertex_color_use_as_albedo = true
	fol_mat.roughness = 0.85
	fol_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_fol_mi = _add_multimesh(foliage_mesh, tree_positions, fol_mat)
	_add_tree_collision(tree_positions)

	var rock_target := int(900.0 * float(p["rocks"]))
	var rock_positions := _scatter(rng, rock_target, -1.5, 27.0, 0.18, 1.0, 0.0, 0.0, spawn, -1.0, 0.5, 2.4)
	var rock_mat := StandardMaterial3D.new()
	rock_mat.vertex_color_use_as_albedo = true
	rock_mat.roughness = 1.0
	_rock_mi = _add_multimesh(rock_mesh, rock_positions, rock_mat)

	var pine_target := int(2200.0 * float(p["pine"]))
	var pine_positions := _scatter(rng, pine_target, 13.0, 26.0, 0.0, 0.5, 0.0, 0.0, spawn, -1.0, 0.7, 1.7, true)
	var pine_trunk_mat := StandardMaterial3D.new()
	pine_trunk_mat.vertex_color_use_as_albedo = true
	pine_trunk_mat.roughness = 1.0
	_pine_trunk_mi = _add_multimesh(pine_meshes[0], pine_positions, pine_trunk_mat)
	var pine_fol_mat := StandardMaterial3D.new()
	pine_fol_mat.vertex_color_use_as_albedo = true
	pine_fol_mat.roughness = 0.85
	pine_fol_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_pine_fol_mi = _add_multimesh(pine_meshes[1], pine_positions, pine_fol_mat)
	_add_tree_collision(pine_positions)

	var bush_target := int(340.0 * float(p["bush"]))
	var bush_positions := _scatter(rng, bush_target, 0.8, 9.0, 0.0, 0.45, 0.0, 4.0, spawn, 150.0, 0.7, 1.6)
	var bush_mat := StandardMaterial3D.new()
	bush_mat.vertex_color_use_as_albedo = true
	bush_mat.roughness = 1.0
	_bush_mi = _add_multimesh(bush_mesh, bush_positions, bush_mat)


func _build_groundcover(rng: RandomNumberGenerator = null, flower_mesh: ArrayMesh = null, p: Dictionary = {}) -> void:
	if p.is_empty():
		p = QUALITY_PRESETS[_quality]
	if flower_mesh == null:
		flower_mesh = _make_flower_mesh()
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.seed = _world_seed + 9
	_build_avoidance_grids()
	var flower_positions: Array[Transform3D] = []
	var flower_colors: Array[Color] = []
	var flower_target := int(600.0 * float(p["flower"]))
	var flower_tries := 0
	var flower_cols := [Color(1.0, 0.85, 0.9), Color(1.0, 0.92, 0.7), Color(0.95, 0.72, 0.82),
		Color(0.85, 0.9, 1.0), Color(0.95, 0.95, 0.85)]
	while flower_positions.size() < flower_target and flower_tries < flower_target * 6:
		flower_tries += 1
		var fx := rng.randf_range(-130.0, 130.0)
		var fz := rng.randf_range(-130.0, 130.0)
		var fh := _ground_height(fx, fz)
		if fh < 0.8 or fh > 8.0:
			continue
		if _slope_at(fx, fz) > 0.35:
			continue
		if _near_cells(_road_cells, Vector2(fx, fz)):
			continue
		flower_positions.append(_tform(Vector3(fx, fh, fz), rng.randf() * TAU, rng.randf_range(0.7, 1.4)))
		flower_colors.append(flower_cols[rng.randi() % flower_cols.size()])
	var flower_mat := StandardMaterial3D.new()
	flower_mat.vertex_color_use_as_albedo = true
	flower_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flower_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flower_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_flower_mi = _add_multimesh(flower_mesh, flower_positions, flower_mat, flower_colors)
	if not _server:
		_build_grass(_grass_count())


var _road_cells := {}
var _river_cells := {}


func _build_avoidance_grids() -> void:
	_road_cells = {}
	_river_cells = {}
	for path in _highways:
		for pt in path:
			_mark_cells(_road_cells, pt, 7.0)
	for rpath in _rivers:
		for pt in rpath:
			_mark_cells(_river_cells, pt, 5.0)


func _mark_cells(cells: Dictionary, pos: Vector2, radius: float) -> void:
	var cell := 8.0
	var r := int(ceil(radius / cell))
	var cx := int(floor(pos.x / cell))
	var cz := int(floor(pos.y / cell))
	for i in range(-r, r + 1):
		for j in range(-r, r + 1):
			cells[Vector2i(cx + i, cz + j)] = true


func _near_cells(cells: Dictionary, pos: Vector2) -> bool:
	var cell := 8.0
	var cx := int(floor(pos.x / cell))
	var cz := int(floor(pos.y / cell))
	for i in range(-1, 2):
		for j in range(-1, 2):
			if cells.has(Vector2i(cx + i, cz + j)):
				return true
	return false


func _scatter(rng: RandomNumberGenerator, count: int, h_min: float, h_max: float,
		slope_min: float, slope_max: float, min_dist: float, near_margin: float,
		spawn: Vector3, max_dist: float = -1.0, s_min: float = 0.75, s_max: float = 1.5,
		falloff: bool = false) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	var tries := 0
	var max_tries := maxi(count * 6, 500)
	while out.size() < count and tries < max_tries:
		tries += 1
		var x := rng.randf_range(-_half + 6.0, _half - 6.0)
		var z := rng.randf_range(-_half + 6.0, _half - 6.0)
		if max_dist > 0.0 and Vector2(x, z).distance_to(Vector2(spawn.x, spawn.z)) > max_dist:
			continue
		if falloff:
			var w := lerpf(1.0, 0.3, clampf(Vector2(x, z).distance_to(Vector2(spawn.x, spawn.z)) / (_half * 0.5), 0.0, 1.0))
			if rng.randf() > w:
				continue
		var h := _height_at(x, z)
		if h < h_min or h > h_max:
			continue
		var slope := _slope_at(x, z)
		if slope < slope_min or slope > slope_max:
			continue
		if Vector2(x, z).distance_to(Vector2(spawn.x, spawn.z)) < min_dist:
			continue
		var clear := true
		for hs in get_tree().get_nodes_in_group("houses"):
			if Vector2(x, z).distance_to(Vector2((hs as Node3D).global_position.x, (hs as Node3D).global_position.z)) < near_margin:
				clear = false
				break
		if not clear:
			continue
		out.append(_tform(Vector3(x, h, z), rng.randf() * TAU, rng.randf_range(s_min, s_max)))
	return out

func _on_stats_changed(hp: float, stamina: float, thirst: float = 100.0) -> void:
	if _hp_bar:
		_hp_bar.value = hp
	if _stamina_bar:
		_stamina_bar.value = stamina
	if _thirst_bar:
		_thirst_bar.value = thirst

func _on_player_died() -> void:
	if _player:
		_player.call("respawn", _spawn_pos)

func _tform(origin: Vector3, yaw: float, s: float) -> Transform3D:
	var b := Basis.from_euler(Vector3(0.0, yaw, 0.0)).scaled(Vector3.ONE * s)
	return Transform3D(b, origin)

func _add_tree_collision(transforms: Array) -> void:
	var body := StaticBody3D.new()
	body.name = "TreeCollision"
	var shape := CylinderShape3D.new()
	shape.radius = 0.45
	shape.height = 3.4
	for t: Transform3D in transforms:
		if t.origin.distance_to(Vector3.ZERO) > TREE_COL_RADIUS:
			continue
		var col := CollisionShape3D.new()
		col.shape = shape
		col.position = t.origin + Vector3(0.0, 1.7, 0.0)
		body.add_child(col)
	add_child(body)

func _add_multimesh(mesh: ArrayMesh, transforms: Array, mat: Material, colors: Array = []) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	if not colors.is_empty():
		mm.use_colors = true
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	if not colors.is_empty():
		for i in transforms.size():
			mm.set_instance_color(i, colors[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = mat
	add_child(mi)
	return mi

func _build_grass(count: int) -> void:
	if _grass_mi:
		_grass_mi.queue_free()
		_grass_mi = null
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed
	var positions: Array[Transform3D] = []
	var spawn := Vector3(0.0, _height_at(0.0, 0.0) + 2.0, 0.0)
	var tries := 0
	var max_tries := maxi(count * 8, 6000)
	while positions.size() < count and tries < max_tries:
		tries += 1
		var x: float
		var z: float
		if rng.randf() < 0.45:
			x = rng.randf_range(-280.0, 280.0)
			z = rng.randf_range(-280.0, 280.0)
		else:
			var a := rng.randf() * TAU
			var r := rng.randf_range(300.0, 900.0)
			x = cos(a) * r
			z = sin(a) * r
		if Vector2(x, z).distance_to(Vector2(spawn.x, spawn.z)) > 900.0:
			continue
		var h := _ground_height(x, z)
		if h < 0.3 or h > 12.0:
			continue
		if _slope_at(x, z) > 0.4:
			continue
		if Vector2(x, z).distance_to(Vector2(spawn.x, spawn.z)) < 6.0:
			continue
		if _near_cells(_road_cells, Vector2(x, z)) or _near_cells(_river_cells, Vector2(x, z)):
			continue
		var s := rng.randf_range(0.6, 1.8)
		positions.append(_tform(Vector3(x, h, z), rng.randf() * TAU, s))
	var grass_mat := ShaderMaterial.new()
	grass_mat.shader = preload("res://shaders/grass.gdshader")
	_grass_mi = _add_multimesh(_make_grass_tuft(), positions, grass_mat)

func _grass_count() -> int:
	return int(34000.0 * float(QUALITY_PRESETS[_quality]["grass"]))

func _make_cylinder(r_b: float, r_t: float, height: float, sides: int, col: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n_top := 0
	for i in sides:
		var a0 := float(i) / sides * TAU
		var a1 := float(i + 1) / sides * TAU
		var c0 := Vector2(cos(a0), sin(a0))
		var c1 := Vector2(cos(a1), sin(a1))
		var p0 := Vector3(c0.x * r_b, 0.0, c0.y * r_b)
		var p1 := Vector3(c1.x * r_b, 0.0, c1.y * r_b)
		var p2 := Vector3(c1.x * r_t, height, c1.y * r_t)
		var p3 := Vector3(c0.x * r_t, height, c0.y * r_t)
		var n0 := Vector3(c0.x, 0.0, c0.y).normalized()
		var n1 := Vector3(c1.x, 0.0, c1.y).normalized()
		st.set_normal(n0)
		st.set_color(col)
		st.add_vertex(p0)
		st.set_normal(n1)
		st.set_color(col)
		st.add_vertex(p1)
		st.set_normal(n1)
		st.set_color(col)
		st.add_vertex(p2)
		st.set_normal(n0)
		st.set_color(col)
		st.add_vertex(p0)
		st.set_normal(n1)
		st.set_color(col)
		st.add_vertex(p2)
		st.set_normal(n0)
		st.set_color(col)
		st.add_vertex(p3)
	return st.commit()

func _cone(st: SurfaceTool, origin: Vector3, radius: float, height: float, sides: int, col: Color) -> void:
	var apex := origin + Vector3(0.0, height, 0.0)
	for i in sides:
		var a0 := float(i) / sides * TAU
		var a1 := float(i + 1) / sides * TAU
		var c0 := Vector2(cos(a0), sin(a0))
		var c1 := Vector2(cos(a1), sin(a1))
		var p0 := origin + Vector3(c0.x * radius, 0.0, c0.y * radius)
		var p1 := origin + Vector3(c1.x * radius, 0.0, c1.y * radius)
		var n0 := Vector3(c0.x, radius / height, c0.y).normalized()
		var n1 := Vector3(c1.x, radius / height, c1.y).normalized()
		st.set_normal(n0)
		st.set_color(col)
		st.add_vertex(p0)
		st.set_normal(n1)
		st.set_color(col)
		st.add_vertex(p1)
		st.set_normal(n0.lerp(n1, 0.5))
		st.set_color(col)
		st.add_vertex(apex)
	return

func _make_tree_foliage() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_cone(st, Vector3(0.0, 2.5, 0.0), 1.55, 2.5, 9, _foliage)
	_cone(st, Vector3(0.0, 3.6, 0.0), 1.15, 2.0, 9, _foliage.lightened(0.06))
	_cone(st, Vector3(0.0, 4.5, 0.0), 0.75, 1.5, 9, _foliage.lightened(0.12))
	return st.commit()

func _make_pine_mesh() -> Array[ArrayMesh]:
	var trunk := _make_cylinder(0.22, 0.12, 3.2, 7, Color(0.32, 0.22, 0.16))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var col := _foliage.darkened(0.15)
	_cone(st, Vector3(0.0, 3.4, 0.0), 2.0, 2.0, 8, col)
	_cone(st, Vector3(0.0, 4.6, 0.0), 1.5, 1.7, 8, col.lightened(0.05))
	_cone(st, Vector3(0.0, 5.6, 0.0), 1.0, 1.4, 8, col.lightened(0.1))
	_cone(st, Vector3(0.0, 6.5, 0.0), 0.6, 1.2, 8, col.lightened(0.15))
	return [trunk, st.commit()]

func _sphere_into(st: SurfaceTool, origin: Vector3, radius: float, rows: int, col: Color) -> void:
	for j in rows:
		var v0 := PI * float(j) / float(rows)
		var v1 := PI * float(j + 1) / float(rows)
		for i in 12:
			var u0 := TAU * float(i) / 12.0
			var u1 := TAU * float(i + 1) / 12.0
			var a := Vector3(sin(v0) * cos(u0), cos(v0), sin(v0) * sin(u0))
			var b := Vector3(sin(v0) * cos(u1), cos(v0), sin(v0) * sin(u1))
			var c := Vector3(sin(v1) * cos(u1), cos(v1), sin(v1) * sin(u1))
			var d := Vector3(sin(v1) * cos(u0), cos(v1), sin(v1) * sin(u0))
			st.set_normal(a)
			st.set_color(col)
			st.add_vertex(origin + a * radius)
			st.set_normal(b)
			st.set_color(col)
			st.add_vertex(origin + b * radius)
			st.set_normal(c)
			st.set_color(col)
			st.add_vertex(origin + c * radius)
			st.set_normal(a)
			st.set_color(col)
			st.add_vertex(origin + a * radius)
			st.set_normal(c)
			st.set_color(col)
			st.add_vertex(origin + c * radius)
			st.set_normal(d)
			st.set_color(col)
			st.add_vertex(origin + d * radius)

func _make_bush_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed - 3991
	var base := _grass_base.darkened(0.1)
	for i in 5:
		var r := rng.randf_range(0.3, 0.55)
		var cy := rng.randf_range(0.1, 0.4)
		var c := base.lightened(rng.randf_range(-0.05, 0.12))
		_sphere_into(st, Vector3(rng.randf_range(-0.3, 0.3), cy, rng.randf_range(-0.3, 0.3)), r, 8, c)
	return st.commit()

func _make_flower_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for rot in [0.0, PI / 2.0]:
		var b := Basis(Vector3.UP, rot)
		var p0 := b * Vector3(-0.05, 0.0, 0.0)
		var p1 := b * Vector3(0.05, 0.0, 0.0)
		var p2 := b * Vector3(0.0, 0.22, 0.0)
		st.set_normal(Vector3.UP)
		st.set_color(Color.WHITE)
		st.add_vertex(p0)
		st.set_normal(Vector3.UP)
		st.set_color(Color.WHITE)
		st.add_vertex(p1)
		st.set_normal(Vector3.UP)
		st.set_color(Color.WHITE)
		st.add_vertex(p2)
		st.set_normal(Vector3.UP)
		st.set_color(Color.WHITE)
		st.add_vertex(p0)
		st.set_normal(Vector3.UP)
		st.set_color(Color.WHITE)
		st.add_vertex(p2)
		st.set_normal(Vector3.UP)
		st.set_color(Color.WHITE)
		st.add_vertex(p1)
	return st.commit()

func _make_rock_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed - 2017
	var rows := 8
	var cols := 13
	var pts: Array[Vector3] = []
	var nrm: Array[Vector3] = []
	for j in rows:
		var v := PI * float(j) / float(rows - 1)
		for i in cols:
			var u := TAU * float(i) / float(cols)
			var dir := Vector3(sin(v) * cos(u), cos(v), sin(v) * sin(u))
			var r := 1.0 * (0.72 + 0.5 * _detail.get_noise_3d(dir.x * 2.2, dir.y * 2.2, dir.z * 2.2) * 0.5 + 0.5)
			r = maxf(r, 0.3)
			pts.append(dir * r)
			nrm.append(dir)
	for j in rows - 1:
		for i in cols:
			var i2 := (i + 1) % cols
			var a := j * cols + i
			var b := j * cols + i2
			var c := (j + 1) * cols + i2
			var d := (j + 1) * cols + i
			st.set_normal(nrm[a])
			st.set_color(_rock_color())
			st.add_vertex(pts[a])
			st.set_normal(nrm[b])
			st.set_color(_rock_color())
			st.add_vertex(pts[b])
			st.set_normal(nrm[c])
			st.set_color(_rock_color())
			st.add_vertex(pts[c])
			st.set_normal(nrm[a])
			st.set_color(_rock_color())
			st.add_vertex(pts[a])
			st.set_normal(nrm[c])
			st.set_color(_rock_color())
			st.add_vertex(pts[c])
			st.set_normal(nrm[d])
			st.set_color(_rock_color())
			st.add_vertex(pts[d])
	return st.commit()

func _rock_color() -> Color:
	var t := _detail.get_noise_1d(_rock_t) * 0.5 + 0.5
	_rock_t += 1.0
	return Color(0.34, 0.33, 0.31).lerp(Color(0.48, 0.47, 0.45), t)

var _rock_t := 0.0

func _make_grass_tuft() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed - 1925
	for b in 6:
		var ang := TAU * float(b) / 6.0
		var dirx := cos(ang)
		var dirz := sin(ang)
		var h := rng.randf_range(0.5, 0.95)
		var w := rng.randf_range(0.06, 0.12)
		var col_bottom := _grass_bottom.lerp(_grass_bottom.darkened(0.25), rng.randf())
		var col_top := _grass_top.lerp(_grass_top.darkened(0.15), rng.randf())
		var p0 := Vector3(-dirx * w * 0.5, 0.0, -dirz * w * 0.5)
		var p1 := Vector3(dirx * w * 0.5, 0.0, dirz * w * 0.5)
		var p2 := Vector3(dirx * w * 0.15, h, dirz * w * 0.15)
		var p3 := Vector3(-dirx * w * 0.15, h, -dirz * w * 0.15)
		var n := Vector3(-dirz, 0.0, dirx)
		st.set_normal(n)
		st.set_color(col_bottom)
		st.add_vertex(p0)
		st.set_normal(n)
		st.set_color(col_bottom)
		st.add_vertex(p1)
		st.set_normal(n)
		st.set_color(col_top)
		st.add_vertex(p2)
		st.set_normal(n)
		st.set_color(col_bottom)
		st.add_vertex(p0)
		st.set_normal(n)
		st.set_color(col_top)
		st.add_vertex(p2)
		st.set_normal(n)
		st.set_color(col_top)
		st.add_vertex(p3)
	return st.commit()

# ------------------------------------------------------------------ japan

func _build_japan() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 3

	var sakura_trunk := _make_cylinder(0.15, 0.08, 2.1, 7, Color(0.30, 0.22, 0.18))
	var sakura_foliage := _make_sakura_foliage()
	var sakura_positions: Array[Transform3D] = []
	var sakura_target := int(350.0 * float(QUALITY_PRESETS[_quality]["sakura"]))

	var torii_mat := StandardMaterial3D.new()
	torii_mat.albedo_color = Color(0.72, 0.16, 0.14)
	torii_mat.roughness = 0.6
	var torii_idx := 0

	var lamp_mat := StandardMaterial3D.new()
	lamp_mat.vertex_color_use_as_albedo = true
	lamp_mat.roughness = 0.95
	var lamp_mesh := _make_lantern_mesh()
	var lamp_positions: Array[Transform3D] = []

	for vi in _villages.size():
		var center := _villages[vi]
		var is_main := vi == 0
		var sakura_n := int(sakura_target * (0.45 if is_main else 0.2))
		var placed_here := 0
		var tries := 0
		while placed_here < sakura_n and tries < sakura_n * 12:
			tries += 1
			var ang := rng.randf() * TAU
			var dist := rng.randf_range(45.0, 140.0)
			var x := center.x + cos(ang) * dist
			var z := center.y + sin(ang) * dist
			var h := _height_at(x, z)
			if h < 1.0 or h > 11.0:
				continue
			if _slope_at(x, z) > 0.4:
				continue
			var clear := true
			for hs in get_tree().get_nodes_in_group("houses"):
				if Vector2(x, z).distance_to(Vector2((hs as Node3D).global_position.x, (hs as Node3D).global_position.z)) < 7.0:
					clear = false
					break
			if not clear:
				continue
			var s := rng.randf_range(0.8, 1.5)
			sakura_positions.append(_tform(Vector3(x, h, z), rng.randf() * TAU, s))
			placed_here += 1
		var g1 := _make_torii(torii_mat)
		g1.name = "Torii%d" % torii_idx
		torii_idx += 1
		g1.position = Vector3(center.x, _height_at(center.x, center.y + 14.0), center.y + 14.0)
		g1.rotation_degrees = Vector3(0.0, 180.0, 0.0)
		add_child(g1)
		var g2 := _make_torii(torii_mat)
		g2.name = "Torii%d" % torii_idx
		torii_idx += 1
		g2.position = Vector3(center.x + 26.0, _height_at(center.x + 26.0, center.y - 20.0), center.y - 20.0)
		g2.rotation_degrees = Vector3(0.0, 140.0, 0.0)
		add_child(g2)

		var lamp_placed := 0
		var lamp_tries := 0
		var lamp_target := 12 if is_main else 8
		while lamp_placed < lamp_target and lamp_tries < 400:
			lamp_tries += 1
			var la := rng.randf() * TAU
			var ld := rng.randf_range(6.0, 45.0)
			var lx := center.x + cos(la) * ld
			var lz := center.y + sin(la) * ld
			var lh := _height_at(lx, lz)
			if lh < 1.0 or lh > 8.0:
				continue
			if _slope_at(lx, lz) > 0.3:
				continue
			lamp_positions.append(_tform(Vector3(lx, lh, lz), rng.randf() * TAU, 1.0))
			lamp_placed += 1

	_add_tree_collision(sakura_positions)
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.vertex_color_use_as_albedo = true
	trunk_mat.roughness = 1.0
	_sakura_trunk_mi = _add_multimesh(sakura_trunk, sakura_positions, trunk_mat)
	var fol_mat := StandardMaterial3D.new()
	fol_mat.vertex_color_use_as_albedo = true
	fol_mat.roughness = 0.85
	fol_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_sakura_fol_mi = _add_multimesh(sakura_foliage, sakura_positions, fol_mat)

	var extra_torii := 3
	var t_tries := 0
	while extra_torii > 0 and t_tries < 300:
		t_tries += 1
		var t_ang := rng.randf() * TAU
		var t_dist := rng.randf_range(20.0, 100.0)
		var tx := cos(t_ang) * t_dist
		var tz := sin(t_ang) * t_dist
		var th := _height_at(tx, tz)
		if th < 1.0 or th > 8.0:
			continue
		if _slope_at(tx, tz) > 0.35:
			continue
		var g := _make_torii(torii_mat)
		g.name = "Torii%d" % torii_idx
		torii_idx += 1
		g.position = Vector3(tx, th, tz)
		g.rotation_degrees = Vector3(0.0, rng.randf() * 360.0, 0.0)
		add_child(g)
		extra_torii -= 1

	_add_multimesh(lamp_mesh, lamp_positions, lamp_mat)

	_build_sakura_petals()

func _build_schools() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 41
	for vi in _villages.size():
		var center := _villages[vi]
		var tries := 0
		var placed := false
		while not placed and tries < 150:
			tries += 1
			var ang := rng.randf() * TAU
			var dist := rng.randf_range(14.0, 32.0)
			var x := center.x + cos(ang) * dist
			var z := center.y + sin(ang) * dist
			var h := _height_at(x, z)
			if h < 1.0 or h > 9.0:
				continue
			if _slope_at(x, z) > 0.22:
				continue
			var clear := true
			for hs in get_tree().get_nodes_in_group("houses"):
				if Vector2(x, z).distance_to(Vector2((hs as Node3D).global_position.x, (hs as Node3D).global_position.z)) < 18.0:
					clear = false
					break
			if not clear:
				continue
			var school := _make_school(vi)
			school.name = "School%d" % vi
			school.position = Vector3(x, h, z)
			school.rotation_degrees = Vector3(0.0, rng.randf() * 360.0, 0.0)
			add_child(school)
			placed = true

func _make_school(idx: int) -> Node3D:
	var node := Node3D.new()
	node.name = "School%d" % idx
	node.add_to_group("schools")

	var palettes: Array[Array] = [
		[Color(0.86, 0.80, 0.68), Color(0.22, 0.24, 0.30)],
		[Color(0.78, 0.74, 0.62), Color(0.38, 0.20, 0.16)],
		[Color(0.84, 0.82, 0.74), Color(0.18, 0.30, 0.26)],
	]
	var pal: Array = palettes[idx % palettes.size()]
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = pal[0]
	wall_mat.roughness = 0.95
	var roof_mat := StandardMaterial3D.new()
	roof_mat.albedo_color = pal[1]
	roof_mat.roughness = 0.9
	var win_mat := StandardMaterial3D.new()
	win_mat.albedo_color = Color(0.6, 0.75, 0.92)
	win_mat.roughness = 0.3
	var door_mat := StandardMaterial3D.new()
	door_mat.albedo_color = Color(0.30, 0.20, 0.14)
	door_mat.roughness = 0.8

	var hw := 3.2
	var hd := 2.4
	var wall_h := 3.2
	var t := 0.2

	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.42, 0.31, 0.21)
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(hw * 2.0, t, hd * 2.0)
	var floor := MeshInstance3D.new()
	floor.mesh = floor_mesh
	floor.position = Vector3(0.0, t * 0.5, 0.0)
	floor.material_override = floor_mat
	node.add_child(floor)

	var wall_box := BoxMesh.new()
	wall_box.size = Vector3(hw * 2.0, wall_h, t)
	var back := MeshInstance3D.new()
	back.mesh = wall_box
	back.position = Vector3(0.0, wall_h * 0.5, -hd)
	back.material_override = wall_mat
	node.add_child(back)

	var side_box := BoxMesh.new()
	side_box.size = Vector3(t, wall_h, hd * 2.0)
	for xs in [hw, -hw]:
		var mi := MeshInstance3D.new()
		mi.mesh = side_box
		mi.position = Vector3(xs, wall_h * 0.5, 0.0)
		mi.material_override = wall_mat
		node.add_child(mi)

	var door_gap := 1.2
	var seg_w := (hw * 2.0 - door_gap) * 0.5
	var seg_box := BoxMesh.new()
	seg_box.size = Vector3(seg_w, wall_h, t)
	for sx in [1.0, -1.0]:
		var mi := MeshInstance3D.new()
		mi.mesh = seg_box
		mi.position = Vector3(sx * (door_gap * 0.5 + seg_w * 0.5), wall_h * 0.5, hd)
		mi.material_override = wall_mat
		node.add_child(mi)

	var lintel_mesh := BoxMesh.new()
	lintel_mesh.size = Vector3(door_gap, wall_h - 2.1, t)
	var lintel := MeshInstance3D.new()
	lintel.mesh = lintel_mesh
	lintel.position = Vector3(0.0, (wall_h + 2.1) * 0.5, hd)
	lintel.material_override = wall_mat
	node.add_child(lintel)

	var door_mesh := BoxMesh.new()
	door_mesh.size = Vector3(1.0, 2.1, 0.12)
	var door := MeshInstance3D.new()
	door.mesh = door_mesh
	door.position = Vector3(0.0, 1.05, hd + 0.06)
	door.material_override = door_mat
	node.add_child(door)

	var win_mesh := BoxMesh.new()
	win_mesh.size = Vector3(0.7, 0.8, 0.06)
	for sx in [1.0, -1.0]:
		for wi in [-1, 1]:
			var w := MeshInstance3D.new()
			w.mesh = win_mesh
			w.position = Vector3(sx * (door_gap * 0.5 + seg_w * 0.5), 1.7, hd + wi * (seg_w * 0.35))
			w.material_override = win_mat
			node.add_child(w)
	for zs in [-1, 1]:
		for wx in [-1.4, 1.4]:
			var w := MeshInstance3D.new()
			w.mesh = win_mesh
			w.position = Vector3(wx, 1.7, -hd - zs * 0.03)
			w.material_override = win_mat
			node.add_child(w)

	var ridge_y := wall_h + 1.6
	var roof_len := sqrt(hw * hw + 1.6 * 1.6)
	var roof_ang := rad_to_deg(atan(1.6 / hw))
	var roof_plane := BoxMesh.new()
	roof_plane.size = Vector3(roof_len, 0.18, hd * 2.0 + 0.6)
	var mid_y := (wall_h + ridge_y) * 0.5
	for sx in [1.0, -1.0]:
		var r := MeshInstance3D.new()
		r.mesh = roof_plane
		r.position = Vector3(sx * (roof_len * 0.5 - hw * 0.5) + 0.0, mid_y, 0.0)
		r.rotation_degrees = Vector3(0.0, 0.0, -sx * roof_ang)
		r.material_override = roof_mat
		node.add_child(r)

	var tower_box := BoxMesh.new()
	tower_box.size = Vector3(1.1, 1.6, 1.1)
	var tower := MeshInstance3D.new()
	tower.mesh = tower_box
	tower.position = Vector3(0.0, ridge_y + 0.8, 0.0)
	tower.material_override = wall_mat
	node.add_child(tower)
	var tower_roof := MeshInstance3D.new()
	tower_roof.mesh = _make_cone_mesh(0.95, 0.9, pal[1], 4)
	tower_roof.position = Vector3(0.0, ridge_y + 1.6, 0.0)
	tower_roof.material_override = roof_mat
	node.add_child(tower_roof)

	var clock_mesh := CylinderMesh.new()
	clock_mesh.top_radius = 0.26
	clock_mesh.bottom_radius = 0.26
	clock_mesh.height = 0.07
	var clock := MeshInstance3D.new()
	clock.mesh = clock_mesh
	clock.position = Vector3(0.0, ridge_y + 0.85, 0.55)
	clock.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	var clock_mat := StandardMaterial3D.new()
	clock_mat.albedo_color = Color(0.95, 0.93, 0.88)
	clock.material_override = clock_mat
	node.add_child(clock)

	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.85, 0.85, 0.85)
	pole_mat.roughness = 0.6
	var pole := MeshInstance3D.new()
	pole.mesh = _make_cylinder(0.045, 0.035, 2.6, 6, Color(0.85, 0.85, 0.85))
	pole.position = Vector3(0.0, ridge_y + 2.9, 0.0)
	pole.material_override = pole_mat
	node.add_child(pole)

	var sign := Label3D.new()
	sign.text = "SCHOOL"
	sign.position = Vector3(0.0, wall_h - 0.35, hd + 0.35)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.pixel_size = 0.0042
	sign.outline_size = 6
	sign.modulate = Color(0.95, 0.95, 1.0)
	node.add_child(sign)

	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(hw * 2.0, wall_h, hd * 2.0)
	col.shape = bs
	col.position = Vector3(0.0, wall_h * 0.5, 0.0)
	body.add_child(col)
	node.add_child(body)

	node.set_meta("entry_local", Vector3(0.0, t, hd))
	return node

func _build_structures() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 21
	for vi in _villages.size():
		var center := _villages[vi]
		var is_main := vi == 0
		if is_main:
			_place_structures(rng, center, _make_pagoda, 50.0, 120.0, 3)
			_place_structures(rng, center, _make_stone_shrine, 30.0, 90.0, 4)
			_place_structures(rng, center, _make_campfire, 25.0, 80.0, 3)
			_place_structures(rng, center, _make_well, 30.0, 90.0, 2)
			_build_market(center, 3)
			_build_shrine(center)
			_build_windmill(center)
		else:
			_place_structures(rng, center, _make_stone_shrine, 20.0, 70.0, 2)
			_place_structures(rng, center, _make_campfire, 15.0, 60.0, 2)
			_place_structures(rng, center, _make_well, 20.0, 70.0, 1)
			_build_market(center, 2)
	_build_schools()
	_build_deer()
	_build_berry_bushes()
	_build_mushroom_forest()


func _build_deer() -> void:
	if _villages.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 95
	var v := _villages[0]
	var count := 3 if _ram_scale() >= 1.0 else 2
	for i in count:
		var ang := rng.randf() * TAU
		var dist := rng.randf_range(120.0, 300.0)
		var x := v.x + cos(ang) * dist
		var z := v.y + sin(ang) * dist
		var h := _height_at(x, z)
		if h < 2.0 or h > 14.0:
			continue
		if _slope_at(x, z) > 0.3:
			continue
		var deer := preload("res://scripts/deer.gd").new()
		deer.name = "Deer"
		deer.set("world", self)
		deer.position = Vector3(x, h, z)
		deer.rotation_degrees = Vector3(0.0, rng.randf() * 360.0, 0.0)
		add_child(deer)

func _build_power_plants() -> void:
	_reactors.clear()
	_meltdown_done.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 50
	var main_pos := _find_plant_spot(Vector2.ZERO, 330.0, 420.0, rng.randf_range(-0.5, 0.5), rng)
	if main_pos != Vector2.ZERO:
		_spawn_plant(0, main_pos, rng)
	if _villages.size() > 1:
		var vi := rng.randi_range(1, _villages.size() - 1)
		var pos := _find_plant_spot(_villages[vi], 220.0, 300.0, rng.randf_range(-PI, PI), rng)
		if pos != Vector2.ZERO:
			_spawn_plant(_reactors.size(), pos, rng)
	if not _reactors.is_empty():
		_rebuild_terrain()
	_build_beacon()

func _find_plant_spot(vc: Vector2, min_d: float, max_d: float, ang: float, rng: RandomNumberGenerator) -> Vector2:
	for i in 80:
		var d := lerpf(min_d, max_d, rng.randf())
		var a := ang + rng.randf_range(-0.9, 0.9)
		var x := vc.x + cos(a) * d
		var z := vc.y + sin(a) * d
		if absf(x) > WORLD_SIZE * 0.48 or absf(z) > WORLD_SIZE * 0.48:
			continue
		var h := _height_at(x, z)
		if h < 2.0 or h > 14.0:
			continue
		if _slope_at(x, z) > 0.2:
			continue
		var ok := true
		for v in _villages:
			if Vector2(x, z).distance_to(v) < 140.0:
				ok = false
				break
		if not ok:
			continue
		return Vector2(x, z)
	return Vector2.ZERO

func _spawn_plant(idx: int, pos: Vector2, rng: RandomNumberGenerator) -> void:
	_flatten_heights(pos.x, pos.y, 82.0, 16.0)
	var h := _height_at(pos.x, pos.y)
	var plant := preload("res://scripts/reactor.gd").new()
	plant.setup(idx, self, rng)
	plant.position = Vector3(pos.x, h, pos.y)
	plant.rotation_degrees = Vector3(0.0, rng.randf() * TAU, 0.0)
	add_child(plant)
	_reactors.append(plant)
	if not _client:
		_make_hazmat_pickup(plant.to_global(Vector3(-26.0, 1.25, -2.6)))
		_make_charger(plant.to_global(Vector3(0.0, 0.0, 14.0)), rng)

func _build_power_grid() -> void:
	if _reactors.is_empty():
		return
	if _unit_wire_mesh == null:
		_unit_wire_mesh = _make_wire_mesh()
	var wire_mat := StandardMaterial3D.new()
	wire_mat.albedo_color = Color(0.38, 0.40, 0.46)
	wire_mat.roughness = 0.6
	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.45, 0.44, 0.42)
	pole_mat.roughness = 0.7
	var insul_mat := StandardMaterial3D.new()
	insul_mat.albedo_color = Color(0.8, 0.82, 0.86)
	insul_mat.roughness = 0.4
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 51
	var grid := Node3D.new()
	grid.name = "PowerGrid"
	add_child(grid)
	var pidx := 0
	for v in _villages:
		var best: Node3D = null
		var best_d := INF
		for r in _reactors:
			if not is_instance_valid(r):
				continue
			var rp := (r as Node3D).global_position
			var d := Vector2(rp.x, rp.z).distance_to(v)
			if d < best_d:
				best_d = d
				best = r as Node3D
		if best != null:
			var bp := best.global_position
			pidx = _build_power_line(grid, Vector2(bp.x, bp.z), v, pidx,
				wire_mat, pole_mat, insul_mat, rng)
	if _reactors.size() >= 2:
		var a := (_reactors[0] as Node3D).global_position
		var b := (_reactors[1] as Node3D).global_position
		pidx = _build_power_line(grid, Vector2(a.x, a.z), Vector2(b.x, b.z), pidx,
			wire_mat, pole_mat, insul_mat, rng)

func _build_power_line(grid: Node3D, from: Vector2, to: Vector2, pidx: int, wire_mat: Material, pole_mat: Material, insul_mat: Material, rng: RandomNumberGenerator) -> int:
	var dirv := to - from
	var len := dirv.length()
	if len < 100.0:
		return pidx
	var dn := dirv / len
	var start := from + dn * 50.0
	var end := to - dn * 70.0
	var step := clampf(len / 10.0, 40.0, 90.0)
	var n := maxi(1, int(ceil(start.distance_to(end) / step)))
	var pts: Array[Vector3] = []
	var wi := 0
	for i in range(n + 1):
		var f := float(i) / n
		var p := start.lerp(end, f)
		var h := _height_at(p.x, p.y)
		if h < -8.0 or h > 40.0:
			continue
		var pole := _make_power_pole(pole_mat, insul_mat)
		pole.name = "Pole%d" % pidx
		pidx += 1
		pole.rotation.y = atan2(-dn.x, -dn.y)
		pole.position = Vector3(p.x, h, p.y)
		grid.add_child(pole)
		pts.append(Vector3(p.x, maxf(h, 0.5) + 13.5, p.y))
	for i in range(pts.size() - 1):
		if pts[i].distance_to(pts[i + 1]) > 160.0:
			continue
		_build_wire(grid, pts[i], pts[i + 1], wire_mat, wi)
		wi += 1
	if pts.is_empty():
		return pidx
	var th := _height_at(end.x, end.y)
	var tr := _make_transformer()
	tr.name = "Transformer%d" % pidx
	tr.position = Vector3(end.x, maxf(th, 0.5), end.y)
	grid.add_child(tr)
	_build_wire(grid, pts[pts.size() - 1], Vector3(end.x, maxf(th, 0.5) + 6.0, end.y), wire_mat, wi)
	return pidx

func _make_power_pole(pole_mat: Material, insul_mat: Material) -> Node3D:
	var node := Node3D.new()
	var column := MeshInstance3D.new()
	column.mesh = _make_cylinder(0.45, 0.24, 13.5, 8, Color(0.45, 0.44, 0.42))
	column.material_override = pole_mat
	column.position = Vector3(0.0, 6.75, 0.0)
	node.add_child(column)
	var arm := MeshInstance3D.new()
	var arm_mesh := BoxMesh.new()
	arm_mesh.size = Vector3(3.2, 0.18, 0.18)
	arm.mesh = arm_mesh
	arm.position = Vector3(0.0, 12.9, 0.0)
	arm.material_override = pole_mat
	node.add_child(arm)
	for x in [-1.0, 1.0]:
		var ins := MeshInstance3D.new()
		ins.mesh = _make_cylinder(0.09, 0.09, 0.35, 8, Color(0.8, 0.82, 0.86))
		ins.material_override = insul_mat
		ins.position = Vector3(x, 13.25, 0.0)
		node.add_child(ins)
	return node

func _make_wire_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r := 0.09
	var sides := 6
	for i in sides:
		var a0 := float(i) / sides * TAU
		var a1 := float(i + 1) / sides * TAU
		var c0 := Vector2(cos(a0), sin(a0))
		var c1 := Vector2(cos(a1), sin(a1))
		var p0 := Vector3(c0.x * r, c0.y * r, -0.5)
		var p1 := Vector3(c1.x * r, c1.y * r, -0.5)
		var p2 := Vector3(c1.x * r, c1.y * r, 0.5)
		var p3 := Vector3(c0.x * r, c0.y * r, 0.5)
		var n0 := Vector3(c0.x, c0.y, 0.0)
		var n1 := Vector3(c1.x, c1.y, 0.0)
		st.set_normal(n0)
		st.add_vertex(p0)
		st.set_normal(n1)
		st.add_vertex(p1)
		st.set_normal(n1)
		st.add_vertex(p2)
		st.set_normal(n0)
		st.add_vertex(p0)
		st.set_normal(n1)
		st.add_vertex(p2)
		st.set_normal(n0)
		st.add_vertex(p3)
	return st.commit()

func _build_wire(parent: Node, a: Vector3, b: Vector3, mat: Material, wi: int) -> void:
	var mid := (a + b) * 0.5
	mid.y -= a.distance_to(b) * 0.09
	var n := 4
	for i in n:
		var t0 := float(i) / n
		var t1 := float(i + 1) / n
		var pa := _bez_point(a, mid, b, t0)
		var pb := _bez_point(a, mid, b, t1)
		var dir := (pb - pa).normalized()
		var up := Vector3.UP
		if absf(dir.dot(up)) > 0.99:
			up = Vector3.FORWARD
		var seg := MeshInstance3D.new()
		seg.name = "Wire%d_%d" % [wi, i]
		seg.mesh = _unit_wire_mesh
		seg.basis = Basis.looking_at(dir, up)
		seg.position = (pa + pb) * 0.5
		seg.scale.z = pa.distance_to(pb)
		seg.material_override = mat
		parent.add_child(seg)

func _bez_point(a: Vector3, c: Vector3, b: Vector3, t: float) -> Vector3:
	var u := 1.0 - t
	return a * (u * u) + c * (2.0 * u * t) + b * (t * t)

func _make_transformer() -> Node3D:
	var node := Node3D.new()
	var base := MeshInstance3D.new()
	base.mesh = _make_cylinder(0.6, 0.6, 1.2, 8, Color(0.42, 0.44, 0.48))
	base.position = Vector3(0.0, 0.6, 0.0)
	node.add_child(base)
	var top := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.0, 1.0, 0.9)
	top.mesh = bm
	top.position = Vector3(0.0, 1.9, 0.0)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.55, 0.57, 0.62)
	m.roughness = 0.6
	top.material_override = m
	node.add_child(top)
	for x in [-0.3, 0.3]:
		var bushing := MeshInstance3D.new()
		bushing.mesh = _make_cylinder(0.07, 0.07, 0.5, 8, Color(0.85, 0.86, 0.9))
		bushing.position = Vector3(x, 2.5, 0.0)
		node.add_child(bushing)
	return node

func _on_reactor_meltdown(idx: int, pos: Vector3) -> void:
	if _meltdown_done.has(idx):
		return
	_meltdown_done[idx] = true
	_crater_terrain(pos.x, pos.z, 55.0, 13.0)
	if _player and not _client and _player.global_position.distance_to(pos) < 260.0:
		_post_chat("ALARM", "A reactor just exploded nearby! Radiation zone active.")
	if not _client:
		_apply_blast(pos, 170.0, 90)

func _apply_blast(center: Vector3, radius: float, max_dmg: int) -> void:
	var targets: Array[Node3D] = []
	if _player:
		targets.append(_player)
	if _server:
		for id in _net_players:
			var p: Node3D = _net_players[id]
			if p != null:
				targets.append(p)
	var npcs: Array = get_tree().get_nodes_in_group("npc")
	var zombies: Array = get_tree().get_nodes_in_group("zombies")
	for n in npcs:
		targets.append(n as Node3D)
	for z in zombies:
		targets.append(z as Node3D)
	for t in targets:
		if t == null or not is_instance_valid(t):
			continue
		var d := t.global_position.distance_to(center)
		if d >= radius:
			continue
		var dmg := int(round(float(max_dmg) * (1.0 - d / radius)))
		if t.has_method("hit"):
			t.call("hit", dmg)

func _flatten_heights(cx: float, cz: float, radius: float, blend: float) -> void:
	if _grid <= 0:
		return
	var target := _height_at(cx, cz)
	var flat_r := maxf(1.0, radius - blend)
	var i0 := _axis_index(cx - radius)
	var i1 := clampi(_axis_index(cx + radius) + 1, i0, _grid - 1)
	var j0 := _axis_index(cz - radius)
	var j1 := clampi(_axis_index(cz + radius) + 1, j0, _grid - 1)
	for iz in range(j0, j1 + 1):
		var wz := _x_at(iz)
		for ix in range(i0, i1 + 1):
			var wx := _x_at(ix)
			var d := Vector2(wx, wz).distance_to(Vector2(cx, cz))
			if d >= radius:
				continue
			var f := 1.0
			if d > flat_r:
				f = 1.0 - (d - flat_r) / (radius - flat_r)
			var idx := iz * _grid + ix
			_heights[idx] = lerpf(_heights[idx], target, clampf(f, 0.0, 1.0))


func _carve_heights(cx: float, cz: float, radius: float, depth: float) -> void:
	if _grid <= 0:
		return
	var i0 := _axis_index(cx - radius)
	var i1 := clampi(_axis_index(cx + radius) + 1, i0, _grid - 1)
	var j0 := _axis_index(cz - radius)
	var j1 := clampi(_axis_index(cz + radius) + 1, j0, _grid - 1)
	for iz in range(j0, j1 + 1):
		var wz := _x_at(iz)
		for ix in range(i0, i1 + 1):
			var wx := _x_at(ix)
			var d := Vector2(wx, wz).distance_to(Vector2(cx, cz))
			if d >= radius:
				continue
			var f := 1.0 - d / radius
			f = f * f
			var idx := iz * _grid + ix
			_heights[idx] = maxf(-7.0, _heights[idx] - depth * f)


func _axis_index(v: float) -> int:
	if _grid <= 0:
		return 0
	var hi := _grid - 1
	if v >= _x_at(hi):
		return hi
	var lo := 0
	while lo < hi:
		var mid := (lo + hi) >> 1
		if _x_at(mid) >= v:
			hi = mid
		else:
			lo = mid + 1
	return maxi(0, lo - 1)


func _ground_height(wx: float, wz: float) -> float:
	if _grid < 2:
		return _height_at(wx, wz)
	var i0 := clampi(_axis_index(wx), 0, _grid - 2)
	var j0 := clampi(_axis_index(wz), 0, _grid - 2)
	var i1 := i0 + 1
	var j1 := j0 + 1
	var x0 := _x_at(i0)
	var x1 := _x_at(i1)
	var z0 := _x_at(j0)
	var z1 := _x_at(j1)
	var fw := 0.0
	var fz := 0.0
	if x1 != x0:
		fw = (wx - x0) / (x1 - x0)
	if z1 != z0:
		fz = (wz - z0) / (z1 - z0)
	var h00 := _heights[j0 * _grid + i0]
	var h10 := _heights[j0 * _grid + i1]
	var h01 := _heights[j1 * _grid + i0]
	var h11 := _heights[j1 * _grid + i1]
	var h0 := lerpf(h00, h10, fw)
	var h1 := lerpf(h01, h11, fw)
	return lerpf(h0, h1, fz)


func _crater_terrain(cx: float, cz: float, radius: float, depth: float) -> void:
	if _grid <= 0:
		return
	for iz in _grid:
		var wz := _x_at(iz)
		for ix in _grid:
			var wx := _x_at(ix)
			var d := Vector2(wx, wz).distance_to(Vector2(cx, cz))
			if d >= radius:
				continue
			var f := 1.0 - d / radius
			f = f * f
			var idx := iz * _grid + ix
			_heights[idx] = maxf(-7.0, _heights[idx] - depth * f)
	_rebuild_terrain()

func _rebuild_terrain() -> void:
	if _defer_terrain:
		_terrain_dirty = true
		return
	for c in get_children():
		if c.name == "TerrainMesh" or c.name == "TerrainBody":
			c.queue_free()
	_build_terrain_nodes()


func _flush_terrain() -> void:
	_defer_terrain = false
	if _terrain_dirty:
		_terrain_dirty = false
		_build_terrain_nodes()

func _build_terrain_nodes() -> void:
	var normals := _grid_normals()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in _grid:
		var wz := _x_at(iz)
		for ix in _grid:
			var idx := iz * _grid + ix
			var slope := 1.0 - clampf(normals[idx].y, 0.0, 1.0)
			st.set_normal(normals[idx])
			st.set_color(_terrain_color(_heights[idx], slope, _x_at(ix), wz))
			st.add_vertex(Vector3(_x_at(ix), _heights[idx], wz))
	for iz in _grid - 1:
		for ix in _grid - 1:
			var a := iz * _grid + ix
			var b := a + 1
			var c := (iz + 1) * _grid + ix
			var d := c + 1
			st.add_index(a)
			st.add_index(b)
			st.add_index(c)
			st.add_index(b)
			st.add_index(d)
			st.add_index(c)
	var array := st.commit()
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/terrain.gdshader")
	var mi := MeshInstance3D.new()
	mi.name = "TerrainMesh"
	mi.mesh = array
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mi)
	var body := StaticBody3D.new()
	body.name = "TerrainBody"
	var shape := CollisionShape3D.new()
	shape.shape = _make_terrain_collision()
	body.add_child(shape)
	add_child(body)

func _place_structures(rng: RandomNumberGenerator, center: Vector2, builder: Callable, min_d: float, max_d: float, count: int) -> void:
	var placed := 0
	var tries := 0
	while placed < count and tries < 500:
		tries += 1
		var ang := rng.randf() * TAU
		var dist := rng.randf_range(min_d, max_d)
		var x := center.x + cos(ang) * dist
		var z := center.y + sin(ang) * dist
		var h := _height_at(x, z)
		if h < 1.0 or h > 12.0:
			continue
		if _slope_at(x, z) > 0.4:
			continue
		var clear := true
		for hs in get_tree().get_nodes_in_group("houses"):
			if Vector2(x, z).distance_to(Vector2((hs as Node3D).global_position.x, (hs as Node3D).global_position.z)) < 14.0:
				clear = false
				break
		if not clear:
			continue
		var node := builder.call() as Node3D
		if node == null:
			return
		node.name = "%s%d" % [String(builder.get_method()).trim_prefix("_make_"), placed]
		node.position = Vector3(x, h, z)
		node.rotation_degrees = Vector3(0.0, rng.randf() * 360.0, 0.0)
		add_child(node)
		placed += 1

func _make_cone_mesh(radius: float, height: float, col: Color, sides: int = 8) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_cone(st, Vector3.ZERO, radius, height, sides, col)
	return st.commit()

func _make_pagoda() -> Node3D:
	var node := Node3D.new()
	node.name = "Pagoda"
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.52, 0.34, 0.22)
	body_mat.roughness = 0.9
	var roof_mat := StandardMaterial3D.new()
	roof_mat.vertex_color_use_as_albedo = true
	roof_mat.roughness = 0.85
	roof_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var dark := Color(0.44, 0.29, 0.23)

	var tier_box := BoxMesh.new()
	tier_box.size = Vector3(3.0, 1.2, 3.0)
	var tier := MeshInstance3D.new()
	tier.mesh = tier_box
	tier.position = Vector3(0.0, 0.6, 0.0)
	tier.material_override = body_mat
	node.add_child(tier)
	var roof := MeshInstance3D.new()
	roof.mesh = _make_cone_mesh(2.4, 1.7, dark, 8)
	roof.position = Vector3(0.0, 1.2, 0.0)
	roof.material_override = roof_mat
	node.add_child(roof)

	var tier_box2 := BoxMesh.new()
	tier_box2.size = Vector3(2.4, 1.0, 2.4)
	var tier2 := MeshInstance3D.new()
	tier2.mesh = tier_box2
	tier2.position = Vector3(0.0, 3.4, 0.0)
	tier2.material_override = body_mat
	node.add_child(tier2)
	var roof2 := MeshInstance3D.new()
	roof2.mesh = _make_cone_mesh(1.9, 1.4, dark, 8)
	roof2.position = Vector3(0.0, 3.9, 0.0)
	roof2.material_override = roof_mat
	node.add_child(roof2)

	var tier_box3 := BoxMesh.new()
	tier_box3.size = Vector3(1.8, 0.8, 1.8)
	var tier3 := MeshInstance3D.new()
	tier3.mesh = tier_box3
	tier3.position = Vector3(0.0, 5.7, 0.0)
	tier3.material_override = body_mat
	node.add_child(tier3)
	var roof3 := MeshInstance3D.new()
	roof3.mesh = _make_cone_mesh(1.3, 1.0, dark, 8)
	roof3.position = Vector3(0.0, 6.1, 0.0)
	roof3.material_override = roof_mat
	node.add_child(roof3)

	var fin := MeshInstance3D.new()
	fin.mesh = _make_cone_mesh(0.2, 0.9, dark, 8)
	fin.position = Vector3(0.0, 7.1, 0.0)
	fin.material_override = roof_mat
	node.add_child(fin)

	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(3.0, 1.2, 3.0)
	col.shape = bs
	col.position = Vector3(0.0, 0.6, 0.0)
	body.add_child(col)
	var col2 := CollisionShape3D.new()
	var bs2 := BoxShape3D.new()
	bs2.size = Vector3(2.4, 1.0, 2.4)
	col2.shape = bs2
	col2.position = Vector3(0.0, 3.4, 0.0)
	body.add_child(col2)
	var col3 := CollisionShape3D.new()
	var bs3 := BoxShape3D.new()
	bs3.size = Vector3(1.8, 0.8, 1.8)
	col3.shape = bs3
	col3.position = Vector3(0.0, 5.7, 0.0)
	body.add_child(col3)
	node.add_child(body)
	return node

func _make_stone_shrine() -> Node3D:
	var node := Node3D.new()
	node.name = "StoneShrine"
	var slab_mat := StandardMaterial3D.new()
	slab_mat.vertex_color_use_as_albedo = true
	slab_mat.roughness = 1.0
	var slab := MeshInstance3D.new()
	slab.mesh = _make_cylinder(1.5, 1.5, 0.35, 10, Color(0.55, 0.54, 0.52))
	slab.position = Vector3(0.0, 0.175, 0.0)
	slab.material_override = slab_mat
	node.add_child(slab)
	var lamp_mat := StandardMaterial3D.new()
	lamp_mat.vertex_color_use_as_albedo = true
	lamp_mat.roughness = 0.95
	for i in 4:
		var ang := TAU * float(i) / 4.0 + 0.4
		var lamp := MeshInstance3D.new()
		lamp.mesh = _make_lantern_mesh()
		lamp.scale = Vector3.ONE * 0.7
		lamp.position = Vector3(cos(ang) * 2.1, 0.35, sin(ang) * 2.1)
		lamp.material_override = lamp_mat
		node.add_child(lamp)
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var bs := CylinderShape3D.new()
	bs.radius = 1.5
	bs.height = 0.35
	col.shape = bs
	col.position = Vector3(0.0, 0.175, 0.0)
	body.add_child(col)
	var lamp_col_shape := CylinderShape3D.new()
	lamp_col_shape.radius = 0.4
	lamp_col_shape.height = 1.5
	for i in 4:
		var ang := TAU * float(i) / 4.0 + 0.4
		var lc := CollisionShape3D.new()
		lc.shape = lamp_col_shape
		lc.position = Vector3(cos(ang) * 2.1, 0.85, sin(ang) * 2.1)
		body.add_child(lc)
	node.add_child(body)
	return node

func _make_campfire() -> Node3D:
	var node := Node3D.new()
	node.name = "Campfire"
	var stone_mat := StandardMaterial3D.new()
	stone_mat.vertex_color_use_as_albedo = true
	stone_mat.roughness = 1.0
	for i in 8:
		var ang := TAU * float(i) / 8.0
		var rock := MeshInstance3D.new()
		rock.mesh = _make_cylinder(0.14, 0.10, 0.3, 6, Color(0.5, 0.5, 0.48))
		rock.position = Vector3(cos(ang) * 0.9, 0.15, sin(ang) * 0.9)
		rock.material_override = stone_mat
		node.add_child(rock)
	var log_mat := StandardMaterial3D.new()
	log_mat.albedo_color = Color(0.38, 0.26, 0.16)
	log_mat.roughness = 1.0
	for i in 4:
		var ang := TAU * float(i) / 4.0 + 0.5
		var log := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(0.5, 0.16, 0.12)
		log.mesh = lm
		log.position = Vector3(cos(ang) * 0.35, 0.24, sin(ang) * 0.35)
		log.material_override = log_mat
		node.add_child(log)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.55, 0.2)
	light.light_energy = 2.0
	light.omni_range = 8.0
	light.shadow_enabled = false
	light.position = Vector3(0.0, 0.7, 0.0)
	node.add_child(light)
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var bs := CylinderShape3D.new()
	bs.radius = 1.0
	bs.height = 0.5
	col.shape = bs
	col.position = Vector3(0.0, 0.25, 0.0)
	body.add_child(col)
	node.add_child(body)
	return node

func _make_well() -> Node3D:
	var node := Node3D.new()
	node.name = "Well"
	node.add_to_group("wells")
	var stone_mat := StandardMaterial3D.new()
	stone_mat.vertex_color_use_as_albedo = true
	stone_mat.roughness = 1.0
	stone_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in 10:
		var ang := TAU * float(i) / 10.0
		for r in 2:
			var block := MeshInstance3D.new()
			block.mesh = _make_cylinder(0.18, 0.16, 0.4, 6, Color(0.55, 0.54, 0.52))
			block.position = Vector3(cos(ang) * 1.1, 0.2 + r * 0.4, sin(ang) * 1.1)
			block.material_override = stone_mat
			node.add_child(block)
	var post_mat := StandardMaterial3D.new()
	post_mat.albedo_color = Color(0.45, 0.30, 0.18)
	post_mat.roughness = 0.9
	for side in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.18, 1.6, 0.18)
		post.mesh = pm
		post.position = Vector3(side * 1.05, 0.8, 0.0)
		post.material_override = post_mat
		node.add_child(post)
	var roof := MeshInstance3D.new()
	roof.mesh = _make_cone_mesh(1.5, 0.7, Color(0.45, 0.30, 0.18), 6)
	roof.position = Vector3(0.0, 1.6, 0.0)
	roof.material_override = stone_mat
	node.add_child(roof)
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var bs := CylinderShape3D.new()
	bs.radius = 1.2
	bs.height = 0.8
	col.shape = bs
	col.position = Vector3(0.0, 0.4, 0.0)
	body.add_child(col)
	var post_col_shape := BoxShape3D.new()
	post_col_shape.size = Vector3(0.18, 1.6, 0.18)
	for side in [-1.0, 1.0]:
		var pc := CollisionShape3D.new()
		pc.shape = post_col_shape
		pc.position = Vector3(side * 1.05, 0.8, 0.0)
		body.add_child(pc)
	node.add_child(body)
	return node

func _make_stall(good := 0) -> Node3D:
	var node := Node3D.new()
	node.name = "MarketStall"
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.55, 0.36, 0.22)
	wood_mat.roughness = 0.95
	var roof_mat := StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.75, 0.20, 0.16)
	roof_mat.roughness = 0.85
	roof_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	for corner in [Vector3(-1.4, 0.0, -0.9), Vector3(1.4, 0.0, -0.9), Vector3(-1.4, 0.0, 0.9), Vector3(1.4, 0.0, 0.9)]:
		var post := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.12, 2.0, 0.12)
		post.mesh = pm
		post.position = corner + Vector3(0.0, 1.0, 0.0)
		post.material_override = wood_mat
		node.add_child(post)
	var counter := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(3.0, 0.1, 0.7)
	counter.mesh = cm
	counter.position = Vector3(0.0, 1.05, 0.4)
	counter.material_override = wood_mat
	node.add_child(counter)
	var awning := MeshInstance3D.new()
	var am := BoxMesh.new()
	am.size = Vector3(3.4, 0.1, 1.5)
	awning.mesh = am
	awning.position = Vector3(0.0, 2.0, -0.3)
	awning.rotation_degrees = Vector3(-20.0, 0.0, 0.0)
	awning.material_override = roof_mat
	node.add_child(awning)
	var body := StaticBody3D.new()
	body.set_script(preload("res://scripts/market_stall.gd"))
	body.set("world", self)
	body.set_meta("good", good)
	body.collision_layer = 2
	var post_col := BoxShape3D.new()
	post_col.size = Vector3(0.12, 2.0, 0.12)
	for corner in [Vector3(-1.4, 0.0, -0.9), Vector3(1.4, 0.0, -0.9), Vector3(-1.4, 0.0, 0.9), Vector3(1.4, 0.0, 0.9)]:
		var pc := CollisionShape3D.new()
		pc.shape = post_col
		pc.position = corner + Vector3(0.0, 1.0, 0.0)
		body.add_child(pc)
	var counter_col := CollisionShape3D.new()
	var cs := BoxShape3D.new()
	cs.size = Vector3(3.0, 0.1, 0.7)
	counter_col.shape = cs
	counter_col.position = Vector3(0.0, 1.05, 0.4)
	body.add_child(counter_col)
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.5, 0.9, 0.5)
	col.shape = bs
	col.position = Vector3(0.0, 0.45, 0.0)
	body.add_child(col)
	node.add_child(body)
	var good_names := ["MEDKIT — 1 FISH", "AMMO — 2 FISH", "GUN — 3 FISH"]
	var good_colors := [Color(0.9, 0.32, 0.32), Color(0.72, 0.55, 0.22), Color(0.13, 0.13, 0.15)]
	var sign := Label3D.new()
	sign.text = good_names[good]
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.modulate = Color(1, 1, 1, 0.95)
	sign.outline_modulate = Color(0, 0, 0, 0.85)
	sign.outline_size = 10
	sign.pixel_size = 0.0045
	sign.font_size = 40
	sign.position = Vector3(0.0, 2.5, -0.3)
	node.add_child(sign)
	var board_mat := StandardMaterial3D.new()
	board_mat.albedo_color = good_colors[good]
	board_mat.roughness = 0.6
	board_mat.emission_enabled = true
	board_mat.emission = good_colors[good]
	board_mat.emission_energy_multiplier = 0.5
	var board := MeshInstance3D.new()
	var bm2 := BoxMesh.new()
	bm2.size = Vector3(2.6, 0.35, 0.06)
	board.mesh = bm2
	board.material_override = board_mat
	board.position = Vector3(0.0, 2.55, -0.35)
	node.add_child(board)
	return node

func _build_market(center: Vector2, count: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 22 + int(center.x * 7.31 + center.y * 3.71)
	var placed := 0
	var tries := 0
	while placed < count and tries < 200:
		tries += 1
		var ang := rng.randf() * TAU
		var dist := rng.randf_range(8.0, 18.0)
		var x := center.x + cos(ang) * dist
		var z := center.y + sin(ang) * dist
		var h := _height_at(x, z)
		if h < 1.0 or h > 6.0:
			continue
		if _slope_at(x, z) > 0.25:
			continue
		var stall := _make_stall(placed % 3)
		stall.name = "MarketStall%d" % placed
		stall.position = Vector3(x, h, z)
		stall.rotation_degrees = Vector3(0.0, rng.randf() * 360.0, 0.0)
		add_child(stall)
		placed += 1

func _build_shrine(center: Vector2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 23 + int(center.x * 5.13 + center.y * 9.41)
	var spot := Vector2.ZERO
	for i in 120:
		var ang := rng.randf_range(-0.7, 0.7)
		var dist := rng.randf_range(520.0, 650.0)
		var x := center.x + cos(ang) * dist
		var z := center.y + sin(ang) * dist
		var h := _height_at(x, z)
		if h < 2.0 or h > 22.0:
			continue
		if _slope_at(x, z) > 0.22:
			continue
		spot = Vector2(x, z)
		break
	if spot == Vector2.ZERO:
		return
	var ground := _height_at(spot.x, spot.y)
	var grp := Node3D.new()
	grp.name = "EastShrine"
	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.5, 0.48, 0.44)
	stone_mat.roughness = 0.95
	var podium := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 4.2
	pm.bottom_radius = 4.8
	pm.height = 1.4
	podium.mesh = pm
	podium.material_override = stone_mat
	podium.position = Vector3(0.0, 0.7, 0.0)
	grp.add_child(podium)
	var inner := MeshInstance3D.new()
	var im := CylinderMesh.new()
	im.top_radius = 2.2
	im.bottom_radius = 2.2
	im.height = 0.8
	inner.mesh = im
	inner.material_override = stone_mat
	inner.position = Vector3(0.0, 1.5, 0.0)
	grp.add_child(inner)
	var orb_mat := StandardMaterial3D.new()
	orb_mat.albedo_color = Color(0.35, 0.65, 1.0)
	orb_mat.roughness = 0.1
	orb_mat.metallic = 0.4
	orb_mat.emission_enabled = true
	orb_mat.emission = Color(0.3, 0.6, 1.0)
	orb_mat.emission_energy_multiplier = 0.9
	var orb := MeshInstance3D.new()
	var osm := SphereMesh.new()
	osm.radius = 0.55
	osm.height = 1.1
	orb.mesh = osm
	orb.material_override = orb_mat
	orb.position = Vector3(0.0, 2.2, 0.0)
	grp.add_child(orb)
	var torch_mat := StandardMaterial3D.new()
	torch_mat.albedo_color = Color(0.55, 0.26, 0.18)
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var post := MeshInstance3D.new()
		var pom := CylinderMesh.new()
		pom.top_radius = 0.18
		pom.bottom_radius = 0.18
		pom.height = 4.2
		post.mesh = pom
		post.material_override = torch_mat
		post.position = Vector3(side * 4.6, 2.1, 3.2)
		grp.add_child(post)
		var flame_mat := StandardMaterial3D.new()
		flame_mat.albedo_color = Color(1.0, 0.7, 0.25)
		flame_mat.emission_enabled = true
		flame_mat.emission = Color(1.0, 0.55, 0.15)
		flame_mat.emission_energy_multiplier = 1.2
		var flame := MeshInstance3D.new()
		var fm := SphereMesh.new()
		fm.radius = 0.16
		fm.height = 0.32
		flame.mesh = fm
		flame.material_override = flame_mat
		flame.position = Vector3(side * 4.6, 4.25, 3.2)
		grp.add_child(flame)
	var gate_mat := StandardMaterial3D.new()
	gate_mat.albedo_color = Color(0.62, 0.16, 0.14)
	gate_mat.roughness = 0.7
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var post := MeshInstance3D.new()
		var pom := CylinderMesh.new()
		pom.top_radius = 0.28
		pom.bottom_radius = 0.28
		pom.height = 6.0
		post.mesh = pom
		post.material_override = gate_mat
		post.position = Vector3(side * 2.6, 3.0, -7.5)
		grp.add_child(post)
	var beam := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.26
	bm.bottom_radius = 0.26
	bm.height = 6.6
	beam.mesh = bm
	beam.material_override = gate_mat
	beam.position = Vector3(0.0, 5.6, -7.5)
	grp.add_child(beam)
	var lam := MeshInstance3D.new()
	var lm := CylinderMesh.new()
	lm.top_radius = 0.2
	lm.bottom_radius = 0.2
	lm.height = 5.2
	lam.mesh = lm
	lam.material_override = gate_mat
	lam.position = Vector3(0.0, 5.5, -7.5)
	lam.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	grp.add_child(lam)
	var glow := OmniLight3D.new()
	glow.name = "ShrineGlow"
	glow.light_color = Color(0.4, 0.7, 1.0)
	glow.light_energy = 0.0
	glow.omni_range = 26.0
	glow.position = Vector3(0.0, 2.4, 0.0)
	grp.add_child(glow)
	grp.set_meta("glow", glow)
	var body := StaticBody3D.new()
	body.name = "ShrineInteract"
	var col := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = 3.0
	cs.height = 4.0
	col.shape = cs
	col.position = Vector3(0.0, 2.0, 0.0)
	body.add_child(col)
	body.set_script(preload("res://scripts/shrine.gd"))
	body.world = self
	grp.add_child(body)
	grp.position = Vector3(spot.x, ground, spot.y)
	add_child(grp)
	_shrine = grp


func _use_shrine() -> void:
	if _shrine == null:
		return
	var day := int(floor(_time_of_day / 24.0))
	if day == _shrine_used_day:
		_alert("Shrine", "The spirits have already blessed you today.")
		return
	if _player == null or not is_instance_valid(_player):
		return
	if _player.global_position.distance_to(_shrine.global_position) > 7.0:
		return
	_shrine_used_day = day
	_player.health = minf(_player.health + 25.0, _player.max_health)
	var day_str := "day"
	if fmod(_time_of_day, 24.0) >= 19.0 or fmod(_time_of_day, 24.0) < 5.0:
		day_str = "night"
	_alert("Shrine", "The old spirits mend your wounds. (+25 HP)")
	_broadcast_chat("Shrine", "The shrine's light heals you for the " + day_str + ".")
	_complete_task("shrine", "Received the east shrine's blessing")


func _shrine_guards(pos: Vector3) -> bool:
	return _shrine != null and is_instance_valid(_shrine) and _shrine.global_position.distance_to(pos) < 9.0


func _tick_shrine(delta: float) -> void:
	if _shrine == null or not is_instance_valid(_shrine):
		return
	var glow := _shrine.get_meta("glow") as OmniLight3D
	var target := (1.6 + sin(Time.get_ticks_msec() / 1000.0 * 1.3) * 0.3) if _is_night() else 0.0
	glow.light_energy = lerpf(glow.light_energy, target, minf(delta * 3.0, 1.0))


func _build_windmill(center: Vector2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 94
	var spot := Vector2.ZERO
	for i in 140:
		var ang := rng.randf_range(-2.9, -0.4)
		var dist := rng.randf_range(55.0, 95.0)
		var x := center.x + cos(ang) * dist
		var z := center.y + sin(ang) * dist
		var h := _height_at(x, z)
		if h < 1.5 or h > 16.0:
			continue
		if _slope_at(x, z) > 0.18:
			continue
		spot = Vector2(x, z)
		break
	if spot == Vector2.ZERO:
		return
	var ground := _height_at(spot.x, spot.y)
	var grp := Node3D.new()
	grp.name = "Windmill"
	var tower_mat := StandardMaterial3D.new()
	tower_mat.albedo_color = Color(0.78, 0.68, 0.52)
	tower_mat.roughness = 0.95
	var roof_mat := StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.55, 0.3, 0.2)
	roof_mat.roughness = 0.8
	var blade_mat := StandardMaterial3D.new()
	blade_mat.albedo_color = Color(0.62, 0.56, 0.46)
	blade_mat.roughness = 0.9
	var tower := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 1.5
	tm.bottom_radius = 2.6
	tm.height = 9.0
	tower.mesh = tm
	tower.material_override = tower_mat
	tower.position = Vector3(0.0, 4.5, 0.0)
	grp.add_child(tower)
	var band := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 2.05
	bm.bottom_radius = 2.05
	bm.height = 0.5
	band.mesh = bm
	band.material_override = roof_mat
	band.position = Vector3(0.0, 9.2, 0.0)
	grp.add_child(band)
	var roof := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 0.3
	rm.bottom_radius = 2.1
	rm.height = 2.2
	roof.mesh = rm
	roof.material_override = roof_mat
	roof.position = Vector3(0.0, 10.4, 0.0)
	grp.add_child(roof)
	var door_mat := StandardMaterial3D.new()
	door_mat.albedo_color = Color(0.35, 0.25, 0.16)
	var door := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(1.0, 1.8, 0.12)
	door.mesh = dm
	door.material_override = door_mat
	door.position = Vector3(0.0, 0.9, 1.62)
	grp.add_child(door)
	var hub := Node3D.new()
	hub.name = "WindmillBlades"
	hub.position = Vector3(0.0, 9.2, 0.0)
	hub.rotation_degrees = Vector3(0.0, rng.randf() * 360.0, 0.0)
	grp.add_child(hub)
	for i in 4:
		var ang := i * PI / 2.0
		var blade := MeshInstance3D.new()
		var bld := BoxMesh.new()
		bld.size = Vector3(0.35, 4.2, 0.1)
		blade.mesh = bld
		blade.material_override = blade_mat
		blade.position = Vector3(cos(ang) * 2.1, sin(ang) * 2.1, 0.0)
		blade.rotation.z = ang
		blade.scale = Vector3(1.0, 1.0, 1.0)
		hub.add_child(blade)
	grp.position = Vector3(spot.x, ground, spot.y)
	add_child(grp)
	_windmill_blades = hub


func _tick_windmill(delta: float) -> void:
	if _windmill_blades == null or not is_instance_valid(_windmill_blades):
		return
	_windmill_ang += delta * (0.3 + _wind_speed * 1.6)
	_windmill_blades.rotation.z = _windmill_ang

func _build_villages() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 40
	_villages.clear()
	_villages.append(Vector2.ZERO)
	_village_window_mats = []
	_village_powered = []
	_village_outage = []
	var target := mini(int(1.0 + 2.0 * clampf(_ram_scale(), 0.5, 2.0)), 4)
	var tries := 0
	while _villages.size() <= target and tries < 300:
		tries += 1
		var ang := rng.randf() * TAU
		var dist := rng.randf_range(VILLAGE_MIN_DIST, VILLAGE_MAX_DIST)
		var x := cos(ang) * dist
		var z := sin(ang) * dist
		var h := _height_at(x, z)
		if h < 1.0 or h > 12.0:
			continue
		if _slope_at(x, z) > 0.25:
			continue
		var far := true
		for v in _villages:
			if Vector2(x, z).distance_to(v) < VILLAGE_MIN_DIST:
				far = false
				break
		if not far:
			continue
		_villages.append(Vector2(x, z))
	for _vi in _villages.size():
		_village_window_mats.append([])
		_village_powered.append(true)
		_village_outage.append(0.0)
	_build_village_lamps()
	_build_village_dressing()
	_build_cats()
	_build_dogs()
	_build_bell_tower()


func _build_village_lamps() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 93
	_village_lamps = []
	for vi in _villages.size():
		var v := _villages[vi]
		var village_mats: Array = []
		var post_mat := StandardMaterial3D.new()
		post_mat.albedo_color = Color(0.2, 0.2, 0.22)
		post_mat.roughness = 0.8
		var lamp_mat := StandardMaterial3D.new()
		lamp_mat.albedo_color = Color(1.0, 0.88, 0.55)
		lamp_mat.emission_enabled = true
		lamp_mat.emission = Color(0.0, 0.0, 0.0)
		var count := 4 if vi == 0 else 2
		for i in count:
			var ang := rng.randf() * TAU
			var dist := rng.randf_range(8.0, 16.0)
			var x := v.x + cos(ang) * dist
			var z := v.y + sin(ang) * dist
			var h := _height_at(x, z)
			if h < 0.5 or h > 10.0:
				continue
			var lamp := Node3D.new()
			lamp.name = "StreetLamp"
			lamp.position = Vector3(x, h, z)
			var post := MeshInstance3D.new()
			var pm := CylinderMesh.new()
			pm.top_radius = 0.09
			pm.bottom_radius = 0.13
			pm.height = 4.4
			post.mesh = pm
			post.material_override = post_mat
			post.position = Vector3(0.0, 2.2, 0.0)
			lamp.add_child(post)
			var arm := MeshInstance3D.new()
			var am := BoxMesh.new()
			am.size = Vector3(0.75, 0.08, 0.08)
			arm.mesh = am
			arm.material_override = post_mat
			arm.position = Vector3(0.35, 4.3, 0.0)
			lamp.add_child(arm)
			var head := MeshInstance3D.new()
			var hm := SphereMesh.new()
			hm.radius = 0.22
			hm.height = 0.4
			head.mesh = hm
			head.material_override = lamp_mat
			head.position = Vector3(0.72, 4.35, 0.0)
			lamp.add_child(head)
			add_child(lamp)
			village_mats.append(lamp_mat)
		_village_lamps.append(village_mats)


func _build_village_dressing() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 137
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.6, 0.6, 0.62)
	stone.roughness = 0.95
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.28, 0.28, 0.30)
	dark.roughness = 1.0
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.5, 0.36, 0.2)
	wood.roughness = 0.9
	var barrel_mat := StandardMaterial3D.new()
	barrel_mat.albedo_color = Color(0.42, 0.30, 0.17)
	barrel_mat.roughness = 0.95
	var band_mat := StandardMaterial3D.new()
	band_mat.albedo_color = Color(0.25, 0.25, 0.27)
	band_mat.roughness = 0.6
	for vi in _villages.size():
		var v := _villages[vi]
		if vi == 0:
			var wa := 0.7
			var wx := v.x + cos(wa) * 6.5
			var wz := v.y + sin(wa) * 6.5
			var wh := _height_at(wx, wz)
			if wh >= 0.5 and wh <= 9.0:
				_place_well(Vector3(wx, wh, wz), stone, dark, wood)
		for b in (3 if vi == 0 else 2):
			var ang := rng.randf() * TAU
			var dist := rng.randf_range(7.0, 11.0)
			var x := v.x + cos(ang) * dist
			var z := v.y + sin(ang) * dist
			var h := _height_at(x, z)
			if h < 0.5 or h > 9.0:
				continue
			_place_bench(Vector3(x, h, z), rng.randf() * TAU, wood)
		for br in (4 if vi == 0 else 2):
			var ang := rng.randf() * TAU
			var dist := rng.randf_range(6.0, 13.0)
			var x := v.x + cos(ang) * dist
			var z := v.y + sin(ang) * dist
			var h := _height_at(x, z)
			if h < 0.5 or h > 9.0:
				continue
			_place_barrel(Vector3(x, h, z), barrel_mat, band_mat)


func _place_well(pos: Vector3, stone: StandardMaterial3D, dark: StandardMaterial3D, wood: StandardMaterial3D) -> void:
	var well := StaticBody3D.new()
	well.name = "Well"
	well.position = pos
	var ring := MeshInstance3D.new()
	ring.mesh = _make_cylinder(1.05, 0.85, 1.0, 14, Color(0.62, 0.62, 0.64))
	ring.material_override = stone
	ring.position = Vector3(0.0, 0.5, 0.0)
	well.add_child(ring)
	var dark_disc := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = 0.8
	dm.bottom_radius = 0.8
	dm.height = 0.3
	dark_disc.mesh = dm
	dark_disc.material_override = dark
	dark_disc.position = Vector3(0.0, 0.68, 0.0)
	well.add_child(dark_disc)
	for side in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		post.mesh = _make_cylinder(0.07, 0.07, 2.4, 8, Color(0.42, 0.28, 0.15))
		post.material_override = wood
		post.position = Vector3(1.1 * side, 1.2, 0.0)
		well.add_child(post)
	var roof := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 0.1
	rm.bottom_radius = 1.5
	rm.height = 0.35
	roof.mesh = rm
	roof.material_override = wood
	roof.position = Vector3(0.0, 2.5, 0.0)
	well.add_child(roof)
	var bucket := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.14
	bm.bottom_radius = 0.16
	bm.height = 0.3
	bucket.mesh = bm
	bucket.material_override = dark
	bucket.position = Vector3(0.0, 1.45, 0.0)
	well.add_child(bucket)
	var col := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = 1.0
	cs.height = 1.6
	col.shape = cs
	col.position = Vector3(0.0, 0.8, 0.0)
	well.add_child(col)
	add_child(well)


func _place_bench(pos: Vector3, yaw: float, wood: StandardMaterial3D) -> void:
	var bench := Node3D.new()
	bench.name = "Bench"
	bench.position = pos
	bench.rotation_degrees = Vector3(0.0, rad_to_deg(yaw), 0.0)
	for sx in [-0.9, 0.9]:
		var leg := MeshInstance3D.new()
		leg.mesh = _make_cylinder(0.06, 0.06, 0.5, 6, Color(0.4, 0.27, 0.14))
		leg.material_override = wood
		leg.position = Vector3(sx, 0.25, 0.0)
		bench.add_child(leg)
	var seat := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(2.0, 0.08, 0.5)
	seat.mesh = sm
	seat.material_override = wood
	seat.position = Vector3(0.0, 0.55, 0.0)
	bench.add_child(seat)
	var back := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.0, 0.5, 0.08)
	back.mesh = bm
	back.material_override = wood
	back.position = Vector3(0.0, 0.8, -0.3)
	bench.add_child(back)
	add_child(bench)


func _place_barrel(pos: Vector3, wood: StandardMaterial3D, band: StandardMaterial3D) -> void:
	var barrel := Node3D.new()
	barrel.name = "Barrel"
	barrel.position = pos
	var body := MeshInstance3D.new()
	body.mesh = _make_cylinder(0.38, 0.32, 0.85, 10, Color(0.44, 0.32, 0.18))
	body.material_override = wood
	body.position = Vector3(0.0, 0.43, 0.0)
	barrel.add_child(body)
	for by in [0.22, 0.64]:
		var band_m := MeshInstance3D.new()
		band_m.mesh = _make_cylinder(0.39, 0.39, 0.08, 10, Color(0.22, 0.22, 0.24))
		band_m.material_override = band
		band_m.position = Vector3(0.0, by, 0.0)
		barrel.add_child(band_m)
	add_child(barrel)


func _build_dogs() -> void:
	if _villages.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 92
	var v := _villages[0]
	for i in 2:
		var ang := rng.randf() * TAU
		var r := rng.randf_range(10.0, 30.0)
		var x := v.x + cos(ang) * r
		var z := v.y + sin(ang) * r
		var h := _height_at(x, z)
		if h < 0.8 or h > 10.0:
			continue
		var dog := preload("res://scripts/dog.gd").new()
		dog.name = "Dog"
		dog.set("world", self)
		dog.position = Vector3(x, h, z)
		dog.rotation_degrees = Vector3(0.0, rng.randf() * 360.0, 0.0)
		add_child(dog)


func _build_cats() -> void:
	if _villages.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 91
	var cat_count := 2 if _ram_scale() >= 1.0 else 1
	for i in cat_count:
		var v := _villages[i % _villages.size()]
		var ang := rng.randf() * TAU
		var r := rng.randf_range(8.0, 22.0)
		var x := v.x + cos(ang) * r
		var z := v.y + sin(ang) * r
		var h := _height_at(x, z)
		if h < 0.8 or h > 10.0:
			continue
		var cat := preload("res://scripts/cat.gd").new()
		cat.name = "Cat"
		cat.set("world", self)
		cat.position = Vector3(x, h, z)
		cat.rotation_degrees = Vector3(0.0, rng.randf() * 360.0, 0.0)
		add_child(cat)

func _build_houses() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 8
	var placed_positions: Array[Vector3] = []
	for vi in _villages.size():
		var center := _villages[vi]
		var house_count := 6 if vi == 0 else 4
		var placed := 0
		var tries := 0
		while placed < house_count and tries < 400:
			tries += 1
			var ang := rng.randf() * TAU
			var dist := rng.randf_range(12.0, VILLAGE_HOUSE_RADIUS)
			var x := center.x + cos(ang) * dist
			var z := center.y + sin(ang) * dist
			var h := _height_at(x, z)
			if h < 1.0 or h > 8.0:
				continue
			if _slope_at(x, z) > 0.3:
				continue
			if Vector2(x, z).distance_to(center) < 12.0:
				continue
			var spaced := true
			for p in placed_positions:
				if Vector2(x, z).distance_to(Vector2(p.x, p.z)) < 16.0:
					spaced = false
					break
			if not spaced:
				continue
			_flatten_heights(x, z, 8.0, 3.0)
			h = _height_at(x, z)
			var house := _make_house(placed_positions.size(), vi)
			house.position = Vector3(x, h, z)
			house.rotation_degrees = Vector3(0.0, rng.randf() * 360.0, 0.0)
			add_child(house)
			placed_positions.append(house.global_position)
			placed += 1
	_rebuild_terrain()
	_build_campfires()
	_build_gardens()

func _build_village_paths() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 141
	var path_mat := StandardMaterial3D.new()
	path_mat.albedo_color = Color(0.36, 0.27, 0.18)
	path_mat.roughness = 1.0
	path_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	path_mat.uv1_scale = Vector3(0.5, 0.5, 0.5)
	var edge_mat := StandardMaterial3D.new()
	edge_mat.albedo_color = Color(0.28, 0.21, 0.14)
	edge_mat.roughness = 1.0
	edge_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var grass_mat := StandardMaterial3D.new()
	grass_mat.albedo_color = Color(0.30, 0.36, 0.20)
	grass_mat.roughness = 1.0
	grass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	for vi in _villages.size():
		var c := _villages[vi]
		for hs in get_tree().get_nodes_in_group("houses"):
			var h := hs as Node3D
			if h == null or not is_instance_valid(h):
				continue
			var hp := h.global_position
			if Vector2(hp.x, hp.z).distance_to(c) > VILLAGE_HOUSE_RADIUS + 6.0:
				continue
			if Vector2(hp.x, hp.z).distance_to(c) < 10.0:
				continue
			_flatten_path(Vector2(c.x, c.y), Vector2(hp.x, hp.z), 3.4)
			_make_path(Vector3(c.x, 0.0, c.y), hp, rng, path_mat, edge_mat, grass_mat)
	_rebuild_terrain()


func _make_path(from_v3: Vector3, to_v3: Vector3, rng: RandomNumberGenerator, path_mat: Material, edge_mat: Material, grass_mat: Material) -> void:
	var a := Vector2(from_v3.x, from_v3.z)
	var b := Vector2(to_v3.x, to_v3.z)
	var mid := (a + b) * 0.5 + Vector2(rng.randf_range(-2.0, 2.0), rng.randf_range(-2.0, 2.0))
	var segs := 6
	var pts: Array = []
	var perps: Array = []
	for i in range(segs + 1):
		var t := float(i) / float(segs)
		var inv := 1.0 - t
		var p := a * inv * inv + mid * 2.0 * inv * t + b * t * t
		var h := _ground_height(p.x, p.y) + 0.12
		var dir := Vector2.ZERO
		if i < segs:
			var tn := float(i + 1) / float(segs)
			var invn := 1.0 - tn
			var pn := a * invn * invn + mid * 2.0 * invn * tn + b * tn * tn
			dir = pn - p
		elif segs >= 1:
			var tp := float(i - 1) / float(segs)
			var invp := 1.0 - tp
			var pp := a * invp * invp + mid * 2.0 * invp * tp + b * tp * tp
			dir = p - pp
		var pr := Vector2(-dir.y, dir.x)
		if pr.length() < 0.5:
			pr = Vector2.UP
		pr = pr.normalized()
		pts.append(Vector3(p.x, h, p.y))
		perps.append(Vector3(pr.x, 0.0, pr.y))
	var node := Node3D.new()
	node.name = "VillagePath_%d" % _village_path_counter
	_village_path_counter += 1
	add_child(node)
	node.add_child(_make_ribbon_mesh(pts, perps, 1.9, 0.0, 0.02, edge_mat))
	node.add_child(_make_ribbon_mesh(pts, perps, 1.25, 0.0, 0.06, path_mat))
	var fringe := _make_ribbon_mesh(pts, perps, 1.32, 0.0, 0.025, grass_mat)
	fringe.name = "Fringe"
	node.add_child(fringe)


func _flatten_path(a: Vector2, b: Vector2, radius: float) -> void:
	var segs := 8
	for i in range(segs + 1):
		var t := float(i) / float(segs)
		var p := a.lerp(b, t)
		_flatten_heights(p.x, p.y, radius, radius * 0.5)


func _make_npc(color: Color) -> CharacterBody3D:
	var npc := CharacterBody3D.new()
	npc.name = "NPC"
	npc.set_script(load("res://scripts/npc.gd"))
	npc.collision_layer = 1 | 2
	npc.add_to_group("npc")
	npc.set("world", self)
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.7
	var col := CollisionShape3D.new()
	col.shape = cap
	col.position = Vector3(0.0, 0.85, 0.0)
	npc.add_child(col)
	var robe_mat := StandardMaterial3D.new()
	robe_mat.albedo_color = color
	robe_mat.roughness = 0.9
	var robe_sat := color.lerp(Color(0.5, 0.5, 0.5), 0.35)
	var darker_mat := StandardMaterial3D.new()
	darker_mat.albedo_color = robe_sat.darkened(0.35)
	darker_mat.roughness = 1.0
	var skin_mat := StandardMaterial3D.new()
	skin_mat.albedo_color = Color(0.93, 0.76, 0.62)
	skin_mat.roughness = 0.7
	var hair_mat := StandardMaterial3D.new()
	hair_mat.albedo_color = Color(0.28, 0.2, 0.15)
	hair_mat.roughness = 0.9
	var sock_mat := StandardMaterial3D.new()
	sock_mat.albedo_color = Color(0.98, 0.98, 0.98)
	sock_mat.roughness = 0.8
	var boot_mats := [robe_sat.darkened(0.5), Color(0.25, 0.16, 0.1)]
	var boot_mat := StandardMaterial3D.new()
	boot_mat.albedo_color = boot_mats[randi() % boot_mats.size()]
	boot_mat.roughness = 0.8
	var model := Node3D.new()
	model.name = "Model"
	npc.add_child(model)
	var robe := MeshInstance3D.new()
	var robe_mesh := BoxMesh.new()
	robe_mesh.size = Vector3(0.66, 1.05, 0.42)
	robe.mesh = robe_mesh
	robe.material_override = robe_mat
	robe.position = Vector3(0.0, 0.78, 0.0)
	model.add_child(robe)
	var belt := MeshInstance3D.new()
	var belt_mesh := BoxMesh.new()
	belt_mesh.size = Vector3(0.68, 0.1, 0.46)
	belt.mesh = belt_mesh
	belt.material_override = darker_mat
	belt.position = Vector3(0.0, 0.68, 0.0)
	model.add_child(belt)
	var shoulder_r := MeshInstance3D.new()
	var sh_mesh := SphereMesh.new()
	sh_mesh.radius = 0.16
	sh_mesh.height = 0.32
	shoulder_r.mesh = sh_mesh
	shoulder_r.material_override = darker_mat
	shoulder_r.position = Vector3(-0.3, 1.28, 0.0)
	shoulder_r.scale = Vector3(1.1, 0.7, 0.9)
	model.add_child(shoulder_r)
	var shoulder_l := MeshInstance3D.new()
	shoulder_l.mesh = sh_mesh
	shoulder_l.material_override = darker_mat
	shoulder_l.position = Vector3(0.3, 1.28, 0.0)
	shoulder_l.scale = Vector3(1.1, 0.7, 0.9)
	model.add_child(shoulder_l)
	var arm_cyl_mesh := CapsuleMesh.new()
	arm_cyl_mesh.radius = 0.08
	arm_cyl_mesh.height = 0.5
	for sx in [-0.3, 0.3]:
		var arm := MeshInstance3D.new()
		arm.mesh = arm_cyl_mesh
		arm.material_override = darker_mat
		arm.position = Vector3(sx * 0.62, 0.98, 0.0)
		model.add_child(arm)
		var hand := MeshInstance3D.new()
		var hand_mesh := SphereMesh.new()
		hand_mesh.radius = 0.08
		hand_mesh.height = 0.14
		hand.mesh = hand_mesh
		hand.material_override = skin_mat
		hand.position = Vector3(sx * 0.66, 0.72, 0.0)
		model.add_child(hand)
	for sx in [-0.15, 0.15]:
		var leg := MeshInstance3D.new()
		var leg_mesh := CapsuleMesh.new()
		leg_mesh.radius = 0.12
		leg_mesh.height = 0.7
		leg.mesh = leg_mesh
		leg.material_override = sock_mat
		leg.position = Vector3(sx, 0.34, 0.0)
		model.add_child(leg)
		var foot := MeshInstance3D.new()
		var foot_mesh := BoxMesh.new()
		foot_mesh.size = Vector3(0.18, 0.1, 0.3)
		foot.mesh = foot_mesh
		foot.material_override = boot_mat
		foot.position = Vector3(sx, 0.05, 0.06)
		model.add_child(foot)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.16
	head_mesh.height = 0.3
	head.mesh = head_mesh
	head.position = Vector3(0.0, 1.42, 0.0)
	head.material_override = skin_mat
	model.add_child(head)
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.1, 0.1, 0.12)
	eye_mat.roughness = 0.3
	for ey in [-0.06, 0.06]:
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.025
		eye_mesh.height = 0.04
		eye.mesh = eye_mesh
		eye.material_override = eye_mat
		eye.position = Vector3(ey, 1.46, 0.13)
		model.add_child(eye)
	var hat := MeshInstance3D.new()
	var hat_mesh := BoxMesh.new()
	hat_mesh.size = Vector3(0.4, 0.12, 0.4)
	hat.mesh = hat_mesh
	hat.position = Vector3(0.0, 1.6, 0.0)
	hat.material_override = robe_mat
	model.add_child(hat)
	var hat_brim := MeshInstance3D.new()
	var brim_mesh := CylinderMesh.new()
	brim_mesh.top_radius = 0.26
	brim_mesh.bottom_radius = 0.26
	brim_mesh.height = 0.04
	hat_brim.mesh = brim_mesh
	hat_brim.material_override = darker_mat
	hat_brim.position = Vector3(0.0, 1.56, 0.0)
	hat_brim.rotation.x = PI / 2.0
	model.add_child(hat_brim)
	return npc

func _build_npcs() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 9
	var robes := [Color(0.55, 0.34, 0.26), Color(0.36, 0.45, 0.58),
		Color(0.62, 0.55, 0.30), Color(0.30, 0.42, 0.34)]
	var child_robes := [Color(0.80, 0.60, 0.45), Color(0.55, 0.70, 0.80)]
	var idx := 0
	var armed := 3
	var houses := get_tree().get_nodes_in_group("houses")
	var wander_target := int(4.0 * clampf(_ram_scale(), 0.5, 2.0))
	_npc_list.clear()
	for house in houses:
		var h := house as Node3D
		var spot: Vector3 = h.to_global(h.get_meta("interior_local"))
		var npc := _make_npc(robes[idx % robes.size()])
		npc.position = spot
		npc.rotation_degrees = Vector3(0.0, rng.randf() * 360.0, 0.0)
		add_child(npc)
		_npc_list.append(npc)
		npc.set("_home", h.to_global(h.get_meta("entry_local")))
		if idx < armed:
			npc.set("has_gun", true)
		idx += 1
	var placed := 0
	var tries := 0
	while idx < houses.size() + wander_target and tries < 400:
		tries += 1
		var x := rng.randf_range(-_half + 8.0, _half - 8.0)
		var z := rng.randf_range(-_half + 8.0, _half - 8.0)
		var h := _height_at(x, z)
		if h < 1.0 or h > 9.0:
			continue
		if _slope_at(x, z) > 0.4:
			continue
		if Vector2(x, z).distance_to(Vector2.ZERO) < 10.0:
			continue
		var npc := _make_npc(robes[idx % robes.size()])
		npc.position = Vector3(x, h, z)
		npc.rotation_degrees = Vector3(0.0, rng.randf() * 360.0, 0.0)
		add_child(npc)
		_npc_list.append(npc)
		if idx < armed:
			npc.set("has_gun", true)
		idx += 1
		placed += 1
	var kids := 0
	var kid_tries := 0
	if houses.is_empty():
		return
	while kids < 4 and kid_tries < 300:
		kid_tries += 1
		var house := (houses as Array)[rng.randi() % houses.size()] as Node3D
		var base: Vector3 = house.to_global(house.get_meta("entry_local"))
		var x := base.x + rng.randf_range(-6.0, 6.0)
		var z := base.z + rng.randf_range(-6.0, 6.0)
		var h := _height_at(x, z)
		if h < 1.0 or h > 9.0:
			continue
		if _slope_at(x, z) > 0.4:
			continue
		var kid := _make_npc(child_robes[kids % child_robes.size()])
		kid.scale = Vector3.ONE * 0.62
		kid.position = Vector3(x, h, z)
		kid.rotation_degrees = Vector3(0.0, rng.randf() * 360.0, 0.0)
		add_child(kid)
		_npc_list.append(kid)
		kid.set("is_child", true)
		kids += 1
	var police_col := Color(0.14, 0.18, 0.45)
	var p_placed := 0
	var p_tries := 0
	while p_placed < 2 and p_tries < 200:
		p_tries += 1
		var ang := rng.randf() * TAU
		var dist := rng.randf_range(18.0, 45.0)
		var px := cos(ang) * dist
		var pz := sin(ang) * dist
		var ph := _height_at(px, pz)
		if ph < 1.0 or ph > 9.0:
			continue
		if _slope_at(px, pz) > 0.4:
			continue
		var cop := _make_npc(police_col)
		cop.position = Vector3(px, ph, pz)
		cop.rotation_degrees = Vector3(0.0, rng.randf() * 360.0, 0.0)
		cop.set("is_police", true)
		cop.set("has_gun", true)
		add_child(cop)
		_npc_list.append(cop)
		p_placed += 1
	for n in _npc_list:
		(n as Node3D).set("net_slave", _client)

func _build_plant_workers() -> void:
	if _reactors.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 23
	var vests := [Color(0.85, 0.45, 0.1), Color(0.9, 0.72, 0.12), Color(0.2, 0.5, 0.8)]
	for r in _reactors:
		var plant := r as Node3D
		if plant == null or not is_instance_valid(plant):
			continue
		var base: Vector3 = plant.global_position
		for i in 3:
			var ang := rng.randf() * TAU
			var dist := rng.randf_range(4.0, 26.0)
			var worker := _make_npc(vests[i % vests.size()])
			worker.position = base + Vector3(cos(ang) * dist, 0.0, sin(ang) * dist)
			worker.rotation_degrees = Vector3(0.0, rng.randf() * 360.0, 0.0)
			worker.set("is_worker", true)
			worker.set("_home", base)
			add_child(worker)
			_npc_list.append(worker)
	for n in _npc_list:
		(n as Node3D).set("net_slave", _client)


func _make_zombie(ztype := 0) -> CharacterBody3D:
	var zed := CharacterBody3D.new()
	zed.name = "Zombie"
	zed.set_script(preload("res://scripts/zombie.gd"))
	zed.set("world", self)
	zed.set("ztype", ztype)
	return zed

func _build_zombies() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 17
	var day := int(floor(_time_of_day / 24.0)) + 1
	var day_scale := clampf(1.0 + float(day - 1) * 0.15, 1.0, 2.0)
	var target := int(12.0 * clampf(_ram_scale(), 0.5, 2.0) * day_scale)
	var placed := 0
	var tries := 0
	while placed < target and tries < 500:
		tries += 1
		var ang := rng.randf() * TAU
		var dist := rng.randf_range(60.0, 130.0)
		var x := cos(ang) * dist
		var z := sin(ang) * dist
		var h := _height_at(x, z)
		if h < 0.5 or h > 20.0:
			continue
		if _slope_at(x, z) > 0.5:
			continue
		var ok := true
		for house in get_tree().get_nodes_in_group("houses"):
			var hp2: Vector3 = (house as Node3D).global_position
			if Vector2(x, z).distance_to(Vector2(hp2.x, hp2.z)) < 10.0:
				ok = false
				break
		if not ok:
			continue
		var roll := rng.randf()
		var ztype := 0
		if roll < 0.22:
			ztype = 2
		elif roll < 0.55:
			ztype = 1
		var zed := _make_zombie(ztype)
		zed.position = Vector3(x, h, z)
		zed.rotation_degrees = Vector3(0.0, rng.randf() * 360.0, 0.0)
		zed.set_meta("net_id", placed)
		add_child(zed)
		placed += 1

func _despawn_zombies() -> void:
	for z in get_tree().get_nodes_in_group("zombies"):
		if z.has_method("do_sink"):
			z.call("do_sink")
	_zombie_nodes.clear()

func _zombie_died(z: Node3D) -> void:
	if _server or _client:
		return
	_drop_zombie_loot(z.global_position, int(z.get("ztype")))

func _drop_zombie_loot(pos: Vector3, ztype: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(Time.get_ticks_usec() % 2147483647)
	var roll := rng.randf()
	if roll < 0.38:
		_make_ammo_pickup(pos)
	elif roll < 0.72:
		_make_med_pickup(pos)
	elif roll < 0.8:
		_make_ammo_pickup(pos)
		if ztype == 2:
			_make_med_pickup(pos + Vector3(0.8, 0.0, 0.0))

func _make_sakura_foliage() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base := _sakura
	_cone(st, Vector3(0.0, 2.2, 0.0), 1.55, 2.1, 9, base)
	_cone(st, Vector3(0.0, 3.0, 0.0), 1.1, 1.7, 9, base.lightened(0.07))
	_cone(st, Vector3(0.0, 3.7, 0.0), 0.7, 1.3, 9, base.lightened(0.14))
	return st.commit()

func _make_torii(mat: StandardMaterial3D) -> Node3D:
	var node := Node3D.new()
	node.name = "Torii"
	var pillar := _make_cylinder(0.26, 0.26, 5.4, 10, Color(0.72, 0.16, 0.14))
	var beam := _make_cylinder(0.22, 0.22, 6.0, 10, Color(0.40, 0.10, 0.10))
	var beam_top := _make_cylinder(0.26, 0.26, 6.6, 10, Color(0.28, 0.07, 0.07))
	var rail := _make_cylinder(0.13, 0.13, 5.4, 10, Color(0.50, 0.13, 0.12))
	for side in [-1.0, 1.0]:
		var p := MeshInstance3D.new()
		p.mesh = pillar
		p.position = Vector3(2.0 * side, 2.7, 0.0)
		p.material_override = mat
		node.add_child(p)
	for beam_data: Array in [[3.9, beam], [4.9, beam_top], [5.35, rail]]:
		var b := MeshInstance3D.new()
		b.mesh = beam_data[1]
		b.rotation_degrees = Vector3(0.0, 0.0, 90.0)
		b.position = Vector3(0.0, beam_data[0], 0.0)
		var bm := StandardMaterial3D.new()
		bm.albedo_color = Color(0.40, 0.10, 0.10)
		bm.roughness = 0.7
		b.material_override = bm
		node.add_child(b)
	var plaque := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.6, 1.0, 0.06)
	plaque.mesh = box
	plaque.position = Vector3(0.0, 4.1, -0.05)
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.12, 0.08, 0.07)
	plaque.material_override = pmat
	node.add_child(plaque)
	var body := StaticBody3D.new()
	for side in [-1.0, 1.0]:
		var col := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = Vector3(0.5, 5.4, 0.5)
		col.shape = box_shape
		col.position = Vector3(2.0 * side, 2.7, 0.0)
		body.add_child(col)
	node.add_child(body)
	return node

func _build_cars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 11
	var colors := [Color(0.55, 0.20, 0.18), Color(0.20, 0.30, 0.55),
		Color(0.75, 0.75, 0.78), Color(0.30, 0.55, 0.32)]
	var placed := 0
	var tries := 0
	var car_target := int(2.0 + 2.0 * clampf(_ram_scale(), 0.5, 2.0))
	_cars_list.clear()
	while placed < car_target and tries < 300:
		tries += 1
		var x := rng.randf_range(-60.0, 60.0)
		var z := rng.randf_range(-60.0, 60.0)
		var h := _height_at(x, z)
		if h < 1.5 or h > 8.0:
			continue
		if _slope_at(x, z) > 0.25:
			continue
		if Vector2(x, z).distance_to(Vector2.ZERO) < 12.0:
			continue
		var car := _make_car(colors[placed % colors.size()])
		car.position = Vector3(x, h, z)
		car.rotation_degrees = Vector3(0.0, rng.randf() * 360.0, 0.0)
		add_child(car)
		_cars_list.append(car)
		car.add_to_group("cars")
		car.set_meta("car_id", placed)
		placed += 1

func _make_car(color: Color) -> CharacterBody3D:
	var car := CharacterBody3D.new()
	car.name = "Car"
	car.collision_layer = 1 | 2
	car.collision_mask = 1
	car.set_script(preload("res://scripts/car.gd"))
	car.set("world", self)
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = color
	body_mat.roughness = 0.6
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.8, 0.55, 3.9)
	body.mesh = bm
	body.material_override = body_mat
	body.position = Vector3(0.0, 0.45, 0.0)
	car.add_child(body)
	var cabin_mat := StandardMaterial3D.new()
	cabin_mat.albedo_color = Color(0.2, 0.3, 0.45)
	cabin_mat.roughness = 0.2
	var cabin := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(1.6, 0.5, 1.9)
	cabin.mesh = cm
	cabin.material_override = cabin_mat
	cabin.position = Vector3(0.0, 0.95, -0.15)
	car.add_child(cabin)
	var lamp_mat := StandardMaterial3D.new()
	lamp_mat.albedo_color = Color(1.0, 0.95, 0.6)
	lamp_mat.emission_enabled = true
	lamp_mat.emission = Color(1.0, 0.9, 0.5) * 0.6
	for x in [-0.62, 0.62]:
		var lamp := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(0.3, 0.12, 0.05)
		lamp.mesh = lm
		lamp.material_override = lamp_mat
		lamp.position = Vector3(x, 0.5, 1.95)
		car.add_child(lamp)
	var tire_mat := StandardMaterial3D.new()
	tire_mat.albedo_color = Color(0.06, 0.06, 0.06)
	tire_mat.roughness = 1.0
	for x in [-0.72, 0.72]:
		for z in [-1.35, 1.35]:
			var tire := MeshInstance3D.new()
			var tm := CylinderMesh.new()
			tm.top_radius = 0.28
			tm.bottom_radius = 0.28
			tm.height = 0.24
			tire.mesh = tm
			tire.material_override = tire_mat
			tire.position = Vector3(x, 0.28, z)
			tire.rotation_degrees = Vector3(0.0, 0.0, 90.0)
			car.add_child(tire)
	var col := CollisionShape3D.new()
	var cs := BoxShape3D.new()
	cs.size = Vector3(1.8, 1.0, 3.9)
	col.shape = cs
	col.position = Vector3(0.0, 0.75, 0.0)
	car.add_child(col)
	return car

func _make_house(seed_i: int, village_i: int = 0) -> Node3D:
	var node := Node3D.new()
	node.name = "House%d" % seed_i
	var palettes: Array[Array] = [
		[Color(0.88, 0.83, 0.71), Color(0.40, 0.25, 0.20)],
		[Color(0.82, 0.78, 0.65), Color(0.30, 0.28, 0.22)],
		[Color(0.90, 0.85, 0.75), Color(0.45, 0.20, 0.18)],
		[Color(0.78, 0.80, 0.70), Color(0.25, 0.30, 0.30)],
	]
	var pal: Array = palettes[seed_i % palettes.size()]
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = pal[0]
	wall_mat.roughness = 0.95
	var roof_mat := StandardMaterial3D.new()
	roof_mat.albedo_color = pal[1]
	roof_mat.roughness = 0.9
	roof_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var door_mat := StandardMaterial3D.new()
	door_mat.albedo_color = Color(0.34, 0.22, 0.16)
	door_mat.roughness = 0.8
	var win_mat := StandardMaterial3D.new()
	win_mat.albedo_color = Color(0.55, 0.72, 0.90)
	win_mat.roughness = 0.3
	win_mat.emission_enabled = true
	win_mat.emission = Color(0.3, 0.4, 0.6) * 0.4
	if village_i >= 0 and village_i < _village_window_mats.size():
		_village_window_mats[village_i].append(win_mat)

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_i * 7919 + 13
	var half_w := 2.9 + rng.randf_range(0.0, 0.8)
	var half_d := 2.3 + rng.randf_range(-0.2, 0.4)
	var wall_h := 2.2 + rng.randf_range(-0.1, 0.4)
	var t := 0.18
	var door_gap := 1.1
	var seg_w := (half_w * 2.0 - door_gap) * 0.5

	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.42, 0.31, 0.21)
	floor_mat.roughness = 0.95
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(half_w * 2.0, t, half_d * 2.0)
	var floor := MeshInstance3D.new()
	floor.mesh = floor_mesh
	floor.position = Vector3(0.0, t * 0.5, 0.0)
	floor.material_override = floor_mat
	node.add_child(floor)

	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.6, 0.6, 0.58)
	stone_mat.roughness = 1.0
	var foundation := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(half_w * 2.0 + 0.35, 0.22, half_d * 2.0 + 0.35)
	foundation.mesh = fm
	foundation.position = Vector3(0.0, t, 0.0)
	foundation.material_override = stone_mat
	node.add_child(foundation)

	var wall_box := BoxMesh.new()
	wall_box.size = Vector3(half_w * 2.0, wall_h, t)
	var seg_box := BoxMesh.new()
	seg_box.size = Vector3(seg_w, wall_h, t)
	for zs in [half_d, -half_d]:
		if zs > 0.0:
			for sx in [1.0, -1.0]:
				var mi := MeshInstance3D.new()
				mi.mesh = seg_box
				mi.position = Vector3(sx * (door_gap * 0.5 + seg_w * 0.5), wall_h * 0.5, zs)
				mi.material_override = wall_mat
				node.add_child(mi)
		else:
			var mi := MeshInstance3D.new()
			mi.mesh = wall_box
			mi.position = Vector3(0.0, wall_h * 0.5, zs)
			mi.material_override = wall_mat
			node.add_child(mi)
	var lintel := MeshInstance3D.new()
	var lintel_mesh := BoxMesh.new()
	lintel_mesh.size = Vector3(door_gap, wall_h - 1.75, t)
	lintel.mesh = lintel_mesh
	lintel.position = Vector3(0.0, (wall_h + 1.75) * 0.5, half_d)
	lintel.material_override = wall_mat
	node.add_child(lintel)

	var side_box := BoxMesh.new()
	side_box.size = Vector3(t, wall_h, half_d * 2.0)
	for xs in [half_w, -half_w]:
		var mi := MeshInstance3D.new()
		mi.mesh = side_box
		mi.position = Vector3(xs, wall_h * 0.5, 0.0)
		mi.material_override = wall_mat
		node.add_child(mi)

	var trim_mat := StandardMaterial3D.new()
	trim_mat.albedo_color = pal[1].darkened(0.2)
	trim_mat.roughness = 0.9
	var eave_y := wall_h
	var peak_y := wall_h + 1.6
	var overhang := 0.45
	var slope_run := half_d + overhang
	var pitch_deg := rad_to_deg(atan2(peak_y - eave_y, slope_run))
	var slope_len := sqrt(slope_run * slope_run + (peak_y - eave_y) * (peak_y - eave_y))
	for zside in [1.0, -1.0]:
		var slope := MeshInstance3D.new()
		var sl_mesh := BoxMesh.new()
		sl_mesh.size = Vector3(half_w * 2.0 + overhang * 2.0, 0.1, slope_len)
		slope.mesh = sl_mesh
		slope.material_override = roof_mat
		slope.rotation_degrees = Vector3(pitch_deg * zside, 0.0, 0.0)
		slope.position = Vector3(0.0, eave_y + (peak_y - eave_y) * 0.5, slope_run * 0.5 * zside)
		node.add_child(slope)
		slope.add_to_group("roofs")
	var gst := SurfaceTool.new()
	gst.begin(Mesh.PRIMITIVE_TRIANGLES)
	for gx in [1.0, -1.0]:
		gst.set_normal(Vector3(gx, 0.0, 0.0))
		gst.set_color(Color(1, 1, 1))
		gst.add_vertex(Vector3(gx * half_w, eave_y, -half_d))
		gst.add_vertex(Vector3(gx * half_w, peak_y, 0.0))
		gst.add_vertex(Vector3(gx * half_w, eave_y, half_d))
		gst.set_normal(Vector3(-gx, 0.0, 0.0))
		gst.add_vertex(Vector3(gx * half_w, eave_y, -half_d))
		gst.add_vertex(Vector3(gx * half_w, eave_y, half_d))
		gst.add_vertex(Vector3(gx * half_w, peak_y, 0.0))
	var gmesh := gst.commit()
	var gable := MeshInstance3D.new()
	gable.mesh = gmesh
	gable.material_override = roof_mat
	node.add_child(gable)
	gable.add_to_group("roofs")
	var ridge := MeshInstance3D.new()
	var ridge_mesh := BoxMesh.new()
	ridge_mesh.size = Vector3(half_w * 2.0 + overhang * 2.0, 0.18, 0.6)
	ridge.mesh = ridge_mesh
	ridge.material_override = trim_mat
	ridge.position = Vector3(0.0, peak_y + 0.06, 0.0)
	node.add_child(ridge)
	ridge.add_to_group("roofs")
	for zside in [1.0, -1.0]:
		var fascia := MeshInstance3D.new()
		var fas_mesh := BoxMesh.new()
		fas_mesh.size = Vector3(half_w * 2.0 + overhang * 2.0, 0.12, 0.06)
		fascia.mesh = fas_mesh
		fascia.material_override = trim_mat
		fascia.position = Vector3(0.0, eave_y - 0.02, slope_run * zside)
		node.add_child(fascia)
		fascia.add_to_group("roofs")

	var brick_mat := StandardMaterial3D.new()
	brick_mat.albedo_color = Color(0.55, 0.28, 0.22)
	brick_mat.roughness = 1.0
	var chimney := MeshInstance3D.new()
	var ch_mesh := BoxMesh.new()
	ch_mesh.size = Vector3(0.45, 2.0, 0.55)
	chimney.mesh = ch_mesh
	chimney.material_override = brick_mat
	chimney.position = Vector3(half_w * 0.42, eave_y + 0.7, 0.7)
	node.add_child(chimney)
	chimney.add_to_group("roofs")
	var ch_cap := MeshInstance3D.new()
	var cap_mesh := BoxMesh.new()
	cap_mesh.size = Vector3(0.62, 0.14, 0.72)
	ch_cap.mesh = cap_mesh
	ch_cap.material_override = stone_mat
	ch_cap.position = Vector3(half_w * 0.42, eave_y + 1.72, 0.7)
	node.add_child(ch_cap)
	ch_cap.add_to_group("roofs")

	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.2, 0.14, 0.11)
	frame_mat.roughness = 0.8
	var win_frame := BoxMesh.new()
	win_frame.size = Vector3(0.95, 0.95, 0.14)
	var win_pane := BoxMesh.new()
	win_pane.size = Vector3(0.72, 0.72, 0.05)
	for side in [-1.0, 1.0]:
		var frm := MeshInstance3D.new()
		frm.mesh = win_frame
		frm.material_override = frame_mat
		frm.position = Vector3(half_w * side * 0.55, 1.35, half_d + 0.07)
		node.add_child(frm)
		var pane := MeshInstance3D.new()
		pane.mesh = win_pane
		pane.material_override = win_mat
		pane.position = Vector3(half_w * side * 0.55, 1.35, half_d + 0.12)
		node.add_child(pane)
		var fb := MeshInstance3D.new()
		var fb_mesh := BoxMesh.new()
		fb_mesh.size = Vector3(0.95, 0.12, 0.14)
		fb.mesh = fb_mesh
		var fb_mat := StandardMaterial3D.new()
		fb_mat.albedo_color = wall_mat.albedo_color.darkened(0.35)
		fb_mat.roughness = 1.0
		fb.material_override = fb_mat
		fb.position = Vector3(half_w * side * 0.55, 0.9, half_d + 0.09)
		node.add_child(fb)
	for xside in [1.0, -1.0]:
		var frm := MeshInstance3D.new()
		var wf := BoxMesh.new()
		wf.size = Vector3(0.14, 0.85, 0.85)
		frm.mesh = wf
		frm.material_override = frame_mat
		frm.position = Vector3(half_w * xside + 0.07, 1.3, 0.45)
		node.add_child(frm)
		var pane := MeshInstance3D.new()
		var wp := BoxMesh.new()
		wp.size = Vector3(0.05, 0.64, 0.64)
		pane.mesh = wp
		pane.material_override = win_mat
		pane.position = Vector3(half_w * xside + 0.12, 1.3, 0.45)
		node.add_child(pane)

	var jamb_box := BoxMesh.new()
	jamb_box.size = Vector3(0.1, 1.9, 0.14)
	for sx in [1.0, -1.0]:
		var jamb := MeshInstance3D.new()
		jamb.mesh = jamb_box
		jamb.material_override = frame_mat
		jamb.position = Vector3(sx * (door_gap * 0.5 + 0.05), 0.95, half_d + 0.05)
		node.add_child(jamb)
	var header := MeshInstance3D.new()
	var hdr_mesh := BoxMesh.new()
	hdr_mesh.size = Vector3(door_gap + 0.2, 0.12, 0.14)
	header.mesh = hdr_mesh
	header.material_override = frame_mat
	header.position = Vector3(0.0, 1.9, half_d + 0.05)
	node.add_child(header)
	var step := MeshInstance3D.new()
	var step_mesh := BoxMesh.new()
	step_mesh.size = Vector3(1.5, 0.16, 0.55)
	step.mesh = step_mesh
	step.material_override = stone_mat
	step.position = Vector3(0.0, t, half_d + 0.42)
	node.add_child(step)

	var door := Node3D.new()
	door.name = "Door"
	door.position = Vector3(-0.475, 0.0, half_d + 0.12)
	door.set_script(preload("res://scripts/house_door.gd"))
	var door_box := BoxMesh.new()
	door_box.size = Vector3(0.95, 1.75, 0.1)
	var door_mesh := MeshInstance3D.new()
	door_mesh.mesh = door_box
	door_mesh.position = Vector3(0.475, 0.875, 0.0)
	door_mesh.material_override = door_mat
	door.add_child(door_mesh)
	node.add_child(door)

	var zombie_block := StaticBody3D.new()
	zombie_block.name = "ZombieBlock"
	zombie_block.collision_layer = 4
	zombie_block.collision_mask = 4
	var zcol := CollisionShape3D.new()
	var zbs := BoxShape3D.new()
	zbs.size = Vector3(door_gap + 0.2, wall_h + 0.2, 0.3)
	zcol.shape = zbs
	zcol.position = Vector3(0.0, (wall_h + 0.2) * 0.5, half_d + 0.05)
	zombie_block.add_child(zcol)
	node.add_child(zombie_block)

	var bed := _make_bed()
	bed.position = Vector3(half_w - 1.15, t * 0.5, 0.5)
	node.add_child(bed)

	var body := StaticBody3D.new()
	var col_floor := CollisionShape3D.new()
	var bs_floor := BoxShape3D.new()
	bs_floor.size = Vector3(half_w * 2.0, t, half_d * 2.0)
	col_floor.shape = bs_floor
	col_floor.position = Vector3(0.0, t * 0.5, 0.0)
	body.add_child(col_floor)
	for xs in [half_w, -half_w]:
		var col := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(t, wall_h + 0.2, half_d * 2.0)
		col.shape = bs
		col.position = Vector3(xs, (wall_h + 0.2) * 0.5, 0.0)
		body.add_child(col)
	var col_b := CollisionShape3D.new()
	var bsb := BoxShape3D.new()
	bsb.size = Vector3(half_w * 2.0, wall_h + 0.2, t)
	col_b.shape = bsb
	col_b.position = Vector3(0.0, (wall_h + 0.2) * 0.5, -half_d)
	body.add_child(col_b)
	for sx in [1.0, -1.0]:
		var col_f := CollisionShape3D.new()
		var bsf := BoxShape3D.new()
		bsf.size = Vector3(seg_w, wall_h + 0.2, t)
		col_f.shape = bsf
		col_f.position = Vector3(sx * (door_gap * 0.5 + seg_w * 0.5), (wall_h + 0.2) * 0.5, half_d)
		body.add_child(col_f)
	node.add_child(body)
	node.add_to_group("houses")
	node.set_meta("entry_local", Vector3(0.0, t, half_d))
	node.set_meta("interior_local", Vector3(0.0, t, 0.0))
	return node

func _make_bed() -> StaticBody3D:
	var bed := StaticBody3D.new()
	bed.name = "Bed"
	bed.collision_layer = 2
	bed.collision_mask = 0
	bed.set_script(preload("res://scripts/bed.gd"))
	bed.set("world", self)
	bed.add_to_group("beds")

	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.45, 0.30, 0.18)
	frame_mat.roughness = 0.9
	var frame := MeshInstance3D.new()
	var frame_mesh := BoxMesh.new()
	frame_mesh.size = Vector3(1.1, 0.42, 1.9)
	frame.mesh = frame_mesh
	frame.position = Vector3(0.0, 0.21, 0.0)
	frame.material_override = frame_mat
	bed.add_child(frame)

	var mattress_mat := StandardMaterial3D.new()
	mattress_mat.albedo_color = Color(0.82, 0.78, 0.70)
	mattress_mat.roughness = 1.0
	var mattress := MeshInstance3D.new()
	var mattress_mesh := BoxMesh.new()
	mattress_mesh.size = Vector3(1.0, 0.16, 1.85)
	mattress.mesh = mattress_mesh
	mattress.position = Vector3(0.0, 0.42, 0.05)
	mattress.material_override = mattress_mat
	bed.add_child(mattress)

	var pillow_mat := StandardMaterial3D.new()
	pillow_mat.albedo_color = Color(0.92, 0.90, 0.85)
	pillow_mat.roughness = 1.0
	var pillow := MeshInstance3D.new()
	var pillow_mesh := BoxMesh.new()
	pillow_mesh.size = Vector3(0.6, 0.1, 0.4)
	pillow.mesh = pillow_mesh
	pillow.position = Vector3(0.0, 0.5, -0.8)
	pillow.material_override = pillow_mat
	bed.add_child(pillow)

	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(1.2, 0.7, 2.0)
	col.shape = bs
	col.position = Vector3(0.0, 0.35, 0.0)
	bed.add_child(col)
	return bed

func _make_lantern_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stone := Color(0.55, 0.55, 0.53)
	_cylinder_into(st, 0.55, 0.55, 0.28, 10, stone, Vector3(0.0, 0.14, 0.0))
	_cylinder_into(st, 0.16, 0.16, 0.8, 8, stone.darkened(0.15), Vector3(0.0, 0.68, 0.0))
	_cylinder_into(st, 0.34, 0.34, 0.34, 10, stone.lightened(0.1), Vector3(0.0, 1.28, 0.0))
	_cone(st, Vector3(0.0, 1.62, 0.0), 0.42, 0.36, 10, stone.lightened(0.15))
	return st.commit()

func _cylinder_into(st: SurfaceTool, r_b: float, r_t: float, height: float, sides: int, col: Color, origin: Vector3) -> void:
	for i in sides:
		var a0 := float(i) / sides * TAU
		var a1 := float(i + 1) / sides * TAU
		var c0 := Vector2(cos(a0), sin(a0))
		var c1 := Vector2(cos(a1), sin(a1))
		var p0 := origin + Vector3(c0.x * r_b, 0.0, c0.y * r_b)
		var p1 := origin + Vector3(c1.x * r_b, 0.0, c1.y * r_b)
		var p2 := origin + Vector3(c1.x * r_t, height, c1.y * r_t)
		var p3 := origin + Vector3(c0.x * r_t, height, c0.y * r_t)
		var n0 := Vector3(c0.x, 0.0, c0.y).normalized()
		var n1 := Vector3(c1.x, 0.0, c1.y).normalized()
		st.set_normal(n0)
		st.set_color(col)
		st.add_vertex(p0)
		st.set_normal(n1)
		st.set_color(col)
		st.add_vertex(p1)
		st.set_normal(n1)
		st.set_color(col)
		st.add_vertex(p2)
		st.set_normal(n0)
		st.set_color(col)
		st.add_vertex(p0)
		st.set_normal(n1)
		st.set_color(col)
		st.add_vertex(p2)
		st.set_normal(n0)
		st.set_color(col)
		st.add_vertex(p3)

func _build_sakura_petals() -> void:
	var p := GPUParticles3D.new()
	p.amount = 140
	p.lifetime = 6.0
	p.emitting = true
	p.position = Vector3(0.0, 8.0, 0.0)
	p.visibility_aabb = AABB(Vector3(-70, -10, -70), Vector3(140, 60, 140))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(50.0, 4.0, 50.0)
	pm.direction = Vector3(0.0, -1.0, 0.0)
	pm.spread = 12.0
	pm.gravity = Vector3(0.0, -0.4, 0.0)
	pm.initial_velocity_min = 0.6
	pm.initial_velocity_max = 1.6
	pm.scale_min = 0.5
	pm.scale_max = 1.1
	pm.color = _sakura.lightened(0.08)
	p.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(0.18, 0.18)
	p.draw_pass_1 = quad
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(_sakura.lightened(0.08), 0.9)
	p.material_override = mat
	add_child(p)

# ------------------------------------------------------------------ fireflies

func _build_fireflies() -> void:
	var p := GPUParticles3D.new()
	p.amount = 70
	p.lifetime = 9.0
	p.emitting = true
	p.position = Vector3(0.0, 4.0, 0.0)
	p.visibility_aabb = AABB(Vector3(-60, -10, -60), Vector3(120, 40, 120))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(45.0, 10.0, 45.0)
	pm.direction = Vector3.ZERO
	pm.spread = 180.0
	pm.gravity = Vector3(0.0, 0.05, 0.0)
	pm.initial_velocity_min = 0.2
	pm.initial_velocity_max = 0.7
	pm.scale_min = 0.35
	pm.scale_max = 0.9
	pm.color = Color(1.0, 0.92, 0.6, 0.85)
	pm.color_ramp = null
	p.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(0.32, 0.32)
	p.draw_pass_1 = quad
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.no_depth_test = true
	mat.albedo_color = Color(1.0, 0.9, 0.55, 0.75)
	p.material_override = mat
	add_child(p)
	_fireflies = p

func _update_fireflies(delta: float) -> void:
	if _fireflies == null:
		return
	var tod := fmod(_time_of_day, 24.0)
	var on := tod >= 19.5 or tod < 5.0
	if _fireflies.visible != on:
		_fireflies.visible = on
		_fireflies.emitting = on
	if on:
		_fireflies.position.y = 2.5 + sin(Time.get_ticks_msec() / 1000.0 * 0.5) * 1.2

# ------------------------------------------------------------------ player

func _build_player() -> CharacterBody3D:
	var player := CharacterBody3D.new()
	player.name = "Player"
	player.set_meta("is_player", true)
	player.script = preload("res://scripts/player.gd")
	player.set("world", self)
	player.set("touch_mode", _is_mobile())

	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.7
	col.shape = cap
	col.position.y = 0.85
	player.add_child(col)

	var arm := SpringArm3D.new()
	arm.name = "CameraRig"
	arm.position = Vector3(0.0, 1.62, 0.0)
	arm.spring_length = 0.0
	arm.collision_mask = 1
	player.add_child(arm)

	var cam := Camera3D.new()
	cam.name = "Camera"
	cam.fov = 80.0
	cam.near = 0.05
	cam.far = 3200.0
	cam.current = true
	arm.add_child(cam)

	var lamp := SpotLight3D.new()
	lamp.name = "Headlamp"
	lamp.light_color = Color(1.0, 0.95, 0.82)
	lamp.light_energy = 2.8
	lamp.spot_range = 36.0
	lamp.spot_angle = 30.0
	lamp.spot_attenuation = 1.1
	lamp.shadow_enabled = true
	lamp.shadow_bias = 0.05
	lamp.set("light_volumetric_fog_energy", 0.35)
	cam.add_child(lamp)
	lamp.position = Vector3(0.0, 0.0, -0.1)
	lamp.rotation_degrees = Vector3(0.0, 0.0, 0.0)

	var body_mesh := MeshInstance3D.new()
	body_mesh.name = "Body"
	var cap_mesh := CapsuleMesh.new()
	cap_mesh.radius = 0.32
	cap_mesh.height = 1.6
	body_mesh.mesh = cap_mesh
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.20, 0.25, 0.30)
	body_mat.roughness = 0.7
	body_mesh.material_override = body_mat
	body_mesh.position.y = 0.8
	player.add_child(body_mesh)

	var spawn := Vector3(0.0, _height_at(0.0, 0.0) + 2.2, 0.0)
	_spawn_pos = spawn
	player.position = spawn
	add_child(player)
	_player = player
	player.stats_changed.connect(_on_stats_changed)
	player.died.connect(_on_player_died)
	player.damaged.connect(_on_player_damaged)
	player.shot_fired.connect(_on_player_shot)
	player.crime_committed.connect(_on_player_crime)
	return player

# ------------------------------------------------------------------ hud

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	_hud_layer = layer
	var label := Label.new()
	label.text = "WASD  move     SHIFT  sprint / car turbo     SPACE  jump     LMB  shoot     R  reload\nV  camera     F  flashlight     E  interact / enter car     C  fish (in boat)     T  chat     P  phone     M  radio mute     ESC  menu"
	label.position = Vector2(14.0, -40.0)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	label.add_theme_constant_override("outline_size", 4)
	var anchor := Label.new()
	anchor.text = "PICO PEAKS — 1.0.0 — every texture is procedural"
	anchor.position = Vector2(14.0, 10.0)
	anchor.add_theme_font_size_override("font_size", 15)
	anchor.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	anchor.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	anchor.add_theme_constant_override("outline_size", 4)
	layer.add_child(anchor)
	layer.add_child(label)
	_hud_clock = Label.new()
	_hud_clock.text = "09:00"
	_hud_clock.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_hud_clock.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hud_clock.position = Vector2(-60.0, 10.0)
	_hud_clock.size = Vector2(120.0, 24.0)
	_hud_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud_clock.add_theme_font_size_override("font_size", 18)
	_hud_clock.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	_hud_clock.add_theme_constant_override("outline_size", 4)
	layer.add_child(_hud_clock)
	_tornado_warn = Label.new()
	_tornado_warn.text = ""
	_tornado_warn.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_tornado_warn.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_tornado_warn.position = Vector2(-160.0, 44.0)
	_tornado_warn.size = Vector2(320.0, 24.0)
	_tornado_warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tornado_warn.add_theme_font_size_override("font_size", 17)
	_tornado_warn.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
	_tornado_warn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_tornado_warn.add_theme_constant_override("outline_size", 4)
	_tornado_warn.visible = false
	layer.add_child(_tornado_warn)
	_hud_prompt = Label.new()
	_hud_prompt.text = ""
	_hud_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hud_prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hud_prompt.position = Vector2(-200.0, -120.0)
	_hud_prompt.size = Vector2(400.0, 28.0)
	_hud_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud_prompt.add_theme_font_size_override("font_size", 16)
	_hud_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_hud_prompt.add_theme_constant_override("outline_size", 4)
	layer.add_child(_hud_prompt)
	_hud_ammo = Label.new()
	_hud_ammo.text = ""
	_hud_ammo.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hud_ammo.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hud_ammo.position = Vector2(-200.0, -76.0)
	_hud_ammo.size = Vector2(400.0, 28.0)
	_hud_ammo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud_ammo.add_theme_font_size_override("font_size", 16)
	_hud_ammo.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5, 0.9))
	_hud_ammo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_hud_ammo.add_theme_constant_override("outline_size", 4)
	layer.add_child(_hud_ammo)
	_turbo_label = Label.new()
	_turbo_label.text = "TURBO"
	_turbo_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_turbo_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_turbo_label.position = Vector2(-60.0, -196.0)
	_turbo_label.size = Vector2(120.0, 20.0)
	_turbo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_turbo_label.add_theme_font_size_override("font_size", 15)
	_turbo_label.add_theme_color_override("font_color", Color(0.55, 0.95, 1.0, 0.95))
	_turbo_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_turbo_label.add_theme_constant_override("outline_size", 4)
	_turbo_label.visible = false
	layer.add_child(_turbo_label)
	_turbo_bar = _make_bar(Color(0.35, 0.85, 1.0))
	_turbo_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_turbo_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_turbo_bar.position = Vector2(-105.0, -176.0)
	_turbo_bar.visible = false
	layer.add_child(_turbo_bar)
	_fish_status = Label.new()
	_fish_status.text = ""
	_fish_status.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_fish_status.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_fish_status.position = Vector2(-200.0, -156.0)
	_fish_status.size = Vector2(400.0, 28.0)
	_fish_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fish_status.add_theme_font_size_override("font_size", 16)
	_fish_status.add_theme_color_override("font_color", Color(0.55, 0.95, 1.0, 0.95))
	_fish_status.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_fish_status.add_theme_constant_override("outline_size", 4)
	_fish_status.visible = false
	layer.add_child(_fish_status)
	var holder := Control.new()
	holder.name = "Crosshair"
	holder.set_anchors_preset(Control.PRESET_CENTER)
	holder.size = Vector2.ZERO
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.visible = false
	layer.add_child(holder)
	var seg_col := Color(1.0, 1.0, 1.0, 0.85)
	var seg_w := 2
	var seg_len := 6
	var seg_gap := 4
	for seg in [[0, -seg_gap, seg_w, seg_len], [0, seg_gap, seg_w, seg_len],
			[-seg_gap, 0, seg_len, seg_w], [seg_gap, 0, seg_len, seg_w]]:
		var r := ColorRect.new()
		r.color = seg_col
		r.position = Vector2(seg[0] - seg[2] * 0.5, seg[1] - seg[3] * 0.5)
		r.size = Vector2(seg[2], seg[3])
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(r)
	_crosshair.append(holder)
	_hp_bar = _make_bar(Color(0.85, 0.2, 0.25))
	_hp_bar.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hp_bar.position = Vector2(16.0, -46.0)
	layer.add_child(_hp_bar)
	_stamina_bar = _make_bar(Color(0.3, 0.75, 1.0))
	_stamina_bar.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_stamina_bar.position = Vector2(16.0, -68.0)
	layer.add_child(_stamina_bar)
	_thirst_bar = _make_bar(Color(0.3, 0.55, 1.0))
	_thirst_bar.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_thirst_bar.position = Vector2(16.0, -90.0)
	layer.add_child(_thirst_bar)
	_hud_weather = Label.new()
	_hud_weather.text = "CLEAR   WIND 35%"
	_hud_weather.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hud_weather.position = Vector2(16.0, -118.0)
	_hud_weather.add_theme_font_size_override("font_size", 13)
	_hud_weather.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 0.8))
	_hud_weather.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	_hud_weather.add_theme_constant_override("outline_size", 4)
	layer.add_child(_hud_weather)
	_hud_day = Label.new()
	_hud_day.text = "DAY 1"
	_hud_day.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hud_day.position = Vector2(16.0, -136.0)
	_hud_day.add_theme_font_size_override("font_size", 13)
	_hud_day.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 0.8))
	_hud_day.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	_hud_day.add_theme_constant_override("outline_size", 4)
	layer.add_child(_hud_day)
	_hud_rad = Label.new()
	_hud_rad.text = "RAD 0%"
	_hud_rad.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hud_rad.position = Vector2(16.0, -154.0)
	_hud_rad.add_theme_font_size_override("font_size", 13)
	_hud_rad.add_theme_color_override("font_color", Color(0.45, 1.0, 0.3, 0.8))
	_hud_rad.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	_hud_rad.add_theme_constant_override("outline_size", 4)
	layer.add_child(_hud_rad)
	_phone_widget = Button.new()
	_phone_widget.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_phone_widget.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_phone_widget.grow_vertical = Control.GROW_DIRECTION_END
	_phone_widget.position = Vector2(-232.0, 10.0)
	_phone_widget.custom_minimum_size = Vector2(222.0, 46.0)
	_phone_widget.tooltip_text = "Open phone [P]"
	var w_normal := StyleBoxFlat.new()
	w_normal.bg_color = Color(0.04, 0.06, 0.09, 0.88)
	w_normal.set_corner_radius_all(12)
	w_normal.set_border_width_all(2)
	w_normal.border_color = Color(0.25, 0.4, 0.6)
	w_normal.content_margin_left = 12
	w_normal.content_margin_right = 12
	w_normal.content_margin_top = 6
	w_normal.content_margin_bottom = 6
	var w_hover := w_normal.duplicate()
	w_hover.bg_color = Color(0.07, 0.10, 0.14, 0.94)
	w_hover.border_color = Color(0.4, 0.6, 0.9)
	_phone_widget.add_theme_stylebox_override("normal", w_normal)
	_phone_widget.add_theme_stylebox_override("hover", w_hover)
	_phone_widget.add_theme_stylebox_override("pressed", w_hover)
	_phone_widget.add_theme_stylebox_override("focus", w_normal)
	_phone_widget_body = Label.new()
	_phone_widget_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	_phone_widget_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_phone_widget_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_phone_widget_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_phone_widget_body.text = "PHONE  [P]\n09:00  BAT 100%  GRID ..."
	_phone_widget_body.add_theme_font_size_override("font_size", 12)
	_phone_widget.add_child(_phone_widget_body)
	layer.add_child(_phone_widget)
	_compass = preload("res://scripts/compass.gd").new()
	_compass.world = self
	layer.add_child(_compass)
	_lamp_battery_label = Label.new()
	_lamp_battery_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_lamp_battery_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_lamp_battery_label.position = Vector2(-230.0, -18.0)
	_lamp_battery_label.add_theme_font_size_override("font_size", 13)
	_lamp_battery_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	_lamp_battery_label.add_theme_constant_override("outline_size", 4)
	_lamp_battery_label.text = ""
	layer.add_child(_lamp_battery_label)
	_rad_overlay = ColorRect.new()
	_rad_overlay.name = "Radiation"
	_rad_overlay.color = Color(0.45, 1.0, 0.3, 0.0)
	_rad_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rad_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_rad_overlay)
	_weather_flash = ColorRect.new()
	_weather_flash.name = "LightningFlash"
	_weather_flash.color = Color(0.95, 0.98, 1.0, 0.0)
	_weather_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_weather_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_weather_flash)
	_horror_viy = TextureRect.new()
	_horror_viy.name = "HorrorVignette"
	_horror_viy.self_modulate = Color(1.0, 1.0, 1.0, 0.0)
	_horror_viy.set_anchors_preset(Control.PRESET_FULL_RECT)
	_horror_viy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vg := Gradient.new()
	vg.offsets = PackedFloat32Array([0.0, 0.42, 0.58, 1.0])
	vg.colors = PackedColorArray([Color(0.0, 0.0, 0.0, 0.0),
		Color(0.12, 0.0, 0.0, 0.0), Color(0.24, 0.0, 0.02, 0.55), Color(0.04, 0.0, 0.01, 0.9)])
	var vtex := GradientTexture2D.new()
	vtex.gradient = vg
	vtex.width = 512
	vtex.height = 512
	vtex.fill = GradientTexture2D.FILL_RADIAL
	vtex.fill_from = Vector2(0.5, 0.5)
	vtex.fill_to = Vector2(0.5, 0.0)
	_horror_viy.texture = vtex
	_horror_viy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_horror_viy.stretch_mode = TextureRect.STRETCH_SCALE
	_horror_viy.visible = true
	layer.add_child(_horror_viy)

	var hud_root := Control.new()
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.pivot_offset = Vector2.ZERO
	for c in layer.get_children():
		layer.remove_child(c)
		hud_root.add_child(c)
	layer.add_child(hud_root)
	_hud_root = hud_root

	add_child(layer)

	var chat_layer := CanvasLayer.new()
	chat_layer.layer = 11
	_chat_box = preload("res://scripts/chat_box.gd").new()
	_chat_box.message_sent.connect(_on_chat_sent)
	chat_layer.add_child(_chat_box)
	add_child(chat_layer)

	var console_layer := CanvasLayer.new()
	console_layer.layer = 15
	_console = preload("res://scripts/console.gd").new()
	_console.set("world", self)
	console_layer.add_child(_console)
	add_child(console_layer)

	var sleep_layer := CanvasLayer.new()
	sleep_layer.layer = 20
	_sleep_fade = ColorRect.new()
	_sleep_fade.color = Color(0, 0, 0, 0)
	_sleep_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sleep_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sleep_layer.add_child(_sleep_fade)
	_hurt_flash = ColorRect.new()
	_hurt_flash.color = Color(0.9, 0.1, 0.1, 0.0)
	_hurt_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hurt_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sleep_layer.add_child(_hurt_flash)
	_sleep_zzz = Label.new()
	_sleep_zzz.text = "z Z z..."
	_sleep_zzz.set_anchors_preset(Control.PRESET_CENTER)
	_sleep_zzz.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_sleep_zzz.grow_vertical = Control.GROW_DIRECTION_BOTH
	_sleep_zzz.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sleep_zzz.add_theme_font_size_override("font_size", 48)
	_sleep_zzz.add_theme_color_override("font_color", Color(0.8, 0.85, 1.0))
	_sleep_zzz.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	_sleep_zzz.add_theme_constant_override("outline_size", 6)
	_sleep_zzz.visible = false
	sleep_layer.add_child(_sleep_zzz)
	add_child(sleep_layer)

func _is_mobile() -> bool:
	var osn := OS.get_name()
	if osn == "Android" or osn == "iOS":
		return true
	return DisplayServer.get_name() == "android" or DisplayServer.get_name() == "iOS"


func _default_quality() -> int:
	if _is_mobile():
		return 0
	return 2


func _apply_ui_scale() -> void:
	if _hud_root:
		_hud_root.scale = Vector2.ONE * _ui_scale
	if _touch_controls and is_instance_valid(_touch_controls):
		_touch_controls.set("ui_scale", _ui_scale)


func _touch_look(dx: float, dy: float) -> void:
	if _player and _player.has_method("touch_look"):
		_player.touch_look(dx, dy)


func _touch_move(v2: Vector2) -> void:
	if _player and is_instance_valid(_player):
		_player.set("touch_move_vec", v2)


func _toggle_pause() -> void:
	if _pause_menu == null or not is_instance_valid(_pause_menu):
		return
	if bool(_pause_menu.get("visible")):
		_pause_menu.call("close")
	else:
		_pause_menu.call("open")


func _toggle_chat() -> void:
	if _chat_box == null or not is_instance_valid(_chat_box):
		return
	if bool(_chat_box.call("is_open")):
		_chat_box.call("close")
	else:
		_chat_box.call("open")


func _build_touch_controls() -> void:
	if not _is_mobile():
		return
	if _server:
		return
	var layer := CanvasLayer.new()
	layer.layer = 25
	var tc := preload("res://scripts/touch_controls.gd").new()
	tc.world = self
	layer.add_child(tc)
	add_child(layer)
	_touch_controls = tc
	_apply_ui_scale()


func _make_bar(fill: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = false
	bar.size = Vector2(210.0, 18.0)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.0, 0.0, 0.0, 0.5)
	bg.set_corner_radius_all(5)
	bar.add_theme_stylebox_override("background", bg)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(5)
	bar.add_theme_stylebox_override("fill", fg)
	return bar


func _boost_style(boost: float) -> StyleBoxFlat:
	var fg := StyleBoxFlat.new()
	fg.bg_color = Color(0.35, 0.85, 1.0).lerp(Color(1.0, 0.45, 0.1), boost)
	fg.set_corner_radius_all(5)
	return fg

func _build_debug_menu(player: Node3D) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	var menu := preload("res://scripts/debug_menu.gd").new()
	menu.setup(player, self)
	layer.add_child(menu)
	add_child(layer)


func _build_pause_menu(player: Node3D) -> void:
	var menu := preload("res://scripts/pause_menu.gd").new()
	menu.name = "PauseMenu"
	menu.set("world", self)
	menu.setup(_env, _cam_attr, player as CharacterBody3D)
	menu.resume_requested.connect(menu.close)
	menu.quit_requested.connect(_on_quit_game)
	menu.save_and_quit_requested.connect(_on_save_and_quit)
	menu.grass_density_changed.connect(_on_grass_density_changed)
	menu.mangohud_toggled.connect(_on_mangohud_toggled)
	menu.video_settings_changed.connect(_on_video_settings_changed)
	menu.quality_changed.connect(_on_quality_changed)
	menu.ui_scale_changed.connect(_on_ui_scale_changed)
	add_child(menu)
	_pause_menu = menu
	menu.set_quality(_quality)
	menu.set_ui_scale(_ui_scale)

func _build_main_menu(player: Node3D) -> void:
	var menu := preload("res://scripts/main_menu.gd").new()
	menu.name = "MainMenu"
	menu.setup(_env, _cam_attr, player as CharacterBody3D)
	menu.start_world.connect(_on_start_world)
	menu.quit_requested.connect(_on_quit_game)
	menu.grass_density_changed.connect(_on_grass_density_changed)
	menu.mangohud_toggled.connect(_on_mangohud_toggled)
	menu.video_settings_changed.connect(_on_video_settings_changed)
	menu.quality_changed.connect(_on_quality_changed)
	menu.ui_scale_changed.connect(_on_ui_scale_changed)
	add_child(menu)
	_main_menu = menu
	if _shot or _walk or _drive or _ztest or _sanity or _rooftest:
		return
	if _auto_start:
		_auto_start = false
		_config.set_value("world", "start_now", false)
		_config.save(_config_path)
		get_tree().paused = false
		return
	menu.set_mangohud(_mangohud_on)
	menu.set_quality(_quality)
	menu.set_ui_scale(_ui_scale)
	menu.open()

func _on_start_world(name: String, seed: int, season: String) -> void:
	_config.set_value("world", "name", name)
	_config.set_value("world", "seed", seed)
	_config.set_value("world", "season", season)
	_config.set_value("world", "start_now", true)
	_config.save(_config_path)
	get_tree().reload_current_scene()

func _save_current_world() -> void:
	var cf := ConfigFile.new()
	cf.load("user://worlds.cfg")
	var name := String(_config.get_value("world", "name", "Default"))
	cf.set_value(name, "seed", _world_seed)
	cf.set_value(name, "season", _season)
	cf.set_value(name, "time", _time_of_day)
	if _player != null and is_instance_valid(_player):
		var p := _player.global_position
		cf.set_value(name, "px", p.x)
		cf.set_value(name, "py", p.y)
		cf.set_value(name, "pz", p.z)
		cf.set_value(name, "pyaw", float(_player.get("_yaw")))
		cf.set_value(name, "phealth", float(_player.get("health")))
		cf.set_value(name, "pstamina", float(_player.get("stamina")))
		cf.set_value(name, "pthirst", float(_player.get("thirst")))
		cf.set_value(name, "pammo", int(_player.get("ammo")))
		cf.set_value(name, "preserve_ammo", int(_player.get("reserve_ammo")))
		cf.set_value(name, "phas_gun", bool(_player.get("has_gun")))
	cf.set_value(name, "fish_basket", _fish_basket)
	cf.set_value(name, "tasks", _tasks)
	cf.set_value(name, "task_count", _task_count)
	var crops: Array = []
	for plot in _farm_plots:
		if plot == null or not is_instance_valid(plot):
			continue
		crops.append([int(plot.get("crop_type")), float(plot.get("growth"))])
	cf.set_value(name, "crops", crops)
	cf.save("user://worlds.cfg")


func _restore_world_state() -> void:
	if _server or _client:
		return
	var cf := ConfigFile.new()
	if cf.load("user://worlds.cfg") != OK:
		return
	var name := String(_config.get_value("world", "name", "Default"))
	if not cf.has_section(name):
		return
	if cf.has_section_key(name, "time"):
		_time_of_day = float(cf.get_value(name, "time", _time_of_day))
	if _player != null and is_instance_valid(_player):
		if cf.has_section_key(name, "px"):
			var y := float(cf.get_value(name, "py", _height_at(0.0, 0.0) + 2.0))
			_player.global_position = Vector3(
				float(cf.get_value(name, "px")),
				y,
				float(cf.get_value(name, "pz")))
			_player.set("_yaw", float(cf.get_value(name, "pyaw", 0.0)))
			_player.set("health", float(cf.get_value(name, "phealth", 100.0)))
			_player.set("stamina", float(cf.get_value(name, "pstamina", 100.0)))
			_player.set("thirst", float(cf.get_value(name, "pthirst", 100.0)))
			_player.set("ammo", int(cf.get_value(name, "pammo", 12)))
			_player.set("reserve_ammo", int(cf.get_value(name, "preserve_ammo", 24)))
			_player.set("has_gun", bool(cf.get_value(name, "phas_gun", false)))
			_player.call("_apply_rot")
	if cf.has_section_key(name, "fish_basket"):
		_fish_basket = int(cf.get_value(name, "fish_basket", 0))
	if cf.has_section_key(name, "tasks"):
		var saved_tasks = cf.get_value(name, "tasks")
		if saved_tasks is Dictionary:
			for k in _tasks:
				if saved_tasks.has(k) and bool(saved_tasks[k]):
					_tasks[k] = true
			_task_count = int(cf.get_value(name, "task_count", _task_count))
	var saved_crops = cf.get_value(name, "crops", [])
	if saved_crops is Array:
		for i in _farm_plots.size():
			if i < saved_crops.size():
				var row = saved_crops[i]
				if row is Array and row.size() >= 2:
					var plot: Node3D = _farm_plots[i]
					if plot != null and is_instance_valid(plot):
						plot.set("crop_type", int(row[0]))
						plot.set("growth", float(row[1]))

func _on_save_and_quit() -> void:
	_save_current_world()
	_config.set_value("world", "start_now", false)
	_config.save(_config_path)
	get_tree().reload_current_scene()

func _load_settings() -> void:
	_config.load(_config_path)
	_mangohud_on = _config.get_value("graphics", "mangohud", false)
	if _config.has_section_key("graphics", "ui_scale"):
		_ui_scale = float(_config.get_value("graphics", "ui_scale", 1.0))
	else:
		_ui_scale = 1.4 if _is_mobile() else 1.0
	_pause_menu.set_mangohud(_mangohud_on)
	_write_mangohud_conf()
	_apply_video_settings()

func _save_settings() -> void:
	_config.set_value("graphics", "quality", _quality)
	_config.set_value("graphics", "mangohud", _mangohud_on)
	_config.set_value("graphics", "width", _video_width)
	_config.set_value("graphics", "height", _video_height)
	_config.set_value("graphics", "window_mode", _video_mode)
	_config.set_value("graphics", "ui_scale", _ui_scale)
	_config.save(_config_path)

func _on_ui_scale_changed(v: float) -> void:
	_ui_scale = clampf(v, 0.7, 1.8)
	_apply_ui_scale()
	_save_settings()

func _on_video_settings_changed(width: int, height: int, mode: String) -> void:
	_video_width = width
	_video_height = height
	_video_mode = mode
	_save_settings()
	_apply_video_settings()

func _apply_video_settings() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var w := int(_config.get_value("graphics", "width", 0))
	var h := int(_config.get_value("graphics", "height", 0))
	if w <= 0 or h <= 0:
		w = DisplayServer.window_get_size().x
		h = DisplayServer.window_get_size().y
	_video_width = w
	_video_height = h
	_video_mode = String(_config.get_value("graphics", "window_mode", "windowed"))
	_set_window_mode(_video_mode, w, h)

func _set_window_mode(mode: String, w: int, h: int) -> void:
	if DisplayServer.get_name() == "headless":
		return
	match mode:
		"fullscreen":
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"borderless":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			var ss := DisplayServer.screen_get_size()
			DisplayServer.window_set_size(ss)
			DisplayServer.window_set_position(Vector2i.ZERO)
		_:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(Vector2i(w, h))

func _on_mangohud_toggled(on: bool) -> void:
	_mangohud_on = on
	_save_settings()
	_write_mangohud_conf()

func _write_mangohud_conf() -> void:
	var exe := OS.get_executable_path()
	if not exe.get_file().begins_with("pico-peaks"):
		return
	var conf := exe.get_base_dir().path_join("mangohud.conf")
	var f := FileAccess.open(conf, FileAccess.WRITE)
	if f == null:
		return
	f.store_string("enabled=%s\n" % ("true" if _mangohud_on else "false"))
	f.close()

func _on_quit_game() -> void:
	get_tree().quit()

func _on_grass_density_changed(density: float) -> void:
	_build_grass(int(12000.0 * clampf(density, 0.0, 2.0)))

func _apply_quality() -> void:
	if _sanity:
		return
	var p: Dictionary = QUALITY_PRESETS[_quality]
	if _env:
		_env.sdfgi_enabled = bool(p["sdfgi"])
		_env.sdfgi_cascades = int(p["sdfgi_cascades"])
		_env.sdfgi_cascade0_distance = float(p["cascade0"])
		_env.sdfgi_max_distance = float(p["sdfgi_max"])
		_env.volumetric_fog_enabled = bool(p["volumetric"])
		_env.glow_enabled = bool(p["glow"])
		_env.ssr_enabled = bool(p["ssr"])
		_env.ssao_enabled = bool(p["ssao"])
		_env.fog_enabled = bool(p["fog"])
	if _cam_attr:
		_cam_attr.dof_blur_far_enabled = bool(p["dof"])
		_cam_attr.auto_exposure_enabled = bool(p["autoexp"])
	if _sun:
		_sun.shadow_enabled = bool(p["shadow"])
		_sun.set("directional_shadow_max_distance", float(p["shadow"]))
	var vp := get_viewport()
	if DisplayServer.get_name() != "headless" and vp is Viewport:
		vp.msaa_3d = int(p["msaa"])
		vp.scaling_3d_scale = float(p["scale"])

func _on_quality_changed(quality: int) -> void:
	_quality = clampi(quality, 0, QUALITY_PRESETS.size() - 1)
	_apply_quality()
	_save_settings()
	_build_grass(_grass_count())
	_apply_prop_density()

func _apply_prop_density() -> void:
	var p: Dictionary = QUALITY_PRESETS[_quality]
	_show_n(_tree_mi, 9000.0 * float(p["trees"]))
	_show_n(_fol_mi, 9000.0 * float(p["trees"]))
	_show_n(_rock_mi, 900.0 * float(p["rocks"]))
	_show_n(_pine_trunk_mi, 2200.0 * float(p["pine"]))
	_show_n(_pine_fol_mi, 2200.0 * float(p["pine"]))
	_show_n(_sakura_trunk_mi, 350.0 * float(p["sakura"]))
	_show_n(_sakura_fol_mi, 350.0 * float(p["sakura"]))
	_show_n(_bush_mi, 340.0 * float(p["bush"]))
	_show_n(_flower_mi, 600.0 * float(p["flower"]))

func _show_n(mi: MultiMeshInstance3D, count: float) -> void:
	if mi:
		mi.visible_instance_count = maxi(0, int(count))

# ------------------------------------------------------------------ screenshot

func _build_shot_camera() -> void:
	var cam := Camera3D.new()
	cam.name = "ShotCam"
	cam.fov = 70.0
	cam.near = 0.05
	cam.far = 3200.0
	var px := 0.0
	var pz := -9.0
	var h := _height_at(px, pz) + 1.6
	add_child(cam)
	cam.global_position = Vector3(px, h, pz)
	cam.look_at(Vector3(0.0, 5.0, 14.0), Vector3.UP)
	cam.current = true
	DisplayServer.window_set_size(Vector2i(1280, 720))

func _shot_capture() -> void:
	if DisplayServer.get_name() == "headless":
		print("[shot] skipped (headless renderer)")
		get_tree().quit()
		return
	for i in 150:
		await get_tree().process_frame
	var img: Image
	for attempt in 4:
		await get_tree().process_frame
		img = get_viewport().get_texture().get_image()
		if not img:
			continue
		var p := img.get_pixel(640, 360)
		if p.r > 0.02 or p.g > 0.02 or p.b > 0.02:
			break
	if img:
		img.save_png("/home/nicholas/mygame/shot.png")
		print("[shot] saved px=", img.get_pixel(640, 360))
	get_tree().quit()

func _walk_capture() -> void:
	var pos_prints := 0
	for i in 300:
		await get_tree().process_frame
		if _player and pos_prints < 5 and i % 60 == 0:
			var p := _player as CharacterBody3D
			print("[walk] t=", i, " y=", snappedf(_player.global_position.y, 0.01),
				" on_floor=", p.is_on_floor() if p else "?")
			pos_prints += 1
	await get_tree().physics_frame
	await get_tree().physics_frame
	var space := get_world_3d().direct_space_state
	var p := _player as CharacterBody3D
	var p_rid: RID = p.get_rid() if p else RID()
	for gx in [-60.0, -30.0, -10.0, 0.0, 10.0, 30.0, 60.0]:
		for gz in [-30.0, 0.0, 30.0]:
			var q2 := PhysicsRayQueryParameters3D.create(Vector3(gx, 200.0, gz), Vector3(gx, -200.0, gz))
			q2.exclude = [p_rid]
			var h2 := space.intersect_ray(q2)
			var vis := _height_at(gx, gz)
			print("[ray] (", gx, ",", gz, ") coll=",
				snappedf(h2.position.y, 0.01) if h2 else "NONE",
				" vis=", snappedf(vis, 0.01))
	if p:
		p.global_position = Vector3(50.0, 30.0, 50.0)
		p.velocity = Vector3.ZERO
		for i2 in 240:
			await get_tree().physics_frame
		print("[walk] dropped_y=", snappedf(p.global_position.y, 0.01),
			" pos=", p.global_position, " on_floor=", p.is_on_floor(),
			" vis=", snappedf(_height_at(p.global_position.x, p.global_position.z), 0.01))
	if _player:
		var start := _player.global_position
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		Input.action_press("move_forward")
		await get_tree().process_frame
		await get_tree().process_frame
		for i2 in 60:
			await get_tree().physics_frame
		Input.action_release("move_forward")
		var end := _player.global_position
		print("[walk] forward move: start=", start, " end=", end,
			" dist=", snappedf(start.distance_to(end), 0.01))
		print("[walk] ground_y_at_spawn=", snappedf(_height_at(0.0, 0.0), 0.01),
			" player_y=", snappedf(_player.global_position.y, 0.01))
	if DisplayServer.get_name() != "headless":
		var img := get_viewport().get_texture().get_image()
		if img:
			img.save_png("/home/nicholas/mygame/walk.png")
	get_tree().quit()

func _drive_test() -> void:
	await get_tree().process_frame
	var car: CharacterBody3D = null
	for c in get_children():
		if c is CharacterBody3D and c.name == "Car":
			car = c as CharacterBody3D
			break
	if car == null:
		print("[drive] no car found")
		get_tree().quit()
		return
	var start := car.global_position
	_enter_car(car)
	car.set("_speed", 12.0)
	for i in 90:
		await get_tree().physics_frame
	var end := car.global_position
	var dist := start.distance_to(end)
	var cam := car.get_node_or_null("Camera3D") as Camera3D
	var rel := Vector3.ZERO
	if cam:
		rel = cam.global_position - car.global_position
	print("[drive] car moved ", snappedf(dist, 0.01),
		" on_floor=", car.is_on_floor(),
		" in_car=", bool(_player.get("in_car")),
		" cam_current=", (_player.get_node("CameraRig/Camera") as Camera3D).current,
		" cam_rel_z=", snappedf(rel.z, 0.01))
	_exit_car(car)
	await get_tree().physics_frame
	print("[drive] exit in_car=", bool(_player.get("in_car")),
		" player_pos=", _player.global_position)
	get_tree().quit()



func _zombie_test() -> void:
	await get_tree().process_frame
	print("[ztest] time=", _time_of_day, " zombies=", get_tree().get_nodes_in_group("zombies").size())
	_time_of_day = 21.0
	for i in 10:
		await get_tree().process_frame
	var zombies := get_tree().get_nodes_in_group("zombies")
	print("[ztest] night zombies=", zombies.size())
	var houses := get_tree().get_nodes_in_group("houses")
	if zombies.is_empty():
		print("[ztest] FAIL no zombies spawned")
		get_tree().quit()
		return
	var zed := zombies[0] as Node3D
	var layer := (zed as CollisionObject3D).collision_layer
	var mask := (zed as CollisionObject3D).collision_mask
	print("[ztest] zombie layer=", layer, " mask=", mask)
	if not houses.is_empty():
		var h := houses[0] as Node3D
		var interior: Vector3 = h.to_global(h.get_meta("interior_local"))
		if _player:
			_player.global_position = interior
			_player.velocity = Vector3.ZERO
		zed.global_position = h.to_global(h.get_meta("entry_local")) + Vector3(0.0, 0.0, 3.0)
		zed.velocity = Vector3.ZERO
		for i in 120:
			await get_tree().physics_frame
		var after := Vector2(interior.x, interior.z).distance_to(Vector2(zed.global_position.x, zed.global_position.z))
		var reach := zed.global_position.distance_to(_player.global_position)
		print("[ztest] door_block dist_to_interior=", snappedf(after, 0.01),
			" dist_to_player=", snappedf(reach, 0.01),
			" inside=", after < 2.0, " reached_player=", reach < 1.5)
	_time_of_day = 8.0
	for i in 5:
		await get_tree().process_frame
	print("[ztest] day zombies=", get_tree().get_nodes_in_group("zombies").size())
	print("[ztest] DONE")
	get_tree().quit()


func _roof_test() -> void:
	await get_tree().process_frame
	var houses := get_tree().get_nodes_in_group("houses")
	if houses.is_empty():
		print("[rooftest] FAIL no houses")
		get_tree().quit()
		return
	var h := houses[0] as Node3D
	var spawn_ok := _spawn_tornado_at(Vector2(h.global_position.x + 3.0, h.global_position.z))
	print("[rooftest] tornado_spawned=", spawn_ok, " house_pos=", h.global_position,
		" roof_pieces=", _roof_piece_count(h))
	if not spawn_ok:
		get_tree().quit()
		return
	var prev := 0.0
	for mark in [6.0, 16.0]:
		await get_tree().create_timer(mark - prev).timeout
		prev = mark
		var roofs := 0
		var houses_hit := 0
		for tn in _tornadoes:
			if not is_instance_valid(tn):
				continue
			roofs += int(tn.get("_roofs").size())
			houses_hit += int(tn.get("_ripped").size())
		print("[rooftest] t=%.2f roofs_airborne=%d houses_ripped=%d tornadoes=%d" % [_time_of_day, roofs, houses_hit, _tornadoes.size()])
	print("[rooftest] DONE")
	get_tree().quit()


func _roof_piece_count(h: Node3D) -> int:
	var c := 0
	for ch in h.get_children():
		if ch is MeshInstance3D and ch.is_in_group("roofs"):
			c += 1
	return c


# ---------------------------------------------------------------- wolves (new)

func _build_wolves() -> void:
	if _villages.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 133
	var v := _villages[0]
	var count := 2 if _ram_scale() >= 1.0 else 1
	for i in range(count + 1):
		var ang := rng.randf() * TAU
		var dist := rng.randf_range(140.0, 340.0)
		var x := v.x + cos(ang) * dist
		var z := v.y + sin(ang) * dist
		if absf(x) > 940.0 or absf(z) > 940.0:
			continue
		var h := _height_at(x, z)
		if h < 2.0 or h > 20.0:
			continue
		if _slope_at(x, z) > 0.4:
			continue
		var w := preload("res://scripts/wolf.gd").new()
		w.name = "Wolf"
		w.set("world", self)
		w.position = Vector3(x, h, z)
		add_child(w)
		_wolves.append(w)


func _wolf_watch() -> void:
	if _is_night():
		if not _wolf_active:
			_wolf_active = true
			_alert("System", "You hear wolves howling in the hills...")
	else:
		if _wolf_active:
			_wolf_active = false
			for w in _wolves:
				if is_instance_valid(w) and w.has_method("do_despawn"):
					w.call("do_despawn")


func _tick_wolves(delta: float) -> void:
	if _wolf_active:
		for i in range(_wolves.size() - 1, -1, -1):
			var w: Node = _wolves[i]
			if w == null or not is_instance_valid(w):
				_wolves.remove_at(i)
				continue
			if bool(w.get("_dead")):
				_wolves.remove_at(i)
	if not _wolf_active and _wolves.is_empty() and _ram_scale() >= 1.0:
		_build_wolves()


func _wolf_died(w: Node3D) -> void:
	if _server or _client:
		return
	if not _tasks["wolf"]:
		_complete_task("wolf", "Defeated a hungry wolf")


func _build_wildlife() -> void:
	if _villages.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 161
	var v := _villages[0]
	var haystack: Array = [
		[2, 130.0, 360.0, "Bear"],
		[1, 150.0, 380.0, "Boar"],
	]
	for entry in haystack:
		var count := int(entry[0])
		for i in range(count):
			var ang := rng.randf() * TAU
			var dist := rng.randf_range(float(entry[1]), float(entry[2]))
			var x := v.x + cos(ang) * dist
			var z := v.y + sin(ang) * dist
			if absf(x) > 940.0 or absf(z) > 940.0:
				continue
			var h := _height_at(x, z)
			if h < 1.0 or h > 22.0:
				continue
			if _slope_at(x, z) > 0.45:
				continue
			var kind := 0 if String(entry[3]) == "Bear" else 1
			var w := preload("res://scripts/wildlife.gd").new()
			w.name = "Wildlife_%d" % _wildlife_counter
			_wildlife_counter += 1
			w.set("world", self)
			w.set("kind", kind)
			w.position = Vector3(x, h, z)
			add_child(w)
			_wildlife.append(w)


func _bear_died(w: Node3D) -> void:
	if _server or _client:
		return
	if not _tasks["bear"]:
		_complete_task("bear", "Felled a mountain bear")


func _boar_died(w: Node3D) -> void:
	if _server or _client:
		return
	if not _tasks["boar"]:
		_complete_task("boar", "Took down a wild boar")


# ---------------------------------------------------------------- meteors (new)

func _spawn_meteor() -> void:
	if _server or _client:
		return
	var center := _player.global_position if _player != null else Vector3.ZERO
	var attempts := 0
	while attempts < 40 and _craters.size() < 6:
		attempts += 1
		var ang := randf() * TAU
		var dist := randf_range(140.0, 480.0)
		var lx := center.x + cos(ang) * dist
		var lz := center.z + sin(ang) * dist
		if absf(lx) > 940.0 or absf(lz) > 940.0:
			continue
		var lh := _height_at(lx, lz)
		if lh < 1.5:
			continue
		if _slope_at(lx, lz) > 0.5:
			continue
		var start := Vector3(lx + randf_range(-60.0, 60.0), randf_range(160.0, 200.0), lz + randf_range(-60.0, 60.0))
		var impact := Vector3(lx, lh, lz)
		var vel := (impact - start).normalized() * 90.0
		var life := (impact - start).length() / 90.0
		var node := Node3D.new()
		node.name = "Meteor"
		add_child(node)
		var body_mat := StandardMaterial3D.new()
		body_mat.albedo_color = Color(0.55, 0.5, 0.4)
		body_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		body_mat.emission_enabled = true
		body_mat.emission = Color(1.0, 0.6, 0.2) * 0.8
		var bm := SphereMesh.new()
		bm.radius = 1.1
		bm.height = 2.2
		var body := MeshInstance3D.new()
		body.mesh = bm
		body.material_override = body_mat
		node.add_child(body)
		var trail := MeshInstance3D.new()
		var tsm := BoxMesh.new()
		tsm.size = Vector3(0.4, 0.4, 16.0)
		trail.mesh = tsm
		trail.material_override = body_mat
		trail.position = Vector3(0.0, 0.0, 8.0)
		node.add_child(trail)
		var lamp := OmniLight3D.new()
		lamp.light_color = Color(1.0, 0.5, 0.2)
		lamp.light_energy = 10.0
		lamp.omni_range = 40.0
		node.add_child(lamp)
		node.set("_vel", vel)
		node.set("_life", life)
		node.set("_impact", impact)
		node.set("_start", start)
		node.set("_trail", trail)
		node.set("_lamp", lamp)
		node.set("_t", 0.0)
		node.set("_impacted", false)
		_craters.append(node)
		return


func _tick_meteors(delta: float) -> void:
	for j in range(get_child_count() - 1, -1, -1):
		var crater := get_child(j)
		if crater != null and (crater is Node3D) and crater.is_in_group("crater"):
			var glow: OmniLight3D = crater.get_meta("glow", null)
			if glow and is_instance_valid(glow):
				glow.light_energy = maxf(0.0, float(glow.light_energy) - delta * 1.2)
	for i in range(_craters.size() - 1, -1, -1):
		var meteor: Node = _craters[i]
		if meteor == null or not is_instance_valid(meteor):
			_craters.remove_at(i)
			continue
		var t := float(meteor.get("_t"))
		var impacted: bool = bool(meteor.get("_impacted"))
		if not impacted:
			t += delta
			meteor.set("_t", t)
			var life: float = meteor.get("_life")
			var impact: Vector3 = meteor.get("_impact")
			var start: Vector3 = meteor.get("_start")
			var age := clampf(t / life, 0.0, 1.0)
			meteor.global_position = start.lerp(impact, age)
			meteor.look_at(start.lerp(impact, minf(age + 0.02, 1.0)) + meteor.get("_vel").normalized(), Vector3.UP)
			if age >= 1.0:
				impacted = true
				meteor.set("_impacted", true)
				_meteor_impact(meteor, impact)
		else:
			var life2: float = meteor.get("_life")
			t += delta
			meteor.set("_t", t)
			if t > life2 + 1.0:
				meteor.queue_free()
				_craters.remove_at(i)
				continue
			var lamp: OmniLight3D = meteor.get("_lamp")
			if lamp:
				lamp.light_energy = maxf(0.0, 10.0 - (t - life2) * 8.0)
			var trail: MeshInstance3D = meteor.get("_trail")
			if trail:
				trail.visible = false


func _meteor_impact(meteor: Node, impact: Vector3) -> void:
	if _server or _client:
		return
	_make_crater(impact)
	_alert("ALARM", "METEOR IMPACT — a meteor has cratered the ground near your position! Collect what it exposed.")
	if _player and is_instance_valid(_player):
		_quake_t = maxf(_quake_t, 2.0)
	for i in 5:
		var off := Vector3(randf_range(-6.0, 6.0), 0.6, randf_range(-6.0, 6.0))
		if randf() < 0.5:
			_make_star_shard(impact + off)
		else:
			_make_mineral_pickup(impact + off)
	if not _tasks["meteor"]:
		_complete_task("meteor", "Witnessed a meteor crash")


func _make_crater(at: Vector3) -> void:
	var crater := Node3D.new()
	crater.name = "Crater"
	crater.position = at
	crater.set_meta("done", true)
	crater.add_to_group("crater")
	add_child(crater)
	var rim_mat := StandardMaterial3D.new()
	rim_mat.albedo_color = Color(0.22, 0.18, 0.14)
	rim_mat.roughness = 1.0
	for i in 16:
		var ang := float(i) / 16.0 * TAU
		var rr := randf_range(2.2, 3.2)
		var lump := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(0.8, 0.4, 0.8)
		lump.mesh = lm
		lump.material_override = rim_mat
		lump.position = Vector3(cos(ang) * rr, 0.12, sin(ang) * rr)
		lump.rotation.y = ang
		crater.add_child(lump)
	var glow_lamp := OmniLight3D.new()
	glow_lamp.light_color = Color(1.0, 0.5, 0.2)
	glow_lamp.light_energy = 3.0
	glow_lamp.omni_range = 12.0
	crater.add_child(glow_lamp)
	crater.set_meta("glow", glow_lamp)
	var smoke_mat := StandardMaterial3D.new()
	smoke_mat.albedo_color = Color(0.2, 0.2, 0.2, 0.5)
	smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var smoke_particles := GPUParticles3D.new()
	smoke_particles.name = "Smoke"
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.spread = 20.0
	pm.initial_velocity_min = 1.0
	pm.initial_velocity_max = 3.0
	pm.gravity = Vector3(0.0, 1.0, 0.0)
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.3
	pm.scale_min = 0.5
	pm.scale_max = 1.5
	pm.color = Color(0.25, 0.25, 0.25, 0.6)
	pm.lifetime_min = 2.0
	pm.lifetime_max = 4.0
	smoke_particles.process_material = pm
	smoke_particles.amount = 24
	smoke_particles.lifetime = 3.5
	smoke_particles.one_shot = true
	smoke_particles.material_override = smoke_mat
	smoke_particles.position = Vector3(0.0, 0.6, 0.0)
	crater.add_child(smoke_particles)
	smoke_particles.emitting = true


# ---------------------------------------------------------------- bunkers (new)

func _build_bunkers() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 149
	var placed := 0
	var tries := 0
	while placed < 2 and tries < 300:
		tries += 1
		var ang := rng.randf() * TAU
		var dist := rng.randf_range(220.0, 480.0)
		var x := cos(ang) * dist
		var z := sin(ang) * dist
		if absf(x) > 930.0 or absf(z) > 930.0:
			continue
		var h := _height_at(x, z)
		if h < 2.0 or h > 18.0:
			continue
		if _slope_at(x, z) > 0.3:
			continue
		var clear := true
		for house in get_tree().get_nodes_in_group("houses"):
			var hp2: Vector3 = (house as Node3D).global_position
			if Vector2(x, z).distance_to(Vector2(hp2.x, hp2.z)) < 30.0:
				clear = false
				break
		if not clear:
			continue
		_make_bunker(Vector3(x, h, z), rng)
		placed += 1


func _make_bunker(pos: Vector3, rng: RandomNumberGenerator) -> Node3D:
	var node := Node3D.new()
	node.name = "Bunker"
	node.add_to_group("bunkers")
	node.position = pos
	var concrete := StandardMaterial3D.new()
	concrete.albedo_color = Color(0.45, 0.46, 0.48)
	concrete.roughness = 0.95
	var door_mat := StandardMaterial3D.new()
	door_mat.albedo_color = Color(0.3, 0.32, 0.3)
	door_mat.roughness = 0.9
	var hazard_mat := StandardMaterial3D.new()
	hazard_mat.albedo_color = Color(0.9, 0.75, 0.1)
	hazard_mat.emission_enabled = true
	hazard_mat.emission = Color(0.9, 0.75, 0.1) * 0.4
	var top := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(9.0, 1.0, 7.0)
	top.mesh = tm
	top.material_override = concrete
	top.position = Vector3(0.0, 1.0, 0.0)
	node.add_child(top)
	for ex in [-3.0, 3.0]:
		for ez in [-2.0, 2.0]:
			var lump := MeshInstance3D.new()
			var lsm := BoxMesh.new()
			lsm.size = Vector3(0.9, 0.5, 0.9)
			lump.mesh = lsm
			lump.material_override = concrete
			lump.position = Vector3(ex, 0.3, ez)
			lump.rotation.y = rng.randf() * TAU
			node.add_child(lump)
	var hatch := MeshInstance3D.new()
	var hm := BoxMesh.new()
	hm.size = Vector3(2.2, 0.4, 2.2)
	hatch.mesh = hm
	hatch.material_override = door_mat
	hatch.position = Vector3(0.0, 1.35, 0.0)
	node.add_child(hatch)
	var strip := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(2.2, 0.1, 0.25)
	strip.mesh = sm
	strip.material_override = hazard_mat
	strip.position = Vector3(0.0, 1.55, -0.2)
	node.add_child(strip)
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(0.8, 0.7, 0.4)
	lamp.light_energy = 2.0
	lamp.omni_range = 14.0
	lamp.position = Vector3(0.0, 2.0, 0.0)
	node.add_child(lamp)
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(9.0, 1.6, 7.0)
	col.shape = bs
	col.position = Vector3(0.0, 1.0, 0.0)
	body.add_child(col)
	node.add_child(body)
	var ladder := MeshInstance3D.new()
	var ldm := BoxMesh.new()
	ldm.size = Vector3(0.1, 0.6, 0.1)
	ladder.mesh = ldm
	ladder.material_override = door_mat
	ladder.position = Vector3(0.0, 1.7, 2.4)
	node.add_child(ladder)
	var sign := Label3D.new()
	sign.text = "BUNKER"
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.pixel_size = 0.005
	sign.outline_size = 6
	sign.modulate = Color(0.9, 0.9, 0.95)
	sign.position = Vector3(0.0, 2.1, -0.6)
	node.add_child(sign)
	node.set_meta("done", false)
	add_child(node)
	node.set_meta("looted", false)
	for i in 3:
		var off := Vector3(rng.randf_range(-6.0, 6.0), 0.5, rng.randf_range(-6.0, 6.0))
		var roll := rng.randf()
		if roll < 0.4:
			_make_gun_pickup(node.global_position + off)
		elif roll < 0.7:
			_make_ammo_pickup(node.global_position + off)
		elif roll < 0.9:
			_make_med_pickup(node.global_position + off)
		else:
			_make_star_shard(node.global_position + off)
	return node


# ---------------------------------------------------------------- farming (new)

func _build_farm_plots() -> void:
	if _gardens.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 152
	var placed := 0
	var tries := 0
	var num_gardens := _gardens.size()
	while placed < 6 and tries < 400:
		tries += 1
		var g: Node3D = _gardens[placed % num_gardens] as Node3D
		if g == null:
			continue
		var ang := rng.randf() * TAU
		var dist := rng.randf_range(1.5, 6.0)
		var x := g.global_position.x + cos(ang) * dist
		var z := g.global_position.z + sin(ang) * dist
		var h := _height_at(x, z)
		if h < 0.5 or h > 20.0:
			continue
		if _slope_at(x, z) > 0.3:
			continue
		var plot := preload("res://scripts/crop_plot.gd").new()
		plot.world = self
		plot.crop_type = rng.randi_range(0, 2)
		plot.position = Vector3(x, h + 0.04, z)
		add_child(plot)
		_farm_plots.append(plot)
		placed += 1


func _harvest_crop(plot: Node3D) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if plot.global_position.distance_to(_player.global_position) > 4.5:
		return
	var growth := float(plot.get("growth"))
	var crop_type := int(plot.get("crop_type"))
	var crop_names: Array[String] = ["Wheat", "Pumpkin", "Corn"]
	var crop_name := crop_names[crop_type] if crop_type >= 0 and crop_type < crop_names.size() else crop_names[0]
	if growth < 1.0:
		_post_chat("Farm", "The %s isn't ripe yet. Come back when it's glowing." % crop_name)
		return
	var heal := 12.0
	var stam := 15.0
	_player.health = minf(float(_player.get("max_health")), float(_player.get("health")) + heal)
	_player.stamina = minf(float(_player.get("max_stamina")), float(_player.get("stamina")) + stam)
	_post_chat("You", "You harvested the %s. +%d HP, +%d stamina." % [crop_name, int(heal), int(stam)])
	if plot.has_method("reset_crop"):
		plot.call("reset_crop")
	if not _tasks["crop"]:
		_complete_task("crop", "Harvested a crop from the farm")


# ---------------------------------------------------------------- dirt bike (new)

func _build_bikes() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed + 13
	var colors := [Color(0.85, 0.3, 0.1), Color(0.2, 0.5, 0.85), Color(0.15, 0.75, 0.35)]
	_bikes_list.clear()
	var placed := 0
	# Always place a bike near the start so it's quickly discoverable.
	for try_i in 400:
		var x := rng.randf_range(-60.0, 60.0)
		var z := rng.randf_range(-60.0, 60.0)
		var h := _height_at(x, z)
		if h < 1.0 or h > 11.0 or _slope_at(x, z) > 0.3:
			continue
		if Vector2(x, z).distance_to(Vector2.ZERO) < 22.0:
			continue
		_add_bike_build(x, h, z, rng, placed, colors)
		placed += 1
		break
	# Distribute the rest along highways so they're easy to spot while traveling.
	var road_points := _collect_highway_points(6.0, 13.0)
	while placed < 4 and not road_points.is_empty() and placed < 4:
		var pi := rng.randi_range(0, road_points.size() - 1)
		var x := road_points[pi].x
		var z := road_points[pi].y
		var h := _height_at(x, z)
		if h < 0.8 or h > 14.0 or _slope_at(x, z) > 0.3:
			road_points.remove_at(pi)
			continue
		_add_bike_build(x, h, z, rng, placed, colors)
		road_points.remove_at(pi)
		placed += 1
	# Any remaining bikes scatter across the map.
	var bike_target := int(2.0 + 2.0 * clampf(_ram_scale(), 0.5, 2.0))
	var tries := 0
	while placed < bike_target and tries < 400:
		tries += 1
		var x := rng.randf_range(-150.0, 150.0)
		var z := rng.randf_range(-150.0, 150.0)
		var h := _height_at(x, z)
		if h < 1.0 or h > 14.0:
			continue
		if _slope_at(x, z) > 0.3:
			continue
		if Vector2(x, z).distance_to(Vector2.ZERO) < 18.0:
			continue
		_add_bike_build(x, h, z, rng, placed, colors)
		placed += 1


func _collect_highway_points(min_d: float, max_d: float) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for path in _highways:
		var pts := path as Array
		if pts.size() < 2:
			continue
		for i in range(0, pts.size(), 3):
			out.append((pts[i] as Vector2))
	return out


func _add_bike_build(x: float, h: float, z: float, rng: RandomNumberGenerator, placed: int, colors: Array) -> void:
	var bike := _make_bike(colors[placed % colors.size()])
	bike.position = Vector3(x, h, z)
	bike.rotation_degrees = Vector3(0.0, rng.randf() * 360.0, 0.0)
	add_child(bike)
	_bikes_list.append(bike)
	bike.add_to_group("cars")
	bike.set_meta("car_id", 1000 + placed)


func _make_bike(color: Color) -> CharacterBody3D:
	var bike := CharacterBody3D.new()
	bike.name = "Bike"
	bike.collision_layer = 1 | 2
	bike.collision_mask = 1
	bike.set_script(preload("res://scripts/bike.gd"))
	bike.set("world", self)
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = color
	body_mat.roughness = 0.5
	var frame := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(0.9, 0.4, 1.1)
	frame.mesh = fm
	frame.material_override = body_mat
	frame.position = Vector3(0.0, 0.45, 0.0)
	bike.add_child(frame)
	var dark_mat := StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.12, 0.12, 0.14)
	dark_mat.roughness = 0.9
	var seat := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.3, 0.12, 0.35)
	seat.mesh = sm
	seat.material_override = dark_mat
	seat.position = Vector3(0.0, 0.62, 0.18)
	bike.add_child(seat)
	var bar_mat := StandardMaterial3D.new()
	bar_mat.albedo_color = Color(0.2, 0.2, 0.22)
	bar_mat.roughness = 0.4
	for side in [-0.33, 0.33]:
		var handle := MeshInstance3D.new()
		var hm := BoxMesh.new()
		hm.size = Vector3(0.75, 0.06, 0.06)
		handle.mesh = hm
		handle.material_override = bar_mat
		handle.position = Vector3(side * 0.33, 0.95, -0.25)
		bike.add_child(handle)
	var lamp_mat := StandardMaterial3D.new()
	lamp_mat.albedo_color = Color(1.0, 0.9, 0.5)
	lamp_mat.emission_enabled = true
	lamp_mat.emission = Color(1.0, 0.9, 0.5) * 0.8
	var headlight := OmniLight3D.new()
	headlight.light_color = Color(1.0, 0.95, 0.8)
	headlight.light_energy = 4.0
	headlight.omni_range = 18.0
	headlight.position = Vector3(0.0, 0.9, -0.8)
	bike.add_child(headlight)
	return bike


func _enter_bike(bike: CharacterBody3D) -> void:
	if _server or _client:
		return
	if _player == null or bool(_player.get("in_car")):
		return
	_current_target = null
	_cancel_fishing()
	var p := _player as CharacterBody3D
	_player.set("in_car", true)
	_player.set("in_car_id", int(bike.get_meta("car_id", -1)))
	_player.set("_freeze", true)
	_player.set("_third_person", false)
	if _player.has_method("_apply_view"):
		_player._apply_view()
	p.collision_layer = 0
	p.collision_mask = 0
	var cam := _player.get_node("CameraRig/Camera") as Camera3D
	if cam:
		cam.current = false
	var bike_cam := bike.get_node_or_null("Camera3D") as Camera3D
	if bike_cam:
		bike_cam.current = true
	bike.set_player(_player)
	bike.set("_enter_frame", Engine.get_physics_frames())
	_post_chat("System", "Riding the dirt bike — WASD to move, SHIFT to boost, E to dismount.")


func _exit_bike(bike: CharacterBody3D) -> void:
	if _server or _client:
		return
	if _player == null or not bool(_player.get("in_car")):
		return
	_player.set("in_car", false)
	_player.set("in_car_id", -1)
	_player.set("_freeze", false)
	var p := _player as CharacterBody3D
	p.collision_layer = 1
	p.collision_mask = 1
	var off: Vector3 = bike.global_transform.basis * Vector3(0.0, 0.0, -2.4)
	p.global_position = bike.global_position + off
	p.velocity = Vector3.ZERO
	var cam := p.get_node("CameraRig/Camera") as Camera3D
	if cam:
		cam.current = true
	var bike_cam := bike.get_node_or_null("Camera3D") as Camera3D
	if bike_cam:
		bike_cam.current = false
	bike.set_player(null)
	_post_chat("System", "You got off the dirt bike.")


func _make_mineral_pickup(pos: Vector3) -> void:
	if _server or _client:
		return
	var pickup := StaticBody3D.new()
	pickup.name = "Mineral"
	pickup.collision_layer = 2
	pickup.collision_mask = 0
	pickup.set_script(preload("res://scripts/mineral_pickup.gd"))
	pickup.set("world", self)
	pickup.position = pos + Vector3(0.0, 0.2, 0.0)
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.35, 0.35, 0.35)
	col.shape = bs
	pickup.add_child(col)
	var ore_mat := StandardMaterial3D.new()
	ore_mat.albedo_color = Color(0.7, 0.6, 0.35)
	ore_mat.emission_enabled = true
	ore_mat.emission = Color(0.7, 0.55, 0.2)
	ore_mat.emission_energy_multiplier = 1.5
	var ore := MeshInstance3D.new()
	var om := BoxMesh.new()
	om.size = Vector3(0.28, 0.28, 0.28)
	ore.mesh = om
	ore.material_override = ore_mat
	ore.position = Vector3(0.0, 0.16, 0.0)
	pickup.add_child(ore)
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.9, 0.7, 0.3)
	glow.light_energy = 1.5
	glow.omni_range = 5.0
	pickup.add_child(glow)
	var pid := _next_pickup_id
	_next_pickup_id += 1
	pickup.set_meta("pickup_id", pid)
	pickup.add_to_group("pickups")
	_pickups[pid] = pickup
	add_child(pickup)


func _make_gun_pickup(pos: Vector3) -> void:
	if _server or _client:
		return
	var pickup := StaticBody3D.new()
	pickup.name = "BunkerGun"
	pickup.collision_layer = 2
	pickup.collision_mask = 0
	pickup.set_script(preload("res://scripts/gun_pickup.gd"))
	pickup.set("world", self)
	pickup.position = pos + Vector3(0.0, 0.25, 0.0)
	var pid := _next_pickup_id
	_next_pickup_id += 1
	pickup.set_meta("pickup_id", pid)
	pickup.add_to_group("pickups")
	_pickups[pid] = pickup
	add_child(pickup)
