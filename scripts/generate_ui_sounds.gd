## UI 音效生成器
## 功能：在 Godot 编辑器中生成简单的 UI 音效文件
## 使用方法：在 Godot 编辑器中作为工具脚本运行，或调用 generate_all_sounds() 方法
## 作者：TaikoLine Team
## 日期：2026-03-27

@tool
extends Node

## 音效输出目录
const OUTPUT_DIR := "res://resources/sounds/ui/"

## 音效配置
const SOUND_CONFIGS := {
	"hover.wav": {
		"frequency": 800.0,
		"duration": 0.1,
		"volume_db": -15.0,
		"waveform": "sine"
	},
	"confirm.wav": {
		"frequency": 1000.0,
		"duration": 0.2,
		"volume_db": -10.0,
		"waveform": "sine"
	},
	"navigate.wav": {
		"frequency": 600.0,
		"duration": 0.08,
		"volume_db": -20.0,
		"waveform": "sine"
	}
}

## 生成所有音效
func generate_all_sounds() -> Dictionary:
	var results := {}
	for filename in SOUND_CONFIGS.keys():
		var config = SOUND_CONFIGS[filename]
		var success = _generate_sound(filename, config)
		results[filename] = "成功" if success else "失败"
	return results

## 生成单个音效文件
## 参数 filename: 输出文件名
## 参数 config: 音效配置
## 返回: 是否成功
func _generate_sound(filename: String, config: Dictionary) -> bool:
	var output_path = OUTPUT_DIR + filename
	
	# 创建 AudioStreamWAV
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	stream.stereo = false
	
	# 计算采样数
	var duration: float = config.get("duration", 0.1)
	var sample_count = int(duration * stream.mix_rate)
	
	# 生成音频数据
	var data = PackedByteArray()
	data.resize(sample_count * 2)  # 16-bit = 2 bytes per sample
	
	var frequency: float = config.get("frequency", 800.0)
	var volume_db: float = config.get("volume_db", -10.0)
	var amplitude = pow(10.0, volume_db / 20.0) * 32767.0
	
	for i in range(sample_count):
		var t = float(i) / stream.mix_rate
		var sample_value: float
		
		# 根据波形类型生成采样
		match config.get("waveform", "sine"):
			"sine":
				sample_value = sin(t * frequency * TAU)
			"square":
				sample_value = 1.0 if sin(t * frequency * TAU) > 0 else -1.0
			"triangle":
				var phase = fmod(t * frequency, 1.0)
				sample_value = 4.0 * abs(phase - 0.5) - 1.0
			_:
				sample_value = sin(t * frequency * TAU)
		
		# 应用淡入淡出
		var fade_samples = int(sample_count * 0.1)  # 10% 淡入淡出
		if i < fade_samples:
			sample_value *= float(i) / fade_samples
		elif i > sample_count - fade_samples:
			sample_value *= float(sample_count - i) / fade_samples
		
		# 转换为 16-bit 整数
		var int_sample = int(sample_value * amplitude)
		int_sample = clamp(int_sample, -32768, 32767)
		
		# 写入字节（小端序）
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF
	
	stream.data = data
	
	# 保存文件
	var save_result = ResourceSaver.save(stream, output_path)
	return save_result == OK

## 在编辑器中运行时自动生成音效
func _run() -> void:
	var results = generate_all_sounds()
	print("UI 音效生成结果:")
	for filename in results.keys():
		print("  %s: %s" % [filename, results[filename]])