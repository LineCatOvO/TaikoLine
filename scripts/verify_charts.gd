extends SceneTree

## 谱面验证脚本
## 用于验证新创建的谱面能否正常解析

const TJAData = preload("res://src/parser/tja_data.gd")
const TJAParser = preload("res://src/parser/tja_parser.gd")

func _init():
	var parser = TJAParser.new()
	var charts = [
		"res://songs/test/tutorial.tja",
		"res://songs/test/rhythm_training.tja",
		"res://songs/test/special_notes.tja",
		"res://songs/test/speed_variation.tja",
		"res://songs/test/full_demo.tja"
	]

	print("\n========================================")
	print("谱面验证测试")
	print("========================================\n")

	var success_count = 0
	var fail_count = 0

	for chart_path in charts:
		print("测试谱面: " + chart_path)
		var result = parser.parse_file(chart_path)

		if result.success:
			print("  ✓ 解析成功")
			print("  - 标题: " + result.song.title)
			print("  - BPM: " + str(result.song.bpm))
			print("  - 难度数量: " + str(result.song.courses.size()))

			for course_type in result.song.courses:
				var course = result.song.courses[course_type]
				print("    - " + TJAData.course_type_to_string(course_type) + ": 等级 " + str(course.level) + ", 小节 " + str(course.measures.size()))

			success_count += 1
		else:
			print("  ✗ 解析失败")
			print("  - 错误: " + result.error)
			print("  - 行号: " + str(result.error_line))
			fail_count += 1

		print("")

	print("========================================")
	print("验证结果: 成功 " + str(success_count) + " / 失败 " + str(fail_count))
	print("========================================\n")

	quit()