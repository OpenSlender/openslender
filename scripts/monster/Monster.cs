using Godot;
using System;

public partial class Monster : CharacterBody3D
{
    [Export] public NodePath TargetPath { get; set; }
    [Export] public float Speed { get; set; } = 3.0f;
    [Export] public float DetectionRange { get; set; } = 10.0f;

    private Node3D _target;
    private NavigationAgent3D _navigationAgent;

    public override void _Ready()
    {
        _target = GetNode<Node3D>(TargetPath);
        _navigationAgent = GetNode<NavigationAgent3D>("NavigationAgent3D");
        _navigationAgent.TargetPosition = _target.GlobalPosition;
    }

    public override void _Process(double delta)
    {
        if (_target == null || _navigationAgent == null) return;

        float distanceToTarget = GlobalPosition.DistanceTo(_target.GlobalPosition);
        if (distanceToTarget <= DetectionRange)
        {
            _navigationAgent.TargetPosition = _target.GlobalPosition;
            Vector3 nextPathPosition = _navigationAgent.GetNextPathPosition();
            Vector3 direction = (nextPathPosition - GlobalPosition).Normalized();
            Velocity = direction * Speed;
            MoveAndSlide();
        }
    }
}
