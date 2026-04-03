class_name ResultBackground
extends Control
## 结果界面动态背景组件
## 显示动态渐变背景和粒子效果
##
## 设计参考：太鼓达人虹版结果界面背景效果
## - 渐变背景：根据评级类型显示不同颜色
## - 粒子效果：金冠/银冠时显示庆祝粒子
## - 光线效果：动态光线扫描效果

## 背景类型
enum BackgroundType {
	GOLD,    ## 金冠背景（金色渐变）
	SILVER,  ## 银冠背景（银色渐变）
	BRONZE,  ## 铜冠背景（铜色渐变）
	FAILED   ## 失败背景（灰色渐变）
}

## 配置
@export var particle_count: int = 30
@export var particle_speed: float = 100.0
@export var gradient_duration: float = 2.0

## 颜色配置
const COLOR_GOLD_TOP := Color(0.2, 0.15, 0.05)
const COLOR_GOLD_BOTTOM := Color(0.1, 0.08, 0.02)
const COLOR_SILVER_TOP := Color(0.15, 0.15, 0.2)
const COLOR_SILVER_BOTTOM := Color(0.08, 0.08, 0.12)
const COLOR_BRONZE_TOP := Color(0.15, 0.1, 0.08)
const COLOR_BRONZE_BOTTOM := Color(0.08, 0.05, 0.03)
const COLOR_FAILED_TOP := Color(0.1, 0.1, 0.12)
const COLOR_FAILED_BOTTOM := Color(0.05, 0.05, 0.08)

## UI节点引用
var _gradient_rect: ColorRect
var _gradient_overlay: ColorRect
var _particle_container: Control
var _light_beam: ColorRect
var _particles: Array[Control] = []
var _gradient_tween: Tween
var _light_tween: Tween

## 当前背景类型
var _current_type: BackgroundType = BackgroundType.BRONZE

## 是否显示粒子
var _show_particles: bool = false


func _ready() -> void:
	_setup_ui()
	_start_background_animation()


## 设置UI
func _setup_ui() -> void:
	# 设置锚点为全屏
	anchors_preset = Control.PRESET_FULL_RECT

	# 创建渐变背景（底层）
	_gradient_rect = ColorRect.new()
	_gradient_rect.color = COLOR_BRONZE_TOP
	add_child(_gradient_rect)
	_gradient_rect.anchors_preset = Control.PRESET_FULL_RECT

	# 创建渐变覆盖层（用于动态渐变效果）
	_gradient_overlay = ColorRect.new()
	_gradient_overlay.color = COLOR_BRONZE_BOTTOM
	_gradient_overlay.modulate.a = 0.5
	add_child(_gradient_overlay)
	_gradient_overlay.anchors_preset = Control.PRESET_FULL_RECT

	# 创建粒子容器
	_particle_container = Control.new()
	add_child(_particle_container)
	_particle_container.anchors_preset = Control.PRESET_FULL_RECT

	# 创建光线效果
	_light_beam = ColorRect.new()
	_light_beam.color = Color(1.0, 1.0, 1.0, 0.1)
	_light_beam.custom_minimum_size = Vector2(50, 2000)
	_light_beam.modulate.a = 0.0
	add_child(_light_beam)
	_light_beam.position = Vector2(-100, 0)

	# 创建粒子
	_create_particles()


## 创建粒子
func _create_particles() -> void:
	for i in range(particle_count):
		var particle = ColorRect.new()
		particle.color = Color(1.0, 0.85, 0.0, 0.8)  # 金色粒子
		particle.custom_minimum_size = Vector2(4, 4)
		particle.modulate.a = 0.0
		particle.position = Vector2(
			randf_range(0, size.x),
			randf_range(0, size.y)
		)
		_particle_container.add_child(particle)
		_particles.append(particle)


## 设置背景类型
func set_background_type(type: BackgroundType) -> void:
	_current_type = type

	# 设置颜色
	var top_color: Color
	var bottom_color: Color
	var particle_color: Color

	match type:
		BackgroundType.GOLD:
			top_color = COLOR_GOLD_TOP
			bottom_color = COLOR_GOLD_BOTTOM
			particle_color = Color(1.0, 0.85, 0.0, 0.8)  # 金色粒子
			_show_particles = true
		BackgroundType.SILVER:
			top_color = COLOR_SILVER_TOP
			bottom_color = COLOR_SILVER_BOTTOM
			particle_color = Color(0.85, 0.85, 0.85, 0.8)  # 银色粒子
			_show_particles = true
		BackgroundType.BRONZE:
			top_color = COLOR_BRONZE_TOP
			bottom_color = COLOR_BRONZE_BOTTOM
			particle_color = Color(0.85, 0.55, 0.25, 0.5)  # 铜色粒子
			_show_particles = false
		BackgroundType.FAILED:
			top_color = COLOR_FAILED_TOP
			bottom_color = COLOR_FAILED_BOTTOM
			particle_color = Color(0.5, 0.5, 0.5, 0.3)  # 灰色粒子
			_show_particles = false

	# 更新背景颜色
	_gradient_rect.color = top_color
	_gradient_overlay.color = bottom_color

	# 更新粒子颜色
	for particle in _particles:
		particle.color = particle_color

	# 启动粒子动画（如果需要）
	if _show_particles:
		_start_particle_animation()
	else:
		_stop_particle_animation()


## 启动背景动画
func _start_background_animation() -> void:
	# 渐变脉冲效果
	_gradient_tween = create_tween()
	_gradient_tween.set_loops()

	_gradient_tween.tween_property(_gradient_overlay, "modulate:a", 0.7, gradient_duration)
	_gradient_tween.tween_property(_gradient_overlay, "modulate:a", 0.3, gradient_duration)

	# 光线扫描效果
	_start_light_beam_animation()


## 启动光线扫描动画
func _start_light_beam_animation() -> void:
	_light_tween = create_tween()
	_light_tween.set_loops()

	# 光线从左到右扫描
	_light_beam.position.x = -100
	_light_beam.modulate.a = 0.0

	_light_tween.tween_interval(2.0)  # 等待2秒
	_light_tween.tween_property(_light_beam, "modulate:a", 0.15, 0.5)
	_light_tween.tween_property(_light_beam, "position:x", size.x + 100, 3.0)
	_light_tween.tween_property(_light_beam, "modulate:a", 0.0, 0.5)


## 启动粒子动画
func _start_particle_animation() -> void:
	for particle in _particles:
		_animate_particle(particle)


## 动画单个粒子
func _animate_particle(particle: Control) -> void:
	# 随机延迟启动
	await get_tree().create_timer(randf_range(0, 2.0)).timeout

	while _show_particles:
		# 随机位置
		particle.position = Vector2(
			randf_range(0, size.x),
			size.y + 10
		)
		particle.modulate.a = randf_range(0.3, 0.8)

		# 向上移动
		var tween = particle.create_tween()
		var target_y = -10
		var duration = (size.y + 20) / particle_speed

		tween.tween_property(particle, "position:y", target_y, duration)
		tween.tween_property(particle, "modulate:a", 0.0, duration * 0.5)

		await tween.finished

		# 等待一段时间再重新出现
		await get_tree().create_timer(randf_range(0.5, 2.0)).timeout


## 停止粒子动画
func _stop_particle_animation() -> void:
	_show_particles = false
	for particle in _particles:
		particle.modulate.a = 0.0


## 播放庆祝效果（金冠/银冠）
func play_celebration_effect() -> void:
	# 增强光线效果
	if _light_tween and _light_tween.is_valid():
		_light_tween.kill()

	_light_tween = create_tween()
	_light_tween.set_parallel(true)

	# 多条光线同时扫描
	for i in range(3):
		var delay = i * 0.3
		_light_tween.tween_interval(delay)
		_light_tween.tween_property(_light_beam, "modulate:a", 0.3, 0.3)
		_light_tween.tween_property(_light_beam, "position:x", size.x + 100, 1.5)
		_light_tween.tween_property(_light_beam, "modulate:a", 0.0, 0.3)

	# 增强粒子效果
	for particle in _particles:
		particle.color = Color(1.0, 1.0, 0.5, 1.0)  # 更亮的金色


## 播放失败效果
func play_failed_effect() -> void:
	# 暗化背景
	var tween = create_tween()
	tween.tween_property(_gradient_overlay, "modulate:a", 0.8, 0.5)

	# 停止光线效果
	if _light_tween and _light_tween.is_valid():
		_light_tween.kill()
	_light_beam.modulate.a = 0.0


## 获取当前背景类型
func get_background_type() -> BackgroundType:
	return _current_type


## 重置
func reset() -> void:
	_stop_particle_animation()
	set_background_type(BackgroundType.BRONZE)
	_gradient_overlay.modulate.a = 0.5
	_light_beam.modulate.a = 0.0


## 清理
func _exit_tree() -> void:
	_stop_particle_animation()
	if _gradient_tween and _gradient_tween.is_valid():
		_gradient_tween.kill()
	if _light_tween and _light_tween.is_valid():
		_light_tween.kill()