using Godot;
using System;

public partial class NoteTrack : Node2D
{
    public override void _Draw()
    {
        //todo Read Settings from SettingsManager to acquire values in need
        Vector2 WindowSize = GetWindow().Size;
        //draw track
        ColorRect aSimpleRectForTrack = new ColorRect();
        aSimpleRectForTrack.SetColor(new Color(.8f, .8f, .8f));
        aSimpleRectForTrack.Size = new Vector2(GetWindow().Size.X, (int)(GetWindow().Size.Y * 0.2f));
        aSimpleRectForTrack.SetAnchor(Side.Left,0f);
        aSimpleRectForTrack.SetPosition(new Vector2(0f,GetWindow().Size.Y*0.3f));
		
        float radius=0.2f;
        Node2D RoundForDrum = new Node2D();
        AddChild(aSimpleRectForTrack);
    }
}
