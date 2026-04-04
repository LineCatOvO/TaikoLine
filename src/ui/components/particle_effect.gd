## 粒子效果组件
## 功能：创建简单的粒子动画效果，用于庆祝、成功等场景
## 作者：TaikoLine Team
## 日期：2026-04-03

class_name ParticleEffect
extends Control

## 粒子类型
enum ParticleType {
	CELEBRATION,    ## 庆祝粒子（向上飘散）
	EXPLOSION,      ## 爆炸粒子（向四周扩散）
	SPARKLE,        ## 闪烁粒子（随机闪烁）
	CONFETTI,       ## 彩带粒子（彩色飘落）
	STARS           ## 星星粒子（旋转上升）
}

## 信号
signal effect_completed

## 配置参数
@export var particle_type: ParticleType = ParticleType.CELEBRATION
@export var particle_count: int = 20  ## 粒子数量
@export var particle_size: float = 8.0  ## 粒子大小
@export var particle_duration: float = 1.5  ## 粒子生命周期
@export var spawn_rate: float = 0.05  ## 生成速率（秒）
@export var colors: Array[Color] = []  ## 粒子颜色数组
@export var auto_remove: bool = true  ## 完成后自动移除

## 默认颜色配置
const DEFAULT_CELEBRATION_COLORS = [
	Color(1.0, 0.3, 0.3),  # 红色
	Color(1.0, 0.8, 0.0),  # 金色
	Color(0.3, 0.8, 0.3),  # 绿色
	Color(0.3, 0.6, 1.0),  # 蓝色
	Color(1.0, 0.5, 0.8)   # 粉色
]

const DEFAULT_CONFETTI_COLORS = [
	Color(1.0, 0.2, 0.2),  # 红色
	Color(1.0, 0.9, 0.0),  # 金色
	Color(0.2, 0.9, 0.2),  # 绿色
	Color(0.2, 0.5, 1.0),  # 蓝色
	Color(1.0, 0.4, 0.8),  # 粉色
	Color(0.8, 0.4, 1.0)   # 紫色
]

## 粒子节点列表
var _particles: Array[Control] = []

## 是否正在播放
var _is_playing: bool = false

## 活动的 Tween
var _active_tweens: Array[Tween] = []


func _ready() -> void:
	# 设置为覆盖整个父节点区域
	anchors_preset = Control.PRESET_FULL_RECT
	offset_left = 0
	offset_right = 0
	offset_top = 0
	offset_bottom = 0
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 设置默认颜色
	if colors.is_empty():
		_setup_default_colors()


## 设置默认颜色
func _setup_default_colors() -> void:
	match particle_type:
		ParticleType.CELEBRATION, ParticleType.EXPLOSION, ParticleType.SPARKLE:
			colors = DEFAULT_CELEBRATION_COLORS
		ParticleType.CONFETTI:
			colors = DEFAULT_CONFETTI_COLORS
		ParticleType.STARS:
			colors = [Color(1.0, 0.9, 0.0), Color(1.0, 0.8, 0.3)]  # 金色系


## 开始播放粒子效果
## 参数 position: 效果起始位置（可选，默认为中心）
func start_effect(position: Vector2 = Vector2.ZERO) -> void:
	if _is_playing:
		return

	_is_playing = true

	# 如果位置为零，使用中心位置
	if position == Vector2.ZERO:
		var parent_size = get_parent().size if get_parent() is Control else Vector2(400, 300)
		position = parent_size / 2

	# 根据类型生成粒子
	match particle_type:
		ParticleType.CELEBRATION:
			_spawn_celebration_particles(position)
		ParticleType.EXPLOSION:
			_spawn_explosion_particles(position)
		ParticleType.SPARKLE:
			_spawn_sparkle_particles(position)
		ParticleType.CONFETTI:
			_spawn_confetti_particles()
		ParticleType.STARS:
			_spawn_star_particles(position)


## 生成庆祝粒子（向上飘散）
func _spawn_celebration_particles(position: Vector2) -> void:
	for i in range(particle_count):
		await get_tree().create_timer(spawn_rate).timeout

		var particle = _create_particle()
		particle.position = position

		# 随机方向（主要向上）
		var angle = randf_range(-PI/4, PI/4) - PI/2  # -90度 ± 45度
		var speed = randf_range(100, 200)
		var target_pos = position + Vector2(cos(angle) * speed, sin(angle) * speed)

		# 创建动画
		var tween = create_tween()
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUAD)

		tween.tween_property(particle, "position", target_pos, particle_duration)
		tween.tween_property(particle, "modulate:a", 0.0, particle_duration)
		tween.tween_property(particle, "scale", Vector2(0.5, 0.5), particle_duration)

		tween.set_parallel(false)
		tween.tween_callback(_on_particle_completed.bind(particle, tween))

		_active_tweens.append(tween)


## 生成爆炸粒子（向四周扩散）
func _spawn_explosion_particles(position: Vector2) -> void:
	for i in range(particle_count):
		# 立即生成所有粒子
		var particle = _create_particle()
		particle.position = position

		# 随机方向（向四周）
		var angle = randf_range(0, TAU)
		var speed = randf_range(80, 150)
		var target_pos = position + Vector2(cos(angle) * speed, sin(angle) * speed)

		# 创建动画
		var tween = create_tween()
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUAD)

		tween.tween_property(particle, "position", target_pos, particle_duration)
		tween.tween_property(particle, "modulate:a", 0.0, particle_duration)
		tween.tween_property(particle, "scale", Vector2(0.3, 0.3), particle_duration)

		tween.set_parallel(false)
		tween.tween_callback(_on_particle_completed.bind(particle, tween))

		_active_tweens.append(tween)


## 生成闪烁粒子（随机位置闪烁）
func _spawn_sparkle_particles(position: Vector2) -> void:
	for i in range(particle_count):
		await get_tree().create_timer(spawn_rate * 2).timeout

		# 随机位置（在中心附近）
		var offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
		var particle = _create_particle()
		particle.position = position + offset
		particle.scale = Vector2(0.5, 0.5)

		# 闪烁动画
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_SINE)

		tween.tween_property(particle, "scale", Vector2(1.2, 1.2), particle_duration * 0.3)
		tween.tween_property(particle, "modulate:a", 1.0, particle_duration * 0.2)
		tween.tween_property(particle, "scale", Vector2(0.8, 0.8), particle_duration * 0.3)
		tween.tween_property(particle, "modulate:a", 0.0, particle_duration * 0.2)

		tween.tween_callback(_on_particle_completed.bind(particle, tween))

		_active_tweens.append(tween)


## 生成彩带粒子（从顶部飘落）
func _spawn_confetti_particles() -> void:
	var parent_size = get_parent().size if get_parent() is Control else Vector2(400, 300)

	for i in range(particle_count):
		await get_tree().create_timer(spawn_rate).timeout

		# 从顶部随机位置开始
		var start_x = randf_range(0, parent_size.x)
		var particle = _create_particle(true)  # 使用矩形形状
		particle.position = Vector2(start_x, -20)
		particle.rotation = randf_range(-PI/4, PI/4)

		# 飘落动画
		var tween = create_tween()
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_QUAD)

		# 下落
		tween.tween_property(particle, "position:y", parent_size.y + 50, particle_duration)

		# 左右摇摆
		tween.set_parallel(false)
		var swing_count = 3
		for j in range(swing_count):
			tween.tween_property(particle, "position:x", start_x + randf_range(-30, 30), particle_duration / swing_count)
			tween.tween_property(particle, "rotation", randf_range(-PI/2, PI/2), particle_duration / swing_count)

		tween.tween_callback(_on_particle_completed.bind(particle, tween))

		_active_tweens.append(tween)


## 生成星星粒子（旋转上升）
func _spawn_star_particles(position: Vector2) -> void:
	for i in range(particle_count):
		await get_tree().create_timer(spawn_rate).timeout

		var particle = _create_star_particle()
		particle.position = position + Vector2(randf_range(-30, 30), randf_range(-30, 30))

		# 上升并旋转
		var tween = create_tween()
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUAD)

		tween.tween_property(particle, "position:y", position.y - 100, particle_duration)
		tween.tween_property(particle, "rotation", TAU, particle_duration)
		tween.tween_property(particle, "modulate:a", 0.0, particle_duration)
		tween.tween_property(particle, "scale", Vector2(0.5, 0.5), particle_duration)

		tween.set_parallel(false)
		tween.tween_callback(_on_particle_completed.bind(particle, tween))

		_active_tweens.append(tween)


## 创建基础粒子节点
## 参数 is_rect: 是否使用矩形形状
func _create_particle(is_rect: bool = false) -> Control:
	var particle: Control

	if is_rect:
		# 矩形粒子（彩带）
		particle = ColorRect.new()
		particle.color = colors[randi() % colors.size()]
		particle.custom_minimum_size = Vector2(particle_size * 2, particle_size)
		particle.size = Vector2(particle_size * 2, particle_size)
	else:
		# 圆形粒子
		particle = ColorRect.new()
		particle.color = colors[randi() % colors.size()]
		particle.custom_minimum_size = Vector2(particle_size, particle_size)
		particle.size = Vector2(particle_size, particle_size)

	add_child(particle)
	_particles.append(particle)

	return particle


## 创建星星形状粒子
func _create_star_particle() -> Control:
	# 使用多个小方块组成星星形状
	var star_container = Control.new()
	star_container.custom_minimum_size = Vector2(particle_size * 2, particle_size * 2)

	# 中心点
	var center = ColorRect.new()
	center.color = colors[randi() % colors.size()]
	center.custom_minimum_size = Vector2(particle_size, particle_size)
	center.position = Vector2(particle_size / 2, particle_size / 2)
	star_container.add_child(center)

	# 四个角（形成十字）
	for i in range(4):
		var arm = ColorRect.new()
		arm.color = colors[randi() % colors.size()]
		arm.custom_minimum_size = Vector2(particle_size / 2, particle_size / 2)

		var angle = i * PI / 2
		arm.position = Vector2(
			particle_size + cos(angle) * particle_size / 2 - particle_size / 4,
			particle_size + sin(angle) * particle_size / 2 - particle_size / 4
		)
		star_container.add_child(arm)

	add_child(star_container)
	_particles.append(star_container)

	return star_container


## 粒子完成回调
func _on_particle_completed(particle: Control, tween: Tween) -> void:
	_particles.erase(particle)
	_active_tweens.erase(tween)

	if auto_remove:
		particle.queue_free()

	# 检查是否所有粒子都完成
	if _particles.is_empty() and _active_tweens.is_empty():
		_is_playing = false
		effect_completed.emit()


## 停止所有粒子效果
func stop_effect() -> void:
	_is_playing = false

	for tween in _active_tweens:
		if tween and tween.is_valid():
			tween.kill()

	_active_tweens.clear()

	for particle in _particles:
		particle.queue_free()

	_particles.clear()


## 设置粒子类型
func set_particle_type(type: ParticleType) -> void:
	particle_type = type
	_setup_default_colors()


## 设置粒子数量
func set_particle_count(count: int) -> void:
	particle_count = count


## 设置粒子颜色
func set_particle_colors(new_colors: Array[Color]) -> void:
	colors = new_colors


## 检查是否正在播放
func is_playing() -> bool:
	return _is_playing


## 静态方法：在指定节点上创建庆祝效果
static func spawn_celebration(parent: Control, position: Vector2 = Vector2.ZERO) -> ParticleEffect:
	var effect = ParticleEffect.new()
	effect.particle_type = ParticleType.CELEBRATION
	effect.particle_count = 30
	effect.particle_duration = 1.0
	parent.add_child(effect)
	effect.start_effect(position)
	return effect


## 静态方法：在指定节点上创建爆炸效果
static func spawn_explosion(parent: Control, position: Vector2) -> ParticleEffect:
	var effect = ParticleEffect.new()
	effect.particle_type = ParticleType.EXPLOSION
	effect.particle_count = 25
	effect.particle_duration = 0.8
	parent.add_child(effect)
	effect.start_effect(position)
	return effect


## 静态方法：在指定节点上创建彩带效果
static func spawn_confetti(parent: Control) -> ParticleEffect:
	var effect = ParticleEffect.new()
	effect.particle_type = ParticleType.CONFETTI
	effect.particle_count = 50
	effect.particle_duration = 2.0
	parent.add_child(effect)
	effect.start_effect()
	return effect