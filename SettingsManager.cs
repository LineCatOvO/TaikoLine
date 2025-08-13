using Godot;
using TaikoLine.entity;

namespace TaikoLine;

public partial class SettingsManager : Node
{
    private Resource _settings;

    private void LoadSettings()
    {
        _settings = new Settings();
    }
    
    public Resource GetSettings()
    {
        return _settings;
    }
}