class_name GameNote
extends Area2D
## 音符类
## 实现音符的视觉表现和状态管理

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

## 颜色配置
const DON_COLOR := Color(1.0, 0.2, 0.2)      ## 红色
const KA_COLOR := Color(0.2, 0.4, 1.0)       ## 蓝色
const DON_BIG_COLOR := Color(1.0, 0.4, 0.4)  ## 大红色
const KA_BIG_COLOR := Color(0.4, 0.6, 1.0)   ## 大蓝色


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
	
	# 设置音符外观
	_update_appearance()


func _setup_collision() -> void:
	# 创建碰撞形状
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 30.0 if is_big() else 20.0
	collision.shape = shape
	add_child(collision)


## 更新音符外观
func _update_appearance() -> void:
	# 根据音符类型设置颜色和大小
	var color: Color
	var size: float
	
	match note_type:
		TJAData.NoteType.DON:
			color = DON_COLOR
			size = 40.0
		TJAData.NoteType.KA:
			color = KA_COLOR
			size = 40.0
		TJAData.NoteType.DON_BIG:
			color = DON_BIG_COLOR
			size = 60.0
		TJAData.NoteType.KA_BIG:
			color = KA_BIG_COLOR
			size = 60.0
		TJAData.NoteType.RENDA:
			color = DON_COLOR
			size = 40.0
		TJAData.NoteType.RENDA_BIG:
			color = DON_BIG_COLOR
			size = 60.0
		TJAData.NoteType.BALLOON:
			color = Color(1.0, 0.8, 0.2)
			size = 50.0
		TJAData.NoteType.KUSUDAMA:
			color = Color(0.8, 0.2, 0.8)
			size = 50.0
		_:
			color = Color.WHITE
			size = 40.0
	
	# 创建简单的圆形纹理
	var image = Image.create(int(size), int(size), false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var center = Vector2(size / 2.0, size / 2.0)
	var radius = size / 2.0 - 2.0
	
	# 绘制圆形
	for x in range(int(size)):
		for y in range(int(size)):
			var dist = Vector2(x, y).distance_to(center)
			if dist <= radius:
				image.set_pixel(x, y, color)
			elif dist <= radius + 2.0:
				# 边缘
				image.set_pixel(x, y, color.darkened(0.3))
	
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture


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