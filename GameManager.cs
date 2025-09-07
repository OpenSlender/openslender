using Godot;
using System;

public partial class GameManager : Node
{
    public static GameManager Instance { get; private set; }

    [Export] public int TotalCollectibles { get; set; } = 0;
    [Export] public int Collected { get; set; } = 0;

    [Signal]
    public delegate void CollectibleCollectedEventHandler(int collected, int totalCollectibles);
    [Signal]
    public delegate void AllCollectiblesCollectedEventHandler();

    public override void _EnterTree()
    {
        Instance = this;
    }

    public override void _Ready()
    {
        CallDeferred(nameof(InitializeCollectibles));
    }

    private void InitializeCollectibles()
    {
        if (TotalCollectibles == 0)
        {
            TotalCollectibles = GetTree().GetNodesInGroup("collectible").Count;
        }

        EmitSignal(SignalName.CollectibleCollected, Collected, TotalCollectibles);
    }

    public void ResetCollectibles()
    {
        Collected = 0;
        EmitSignal(SignalName.CollectibleCollected, Collected, TotalCollectibles);
    }

    public void CollectCollectible()
    {
        if (Collected >= TotalCollectibles) return;

        Collected++;
        EmitSignal(SignalName.CollectibleCollected, Collected, TotalCollectibles);

        if (Collected >= TotalCollectibles)
        {
            EmitSignal(SignalName.AllCollectiblesCollected);
        }
    }
}
