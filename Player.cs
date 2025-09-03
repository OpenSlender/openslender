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
        public const float JumpVelocity = 4.5f;
        public const float MouseSensitivity = 0.25f;

        private Node3D _cameraPivot;
        private Camera3D _camera;
        private float _pitch = 0f;

        public StateMachine StateMachine { get; private set; }

        private DebugStateOverlay _debugOverlay;
        private CanvasLayer _debugCanvasLayer;

        public override void _Ready()
        {
            AddToGroup("player");

            _cameraPivot = GetNode<Node3D>(CameraPivotPath);
            _camera = GetNode<Camera3D>(CameraPath);
            Input.MouseMode = Input.MouseModeEnum.Captured;

            InitializeStateMachine();

            // Defer debug overlay creation to avoid scene tree conflicts
            CallDeferred(nameof(InitializeDebugOverlay));
        }

        private void InitializeStateMachine()
        {
            StateMachine = new StateMachine();
            AddChild(StateMachine);

            StateMachine.AddState("Idle", new IdleState());
            StateMachine.AddState("Walking", new WalkingState());
            StateMachine.AddState("Running", new RunningState());
            StateMachine.AddState("Jumping", new JumpingState());
            StateMachine.AddState("Falling", new FallingState());
            StateMachine.AddState("Landing", new LandingState());

            StateMachine.SetInitialState("Idle", this);

            StateMachine.StateChanged += OnStateChanged;
        }

        private void OnStateChanged(string fromState, string toState)
        {
            _debugOverlay?.ShowStateTransition(fromState, toState);
        }

        private void InitializeDebugOverlay()
        {
            // Create the canvas layer first
            _debugCanvasLayer = new CanvasLayer();
            _debugCanvasLayer.Layer = 100;
            _debugCanvasLayer.Name = "DebugCanvasLayer";

            // Add canvas layer to root, then chain the next step
            GetTree().Root.CallDeferred(MethodName.AddChild, _debugCanvasLayer);
            CallDeferred(nameof(CreateDebugOverlayControl));
        }

        private void CreateDebugOverlayControl()
        {
            // Create the debug overlay control
            _debugOverlay = new DebugStateOverlay();

            // Add the debug overlay to the canvas layer, then set up the reference
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

            // Handle F3 for debug overlay toggle
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

        public override void _Process(double delta)
        {
            StateMachine?.Update(this, delta);
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
