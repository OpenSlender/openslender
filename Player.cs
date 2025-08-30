using Godot;
using System;

public partial class Player : CharacterBody3D
{
	[Export] public NodePath CameraPivotPath { get; set; }
	[Export] public NodePath CameraPath { get; set; }

	public const float Speed = 5.0f;
	public const float JumpVelocity = 4.5f;
	public const float MouseSensitivity = 0.25f;

	private Node3D _cameraPivot;
	private Camera3D _camera;

	private float _pitch = 0f;

	public override void _Ready()
	{
		_cameraPivot = GetNode<Node3D>(CameraPivotPath);
		_camera = GetNode<Camera3D>(CameraPath);
		// Hide and capture the cursor
		Input.MouseMode = Input.MouseModeEnum.Captured;
	}

	public override void _Input(InputEvent @event)
	{
		// Release cursor on pressing Escape
		if (Input.IsActionJustPressed("ui_cancel"))
		{
			Input.MouseMode = Input.MouseModeEnum.Visible;
		}

		if (@event is InputEventMouseMotion mouseMotion)
		{
			// Horizontal rotation (rotates the player body)
			RotateY(Mathf.DegToRad(-mouseMotion.Relative.X * MouseSensitivity));

			// Vertical rotation (rotates the camera pivot)
			_pitch -= mouseMotion.Relative.Y * MouseSensitivity;
			_pitch = Mathf.Clamp(_pitch, -80f, 80f);
			_cameraPivot.RotationDegrees = new Vector3(_pitch, 0, 0);
		}
	}

	public override void _PhysicsProcess(double delta)
	{
		Vector3 velocity = Velocity;

		// Add the gravity.
		if (!IsOnFloor())
		{
			// In C#, you need to get gravity from ProjectSettings differently
			velocity.Y -= (float)ProjectSettings.GetSetting("physics/3d/default_gravity") * (float)delta;
		}

		// Handle Jump.
		if (Input.IsActionJustPressed("ui_accept") && IsOnFloor())
		{
			velocity.Y = JumpVelocity;
		}

		// Get the input direction and handle the movement/deceleration.
		// As good practice, you should replace UI actions with custom gameplay actions.
		Vector2 inputDir = Input.GetVector("ui_left", "ui_right", "ui_up", "ui_down");
		Vector3 direction = (Transform.Basis * new Vector3(inputDir.X, 0, inputDir.Y)).Normalized();
		if (direction != Vector3.Zero)
		{
			velocity.X = direction.X * Speed;
			velocity.Z = direction.Z * Speed;
		}
		else
		{
			velocity.X = Mathf.MoveToward(Velocity.X, 0, Speed);
			velocity.Z = Mathf.MoveToward(Velocity.Z, 0, Speed);
		}

		Velocity = velocity;
		MoveAndSlide();
	}
}
