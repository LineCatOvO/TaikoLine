using Godot;
using System;
using TaikoLine;
using TaikoLine.entity;

public partial class InputHandler : Node
{
    private Settings _settings;
    public override void _Ready()
    {
        _settings = SettingsManager.GetSettings();
    }

    public override void _Input(InputEvent @event)
    {
        //dfjk esc
        if (@event is InputEventKey keyEvent && keyEvent.Pressed && !keyEvent.Echo)
        {
            if (keyEvent.Keycode == Key.D)
            {
                // do handle
            }
            else if (keyEvent.Keycode == Key.F)
            {
                // do handle
            }
            else if (keyEvent.Keycode == Key.J)
            {
                // do handle
            }
            else if (keyEvent.Keycode == Key.K)
            {
                // do handle
            }
            else if (keyEvent.Keycode == Key.Escape)
            {
                // do handle
            }
        }
    }
}
