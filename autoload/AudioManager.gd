extends Node
## AudioManager
## Central place to play music and SFX, and to toggle/adjust them from
## the Settings menu. Uses two AudioStreamPlayer pools: one for music
## (single looping track) and one for one-shot SFX/UI/cooking sounds.

var music_enabled: bool = true
var sfx_enabled: bool = true
var music_volume: float = 0.8 : set = set_music_volume
var sfx_volume: float = 1.0 : set = set_sfx_volume

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE := 8

# Registry of sound keys -> resource paths. Replace placeholder paths with
# real assets later; missing files are handled gracefully.
var _sfx_library: Dictionary = {
	"ui_click": "res://assets/audio/sfx/ui_click.wav",
	"ui_confirm": "res://assets/audio/sfx/ui_confirm.wav",
	"chop": "res://assets/audio/sfx/chop.wav",
	"sizzle": "res://assets/audio/sfx/sizzle.wav",
	"plate_up": "res://assets/audio/sfx/plate_up.wav",
	"cash_register": "res://assets/audio/sfx/cash_register.wav",
	"customer_happy": "res://assets/audio/sfx/customer_happy.wav",
	"customer_angry": "res://assets/audio/sfx/customer_angry.wav",
	"burn_warning": "res://assets/audio/sfx/burn_warning.wav",
	"star_earned": "res://assets/audio/sfx/star_earned.wav",
}

var _music_library: Dictionary = {
	"menu": "res://assets/audio/music/menu_theme.wav",
	"burger_restaurant": "res://assets/audio/music/burger_theme.wav",
	"pizza_restaurant": "res://assets/audio/music/pizza_theme.wav",
	"coffee_shop": "res://assets/audio/music/coffee_theme.wav",
	"chicken_restaurant": "res://assets/audio/music/chicken_theme.wav",
	"dessert_restaurant": "res://assets/audio/music/dessert_theme.wav",
}

func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Music"
	add_child(_music_player)

	for i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.name = "SfxPlayer%d" % i
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)

	apply_settings()

func apply_settings() -> void:
	_music_player.volume_db = linear_to_db(music_volume if music_enabled else 0.0)
	for p in _sfx_players:
		p.volume_db = linear_to_db(sfx_volume if sfx_enabled else 0.0)

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	if _music_player:
		_music_player.volume_db = linear_to_db(music_volume if music_enabled else 0.0)

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	for p in _sfx_players:
		p.volume_db = linear_to_db(sfx_volume if sfx_enabled else 0.0)

func toggle_music(enabled: bool) -> void:
	music_enabled = enabled
	apply_settings()

func toggle_sfx(enabled: bool) -> void:
	sfx_enabled = enabled
	apply_settings()

func play_music(track_key: String) -> void:
	if not _music_library.has(track_key):
		push_warning("AudioManager: unknown music key '%s'" % track_key)
		return
	var path: String = _music_library[track_key]
	if not ResourceLoader.exists(path):
		return # Placeholder asset not yet added; fail silently.
	var stream: AudioStream = load(path)
	if _music_player.stream == stream and _music_player.playing:
		return
	# Our synthesized music tracks are short (a few seconds) and meant to
	# loop seamlessly - AudioStreamWAV doesn't loop by default, so force it.
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_music_player.stream = stream
	_music_player.play()

func stop_music() -> void:
	_music_player.stop()

func play_sfx(sfx_key: String) -> void:
	if not sfx_enabled:
		return
	if not _sfx_library.has(sfx_key):
		push_warning("AudioManager: unknown sfx key '%s'" % sfx_key)
		return
	var path: String = _sfx_library[sfx_key]
	if not ResourceLoader.exists(path):
		return # Placeholder asset not yet added; fail silently.
	var stream: AudioStream = load(path)
	var player := _get_free_sfx_player()
	player.stream = stream
	player.play()

func _get_free_sfx_player() -> AudioStreamPlayer:
	for p in _sfx_players:
		if not p.playing:
			return p
	return _sfx_players[0]
