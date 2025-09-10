using Godot;
using System;

public partial class ContentManager :Control
{
	public static readonly Color DefaultDonColor = new Color(1f, 0f, 0f);
	public static readonly Color DefaultKaColor = new Color(0f, 0f, 1f);
	public static readonly Color DefaultTrackColor = new Color(0.1f, 0.1f, 0.1f);
	public static readonly Color DefaultJudgementZoneColor = new Color(0.8f, 0.8f, 0.8f);


	public static float _smallNoteDimensionPercent = 0.08f;
	public static float _largeNoteDimensionPercent = 0.16f;
	public static float _trackMarginTopPercent = 0.2f;
	public static float _trackWidthPercent = 0.2f;



	public override void _Ready()
	{
		
	}

	public void InitContentLayout()
	{
		
	}

}
