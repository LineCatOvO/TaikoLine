using Godot;
using System;

public partial class BackgroundManager : Node2D
{
	public override void _Draw()
	{
		DrawRect(new Rect2(Vector2.Zero, GetViewportRect().Size), new Color(0.7f, 0.7f, 0.7f), true);
	}
}
