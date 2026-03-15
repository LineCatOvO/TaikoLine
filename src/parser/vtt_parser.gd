class_name VTTParser
## VTT文件解析器
## 解析WebVTT格式的歌词文件

## 歌词条目类
class LyricsEntry:
	var start_time: float = 0.0  ## 开始时间（秒）
	var end_time: float = 0.0    ## 结束时间（秒）
	var text: String = ""        ## 歌词文本
	
	func _init(p_start: float = 0.0, p_end: float = 0.0, p_text: String = "") -> void:
		start_time = p_start
		end_time = p_end
		text = p_text

## 解析结果类
class VTTParseResult:
	var success: bool = true
	var error: String = ""
	var entries: Array[LyricsEntry] = []
	
	func _init(p_success: bool = true, p_error: String = "") -> void:
		success = p_success
		error = p_error

## 解析VTT文件
func parse_file(file_path: String) -> VTTParseResult:
	var result = VTTParseResult.new()
	
	# 检查文件是否存在
	if not FileAccess.file_exists(file_path):
		result.success = false
		result.error = "文件不存在: " + file_path
		return result
	
	# 读取文件内容
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		result.success = false
		result.error = "无法打开文件: " + file_path
		return result
	
	var content = file.get_as_text()
	file.close()
	
	return parse_content(content)


## 解析VTT内容
func parse_content(content: String) -> VTTParseResult:
	var result = VTTParseResult.new()
	var lines = content.split("\n")
	
	# 检查VTT文件头
	if lines.is_empty() or not lines[0].begins_with("WEBVTT"):
		result.success = false
		result.error = "无效的VTT文件格式"
		return result
	
	var i = 1
	while i < lines.size():
		var line = lines[i].strip_edges()
		
		# 跳过空行
		if line.is_empty():
			i += 1
			continue
		
		# 跳过注释
		if line.begins_with("NOTE"):
			i += 1
			while i < lines.size() and not lines[i].strip_edges().is_empty():
				i += 1
			continue
		
		# 跳过样式定义
		if line.begins_with("STYLE"):
			i += 1
			while i < lines.size() and not lines[i].strip_edges().is_empty():
				i += 1
			continue
		
		# 检查时间戳行
		if "-->" in line:
			var timestamps = _parse_timestamps(line)
			if timestamps == null:
				i += 1
				continue
			
			# 收集歌词文本
			var lyrics_text = ""
			i += 1
			while i < lines.size():
				var text_line = lines[i].strip_edges()
				if text_line.is_empty():
					break
				if not lyrics_text.is_empty():
					lyrics_text += "\n"
				lyrics_text += text_line
				i += 1
			
			# 创建歌词条目
			var entry = LyricsEntry.new(timestamps.start, timestamps.end, lyrics_text)
			result.entries.append(entry)
		else:
			i += 1
	
	return result


## 解析时间戳行
func _parse_timestamps(line: String) -> Dictionary:
	# 格式: 00:00.000 --> 00:05.000
	# 或: 00:00:00.000 --> 00:00:05.000
	
	var parts = line.split("-->")
	if parts.size() != 2:
		return {}
	
	var start_str = parts[0].strip_edges()
	var end_str = parts[1].strip_edges()
	
	# 移除可能的额外参数（如位置信息）
	var space_pos = end_str.find(" ")
	if space_pos != -1:
		end_str = end_str.left(space_pos)
	
	var start_time = _parse_time(start_str)
	var end_time = _parse_time(end_str)
	
	if start_time < 0 or end_time < 0:
		return {}
	
	return {"start": start_time, "end": end_time}


## 解析时间字符串
func _parse_time(time_str: String) -> float:
	# 格式: MM:SS.mmm 或 HH:MM:SS.mmm
	var parts = time_str.split(":")
	
	if parts.size() == 2:
		# MM:SS.mmm
		var minutes = parts[0].to_float()
		var seconds = parts[1].to_float()
		return minutes * 60.0 + seconds
	elif parts.size() == 3:
		# HH:MM:SS.mmm
		var hours = parts[0].to_float()
		var minutes = parts[1].to_float()
		var seconds = parts[2].to_float()
		return hours * 3600.0 + minutes * 60.0 + seconds
	
	return -1.0


## 解析#LYRIC命令格式的歌词
## 格式: #LYRIC 时间,歌词文本
func parse_lyric_commands(content: String) -> Array[LyricsEntry]:
	var entries: Array[LyricsEntry] = []
	var lines = content.split("\n")
	
	for line in lines:
		line = line.strip_edges()
		if not line.begins_with("#LYRIC"):
			continue
		
		# 解析#LYRIC命令
		var param_start = line.find(" ")
		if param_start == -1:
			continue
		
		var params = line.substr(param_start + 1).strip_edges()
		var comma_pos = params.find(",")
		if comma_pos == -1:
			continue
		
		var time_str = params.left(comma_pos).strip_edges()
		var text = params.substr(comma_pos + 1).strip_edges()
		
		var time = time_str.to_float()
		if time >= 0:
			# 创建歌词条目，结束时间设为下一句开始或默认5秒
			var entry = LyricsEntry.new(time, time + 5.0, text)
			entries.append(entry)
	
	# 按时间排序
	entries.sort_custom(func(a, b): return a.start_time < b.start_time)
	
	# 更新结束时间
	for i in range(entries.size() - 1):
		entries[i].end_time = entries[i + 1].start_time
	
	return entries