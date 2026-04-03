class_name GameBackground
extends Control
## 游戏背景效果组件
## 显示动态背景效果，包括渐变、粒子效果等
##
## 设计参考：太鼓达人虹版（Taiko no Tatsujin Nijiiro）
## - 动态渐变背景
## - Go-Go Time 特效
## - 音符轨道发光效果

## 信号
signal gogo_effect_started
signal gogo_effect_ended

## 配置
@export var gradient_speed: float = 0.5  ## 渐变动画速度
@export var particle_count: int = 20     ## 粒子数量
@export var gogo_intensity: float = 0.15 ## Go-Go Time 效果强度

## UI节点引用
var _background: ColorRect
var _gradient_overlay: ColorRect
var _gogo_overlay: ColorRect
var _particle_container: Control

## 动画Tween
var _gradient_tween: Tween
var _gogo_tween: Tween

## Go-Go Time状态
var _is_gogo_active: bool = false

## 粒子列表
var _particles: Array[ColorRect] = []

## 基础颜色
var _base_color: Color = Color(0.067, 0.067, 0.18, 1.0)
var _gogo_color: Color = Color(1.0, 0.42, 0.0, 0.0)


func _ready() -> void:
	_setup_ui()
	_setup_particles()
	_start_gradient_animation()


## 设置UI
func _setup_ui() -> void:
	# 背景
	_background = ColorRect.new()
	_background.color = _base_color
	_background.name = "Background"
	add_child(_background)
	_background.anchors_preset = Control.PRESET_FULL_RECT
	
	# 渐变覆盖层（用于动态效果）
	_gradient_overlay = ColorRect.new()
	_gradient_overlay.color = Color(0.1, 0.1, 0.2, 0.3)
	_gradient_overlay.name = "GradientOverlay"
	add_child(_gradient_overlay)
	_gradient_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_gradient_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Go-Go Time覆盖层
	_gogo_overlay = ColorRect.new()
	_gogo_overlay.color = _gogo_color
	_gogo_overlay.name = "GogoOverlay"
	add_child(_gogo_overlay)
	_gogo_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_gogo_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 粒子容器
	_particle_container = Control.new()
	_particle_container.name = "ParticleContainer"
	add_child(_particle_container)
	_particle_container.anchors_preset = Control.PRESET_FULL_RECT
	_particle_container.mouse_filter = Control.MOUSE_FILTER_IGNORE


## 设置粒子效果
func _setup_particles() -> void:
	for i in range(particle_count):
		var particle = ColorRect.new()
		particle.color = Color(1.0, 0.84, 0.0, 0.1)  # 金色粒子
		particle.custom_minimum_size = Vector2(4, 4)
		_particle_container.add_child(particle)
		_particles.append(particle)
		
		# 随机位置
		particle.position = Vector2(
			randf_range(0, size.x),
			randf_range(0, size.y)
		)
		
		# 启动粒子动画
		_animate_particle(particle)


## 粒子动画
func _animate_particle(particle: ColorRect) -> void:
	var tween = create_tween()
	tween.set_loops()
	
	# 随机移动
	var target_pos = Vector2(
		randf_range(0, size.x),
		randf_range(0, size.y)
	)
	
	tween.tween_property(particle, "position", target_pos, randf_range(2.0, 5.0))
	tween.tween_property(particle, "modulate:a", randf_range(0.05, 0.15), randf_range(1.0, 2.0))
	tween.tween_property(particle, "modulate:a", 0.0, randf_range(1.0, 2.0))


## 启动渐变动画
func _start_gradient_animation() -> void:
	if _gradient_tween:
		_gradient_tween.kill()
	
	_gradient_tween = create_tween()
	_gradient_tween.set_loops()
	
	# 渐变颜色变化
	_gradient_tween.tween_property(_gradient_overlay, "color", Color(0.15, 0.15, 0.25, 0.3), gradient_speed)
	_gradient_tween.tween_property(_gradient_overlay, "color", Color(0.1, 0.1, 0.2, 0.3), gradient_speed)


## 启动Go-Go Time效果
func start_gogo_effect() -> void:
	if _is_gogo_active:
		return
	
	_is_gogo_active = true
	gogo_effect_started.emit()
	
	# Go-Go Time覆盖层动画
	if _gogo_tween:
		_gogo_tween.kill()
	
	_gogo_tween = create_tween()
	_gogo_tween.tween_property(_gogo_overlay, "color:a", gogo_intensity, 0.3)
	
	# 增强粒子效果
	for particle in _particles:
		particle.color = Color(1.0, 0.5, 0.0, 0.2)  # 橙色粒子
	
	# 加快渐变速度
	if _gradient_tween:
		_gradient_tween.kill()
	
	_gradient_tween = create_tween()
	_gradient_tween.set_loops()
	_gradient_tween.tween_property(_gradient_overlay, "color", Color(0.2, 0.15, 0.1, 0.4), gradient_speed * 0.5)
	_gradient_tween.tween_property(_gradient_overlay, "color", Color(0.15, 0.1, 0.05, 0.4), gradient_speed * 0.5)


## 结束Go-Go Time效果
func end_gogo_effect() -> void:
	if not _is_gogo_active:
		return
	
	_is_gogo_active = false
	gogo_effect_ended.emit()
	
	# Go-Go Time覆盖层动画
	if _gogo_tween:
		_gogo_tween.kill()
	
	_gogo_tween = create_tween()
	_gogo_tween.tween_property(_gogo_overlay, "color:a", 0.0, 0.3)
	
	# 恢复粒子效果
	for particle in _particles:
		particle.color = Color(1.0, 0.84, 0.0, 0.1)  # 金色粒子
	
	# 恢复渐变速度
	_start_gradient_animation()


## 设置基础颜色
func set_base_color(color: Color) -> void:
	_base_color = color
	_background.color = color


## 设置Go-Go颜色
func set_gogo_color(color: Color) -> void:
	_gogo_color = color
	if _is_gogo_active:
		_gogo_overlay.color = Color(color.r, color.g, color.b, gogo_intensity)


## 检查Go-Go状态
func is_gogo_active() -> bool:
	return _is_gogo_active


## 重置
func reset() -> void:
	_is_gogo_active = false
	_gogo_overlay.color.a = 0.0
	_background.color = _base_color
	
	for particle in _particles:
		particle.color = Color(1.0, 0.84, 0.0, 0.1)
	
	_start_gradient_animation()


## 调整大小时重新布局粒子
func _resized() -> void:
	for particle in _particles:
		particle.position = Vector2(
			randf_range(0, size.x),
			randf_range(0, size.y)
		)