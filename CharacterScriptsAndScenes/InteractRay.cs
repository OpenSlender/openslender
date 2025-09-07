using Godot;
using System;

public partial class InteractRay : RayCast3D
{
	[Export] public RayCast3D Ray;
	[Export] public NodePath PromptLabelPath;

	private Label _promptLabel;
	private Collectible _currentHighlighted;

	public override void _Ready()
	{
		if (Ray == null)
		{
			Ray = GetNodeOrNull<RayCast3D>("RayCast3D");
		}

		if (!string.IsNullOrEmpty(PromptLabelPath.ToString()))
		{
			_promptLabel = GetNodeOrNull<Label>(PromptLabelPath);
		}

		if (_promptLabel != null)
		{
			_promptLabel.Visible = false;
		}
	}

	public override void _Process(double delta)
	{
		Collectible collectible = null;

		if (Ray != null && Ray.IsColliding())
		{
			var collider = Ray.GetCollider();
			if (collider is Node node)
			{
				collectible = node as Collectible ?? node.GetParent() as Collectible;
			}
		}

		if (_currentHighlighted != collectible)
		{
			if (_currentHighlighted != null)
			{
				_currentHighlighted.SetHighlighted(false);
			}
			_currentHighlighted = collectible;
			if (_currentHighlighted != null)
			{
				_currentHighlighted.SetHighlighted(true);
			}
		}

		if (_promptLabel != null)
		{
			_promptLabel.Visible = collectible != null;
		}

		if (collectible != null && Input.IsActionJustPressed("interact"))
		{
			collectible.TryPickup();
			if (_currentHighlighted == collectible)
			{
				_currentHighlighted = null;
			}
			if (_promptLabel != null)
			{
				_promptLabel.Visible = false;
			}
		}
	}

}
