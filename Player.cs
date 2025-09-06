using Godot;
using OpenSlender.States;

namespace OpenSlender
{
	public partial class Player : CharacterBody3D
	{
		[Export] public NodePath CameraPivotPath { get; set; }
		[Export] public NodePath CameraPath { get; set; }

		public const float Speed = 5.0f;
		public const float RunSpeed = 8.0f;
		public const float CrouchSpeed = 2.5f;
		public const float JumpVelocity = 4.5f;
		public const float MouseSensitivity = 0.25f;

		private Node3D _cameraPivot;
		private Camera3D _camera;
		private float _pitch = 0f;

		private bool _isCrouching = false;
		private float _normalCameraHeight = 0.0f;
		private float _crouchCameraHeight = -0.3f;
		private float _cameraTransitionSpeed = 8.0f;

		private CollisionShape3D _collisionShape;
		private CapsuleShape3D _capsuleShape;
		private float _normalCapsuleHeight = 2.0f;
		private float _crouchCapsuleHeight = 2.0f;

		private MeshInstance3D _meshInstance;
		private CapsuleMesh _capsuleMesh;

		public StateMachine StateMachine { get; private set; }

		private DebugStateOverlay _debugOverlay;
		private CanvasLayer _debugCanvasLayer;

		public override void _Ready()
		{
			AddToGroup("player");

			_cameraPivot = GetNode<Node3D>(CameraPivotPath);
			_camera = GetNode<Camera3D>(CameraPath);
			_collisionShape = GetNode<CollisionShape3D>("CollisionShape3D");
			_capsuleShape = (CapsuleShape3D)_collisionShape.Shape;
			_normalCapsuleHeight = _capsuleShape.Height;
			_crouchCapsuleHeight = _normalCapsuleHeight * 0.7f;

			_meshInstance = GetNode<MeshInstance3D>("MeshInstance3D");
			_capsuleMesh = (CapsuleMesh)_meshInstance.Mesh;

			Input.MouseMode = Input.MouseModeEnum.Captured;

			InitializeStateMachine();

			CallDeferred(nameof(InitializeDebugOverlay));
		}

		private void InitializeStateMachine()
		{
			StateMachine = new StateMachine();
			AddChild(StateMachine);

			StateMachine.AddState(new IdleState());
			StateMachine.AddState(new WalkingState());
			StateMachine.AddState(new RunningState());
			StateMachine.AddState(new CrouchingState());
			StateMachine.AddState(new JumpingState());
			StateMachine.AddState(new FallingState());
			StateMachine.AddState(new LandingState());

			StateMachine.SetInitialState(StateNames.Idle, this);

			StateMachine.StateChanged += OnStateChanged;
		}

		private void OnStateChanged(string fromState, string toState)
		{
			_debugOverlay?.ShowStateTransition(fromState, toState);
		}

		private void InitializeDebugOverlay()
		{
			_debugCanvasLayer = new CanvasLayer();
			_debugCanvasLayer.Layer = 100;
			_debugCanvasLayer.Name = "DebugCanvasLayer";

			GetTree().Root.CallDeferred(MethodName.AddChild, _debugCanvasLayer);
			CallDeferred(nameof(CreateDebugOverlayControl));
		}

		private void CreateDebugOverlayControl()
		{
			_debugOverlay = new DebugStateOverlay();

			_debugCanvasLayer.CallDeferred(MethodName.AddChild, _debugOverlay);
			CallDeferred(nameof(SetupDebugOverlayReference));
		}

		private void SetupDebugOverlayReference()
		{
			if (_debugOverlay != null)
			{
				_debugOverlay.SetPlayer(this);
				GD.Print("Debug overlay initialized successfully - Press F3 to toggle");
			}
			else
			{
				GD.PrintErr("Failed to initialize debug overlay");
			}
		}

		public override void _Input(InputEvent @event)
		{
			if (Input.IsActionJustPressed("ui_cancel"))
			{
				Input.MouseMode = Input.MouseModeEnum.Visible;
			}

			if (@event is InputEventKey keyEvent && keyEvent.Pressed && keyEvent.Keycode == Key.F3)
			{
				GD.Print("Player: F3 key pressed");
				if (_debugOverlay != null)
				{
					GD.Print("Player: Calling debug overlay toggle");
					_debugOverlay.ToggleVisibility();
				}
				else
				{
					GD.Print("Player: Debug overlay is null!");
				}
			}

			if (@event is InputEventMouseMotion mouseMotion)
			{
				RotateY(Mathf.DegToRad(-mouseMotion.Relative.X * MouseSensitivity));

				_pitch -= mouseMotion.Relative.Y * MouseSensitivity;
				_pitch = Mathf.Clamp(_pitch, -80f, 80f);
				_cameraPivot.RotationDegrees = new Vector3(_pitch, 0, 0);
			}

			StateMachine?.HandleInput(this, @event);
		}

		public override void _PhysicsProcess(double delta)
		{
			StateMachine?.PhysicsUpdate(this, delta);
		}

		public string GetCurrentStateInfo()
		{
			return $"Current State: {StateMachine?.CurrentStateName ?? "None"}";
		}

		public void ForceStateChange(string stateName)
		{
			StateMachine?.ChangeState(stateName, this);
		}

		public void SetCrouchState(bool crouching)
		{
			_isCrouching = crouching;
			UpdateCollisionShape();
		}

		private void UpdateCollisionShape()
		{
			if (_capsuleShape != null)
			{
				float oldHeight = _capsuleShape.Height;
				float targetHeight = _isCrouching ? _crouchCapsuleHeight : _normalCapsuleHeight;

				float heightDifference = oldHeight - targetHeight;

				if (IsOnFloor() && heightDifference != 0)
				{
					Vector3 currentPos = GlobalPosition;
					currentPos.Y -= heightDifference * 0.5f;
					GlobalPosition = currentPos;
				}

				_capsuleShape.Height = targetHeight;
			}

			if (_capsuleMesh != null)
			{
				float targetHeight = _isCrouching ? _crouchCapsuleHeight : _normalCapsuleHeight;
				_capsuleMesh.Height = targetHeight;
			}
		}

		public override void _Process(double delta)
		{
			StateMachine?.Update(this, delta);
			UpdateCameraHeight(delta);
		}

		private void UpdateCameraHeight(double delta)
		{
			float targetHeight = _isCrouching ? _crouchCameraHeight : _normalCameraHeight;
			float currentY = _cameraPivot.Position.Y;
			float newY = Mathf.MoveToward(currentY, targetHeight, _cameraTransitionSpeed * (float)delta);

			_cameraPivot.Position = new Vector3(_cameraPivot.Position.X, newY, _cameraPivot.Position.Z);
		}

		public override void _ExitTree()
		{
			if (StateMachine != null)
			{
				StateMachine.StateChanged -= OnStateChanged;
			}

			if (_debugCanvasLayer != null)
			{
				_debugCanvasLayer.QueueFree();
			}
		}
	}
}
