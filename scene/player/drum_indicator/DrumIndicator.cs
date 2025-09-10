using Godot;
using System;

public partial class DrumIndicator : Node2D
{
    public override void _Draw()
    {
        Vector2 size = GetWindow().Size;
        DrawCircle(new Vector2(size.Y*0.1f,size.Y*0.3f),size.Y*0.2f/2,new Color(1f,0f,0f));
    }
}
