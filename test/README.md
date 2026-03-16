# TaikoLine Test Suite

This directory contains all tests for the TaikoLine project using the GUT (Godot Unit Testing) framework.

## Directory Structure

```
test/
├── unit/                    # Unit tests (test individual components)
│   ├── parser/             # Parser-related tests
│   ├── game/               # Game logic tests
│   └── autoload/           # Autoload singleton tests
├── integration/             # Integration tests (test component interactions)
│   ├── game_flow/          # Game flow integration tests
│   └── audio_sync/         # Audio synchronization tests
├── fixtures/                # Test data and sample files
│   ├── sample_tja/         # Sample TJA files for testing
│   └── sample_vtt/         # Sample VTT subtitle files
├── mock/                    # Mock objects for testing
├── gut_config.gd           # GUT configuration
└── README.md               # This file
```

## Running Tests

### From Godot Editor

1. Open the project in Godot
2. Go to **Project > Project Settings > Plugins**
3. Ensure "Gut" plugin is enabled
4. Open the GUT panel from the bottom panel
5. Click "Run All" to run all tests

### From Command Line

```bash
# Run all tests
godot --headless -s addons/gut/gut_cmdln.gd

# Run specific test file
godot --headless -s addons/gut/gut_cmdln.gd -gselect=test_tja_parser.gd

# Run tests in a specific directory
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit/parser/
```

## Writing Tests

### Test File Naming

- Test files must start with `test_` prefix
- Test files must have `.gd` extension
- Place test files in appropriate subdirectory

### Basic Test Structure

```gdscript
extends GutTest

var object_to_test = null

func before_all():
    # Runs once before all tests
    pass

func before_each():
    # Runs before each test
    object_to_test = YourClass.new()
    pass

func after_each():
    # Runs after each test
    object_to_test = null
    pass

func after_all():
    # Runs once after all tests
    pass

func test_your_feature():
    # Test code here
    assert_eq(object_to_test.method(), expected_value, "Description")
```

### Common Assertions

```gdscript
assert_true(condition, "message")
assert_false(condition, "message")
assert_eq(actual, expected, "message")
assert_not_eq(actual, expected, "message")
assert_null(value, "message")
assert_not_null(value, "message")
assert_almost_eq(actual, expected, tolerance, "message")
```

## Test Categories

### Unit Tests

Test individual functions and classes in isolation. Use mocks for dependencies.

### Integration Tests

Test how multiple components work together. Use real objects when possible.

## GUT Version

- **Installed Version**: 9.6.0
- **Compatible with**: Godot 4.4+
- **Documentation**: https://gut.readthedocs.io/