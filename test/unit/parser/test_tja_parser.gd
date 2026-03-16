# TJA Parser Unit Tests
# Tests for the TJA file parser functionality
# Framework: GUT v9.6.0

extends GutTest

const TJAData = preload("res://src/parser/tja_data.gd")
const TJAParser = preload("res://src/parser/tja_parser.gd")

var parser: TJAParser = null

# ============================================================
# Setup and Teardown
# ============================================================

func before_all():
	# Setup that runs once before all tests
	pass

func before_each():
	# Setup that runs before each test
	parser = TJAParser.new()

func after_each():
	# Cleanup that runs after each test
	parser = null

func after_all():
	# Cleanup that runs once after all tests
	pass

# ============================================================
# TJA-001: Parse Basic Metadata (TITLE, BPM, WAVE, OFFSET)
# ============================================================

func test_tja001_parse_basic_metadata():
	# Test parsing basic metadata fields
	var content = """TITLE:Test Song
BPM:150.5
WAVE:test.ogg
OFFSET:-1.25

COURSE:Oni
LEVEL:5
#START
1000,
#END
"""
	var result = parser.parse_content(content)
	
	assert_true(result.success, "Parse should succeed")
	assert_not_null(result.song, "Song should not be null")
	assert_eq(result.song.title, "Test Song", "Title should be parsed correctly")
	assert_almost_eq(result.song.bpm, 150.5, 0.01, "BPM should be parsed correctly")
	assert_eq(result.song.wave, "test.ogg", "WAVE should be parsed correctly")
	assert_almost_eq(result.song.offset, -1.25, 0.01, "OFFSET should be parsed correctly")

func test_tja001_parse_subtitle():
	# Test parsing subtitle
	var content = """TITLE:Test Song
SUBTITLE:--Test Subtitle
BPM:120

COURSE:Oni
LEVEL:5
#START
1000,
#END
"""
	var result = parser.parse_content(content)
	
	assert_true(result.success, "Parse should succeed")
	assert_eq(result.song.subtitle, "--Test Subtitle", "Subtitle should be parsed correctly")

func test_tja001_parse_optional_metadata():
	# Test parsing optional metadata fields
	var content = """TITLE:Test Song
BPM:120
TITLEEN:Test Song English
GENRE:Pop
MAKER:Test Author
LYRICS:lyrics.vtt
DEMOSTART:5.0
SCOREMODE:1

COURSE:Oni
LEVEL:5
#START
1000,
#END
"""
	var result = parser.parse_content(content)
	
	assert_true(result.success, "Parse should succeed")
	assert_eq(result.song.title_en, "Test Song English", "TITLEEN should be parsed")
	assert_eq(result.song.genre, "Pop", "GENRE should be parsed")
	assert_eq(result.song.maker, "Test Author", "MAKER should be parsed")
	assert_eq(result.song.lyrics, "lyrics.vtt", "LYRICS should be parsed")
	assert_almost_eq(result.song.demo_start, 5.0, 0.01, "DEMOSTART should be parsed")
	assert_eq(result.song.score_mode, 1, "SCOREMODE should be parsed")

# ============================================================
# TJA-002: Parse Course Definition (COURSE, LEVEL, BALLOON, SCOREINIT, SCOREDIFF)
# ============================================================

func test_tja002_parse_course_definition():
	# Test parsing course definition fields
	var content = """TITLE:Test Song
BPM:120

COURSE:Oni
LEVEL:8
BALLOON:5,10,15
SCOREINIT:1000
SCOREDIFF:120
#START
1000,
#END
"""
	var result = parser.parse_content(content)
	
	assert_true(result.success, "Parse should succeed")
	assert_not_null(result.song, "Song should not be null")
	
	var course = result.song.get_course(TJAData.CourseType.ONI)
	assert_not_null(course, "Course should not be null")
	assert_eq(course.level, 8, "LEVEL should be parsed correctly")
	assert_eq(course.balloons.size(), 3, "BALLOON should have 3 values")
	assert_eq(course.balloons[0], 5, "First BALLOON value should be 5")
	assert_eq(course.balloons[1], 10, "Second BALLOON value should be 10")
	assert_eq(course.balloons[2], 15, "Third BALLOON value should be 15")
	assert_eq(course.score_init, 1000, "SCOREINIT should be parsed correctly")
	assert_eq(course.score_diff, 120, "SCOREDIFF should be parsed correctly")

func test_tja002_parse_course_types():
	# Test parsing different course types
	var course_types = {
		"Easy": TJAData.CourseType.EASY,
		"Normal": TJAData.CourseType.NORMAL,
		"Hard": TJAData.CourseType.HARD,
		"Oni": TJAData.CourseType.ONI,
		"Edit": TJAData.CourseType.EDIT,
		"Tower": TJAData.CourseType.TOWER,
		"Dan": TJAData.CourseType.DAN
	}
	
	for course_name in course_types:
		var content = """TITLE:Test Song
BPM:120

COURSE:%s
LEVEL:5
#START
1000,
#END
""" % course_name
		var result = parser.parse_content(content)
		assert_true(result.success, "Parse should succeed for course type: " + course_name)
		
		var expected_type = course_types[course_name]
		var course = result.song.get_course(expected_type)
		assert_not_null(course, "Course should exist for type: " + course_name)
		assert_eq(course.course_type, expected_type, "Course type should match for: " + course_name)

func test_tja002_parse_style():
	# Test parsing STYLE field
	var content = """TITLE:Test Song
BPM:120

COURSE:Oni
LEVEL:5
STYLE:Double
#START
1000,
#END
"""
	var result = parser.parse_content(content)
	
	assert_true(result.success, "Parse should succeed")
	var course = result.song.get_course(TJAData.CourseType.ONI)
	assert_eq(course.style, "Double", "STYLE should be parsed correctly")

# ============================================================
# TJA-003: Parse Basic Notes (0-4 note codes)
# ============================================================

func test_tja003_parse_basic_notes():
	# Test parsing basic note codes 0-4
	var content = """TITLE:Test Song
BPM:120

COURSE:Oni
LEVEL:5
#START
01234,
#END
"""
	var result = parser.parse_content(content)
	
	assert_true(result.success, "Parse should succeed")
	
	var course = result.song.get_course(TJAData.CourseType.ONI)
	assert_not_null(course, "Course should not be null")
	assert_eq(course.measures.size(), 1, "Should have 1 measure")
	
	var measure = course.measures[0]
	assert_eq(measure.notes.size(), 5, "Should have 5 notes")
	
	# Check note types
	assert_eq(measure.notes[0].note_type, TJAData.NoteType.NONE, "Note 0 should be NONE")
	assert_eq(measure.notes[1].note_type, TJAData.NoteType.DON, "Note 1 should be DON")
	assert_eq(measure.notes[2].note_type, TJAData.NoteType.KA, "Note 2 should be KA")
	assert_eq(measure.notes[3].note_type, TJAData.NoteType.DON_BIG, "Note 3 should be DON_BIG")
	assert_eq(measure.notes[4].note_type, TJAData.NoteType.KA_BIG, "Note 4 should be KA_BIG")

func test_tja003_parse_note_positions():
	# Test that note positions are calculated correctly
	var content = """TITLE:Test Song
BPM:120

COURSE:Oni
LEVEL:5
#START
10001,
#END
"""
	var result = parser.parse_content(content)
	
	assert_true(result.success, "Parse should succeed")
	
	var course = result.song.get_course(TJAData.CourseType.ONI)
	var measure = course.measures[0]
	
	# Check positions (0-based index / total notes)
	assert_almost_eq(measure.notes[0].position, 0.0, 0.01, "First note position should be 0.0")
	assert_almost_eq(measure.notes[1].position, 0.2, 0.01, "Second note position should be 0.2")
	assert_almost_eq(measure.notes[2].position, 0.8, 0.01, "Third note position should be 0.8")

func test_tja003_parse_multiple_measures():
	# Test parsing multiple measures
	var content = """TITLE:Test Song
BPM:120

COURSE:Oni
LEVEL:5
#START
1000,
2000,
3000,
#END
"""
	var result = parser.parse_content(content)
	
	assert_true(result.success, "Parse should succeed")
	
	var course = result.song.get_course(TJAData.CourseType.ONI)
	assert_eq(course.measures.size(), 3, "Should have 3 measures")
	
	# Check measure indices
	assert_eq(course.measures[0].index, 0, "First measure index should be 0")
	assert_eq(course.measures[1].index, 1, "Second measure index should be 1")
	assert_eq(course.measures[2].index, 2, "Third measure index should be 2")

# ============================================================
# TJA-004: Parse Renda Notes (5-9 note codes)
# ============================================================

func test_tja004_parse_renda_notes():
	# Test parsing renda (roll) note codes 5-9
	var content = """TITLE:Test Song
BPM:120

COURSE:Oni
LEVEL:5
BALLOON:10
#START
56789,
#END
"""
	var result = parser.parse_content(content)
	
	assert_true(result.success, "Parse should succeed")
	
	var course = result.song.get_course(TJAData.CourseType.ONI)
	var measure = course.measures[0]
	
	# Check note types
	assert_eq(measure.notes[0].note_type, TJAData.NoteType.RENDA, "Note 5 should be RENDA")
	assert_eq(measure.notes[1].note_type, TJAData.NoteType.RENDA_BIG, "Note 6 should be RENDA_BIG")
	assert_eq(measure.notes[2].note_type, TJAData.NoteType.BALLOON, "Note 7 should be BALLOON")
	assert_eq(measure.notes[3].note_type, TJAData.NoteType.END, "Note 8 should be END")
	assert_eq(measure.notes[4].note_type, TJAData.NoteType.KUSUDAMA, "Note 9 should be KUSUDAMA")

func test_tja004_parse_balloon_hits():
	# Test that balloon hits are assigned correctly
	var content = """TITLE:Test Song
BPM:120

COURSE:Oni
LEVEL:5
BALLOON:5,10
#START
78,
78,
#END
"""
	var result = parser.parse_content(content)
	
	assert_true(result.success, "Parse should succeed")
	
	var course = result.song.get_course(TJAData.CourseType.ONI)
	
	# First measure has balloon with 5 hits
	assert_eq(course.measures[0].notes[0].balloon_hits, 5, "First balloon should have 5 hits")
	
	# Second measure has balloon with 10 hits
	assert_eq(course.measures[1].notes[0].balloon_hits, 10, "Second balloon should have 10 hits")

func test_tja004_parse_extended_notes():
	# Test parsing extended note codes (A-G)
	var content = """TITLE:Test Song
BPM:120

COURSE:Oni
LEVEL:5
#START
ABCFG,
#END
"""
	var result = parser.parse_content(content)
	
	assert_true(result.success, "Parse should succeed")
	
	var course = result.song.get_course(TJAData.CourseType.ONI)
	var measure = course.measures[0]
	
	# Check note types
	assert_eq(measure.notes[0].note_type, TJAData.NoteType.DON_DOUBLE, "Note A should be DON_DOUBLE")
	assert_eq(measure.notes[1].note_type, TJAData.NoteType.KA_DOUBLE, "Note B should be KA_DOUBLE")
	assert_eq(measure.notes[2].note_type, TJAData.NoteType.BOMB, "Note C should be BOMB")
	assert_eq(measure.notes[3].note_type, TJAData.NoteType.ADLIB, "Note F should be ADLIB")
	assert_eq(measure.notes[4].note_type, TJAData.NoteType.SWAP, "Note G should be SWAP")

# ============================================================
# TJA-006: Parse BPM Change Command
# ============================================================

func test_tja006_parse_bpm_change():
	# Test parsing #BPMCHANGE command
	var content = """TITLE:Test Song
BPM:120

COURSE:Oni
LEVEL:5
#START
1000,
#BPMCHANGE 180
1000,
#END
"""
	var result = parser.parse_content(content)
	
	assert_true(result.success, "Parse should succeed")
	
	var course = result.song.get_course(TJAData.CourseType.ONI)
	assert_eq(course.measures.size(), 2, "Should have 2 measures")
	
	# First measure should have original BPM
	assert_almost_eq(course.measures[0].bpm, 120.0, 0.01, "First measure BPM should be 120")
	
	# Second measure should have changed BPM
	assert_almost_eq(course.measures[1].bpm, 180.0, 0.01, "Second measure BPM should be 180")

func test_tja006_parse_multiple_bpm_changes():
	# Test multiple BPM changes
	var content = """TITLE:Test Song
BPM:120

COURSE:Oni
LEVEL:5
#START
1000,
#BPMCHANGE 150
1000,
#BPMCHANGE 100
1000,
#BPMCHANGE 200
1000,
#END
"""
	var result = parser.parse_content(content)
	
	assert_true(result.success, "Parse should succeed")
	
	var course = result.song.get_course(TJAData.CourseType.ONI)
	assert_eq(course.measures.size(), 4, "Should have 4 measures")
	
	assert_almost_eq(course.measures[0].bpm, 120.0, 0.01, "Measure 0 BPM should be 120")
	assert_almost_eq(course.measures[1].bpm, 150.0, 0.01, "Measure 1 BPM should be 150")
	assert_almost_eq(course.measures[2].bpm, 100.0, 0.01, "Measure 2 BPM should be 100")
	assert_almost_eq(course.measures[3].bpm, 200.0, 0.01, "Measure 3 BPM should be 200")

func test_tja006_parse_bpm_change_decimal():
	# Test BPM change with decimal value
	var content = """TITLE:Test Song
BPM:120

COURSE:Oni
LEVEL:5
#START
1000,
#BPMCHANGE 125.5
1000,
#END
"""
	var result = parser.parse_content(content)
	
	assert_true(result.success, "Parse should succeed")
	
	var course = result.song.get_course(TJAData.CourseType.ONI)
	assert_almost_eq(course.measures[1].bpm, 125.5, 0.01, "BPM should be 125.5")

# ============================================================
# TJA-012: Handle Empty Lines and Comments
# ============================================================

func test_tja012_skip_empty_lines():
	# Test that empty lines are skipped
	var content = """TITLE:Test Song
BPM:120

COURSE:Oni
LEVEL:5

#START

1000,

#END
"""
	var result = parser.parse_content(content)
	
	assert_true(result.success, "Parse should succeed")
	
	var course = result.song.get_course(TJAData.CourseType.ONI)
	assert_eq(course.measures.size(), 1, "Should have 1 measure (empty lines skipped)")

func test_tja012_skip_comments():
	# Test that comments are skipped
	var content = """TITLE:Test Song
BPM:120
// This is a comment
COURSE:Oni
LEVEL:5
// Another comment
#START
// Comment before notes
1000,
// Comment after notes
#END
"""
	var result = parser.parse_content(content)
	
	assert_true(result.success, "Parse should succeed")
	
	var course = result.song.get_course(TJAData.CourseType.ONI)
	assert_eq(course.measures.size(), 1, "Should have 1 measure (comments skipped)")

func test_tja012_skip_whitespace():
	# Test that leading/trailing whitespace is handled
	var content = """  TITLE:Test Song  
BPM:120

  COURSE:Oni  
LEVEL:5
#START
  1000,  
#END
"""
	var result = parser.parse_content(content)
	
	assert_true(result.success, "Parse should succeed")
	assert_eq(result.song.title, "Test Song", "Title should be trimmed")

# ============================================================
# TJA-014: Error Handling - File Not Found
# ============================================================

func test_tja014_error_file_not_found():
	# Test error handling for non-existent file
	var result = parser.parse_file("res://test/fixtures/sample_tja/nonexistent.tja")
	
	assert_false(result.success, "Parse should fail for non-existent file")
	assert_eq(result.error, "文件不存在: res://test/fixtures/sample_tja/nonexistent.tja", "Error message should indicate file not found")
	assert_eq(result.error_line, 0, "Error line should be 0 for file not found")

func test_tja014_error_empty_file():
	# Test error handling for empty file
	var content = ""
	var result = parser.parse_content(content)
	
	assert_false(result.success, "Parse should fail for empty content")
	assert_not_null(result.error, "Error message should be present")

# ============================================================
# TJA-015: Error Handling - Missing Title
# ============================================================

func test_tja015_error_missing_title():
	# Test error handling for missing title
	var content = """BPM:120

COURSE:Oni
LEVEL:5
#START
1000,
#END
"""
	var result = parser.parse_content(content)
	
	assert_false(result.success, "Parse should fail for missing title")
	assert_eq(result.error, "缺少歌曲标题", "Error message should indicate missing title")

# ============================================================
# TJA-016: Error Handling - Invalid BPM
# ============================================================

func test_tja016_error_invalid_bpm_zero():
	# Test error handling for zero BPM
	var content = """TITLE:Test Song
BPM:0

COURSE:Oni
LEVEL:5
#START
1000,
#END
"""
	var result = parser.parse_content(content)
	
	assert_false(result.success, "Parse should fail for zero BPM")
	assert_eq(result.error, "无效的BPM值", "Error message should indicate invalid BPM")

func test_tja016_error_invalid_bpm_negative():
	# Test error handling for negative BPM
	var content = """TITLE:Test Song
BPM:-120

COURSE:Oni
LEVEL:5
#START
1000,
#END
"""
	var result = parser.parse_content(content)
	
	assert_false(result.success, "Parse should fail for negative BPM")
	assert_eq(result.error, "无效的BPM值", "Error message should indicate invalid BPM")

func test_tja016_error_no_courses():
	# Test error handling for no course definitions
	var content = """TITLE:Test Song
BPM:120
"""
	var result = parser.parse_content(content)
	
	assert_false(result.success, "Parse should fail for no courses")
	assert_eq(result.error, "没有定义任何难度", "Error message should indicate no courses")

# ============================================================
# TJA-018: Parse Multiple Courses
# ============================================================

func test_tja018_parse_multiple_courses():
	# Test parsing multiple course definitions
	var content = """TITLE:Test Song
BPM:120

COURSE:Easy
LEVEL:3
#START
1000,
#END

COURSE:Normal
LEVEL:5
#START
1100,
#END

COURSE:Hard
LEVEL:7
#START
1110,
#END

COURSE:Oni
LEVEL:9
#START
1111,
#END
"""
	var result = parser.parse_content(content)
	
	assert_true(result.success, "Parse should succeed")
	
	# Check all courses exist
	assert_not_null(result.song.get_course(TJAData.CourseType.EASY), "Easy course should exist")
	assert_not_null(result.song.get_course(TJAData.CourseType.NORMAL), "Normal course should exist")
	assert_not_null(result.song.get_course(TJAData.CourseType.HARD), "Hard course should exist")
	assert_not_null(result.song.get_course(TJAData.CourseType.ONI), "Oni course should exist")
	
	# Check levels
	assert_eq(result.song.get_course(TJAData.CourseType.EASY).level, 3, "Easy level should be 3")
	assert_eq(result.song.get_course(TJAData.CourseType.NORMAL).level, 5, "Normal level should be 5")
	assert_eq(result.song.get_course(TJAData.CourseType.HARD).level, 7, "Hard level should be 7")
	assert_eq(result.song.get_course(TJAData.CourseType.ONI).level, 9, "Oni level should be 9")
	
	# Check note counts
	assert_eq(result.song.get_course(TJAData.CourseType.EASY).measures[0].notes.size(), 1, "Easy should have 1 note")
	assert_eq(result.song.get_course(TJAData.CourseType.NORMAL).measures[0].notes.size(), 2, "Normal should have 2 notes")
	assert_eq(result.song.get_course(TJAData.CourseType.HARD).measures[0].notes.size(), 3, "Hard should have 3 notes")
	assert_eq(result.song.get_course(TJAData.CourseType.ONI).measures[0].notes.size(), 4, "Oni should have 4 notes")

func test_tja018_parse_course_override():
	# Test that later course definition overrides earlier one
	var content = """TITLE:Test Song
BPM:120

COURSE:Oni
LEVEL:5
#START
1000,
#END

COURSE:Oni
LEVEL:9
#START
1111,
#END
"""
	var result = parser.parse_content(content)
	
	assert_true(result.success, "Parse should succeed")
	
	var course = result.song.get_course(TJAData.CourseType.ONI)
	assert_eq(course.level, 9, "Level should be from second definition")
	assert_eq(course.measures[0].notes.size(), 4, "Notes should be from second definition")

# ============================================================
# Additional Tests: Other Commands
# ============================================================

func test_parse_scroll_command():
	# Test parsing #SCROLL command
	var content = """TITLE:Test Song
BPM:120

COURSE:Oni
LEVEL:5
#START
1000,
#SCROLL 2.0
1000,
#END
"""
	var result = parser.parse_content(content)
	
	assert_true(result.success, "Parse should succeed")
	
	var course = result.song.get_course(TJAData.CourseType.ONI)
	assert_almost_eq(course.measures[0].scroll, 1.0, 0.01, "First measure scroll should be 1.0")
	assert_almost_eq(course.measures[1].scroll, 2.0, 0.01, "Second measure scroll should be 2.0")

func test_parse_gogo_command():
	# Test parsing #GOGOSTART and #GOGOEND commands
	var content = """TITLE:Test Song
BPM:120

COURSE:Oni
LEVEL:5
#START
1000,
#GOGOSTART
1000,
#GOGOEND
1000,
#END
"""
	var result = parser.parse_content(content)
	
	assert_true(result.success, "Parse should succeed")
	
	var course = result.song.get_course(TJAData.CourseType.ONI)
	assert_false(course.measures[0].is_gogo, "First measure should not be gogo")
	assert_true(course.measures[1].is_gogo, "Second measure should be gogo")
	assert_false(course.measures[2].is_gogo, "Third measure should not be gogo")

func test_parse_measure_command():
	# Test parsing #MEASURE command
	var content = """TITLE:Test Song
BPM:120

COURSE:Oni
LEVEL:5
#START
1000,
#MEASURE 3/4
1000,
#END
"""
	var result = parser.parse_content(content)
	
	assert_true(result.success, "Parse should succeed")
	
	var course = result.song.get_course(TJAData.CourseType.ONI)
	assert_eq(course.measures[0].time_signature, Vector2(4.0, 4.0), "First measure should be 4/4")
	assert_eq(course.measures[1].time_signature, Vector2(3.0, 4.0), "Second measure should be 3/4")

func test_parse_barline_command():
	# Test parsing #BARLINEON and #BARLINEOFF commands
	var content = """TITLE:Test Song
BPM:120

COURSE:Oni
LEVEL:5
#START
1000,
#BARLINEOFF
1000,
#BARLINEON
1000,
#END
"""
	var result = parser.parse_content(content)
	
	assert_true(result.success, "Parse should succeed")
	
	var course = result.song.get_course(TJAData.CourseType.ONI)
	assert_true(course.measures[0].show_barline, "First measure should show barline")
	assert_false(course.measures[1].show_barline, "Second measure should not show barline")
	assert_true(course.measures[2].show_barline, "Third measure should show barline")

# ============================================================
# Fixture File Tests
# ============================================================

func test_parse_basic_fixture():
	# Test parsing the basic.tja fixture file
	var result = parser.parse_file("res://test/fixtures/sample_tja/basic.tja")
	
	assert_true(result.success, "Parse should succeed for basic.tja")
	assert_eq(result.song.title, "Test Song", "Title should be Test Song")
	assert_eq(result.song.subtitle, "--Test Subtitle", "Subtitle should be parsed")
	assert_almost_eq(result.song.bpm, 120.0, 0.01, "BPM should be 120")
	assert_eq(result.song.wave, "test.ogg", "WAVE should be test.ogg")
	
	var course = result.song.get_course(TJAData.CourseType.ONI)
	assert_not_null(course, "Oni course should exist")
	assert_eq(course.measures.size(), 4, "Should have 4 measures")

func test_parse_branching_fixture():
	# Test parsing the branching.tja fixture file
	var result = parser.parse_file("res://test/fixtures/sample_tja/branching.tja")
	
	assert_true(result.success, "Parse should succeed for branching.tja")
	assert_eq(result.song.title, "Branch Test Song", "Title should be Branch Test Song")
	
	var course = result.song.get_course(TJAData.CourseType.ONI)
	assert_not_null(course, "Oni course should exist")
	assert_true(course.has_branch, "Course should have branches")

# ============================================================
# TJAData Helper Function Tests
# ============================================================

func test_char_to_note_type():
	# Test TJAData.char_to_note_type static function
	assert_eq(TJAData.char_to_note_type("0"), TJAData.NoteType.NONE, "0 should be NONE")
	assert_eq(TJAData.char_to_note_type("1"), TJAData.NoteType.DON, "1 should be DON")
	assert_eq(TJAData.char_to_note_type("2"), TJAData.NoteType.KA, "2 should be KA")
	assert_eq(TJAData.char_to_note_type("3"), TJAData.NoteType.DON_BIG, "3 should be DON_BIG")
	assert_eq(TJAData.char_to_note_type("4"), TJAData.NoteType.KA_BIG, "4 should be KA_BIG")
	assert_eq(TJAData.char_to_note_type("5"), TJAData.NoteType.RENDA, "5 should be RENDA")
	assert_eq(TJAData.char_to_note_type("6"), TJAData.NoteType.RENDA_BIG, "6 should be RENDA_BIG")
	assert_eq(TJAData.char_to_note_type("7"), TJAData.NoteType.BALLOON, "7 should be BALLOON")
	assert_eq(TJAData.char_to_note_type("8"), TJAData.NoteType.END, "8 should be END")
	assert_eq(TJAData.char_to_note_type("9"), TJAData.NoteType.KUSUDAMA, "9 should be KUSUDAMA")
	assert_eq(TJAData.char_to_note_type("A"), TJAData.NoteType.DON_DOUBLE, "A should be DON_DOUBLE")
	assert_eq(TJAData.char_to_note_type("a"), TJAData.NoteType.DON_DOUBLE, "a should be DON_DOUBLE")
	assert_eq(TJAData.char_to_note_type("B"), TJAData.NoteType.KA_DOUBLE, "B should be KA_DOUBLE")
	assert_eq(TJAData.char_to_note_type("C"), TJAData.NoteType.BOMB, "C should be BOMB")
	assert_eq(TJAData.char_to_note_type("F"), TJAData.NoteType.ADLIB, "F should be ADLIB")
	assert_eq(TJAData.char_to_note_type("G"), TJAData.NoteType.SWAP, "G should be SWAP")
	assert_eq(TJAData.char_to_note_type("X"), TJAData.NoteType.NONE, "Unknown char should be NONE")

func test_string_to_course_type():
	# Test TJAData.string_to_course_type static function
	assert_eq(TJAData.string_to_course_type("Easy"), TJAData.CourseType.EASY, "Easy should be EASY")
	assert_eq(TJAData.string_to_course_type("Normal"), TJAData.CourseType.NORMAL, "Normal should be NORMAL")
	assert_eq(TJAData.string_to_course_type("Hard"), TJAData.CourseType.HARD, "Hard should be HARD")
	assert_eq(TJAData.string_to_course_type("Oni"), TJAData.CourseType.ONI, "Oni should be ONI")
	assert_eq(TJAData.string_to_course_type("Edit"), TJAData.CourseType.EDIT, "Edit should be EDIT")
	assert_eq(TJAData.string_to_course_type("Tower"), TJAData.CourseType.TOWER, "Tower should be TOWER")
	assert_eq(TJAData.string_to_course_type("Dan"), TJAData.CourseType.DAN, "Dan should be DAN")
	assert_eq(TJAData.string_to_course_type("Unknown"), TJAData.CourseType.ONI, "Unknown should default to ONI")

func test_course_type_to_string():
	# Test TJAData.course_type_to_string static function
	assert_eq(TJAData.course_type_to_string(TJAData.CourseType.EASY), "Easy", "EASY should be Easy")
	assert_eq(TJAData.course_type_to_string(TJAData.CourseType.NORMAL), "Normal", "NORMAL should be Normal")
	assert_eq(TJAData.course_type_to_string(TJAData.CourseType.HARD), "Hard", "HARD should be Hard")
	assert_eq(TJAData.course_type_to_string(TJAData.CourseType.ONI), "Oni", "ONI should be Oni")
	assert_eq(TJAData.course_type_to_string(TJAData.CourseType.EDIT), "Edit", "EDIT should be Edit")
	assert_eq(TJAData.course_type_to_string(TJAData.CourseType.TOWER), "Tower", "TOWER should be Tower")
	assert_eq(TJAData.course_type_to_string(TJAData.CourseType.DAN), "Dan", "DAN should be Dan")

func test_note_is_hittable():
	# Test TJANote.is_hittable function
	var note = TJAData.TJANote.new()
	
	note.note_type = TJAData.NoteType.DON
	assert_true(note.is_hittable(), "DON should be hittable")
	
	note.note_type = TJAData.NoteType.KA
	assert_true(note.is_hittable(), "KA should be hittable")
	
	note.note_type = TJAData.NoteType.NONE
	assert_false(note.is_hittable(), "NONE should not be hittable")
	
	note.note_type = TJAData.NoteType.END
	assert_false(note.is_hittable(), "END should not be hittable")

func test_note_is_renda():
	# Test TJANote.is_renda function
	var note = TJAData.TJANote.new()
	
	note.note_type = TJAData.NoteType.RENDA
	assert_true(note.is_renda(), "RENDA should be renda type")
	
	note.note_type = TJAData.NoteType.BALLOON
	assert_true(note.is_renda(), "BALLOON should be renda type")
	
	note.note_type = TJAData.NoteType.DON
	assert_false(note.is_renda(), "DON should not be renda type")

func test_note_is_big():
	# Test TJANote.is_big function
	var note = TJAData.TJANote.new()
	
	note.note_type = TJAData.NoteType.DON_BIG
	assert_true(note.is_big(), "DON_BIG should be big")
	
	note.note_type = TJAData.NoteType.KA_BIG
	assert_true(note.is_big(), "KA_BIG should be big")
	
	note.note_type = TJAData.NoteType.DON
	assert_false(note.is_big(), "DON should not be big")

func test_measure_get_duration():
	# Test TJAMeasure.get_duration function
	var measure = TJAData.TJAMeasure.new()
	measure.bpm = 120.0
	measure.time_signature = Vector2(4.0, 4.0)
	
	var duration = measure.get_duration()
	assert_almost_eq(duration, 2.0, 0.01, "4/4 at 120 BPM should be 2 seconds")
	
	measure.time_signature = Vector2(3.0, 4.0)
	duration = measure.get_duration()
	assert_almost_eq(duration, 1.5, 0.01, "3/4 at 120 BPM should be 1.5 seconds")

func test_course_get_total_notes():
	# Test TJACourse.get_total_notes function
	var course = TJAData.TJACourse.new()
	
	var measure1 = TJAData.TJAMeasure.new()
	measure1.add_note(TJAData.TJANote.new(TJAData.NoteType.DON))
	measure1.add_note(TJAData.TJANote.new(TJAData.NoteType.KA))
	measure1.add_note(TJAData.TJANote.new(TJAData.NoteType.NONE))
	
	var measure2 = TJAData.TJAMeasure.new()
	measure2.add_note(TJAData.TJANote.new(TJAData.NoteType.DON_BIG))
	measure2.add_note(TJAData.TJANote.new(TJAData.NoteType.END))
	
	course.add_measure(measure1)
	course.add_measure(measure2)
	
	assert_eq(course.get_total_notes(), 3, "Should count 3 hittable notes")

func test_song_get_display_name():
	# Test TJASong.get_display_name function
	var song = TJAData.TJASong.new()
	song.title = "Test Song"
	song.title_en = "Test Song English"
	
	assert_eq(song.get_display_name(), "Test Song English", "Should return English title")
	
	song.title_en = ""
	assert_eq(song.get_display_name(), "Test Song", "Should return original title when English is empty")