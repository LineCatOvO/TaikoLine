using Godot;
using TaikoLine.entity;

namespace TaikoLine;

public partial class SettingsManager : Node
{
    private static Settings _settings;
    public override void _Ready()
    {
        LoadSettings();
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