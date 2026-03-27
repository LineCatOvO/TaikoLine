class_name GameNote
extends Area2D
## 音符类
## 实现音符的视觉表现和状态管理
## 
## 性能优化说明：
## - 使用静态纹理缓存避免重复创建图像
## - 预渲染所有音符类型的纹理
## - 对象池复用减少内存分配

## 音符类型枚举（引用TJAData中的定义）
const TJAData = preload("res://src/parser/tja_data.gd")

## 音符状态枚举
enum NoteState {
	WAITING,     ## 等待中（尚未进入判定区域）
	APPROACHING, ## 接近中（进入判定区域）
	JUDGING,     ## 判定中（在判定窗口内）
	JUDGED,      ## 已判定
	MISSED       ## 错过
}

## 信号
signal note_judged(note: GameNote, judge_result: String)
signal note_missed(note: GameNote)

## ==================== 纹理缓存（静态） ====================
## 缓存所有音符类型的纹理，避免重复创建
static var _texture_cache: Dictionary = {}
static var _cache_initialized: bool = false

## 音符数据
var note_type: TJAData.NoteType = TJAData.NoteType.DON
var note_state: NoteState = NoteState.WAITING
var hit_time: float = 0.0  ## 音符应该被打击的时间（秒）
var position_ratio: float = 0.0  ## 在小节中的位置比例

## 气球/连打数据
var balloon_hits: int = 0
var renda_count: int = 0

## 视觉组件
var sprite: Sprite2D
var animation_player: AnimationPlayer

## 判定区域
var judge_area: Area2D

## 配置
var scroll_speed: float = 1.0
var judge_line_x: float = 400.0  ## 判定线X坐标

## 判定窗口（毫秒）
const PERFECT_WINDOW: float = 33.0
const GOOD_WINDOW: float = 100.0


func _ready() -> void:
	_setup_components()
	_setup_collision()


func _setup_components() -> void:
	# 创建精灵
	sprite = Sprite2D.new()
	add_child(sprite)

	# 创建动画播放器
	animation_player = AnimationPlayer.new()
	add_child(animation_player)

	# 初始化纹理缓存（仅首次）
	_ensure_texture_cache()
	
	# 设置音符外观
	_update_appearance()


## 确保纹理缓存已初始化
static func _ensure_texture_cache() -> void:
	if _cache_initialized:
		return
	
	_cache_initialized = true
	# 预渲染所有音符类型的纹理
	_pre_render_all_textures()


## 预渲染所有音符类型的纹理
static func _pre_render_all_textures() -> void:
	# 定义所有需要预渲染的音符类型
	var note_types := [
		TJAData.NoteType.DON,
		TJAData.NoteType.KA,
		TJAData.NoteType.DON_BIG,
		TJAData.NoteType.KA_BIG,
		TJAData.NoteType.RENDA,
		TJAData.NoteType.RENDA_BIG,
		TJAData.NoteType.BALLOON,
		TJAData.NoteType.KUSUDAMA,
		TJAData.NoteType.DON_DOUBLE,
		TJAData.NoteType.KA_DOUBLE,
		TJAData.NoteType.ADLIB,
	]
	
	for note_t in note_types:
		_get_or_create_texture(note_t)


## 获取或创建纹理（带缓存）
static func _get_or_create_texture(note_t: int) -> ImageTexture:
	# 检查缓存
	if note_t in _texture_cache:
		return _texture_cache[note_t]
	
	# 通过SkinManager获取音符类型对应的配置键名
	var note_type_key := SkinManager.get_note_type_key(note_t)
	
	# 从SkinManager获取颜色和大小
	var color: Color = SkinManager.get_note_color(note_type_key)
	var size: float = SkinManager.get_note_size(note_type_key)
	var outline_color: Color = SkinManager.get_note_outline_color(note_type_key)
	var outline_width: float = SkinManager.get_note_outline_width(note_type_key)
	
	# 创建纹理
	var texture = _create_circle_texture(size, color, outline_color, outline_width)
	_texture_cache[note_t] = texture
	
	return texture


## 创建圆形纹理（优化版本）
static func _create_circle_texture(size: float, color: Color, outline_color: Color, outline_width: float) -> ImageTexture:
	var image = Image.create(int(size), int(size), false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var center = Vector2(size / 2.0, size / 2.0)
	var radius = size / 2.0 - outline_width
	
	# 使用更高效的绘制方式
	var radius_sq = radius * radius
	var outline_radius_sq = (radius + outline_width) * (radius + outline_width)
	
	for x in range(int(size)):
		for y in range(int(size)):
			var dx = x - center.x
			var dy = y - center.y
			var dist_sq = dx * dx + dy * dy
			
			if dist_sq <= radius_sq:
				image.set_pixel(x, y, color)
			elif dist_sq <= outline_radius_sq:
				image.set_pixel(x, y, outline_color)
	
	return ImageTexture.create_from_image(image)


## 更新音符外观（优化版本 - 使用缓存）
func _update_appearance() -> void:
	# 检查sprite是否有效
	if sprite == null:
		return

	# 从缓存获取纹理
	var texture = _get_or_create_texture(note_type)
	if texture:
		sprite.texture = texture


func _setup_collision() -> void:
	# 创建碰撞形状
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 30.0 if is_big() else 20.0
	collision.shape = shape
	add_child(collision)


## 是否为大音符
func is_big() -> bool:
	return note_type in [
		TJAData.NoteType.DON_BIG, 
		TJAData.NoteType.KA_BIG, 
		TJAData.NoteType.RENDA_BIG,
		TJAData.NoteType.DON_DOUBLE,
		TJAData.NoteType.KA_DOUBLE
	]


## 是否为连打类型
func is_renda() -> bool:
	return note_type in [
		TJAData.NoteType.RENDA, 
		TJAData.NoteType.RENDA_BIG, 
		TJAData.NoteType.BALLOON, 
		TJAData.NoteType.KUSUDAMA
	]


## 是否为可打击音符
func is_hittable() -> bool:
	return note_type in [
		TJAData.NoteType.DON, TJAData.NoteType.KA, 
		TJAData.NoteType.DON_BIG, TJAData.NoteType.KA_BIG,
		TJAData.NoteType.RENDA, TJAData.NoteType.RENDA_BIG, 
		TJAData.NoteType.BALLOON, TJAData.NoteType.KUSUDAMA,
		TJAData.NoteType.DON_DOUBLE, TJAData.NoteType.KA_DOUBLE, 
		TJAData.NoteType.ADLIB
	]


## 是否需要红音符输入
func needs_don_input() -> bool:
	return note_type in [
		TJAData.NoteType.DON, 
		TJAData.NoteType.DON_BIG,
		TJAData.NoteType.RENDA,
		TJAData.NoteType.RENDA_BIG,
		TJAData.NoteType.DON_DOUBLE
	]


## 是否需要蓝音符输入
func needs_ka_input() -> bool:
	return note_type in [
		TJAData.NoteType.KA, 
		TJAData.NoteType.KA_BIG,
		TJAData.NoteType.KA_DOUBLE
	]


## 更新音符位置
func update_position(current_time: float, scroll_system) -> void:
	if note_state == NoteState.JUDGED or note_state == NoteState.MISSED:
		return
	
	# 计算时间差
	var time_diff = hit_time - current_time
	
	# 通过滚动系统计算位置
	var x_pos = scroll_system.time_to_position(time_diff)
	position.x = x_pos
	
	# 更新状态
	_update_state(time_diff)


## 更新音符状态
func _update_state(time_diff: float) -> void:
	var time_diff_ms = abs(time_diff) * 1000.0
	
	if note_state == NoteState.JUDGED or note_state == NoteState.MISSED:
		return
	
	# 检查是否错过
	if time_diff < -GOOD_WINDOW / 1000.0:
		note_state = NoteState.MISSED
		note_missed.emit(self)
		return
	
	# 更新状态
	if time_diff_ms <= PERFECT_WINDOW:
		note_state = NoteState.JUDGING
	elif time_diff_ms <= GOOD_WINDOW:
		note_state = NoteState.JUDGING
	elif position.x < judge_line_x + 100:
		note_state = NoteState.APPROACHING
	else:
		note_state = NoteState.WAITING


## 尝试判定
func try_judge(input_type: String, current_time: float) -> String:
	if note_state == NoteState.JUDGED or note_state == NoteState.MISSED:
		return ""
	
	if not is_hittable():
		return ""
	
	# 检查输入是否匹配
	var input_matches = false
	if input_type == "don" and needs_don_input():
		input_matches = true
	elif input_type == "ka" and needs_ka_input():
		input_matches = true
	elif is_renda():
		# 连打可以接受任意输入
		input_matches = true
	
	if not input_matches:
		return ""
	
	# 计算判定
	var time_diff = abs(hit_time - current_time) * 1000.0
	var judge_result = _calculate_judge(time_diff)
	
	if judge_result != "":
		note_state = NoteState.JUDGED
		note_judged.emit(self, judge_result)
		_play_hit_animation()
	
	return judge_result


## 计算判定结果
func _calculate_judge(time_diff_ms: float) -> String:
	if time_diff_ms <= PERFECT_WINDOW:
		return "良"
	elif time_diff_ms <= GOOD_WINDOW:
		return "可"
	else:
		return ""


## 播放打击动画
func _play_hit_animation() -> void:
	# 简单的缩放动画
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.05)
	tween.tween_property(self, "scale", Vector2(0.0, 0.0), 0.1)
	# 注意：不使用queue_free()，因为音符来自对象池
	# 对象池会在需要时回收音符


## 重置音符状态（用于对象池）
func reset() -> void:
	note_state = NoteState.WAITING
	scale = Vector2(1.0, 1.0)
	modulate = Color.WHITE
	balloon_hits = 0
	renda_count = 0


## 设置音符数据
func setup(data: TJAData.TJANote, p_hit_time: float) -> void:
	note_type = data.note_type
	position_ratio = data.position
	balloon_hits = data.balloon_hits
	renda_count = data.renda_count
	hit_time = p_hit_time
	_update_appearance()


## ==================== 纹理缓存管理 ====================

## 清除纹理缓存（皮肤切换时调用）
static func clear_texture_cache() -> void:
	_texture_cache.clear()
	_cache_initialized = false


## 重新初始化纹理缓存（皮肤切换后调用）
static func refresh_texture_cache() -> void:
	clear_texture_cache()
	_ensure_texture_cache()