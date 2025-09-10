using Godot;
using System;

public partial class TrackBackground : Sprite2D
{
    public override void _Draw()
    {
        Rect2 window = GetViewportRect();
    }
}
