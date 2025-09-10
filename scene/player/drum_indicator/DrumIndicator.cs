using Godot;
using System;

public partial class DrumIndicator : ColorRect
{
    [Export] public RichTextLabel ComboText;

    public override void _Ready()
    {
        GameValues gameValues = GetNode<GameValues>("/root/Player/GameValues");
        gameValues.UpdateCombo += OnUpdateCombo;
    }

    private void OnUpdateCombo(int combo)
    {
        if (combo > 4)
        {
            ComboText.SetVisible(true);
            ComboText.SetText($"[font_size=100][color=black]{combo.ToString()}[/color][/font_size]");
        }
        else
        {
            ComboText.SetVisible(false);
        }
    }
}