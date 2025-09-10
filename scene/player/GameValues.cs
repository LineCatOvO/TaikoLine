using Godot;
using System;

public partial class GameValues : Node
{
    [Signal]
    public delegate void UpdateComboEventHandler(int combo);

    private double _timeElapsed = 0d;
    
    private int _combo;
    public int Combo
    {
        get => _combo;
        set
        {
            _combo = value;
            EmitSignalUpdateCombo(value);
        }
    }

    public override void _Ready()
    {
        
    }

    public override void _Process(double delta)
    {
        _timeElapsed+=delta;
        Combo = (int)_timeElapsed;
    }
}
