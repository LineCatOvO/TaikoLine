# GUT Configuration for TaikoLine
# This file configures the GUT (Godot Unit Testing) framework
# Documentation: https://gut.readthedocs.io/

extends Resource

# Directory settings
var directories = {
	"test": {
		"unit": "res://test/unit/",
		"integration": "res://test/integration/"
	},
	"fixtures": "res://test/fixtures/",
	"mock": "res://test/mock/"
}

# Test file patterns
var file_patterns = {
	"unit": "test_*.gd",
	"integration": "test_*.gd"
}

# GUT settings
var config = {
	# Directory to search for tests
	"directories": [
		"res://test/unit/",
		"res://test/integration/"
	],
	
	# File pattern for test files
	"file_pattern": "test_*.gd",
	
	# Should we run tests in subdirectories
	"include_subdirectories": true,
	
	# Pause before teardown (useful for debugging)
	"pause_before_teardown": false,
	
	# Log level (0-3, higher = more verbose)
	"log_level": 2,
	
	# Output format: "console", "junit_xml"
	"output_type": "console",
	
	# Show orphan tracking
	"orphan_tracking": true,
	
	# Show elapsed time for tests
	"show_elapsed_time": true,
	
	# Color output
	"color_output": true,
	
	# Fail on first error
	"fail_on_first_error": false,
	
	# Print summary
	"print_summary": true,
	
	# Export path for JUnit XML (if output_type is "junit_xml")
	"junit_xml_export_path": "res://test/results/junit.xml"
}

# Pre-run hook script (optional)
# This script runs before all tests
var pre_run_script = ""

# Post-run hook script (optional)
# This script runs after all tests
var post_run_script = ""

# Minimum GUT version required
var minimum_gut_version = "9.0.0"