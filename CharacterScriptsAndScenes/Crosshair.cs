using Godot;
using System;

public partial class Crosshair : Control
{
	[Export] public Color Color = Colors.White;
	[Export] public float Thickness = 2.0f;
	[Export] public float BorderThickness = 1.0f;
	[Export] public Color BorderColor = Colors.Black;

	public override void _Ready()
	{
		MouseFilter = MouseFilterEnum.Ignore;
		QueueRedraw();
	}

	public override void _Draw()
	{
		Vector2 Center = GetRect().Size / 2f;
		DrawCircle(Center, Thickness + BorderThickness, BorderColor);
		DrawCircle(Center, Thickness * 0.75f, Color);
	}

}
