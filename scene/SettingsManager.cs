// SHOULD BE ADDED TO AUTOLOAD IN GODOT

using Godot;
using TaikoLine.entity;

namespace TaikoLine;

public partial class SettingsManager : Node
{
    private static Settings _settings;
    public override void _Ready()
    {
        LoadSettings();
        // Engine.MaxFps = _settings.MaxFps;
        Engine.MaxFps = 60;
    }

    private void LoadSettings()
    {
        _settings = new Settings();
    }
    
    public static Settings GetSettings()
    {
        return _settings;
    }
}