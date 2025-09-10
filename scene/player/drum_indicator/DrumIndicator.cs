using Godot;
using System;

public partial class DrumIndicator : ColorRect
{
	public override void _Draw()
	{
		Vector2 size = GetWindow().Size;
		var r = size.Y*0.2f/2;
		var topMargin = size.Y*0.3f+r;
		var leftMargin = size.Y * 0.1f+r;
		DrawCircle(new Vector2(leftMargin,topMargin),r,new Color(1f,0f,0f));
	}
}
