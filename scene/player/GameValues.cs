using Godot;
using System;

public partial class GameValues : Node
{
    [Signal]
    public delegate void UpdateComboEventHandler(int combo);
    [Signal]
    public delegate void UpdateFeverEventHandler(int fever);
    
    private double _timeElapsed = 0d;
    
    private int _combo, _fever;
    public int Combo
    {
        get => _combo;
        set
        {
            if(_combo==value) return;
            _combo = value;
            EmitSignalUpdateCombo(value);
        }
    }
    public int Fever
    {
        get => _fever;
        set
        {
            if(_fever==value) return;
            if (value < 0 || value > 100)
            {
                GD.PushError(new ArgumentOutOfRangeException(nameof(Fever),value,"Fever(int) in game can only be in range of 0~100"));
            }
            _fever = value;
            EmitSignalUpdateFever(value);
        }
    }

    public override void _Ready()
    {
        
    }

    public override void _Process(double delta)
    {
        _timeElapsed+=delta;
        Combo = (int)_timeElapsed;
        Fever = (int)_timeElapsed;
        
    }
}
