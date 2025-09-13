using Godot;
using System;

public partial class FeverMeter : ColorRect
{

    public override void _Ready()
    {
        GameValues gameValues = GetNode<GameValues>("/root/Player/GameValues");
        gameValues.UpdateFever += onUpdateFever;
    }

    public void onUpdateFever(int fever)
    {
        float fFever = fever;
        SetColor(new Color(fFever / 100,0,0));
    }
}
