extends Node

enum Tier { LOW, MEDIUM, HIGH }

var current_tier: Tier = Tier.MEDIUM


func _ready():
	var tier = _detect_hardware()
	apply_tier(tier)


func _detect_hardware() -> Tier:
	# Auto-detect based on system RAM and VRAM
	var ram_info = OS.get_memory_info()
	var ram_mb = ram_info.get("physical", 4000000000) / 1048576

	# Check for mobile
	if OS.has_feature("android") or OS.has_feature("ios"):
		return Tier.LOW

		# Desktop detection
	if ram_mb >= 7500:
		return Tier.HIGH
	elif ram_mb >= 3500:
		return Tier.MEDIUM
	else:
		return Tier.LOW


func apply_tier(tier: Tier):
	current_tier = tier
	match tier:
		Tier.LOW:
			_apply_low()
		Tier.MEDIUM:
			_apply_medium()
		Tier.HIGH:
			_apply_high()
	ProjectSettings.set_setting("rendering/tier", tier)
	print("Graphics tier applied: ", Tier.keys()[tier])


func _apply_low():
	# Tier 1 — Low End (Legacy)
	var env = _get_environment()
	if env:
		env.sdfgi_enabled = false
		env.ssao_enabled = false
		env.ssil_enabled = false
		env.ssr_enabled = false
		env.fog_enabled = true
		env.volumetric_fog_enabled = false
		env.glow_enabled = false
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC

		# Force 30 FPS

		# Shadow quality

		# Set draw distance
	RenderingServer.viewport_set_msaa_3d(
		get_viewport().get_viewport_rid(), RenderingServer.VIEWPORT_MSAA_DISABLED
	)

	# Force 30 FPS
	Engine.max_fps = 30

	# Shadow quality
	_set_shadow_quality(RenderingServer.SHADOW_QUALITY_SOFT_VERY_LOW)
	_set_texture_filter(false)

	# Set draw distance
	ProjectSettings.set_setting("rendering/limits/spatial_indexer/update_iterations_per_frame", 1)


func _apply_medium():
	# Tier 2 — Medium
	var env = _get_environment()
	if env:
		env.sdfgi_enabled = false
		env.ssao_enabled = true
		env.ssao_radius = 0.8
		env.ssao_intensity = 1.0
		env.ssil_enabled = false
		env.ssr_enabled = false
		env.fog_enabled = true
		env.volumetric_fog_enabled = false
		env.glow_enabled = true
		env.glow_intensity = 0.4
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		env.adjustment_enabled = true
		env.adjustment_contrast = 1.05
		env.adjustment_saturation = 0.9
	RenderingServer.viewport_set_msaa_3d(
		get_viewport().get_viewport_rid(), RenderingServer.VIEWPORT_MSAA_2X
	)

	Engine.max_fps = 60
	_set_shadow_quality(RenderingServer.SHADOW_QUALITY_SOFT_LOW)
	_set_texture_filter(true)


func _apply_high():
	# Tier 3 — High End (Ultra)
	var env = _get_environment()
	if env:
		env.sdfgi_enabled = true
		env.sdfgi_cascades = 4
		env.sdfgi_min_cell_size = 0.2
		env.ssao_enabled = true
		env.ssao_radius = 1.2
		env.ssao_intensity = 1.5
		env.ssil_enabled = true
		env.ssr_enabled = true
		env.ssr_max_steps = 64
		env.fog_enabled = true
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = 0.03
		env.volumetric_fog_emission = Color(0.01, 0.01, 0.02, 1)
		env.glow_enabled = true
		env.glow_intensity = 0.6
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		env.adjustment_enabled = true
		env.adjustment_contrast = 1.1
		env.adjustment_saturation = 0.85
		env.dof_blur_far_enabled = true
		env.dof_blur_far_distance = 50.0
		env.dof_blur_far_transition = 30.0
	RenderingServer.viewport_set_msaa_3d(
		get_viewport().get_viewport_rid(), RenderingServer.VIEWPORT_MSAA_4X
	)

	Engine.max_fps = 0  # Uncapped
	_set_shadow_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)


func _get_environment() -> Environment:
	var world = get_viewport().get_world_3d()
	if world and world.environment:
		return world.environment
		# Create environment if none exists
	var env = Environment.new()
	var world_env = WorldEnvironment.new()
	world_env.environment = env
	get_tree().current_scene.add_child(world_env)
	return env


func _set_shadow_quality(quality: int):
	# Godot 4.3: directional_shadow_quality is a ProjectSettings property,
	# not a RenderingServer member. Values match RenderingServer.SHADOW_QUALITY_*.
	ProjectSettings.set_setting(
		"rendering/lights_and_shadows/directional_shadow/soft_shadow_filter", quality
	)


func _set_texture_filter(high_quality: bool):
	var filter = (
		BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		if high_quality
		else BaseMaterial3D.TEXTURE_FILTER_NEAREST
	)


func get_tier_name() -> String:
	return Tier.keys()[current_tier]


func get_draw_distance() -> float:
	match current_tier:
		Tier.LOW:
			return 40.0
		Tier.MEDIUM:
			return 80.0
		Tier.HIGH:
			return 200.0
		_:
			return 80.0


func get_max_texture_resolution() -> int:
	match current_tier:
		Tier.LOW:
			return 512
		Tier.MEDIUM:
			return 1024
		Tier.HIGH:
			return 4096
		_:
			return 1024


func should_use_particles() -> bool:
	return current_tier >= Tier.MEDIUM


func should_use_volumetric_fog() -> bool:
	return current_tier >= Tier.HIGH


func should_use_sdfgi() -> bool:
	return current_tier >= Tier.HIGH


func get_lod_level() -> int:
	# Returns which LOD level to use as default
	match current_tier:
		Tier.LOW:
			return 2  # LOD2 always
		Tier.MEDIUM:
			return 1  # LOD1 close, LOD2 far
		Tier.HIGH:
			return 0  # LOD0 always
		_:
			return 1


func get_memory_strategy() -> String:
	match current_tier:
		Tier.LOW:
			return "single_zone"
		Tier.MEDIUM:
			return "current_plus_adjacent"
		Tier.HIGH:
			return "current_plus_all_adjacent"
		_:
			return "current_plus_adjacent"
