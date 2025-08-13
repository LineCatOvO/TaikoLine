using Godot;
using System;

public partial class TrackBackground : Sprite2D
{
    public override void _Draw()
    {
        Rect2 window = GetViewportRect();
        DrawRect(new Rect2(new Vector2(0f,window.Size.y*ContentManager), GetViewportRect().Size));
    }
}
