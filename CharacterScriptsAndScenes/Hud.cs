using Godot;
using System;

public partial class Hud : Control
{
	private Label _collectiblesLabel;
	public override void _Ready()
	{
		_collectiblesLabel = GetNode<Label>("CollectiblesLabel");

		var gm = GameManager.Instance;
		if (gm != null)
		{
			gm.Connect(GameManager.SignalName.CollectibleCollected, new Callable(this, nameof(onCollectibleCollected)));
			gm.Connect(GameManager.SignalName.AllCollectiblesCollected, new Callable(this, nameof(onAllCollectiblesCollected)));

			onCollectibleCollected(gm.Collected, gm.TotalCollectibles);
		}
	}

	private void onCollectibleCollected(int collected, int totalCollectibles)
	{
		_collectiblesLabel.Text = $"{collected}/{totalCollectibles}";
	}

	private void onAllCollectiblesCollected()
	{
		_collectiblesLabel.Text = "You found all the collectibles!";
	}

}
