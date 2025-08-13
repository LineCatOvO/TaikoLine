using Godot;

namespace TaikoLine.entity;

public partial class Settings : Resource
{
    public int DisplayWidth;
    public int DisplayHeight;
    public bool FullScreenMode;
    public char KeyLeftKa = 'D';
    public char KeyRightKa = 'K';
    public char KeyLeftDon = 'F';
    public char KeyRightDon = 'J';
}