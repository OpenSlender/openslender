using Godot;
using OpenSlender.MonsterStates;

namespace OpenSlender
{
	public partial class Monster : CharacterBody3D
	{
		[Export] public float Speed { get; set; } = 3.0f;
		[Export] public float DetectionRange { get; set; } = 10.0f;

		public NavigationAgent3D NavigationAgent { get; private set; }
		public RayCast3D Raycast { get; private set; }
		public Vector3 LastKnownPosition { get; set; } = Vector3.Zero;
		public MonsterStateMachine StateMachine { get; private set; }

		public override void _Ready()
		{
			NavigationAgent = GetNode<NavigationAgent3D>("NavigationAgent3D");
			Raycast = GetNode<RayCast3D>("RayCast3D");
			InitializeStateMachine();
		}

		private void InitializeStateMachine()
		{
			StateMachine = new MonsterStateMachine();
			AddChild(StateMachine);

			StateMachine.AddState(new WanderingState());
			StateMachine.AddState(new ChasingState());
			StateMachine.AddState(new InvestigatingState());

			StateMachine.SetInitialState(MonsterStateNames.Wandering, this);
		}

		public Node3D FindVisibleTarget()
		{
			var players = GetTree().GetNodesInGroup("players");
			foreach (Node player in players)
			{
				if (player is Node3D playerNode)
				{
					Vector3 directionToPlayer = (playerNode.GlobalPosition - GlobalPosition).Normalized();
					Raycast.GlobalTransform = new Transform3D(Basis.Identity, GlobalPosition);
					Raycast.TargetPosition = directionToPlayer * DetectionRange;
					Raycast.ForceRaycastUpdate();
					if (Raycast.IsColliding() && Raycast.GetCollider() == playerNode)
					{
						return playerNode;
					}
				}
			}
			return null;
		}

		public override void _Process(double delta)
		{
			StateMachine?.Update(this, delta);
		}

		public override void _PhysicsProcess(double delta)
		{
			StateMachine?.PhysicsUpdate(this, delta);
		}
	}
}
