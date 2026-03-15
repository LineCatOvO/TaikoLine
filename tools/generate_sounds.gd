@tool
extends EditorScript
## 音效生成工具
## 在Godot编辑器中运行此脚本生成简单的音效文件
## 使用方法: File -> Run (或按Ctrl+Shift+X)

## 音效参数配置
const SOUND_CONFIGS := {
	"don": {
		"frequency": 200.0,
		"duration": 0.15,
		"waveform": "sine",
		"volume": 0.8
	},
	"ka": {
		"frequency": 400.0,
		"duration": 0.15,
		"waveform": "sine",
		"volume": 0.8
	},
	"balloon": {
		"frequency": 600.0,
		"duration": 0.1,
		"waveform": "square",
		"volume": 0.6
	},
	"judge_perfect": {
		"frequency": 800.0,
		"duration": 0.2,
		"waveform": "sine",
		"volume": 0.7
	},
	"judge_good": {
		"frequency": 600.0,
		"duration": 0.2,
		"waveform": "sine",
		"volume": 0.7
	},
	"judge_miss": {
		"frequency": 200.0,
		"duration": 0.3,
		"waveform": "triangle",
		"volume": 0.5
	},
	"combo_bonus": {
		"frequency": 1000.0,
		"duration": 0.15,
		"waveform": "sine",
		"volume": 0.8
	}
}

const OUTPUT_PATH := "res://resources/sounds/"
const SAMPLE_RATE := 44100


func _run() -> void:
	print("=== 音效生成工具 ===")
	print("开始生成音效文件...")
	
	for sound_name in SOUND_CONFIGS:
		var config: Dictionary = SOUND_CONFIGS[sound_name]
		var success := _generate_sound(sound_name, config)
		if success:
			print("✓ 生成成功: %s.ogg" % sound_name)
		else:
			print("✗ 生成失败: %s" % sound_name)
	
	print("=== 音效生成完成 ===")


func _generate_sound(name: String, config: Dictionary) -> bool:
	var frequency: float = config.get("frequency", 440.0)
	var duration: float = config.get("duration", 0.2)
	var waveform: String = config.get("waveform", "sine")
	var volume: float = config.get("volume", 0.8)
	
	# 计算采样数
	var samples := int(duration * SAMPLE_RATE)
	
	# 创建AudioStreamWAV
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = SAMPLE_RATE
	audio.stereo = false
	
	# 生成采样数据
	var data := PackedByteArray()
	data.resize(samples * 2)  # 16位 = 2字节
	
	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		var sample_value: float
		
		# 根据波形生成采样值
		match waveform:
			"sine":
				sample_value = sin(t * frequency * TAU)
			"square":
				sample_value = 1.0 if sin(t * frequency * TAU) >= 0 else -1.0
			"triangle":
				var phase := fmod(t * frequency, 1.0)
				sample_value = 2.0 * abs(2.0 * phase - 1.0) - 1.0
			"sawtooth":
				var phase := fmod(t * frequency, 1.0)
				sample_value = 2.0 * phase - 1.0
			_:
				sample_value = sin(t * frequency * TAU)
		
		# 应用音量和淡出效果
		var fade_out := 1.0
		var fade_start := samples * 0.7
		if i > fade_start:
			fade_out = 1.0 - (float(i - fade_start) / (samples - fade_start))
		
		sample_value *= volume * fade_out
		
		# 转换为16位整数
		var int_value := int(sample_value * 32767)
		int_value = clampi(int_value, -32768, 32767)
		
		# 写入字节（小端序）
		data[i * 2] = int_value & 0xFF
		data[i * 2 + 1] = (int_value >> 8) & 0xFF
	
	audio.data = data
	
	# 保存为WAV文件
	var wav_path := OUTPUT_PATH + name + ".wav"
	var save_result := audio.save_to_wav(wav_path)
	
	if save_result != OK:
		push_error("保存WAV文件失败: " + wav_path)
		return false
	
	print("  已保存WAV: %s" % wav_path)
	return true


## 将WAV转换为OGG（需要手动在Godot中导入）
## 导入步骤：
## 1. 在FileSystem面板中找到生成的WAV文件
## 2. 右键点击 -> Import
## 3. 在Import面板中选择OGG格式
## 4. 点击Reimport
## 5. 删除原WAV文件（可选）