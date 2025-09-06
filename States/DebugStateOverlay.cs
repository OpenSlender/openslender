using Godot;

namespace OpenSlender.States
{
    public partial class DebugStateOverlay : Control
    {
        private Label _stateLabel;
        private Label _velocityLabel;
        private Label _positionLabel;
        private Label _fpsLabel;
        private Label _instructionsLabel;

        private Player _player;
        private bool _isVisible = false;

        public override void _Ready()
        {
            GD.Print("DebugStateOverlay: Initializing");

            Position = new Vector2(10, 10);
            Size = new Vector2(380, 200);

            Modulate = new Color(1.0f, 1.0f, 1.0f, 0.5f);

            var background = new ColorRect();
            background.Position = Vector2.Zero;
            background.Size = new Vector2(280, 200);
            background.Color = new Color(0.0f, 0.0f, 0.0f, 1.0f);
            AddChild(background);

            var border = new ColorRect();
            border.Position = new Vector2(-2, -2);
            border.Size = new Vector2(284, 204);
            border.Color = new Color(0.4f, 0.4f, 0.4f, 1.0f);
            AddChild(border);
            MoveChild(border, 0);

            var contentMargin = new MarginContainer();
            contentMargin.Position = Vector2.Zero;
            contentMargin.Size = new Vector2(280, 200);
            contentMargin.AddThemeConstantOverride("margin_left", 15);
            contentMargin.AddThemeConstantOverride("margin_top", 15);
            contentMargin.AddThemeConstantOverride("margin_right", 15);
            contentMargin.AddThemeConstantOverride("margin_bottom", 15);
            AddChild(contentMargin);

            var vbox = new VBoxContainer();
            vbox.AddThemeConstantOverride("separation", 4);
            contentMargin.AddChild(vbox);

            _stateLabel = CreateLabel("State: Unknown");
            vbox.AddChild(_stateLabel);

            _velocityLabel = CreateLabel("Velocity: (0.0, 0.0, 0.0)");
            vbox.AddChild(_velocityLabel);

            _positionLabel = CreateLabel("Position: (0.0, 0.0, 0.0)");
            vbox.AddChild(_positionLabel);

            _fpsLabel = CreateLabel("FPS: 0");
            vbox.AddChild(_fpsLabel);

            var separator = new HSeparator();
            separator.AddThemeColorOverride("separator", new Color(0.5f, 0.5f, 0.5f, 0.5f));
            vbox.AddChild(separator);

            _instructionsLabel = CreateLabel("Press F3 to toggle this overlay", new Color(0.7f, 0.7f, 0.7f));
            vbox.AddChild(_instructionsLabel);

            Visible = _isVisible;

            CallDeferred(nameof(FindPlayerReference));
        }

        private Label CreateLabel(string text, Color? color = null)
        {
            var label = new Label();
            label.Text = text;
            label.AddThemeColorOverride("font_color", color ?? Colors.White);
            label.AddThemeColorOverride("font_shadow_color", new Color(0, 0, 0, 0.9f));
            label.AddThemeConstantOverride("shadow_offset_x", 1);
            label.AddThemeConstantOverride("shadow_offset_y", 1);
            return label;
        }

        private void FindPlayerReference()
        {
            if (_player != null && IsInstanceValid(_player))
                return;

            var players = GetTree().GetNodesInGroup("player");
            if (players.Count > 0)
            {
                _player = players[0] as Player;
                if (_player != null && IsInstanceValid(_player))
                {
                    GD.Print("DebugStateOverlay: Found player");
                    return;
                }
            }

            _player = null;
        }

        public override void _Input(InputEvent @event)
        {
            if (@event is InputEventKey keyEvent && keyEvent.Pressed)
            {
                if (keyEvent.Keycode == Key.F3)
                {
                    GD.Print("DebugStateOverlay: F3 pressed, toggling visibility");
                    ToggleVisibility();
                    GetViewport().SetInputAsHandled();
                }
            }
        }

        public override void _Process(double delta)
        {
            if (!_isVisible)
                return;

            if (_player == null)
                FindPlayerReference();

            UpdateDebugInfo();
        }

        private void UpdateDebugInfo()
        {
            try
            {
                _fpsLabel.Text = $"FPS: {Engine.GetFramesPerSecond()}";

                if (_player == null)
                {
                    _stateLabel.Text = "State: Player not found";
                    _velocityLabel.Text = "Velocity: N/A";
                    _positionLabel.Text = "Position: N/A";
                    return;
                }

                string currentState = _player.StateMachine?.CurrentStateName ?? "Unknown";
                _stateLabel.Text = $"State: {currentState}";

                Vector3 velocity = _player.Velocity;
                _velocityLabel.Text = $"Velocity: ({velocity.X:F1}, {velocity.Y:F1}, {velocity.Z:F1})";

                float horizontalSpeed = new Vector2(velocity.X, velocity.Z).Length();
                _velocityLabel.Text += $"\nH-Speed: {horizontalSpeed:F1} | On Floor: {_player.IsOnFloor()}";

                Vector3 position = _player.GlobalPosition;
                _positionLabel.Text = $"Position: ({position.X:F1}, {position.Y:F1}, {position.Z:F1})";
            }
            catch (System.Exception ex)
            {
                GD.PrintErr($"DebugStateOverlay: Error updating info: {ex.Message}");
                _player = null;
            }
        }

        public void ToggleVisibility()
        {
            _isVisible = !_isVisible;
            Visible = _isVisible;
            GD.Print($"Debug overlay: {(_isVisible ? "VISIBLE" : "HIDDEN")}");
        }

        public void SetPlayer(Player player)
        {
            _player = player;
            if (_player != null)
            {
                GD.Print("DebugStateOverlay: Player reference set directly");
            }
        }

        public void ShowStateTransition(string fromState, string toState)
        {
            if (_isVisible)
            {
                GD.Print($"State Transition: {fromState} -> {toState}");
            }
        }

        public override void _ExitTree()
        {
            _player = null;
            GD.Print("DebugStateOverlay: Cleaned up");
        }
    }
}
