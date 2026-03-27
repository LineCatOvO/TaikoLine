# VTT Parser Unit Tests
# Tests for the VTT (WebVTT) lyrics file parser functionality
# Framework: GUT v9.6.0

extends GutTest

const VTTParser = preload("res://src/parser/vtt_parser.gd")

var parser: VTTParser = null

# ============================================================
# Setup and Teardown
# ============================================================

func before_all():
	# Setup that runs once before all tests
	pass

func before_each():
	# Setup that runs before each test
	parser = VTTParser.new()

func after_each():
	# Cleanup that runs after each test
	parser = null

func after_all():
	# Cleanup that runs once after all tests
	pass

# ============================================================
# VTT-001: Parse Basic VTT Format
# ============================================================

func test_vtt001_parse_basic_vtt():
	# Test parsing basic VTT file with header
	var content = """WEBVTT

00:00:01.000 --> 00:00:03.000
Hello World

00:00:04.000 --> 00:00:06.000
Second Line
"""
	var result = parser.parse_content(content)

	assert_true(result.success, "Parse should succeed")
	assert_eq(result.entries.size(), 2, "Should have 2 entries")

	# Check first entry
	assert_almost_eq(result.entries[0].start_time, 1.0, 0.001, "First entry start time should be 1.0")
	assert_almost_eq(result.entries[0].end_time, 3.0, 0.001, "First entry end time should be 3.0")
	assert_eq(result.entries[0].text, "Hello World", "First entry text should be correct")

	# Check second entry
	assert_almost_eq(result.entries[1].start_time, 4.0, 0.001, "Second entry start time should be 4.0")
	assert_almost_eq(result.entries[1].end_time, 6.0, 0.001, "Second entry end time should be 6.0")
	assert_eq(result.entries[1].text, "Second Line", "Second entry text should be correct")

func test_vtt001_parse_vtt_with_header_text():
	# Test parsing VTT with header text after WEBVTT
	var content = """WEBVTT - Karaoke Lyrics

00:00:01.000 --> 00:00:03.000
Test Lyrics
"""
	var result = parser.parse_content(content)

	assert_true(result.success, "Parse should succeed with header text")
	assert_eq(result.entries.size(), 1, "Should have 1 entry")

func test_vtt001_parse_multiple_entries():
	# Test parsing multiple lyrics entries
	var content = """WEBVTT

00:00:00.000 --> 00:00:02.000
First line

00:00:02.000 --> 00:00:04.000
Second line

00:00:04.000 --> 00:00:06.000
Third line

00:00:06.000 --> 00:00:08.000
Fourth line
"""
	var result = parser.parse_content(content)

	assert_true(result.success, "Parse should succeed")
	assert_eq(result.entries.size(), 4, "Should have 4 entries")

# ============================================================
# VTT-002: Parse Timestamps
# ============================================================

func test_vtt002_parse_timestamp_mmss():
	# Test parsing MM:SS.mmm timestamp format
	var content = """WEBVTT

00:30.000 --> 01:00.000
Test
"""
	var result = parser.parse_content(content)

	assert_true(result.success, "Parse should succeed")
	assert_almost_eq(result.entries[0].start_time, 30.0, 0.001, "Start time should be 30.0 seconds")
	assert_almost_eq(result.entries[0].end_time, 60.0, 0.001, "End time should be 60.0 seconds")

func test_vtt002_parse_timestamp_hhmmss():
	# Test parsing HH:MM:SS.mmm timestamp format
	var content = """WEBVTT

00:01:30.000 --> 00:02:00.000
Test
"""
	var result = parser.parse_content(content)

	assert_true(result.success, "Parse should succeed")
	assert_almost_eq(result.entries[0].start_time, 90.0, 0.001, "Start time should be 90.0 seconds (1:30)")
	assert_almost_eq(result.entries[0].end_time, 120.0, 0.001, "End time should be 120.0 seconds (2:00)")

func test_vtt002_parse_timestamp_milliseconds():
	# Test parsing timestamps with milliseconds
	var content = """WEBVTT

00:00:01.500 --> 00:00:03.250
Test
"""
	var result = parser.parse_content(content)

	assert_true(result.success, "Parse should succeed")
	assert_almost_eq(result.entries[0].start_time, 1.5, 0.001, "Start time should be 1.5 seconds")
	assert_almost_eq(result.entries[0].end_time, 3.25, 0.001, "End time should be 3.25 seconds")

func test_vtt002_parse_timestamp_hours():
	# Test parsing timestamps with hours
	var content = """WEBVTT

01:30:00.000 --> 01:35:00.000
Test
"""
	var result = parser.parse_content(content)

	assert_true(result.success, "Parse should succeed")
	assert_almost_eq(result.entries[0].start_time, 5400.0, 0.001, "Start time should be 5400.0 seconds (1:30:00)")
	assert_almost_eq(result.entries[0].end_time, 5700.0, 0.001, "End time should be 5700.0 seconds (1:35:00)")

func test_vtt002_parse_timestamp_with_position():
	# Test parsing timestamps with position information
	var content = """WEBVTT

00:00:01.000 --> 00:00:03.000 align:center line:50%
Test with position
"""
	var result = parser.parse_content(content)

	assert_true(result.success, "Parse should succeed with position info")
	assert_almost_eq(result.entries[0].start_time, 1.0, 0.001, "Start time should be parsed correctly")
	assert_almost_eq(result.entries[0].end_time, 3.0, 0.001, "End time should be parsed correctly")

# ============================================================
# VTT-003: Parse Lyrics Text
# ============================================================

func test_vtt003_parse_single_line_text():
	# Test parsing single line lyrics text
	var content = """WEBVTT

00:00:01.000 --> 00:00:03.000
Single line lyrics
"""
	var result = parser.parse_content(content)

	assert_true(result.success, "Parse should succeed")
	assert_eq(result.entries[0].text, "Single line lyrics", "Text should be parsed correctly")

func test_vtt003_parse_multiline_text():
	# Test parsing multi-line lyrics text
	var content = """WEBVTT

00:00:01.000 --> 00:00:05.000
First line
Second line
Third line
"""
	var result = parser.parse_content(content)

	assert_true(result.success, "Parse should succeed")
	assert_eq(result.entries[0].text, "First line\nSecond line\nThird line", "Multi-line text should be joined with newlines")

func test_vtt003_parse_text_with_special_chars():
	# Test parsing text with special characters
	var content = """WEBVTT

00:00:01.000 --> 00:00:03.000
Hello! How are you? (Test)
"""
	var result = parser.parse_content(content)

	assert_true(result.success, "Parse should succeed")
	assert_eq(result.entries[0].text, "Hello! How are you? (Test)", "Special characters should be preserved")

func test_vtt003_parse_text_with_numbers():
	# Test parsing text with numbers
	var content = """WEBVTT

00:00:01.000 --> 00:00:03.000
12345 Numbers in lyrics
"""
	var result = parser.parse_content(content)

	assert_true(result.success, "Parse should succeed")
	assert_eq(result.entries[0].text, "12345 Numbers in lyrics", "Numbers should be preserved")

func test_vtt003_parse_japanese_text():
	# Test parsing Japanese lyrics text
	var content = """WEBVTT

00:00:01.000 --> 00:00:03.000
こんにちは世界

00:00:04.000 --> 00:00:06.000
日本語の歌詞テスト
"""
	var result = parser.parse_content(content)

	assert_true(result.success, "Parse should succeed")
	assert_eq(result.entries.size(), 2, "Should have 2 entries")
	assert_eq(result.entries[0].text, "こんにちは世界", "Japanese text should be preserved")
	assert_eq(result.entries[1].text, "日本語の歌詞テスト", "Japanese text should be preserved")

# ============================================================
# VTT-004: Parse Comments and Styles
# ============================================================

func test_vtt004_skip_comments():
	# Test that NOTE comments are skipped
	var content = """WEBVTT

NOTE This is a comment

00:00:01.000 --> 00:00:03.000
Lyrics line

NOTE Another comment
"""
	var result = parser.parse_content(content)

	assert_true(result.success, "Parse should succeed")
	assert_eq(result.entries.size(), 1, "Comments should be skipped")
	assert_eq(result.entries[0].text, "Lyrics line", "Only lyrics should be parsed")

func test_vtt004_skip_multiline_comments():
	# Test that multi-line NOTE comments are skipped
	var content = """WEBVTT

NOTE
This is a multi-line comment
that spans multiple lines

00:00:01.000 --> 00:00:03.000
Lyrics line
"""
	var result = parser.parse_content(content)

	assert_true(result.success, "Parse should succeed")
	assert_eq(result.entries.size(), 1, "Multi-line comments should be skipped")

func test_vtt004_skip_style_blocks():
	# Test that STYLE blocks are skipped
	var content = """WEBVTT

STYLE
::cue {
  color: white;
}

00:00:01.000 --> 00:00:03.000
Lyrics line
"""
	var result = parser.parse_content(content)

	assert_true(result.success, "Parse should succeed")
	assert_eq(result.entries.size(), 1, "Style blocks should be skipped")
	assert_eq(result.entries[0].text, "Lyrics line", "Only lyrics should be parsed")

# ============================================================
# VTT-005: Error Handling
# ============================================================

func test_vtt005_error_invalid_header():
	# Test error handling for invalid VTT header
	var content = """INVALID HEADER

00:00:01.000 --> 00:00:03.000
Test
"""
	var result = parser.parse_content(content)

	assert_false(result.success, "Parse should fail for invalid header")
	assert_eq(result.error, "无效的VTT文件格式", "Error should indicate invalid format")

func test_vtt005_error_empty_content():
	# Test error handling for empty content
	var content = ""
	var result = parser.parse_content(content)

	assert_false(result.success, "Parse should fail for empty content")
	assert_eq(result.error, "无效的VTT文件格式", "Error should indicate invalid format")

func test_vtt005_error_file_not_found():
	# Test error handling for non-existent file
	var result = parser.parse_file("res://test/fixtures/sample_vtt/nonexistent.vtt")

	assert_false(result.success, "Parse should fail for non-existent file")
	assert(result.error.contains("文件不存在"), "Error should indicate file not found")

func test_vtt005_error_only_header():
	# Test parsing VTT with only header (no entries)
	var content = """WEBVTT
"""
	var result = parser.parse_content(content)

	assert_true(result.success, "Parse should succeed for header-only file")
	assert_eq(result.entries.size(), 0, "Should have 0 entries")

func test_vtt005_error_invalid_timestamp_format():
	# Test handling of invalid timestamp format
	var content = """WEBVTT

invalid --> timestamp
Test
"""
	var result = parser.parse_content(content)

	# Should succeed but skip invalid entries
	assert_true(result.success, "Parse should succeed")
	assert_eq(result.entries.size(), 0, "Invalid timestamps should be skipped")

# ============================================================
# VTT-006: Parse #LYRIC Commands
# ============================================================

func test_vtt006_parse_lyric_commands():
	# Test parsing #LYRIC command format
	var content = """#LYRIC 1.0,First line
#LYRIC 3.0,Second line
#LYRIC 5.0,Third line
"""
	var entries = parser.parse_lyric_commands(content)

	assert_eq(entries.size(), 3, "Should have 3 entries")

	# Check first entry
	assert_almost_eq(entries[0].start_time, 1.0, 0.001, "First entry start time should be 1.0")
	assert_almost_eq(entries[0].end_time, 3.0, 0.001, "First entry end time should be 3.0 (next entry start)")
	assert_eq(entries[0].text, "First line", "First entry text should be correct")

	# Check second entry
	assert_almost_eq(entries[1].start_time, 3.0, 0.001, "Second entry start time should be 3.0")
	assert_almost_eq(entries[1].end_time, 5.0, 0.001, "Second entry end time should be 5.0")
	assert_eq(entries[1].text, "Second line", "Second entry text should be correct")

	# Check third entry
	assert_almost_eq(entries[2].start_time, 5.0, 0.001, "Third entry start time should be 5.0")
	assert_almost_eq(entries[2].end_time, 10.0, 0.001, "Third entry end time should be 10.0 (start + 5)")

func test_vtt006_parse_lyric_commands_with_whitespace():
	# Test parsing #LYRIC commands with extra whitespace
	var content = """#LYRIC  1.0 ,  First line  
#LYRIC 3.0,Second line
"""
	var entries = parser.parse_lyric_commands(content)

	assert_eq(entries.size(), 2, "Should have 2 entries")
	assert_eq(entries[0].text, "First line", "Whitespace should be trimmed")

func test_vtt006_parse_lyric_commands_empty():
	# Test parsing empty #LYRIC content
	var content = ""
	var entries = parser.parse_lyric_commands(content)

	assert_eq(entries.size(), 0, "Should have 0 entries for empty content")

func test_vtt006_parse_lyric_commands_no_lyric():
	# Test parsing content without #LYRIC commands
	var content = """TITLE:Test
BPM:120
"""
	var entries = parser.parse_lyric_commands(content)

	assert_eq(entries.size(), 0, "Should have 0 entries when no #LYRIC commands")

func test_vtt006_parse_lyric_commands_invalid_format():
	# Test parsing #LYRIC commands with invalid format
	var content = """#LYRIC invalid
#LYRIC 1.0
#LYRIC 2.0,Valid line
"""
	var entries = parser.parse_lyric_commands(content)

	assert_eq(entries.size(), 1, "Should have 1 valid entry")
	assert_eq(entries[0].text, "Valid line", "Only valid entries should be parsed")

func test_vtt006_parse_lyric_commands_sorted():
	# Test that #LYRIC commands are sorted by time
	var content = """#LYRIC 5.0,Third
#LYRIC 1.0,First
#LYRIC 3.0,Second
"""
	var entries = parser.parse_lyric_commands(content)

	assert_eq(entries.size(), 3, "Should have 3 entries")
	assert_eq(entries[0].text, "First", "First entry should be sorted by time")
	assert_eq(entries[1].text, "Second", "Second entry should be sorted by time")
	assert_eq(entries[2].text, "Third", "Third entry should be sorted by time")

# ============================================================
# VTT-007: Edge Cases
# ============================================================

func test_vtt007_parse_empty_lines():
	# Test parsing VTT with empty lines between entries
	var content = """WEBVTT


00:00:01.000 --> 00:00:03.000
First line


00:00:04.000 --> 00:00:06.000
Second line


"""
	var result = parser.parse_content(content)

	assert_true(result.success, "Parse should succeed")
	assert_eq(result.entries.size(), 2, "Empty lines should be handled")

func test_vtt007_parse_whitespace_text():
	# Test parsing VTT with whitespace in text
	var content = """WEBVTT

00:00:01.000 --> 00:00:03.000
  Text with leading/trailing spaces  
"""
	var result = parser.parse_content(content)

	assert_true(result.success, "Parse should succeed")
	assert_eq(result.entries[0].text, "Text with leading/trailing spaces", "Whitespace should be trimmed")

func test_vtt007_parse_zero_timestamp():
	# Test parsing VTT with zero timestamp
	var content = """WEBVTT

00:00:00.000 --> 00:00:02.000
Start from zero
"""
	var result = parser.parse_content(content)

	assert_true(result.success, "Parse should succeed")
	assert_almost_eq(result.entries[0].start_time, 0.0, 0.001, "Start time should be 0.0")

func test_vtt007_parse_large_timestamp():
	# Test parsing VTT with large timestamp values
	var content = """WEBVTT

99:59:59.999 --> 100:00:00.000
Large timestamp
"""
	var result = parser.parse_content(content)

	assert_true(result.success, "Parse should succeed")
	# 99:59:59.999 = 99*3600 + 59*60 + 59.999 = 359999.999 seconds
	assert_almost_eq(result.entries[0].start_time, 359999.999, 0.001, "Large timestamp should be parsed correctly")

func test_vtt007_parse_timestamp_order():
	# Test that entries maintain original order
	var content = """WEBVTT

00:00:10.000 --> 00:00:12.000
Tenth second

00:00:01.000 --> 00:00:03.000
First second

00:00:05.000 --> 00:00:07.000
Fifth second
"""
	var result = parser.parse_content(content)

	assert_true(result.success, "Parse should succeed")
	assert_eq(result.entries.size(), 3, "Should have 3 entries")
	# Entries should maintain original order (not sorted)
	assert_eq(result.entries[0].text, "Tenth second", "First entry should be 'Tenth second'")
	assert_eq(result.entries[1].text, "First second", "Second entry should be 'First second'")
	assert_eq(result.entries[2].text, "Fifth second", "Third entry should be 'Fifth second'")

# ============================================================
# VTT-008: LyricsEntry Class Tests
# ============================================================

func test_vtt008_lyrics_entry_creation():
	# Test creating LyricsEntry directly
	var entry = VTTParser.LyricsEntry.new(1.5, 3.5, "Test Lyrics")

	assert_almost_eq(entry.start_time, 1.5, 0.001, "Start time should be 1.5")
	assert_almost_eq(entry.end_time, 3.5, 0.001, "End time should be 3.5")
	assert_eq(entry.text, "Test Lyrics", "Text should be 'Test Lyrics'")

func test_vtt008_lyrics_entry_default_values():
	# Test LyricsEntry with default values
	var entry = VTTParser.LyricsEntry.new()

	assert_almost_eq(entry.start_time, 0.0, 0.001, "Default start time should be 0.0")
	assert_almost_eq(entry.end_time, 0.0, 0.001, "Default end time should be 0.0")
	assert_eq(entry.text, "", "Default text should be empty")

# ============================================================
# VTT-009: VTTParseResult Class Tests
# ============================================================

func test_vtt009_parse_result_success():
	# Test VTTParseResult for successful parse
	var result = VTTParser.VTTParseResult.new(true, "")

	assert_true(result.success, "Success should be true")
	assert_eq(result.error, "", "Error should be empty")
	assert_eq(result.entries.size(), 0, "Entries should be empty array")

func test_vtt009_parse_result_failure():
	# Test VTTParseResult for failed parse
	var result = VTTParser.VTTParseResult.new(false, "Test error message")

	assert_false(result.success, "Success should be false")
	assert_eq(result.error, "Test error message", "Error message should be stored")

# ============================================================
# VTT-010: Integration Tests
# ============================================================

func test_vtt010_parse_complete_vtt():
	# Test parsing a complete VTT file with all features
	var content = """WEBVTT - Karaoke Song

NOTE This is a sample VTT file for testing

STYLE
::cue {
  background-color: transparent;
}

00:00:00.500 --> 00:00:02.500
First line of lyrics

00:00:03.000 --> 00:00:05.000
Second line
with multiple lines

NOTE This is a mid-file comment

00:00:06.000 --> 00:00:08.500 align:center
Third line with position

00:01:00.000 --> 00:01:05.000
Final line at one minute
"""
	var result = parser.parse_content(content)

	assert_true(result.success, "Parse should succeed for complete VTT")
	assert_eq(result.entries.size(), 4, "Should have 4 entries (comments and styles skipped)")

	# Verify first entry
	assert_almost_eq(result.entries[0].start_time, 0.5, 0.001, "First entry start time")
	assert_eq(result.entries[0].text, "First line of lyrics", "First entry text")

	# Verify second entry (multi-line)
	assert_eq(result.entries[1].text.count("\n"), 1, "Second entry should have one newline")
	assert(result.entries[1].text.contains("multiple lines"), "Second entry should contain 'multiple lines'")

	# Verify last entry
	assert_almost_eq(result.entries[3].start_time, 60.0, 0.001, "Last entry start time should be 60 seconds")

func test_vtt010_parse_real_world_vtt():
	# Test parsing a realistic karaoke VTT file
	var content = """WEBVTT

00:00:05.000 --> 00:00:07.500
君の笑顔が

00:00:08.000 --> 00:00:10.500
見たいから

00:00:11.000 --> 00:00:14.000
走り続ける

00:00:15.000 --> 00:00:18.000
夢を追いかけて
"""
	var result = parser.parse_content(content)

	assert_true(result.success, "Parse should succeed")
	assert_eq(result.entries.size(), 4, "Should have 4 entries")

	# Verify timing sequence
	for i in range(result.entries.size() - 1):
		assert(result.entries[i].end_time <= result.entries[i + 1].start_time,
			"Entries should be in chronological order")