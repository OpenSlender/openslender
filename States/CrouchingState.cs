using Godot;

namespace OpenSlender.States
{
	public class CrouchingState : BaseLocomotionState
	{
		public override void Enter(Player player)
		{
			player.SetCrouchState(true);
		}

		public override void PhysicsUpdate(Player player, double delta)
		{
			Vector3 velocity = player.Velocity;

			if (HandleAirborne(player, ref velocity, delta))
			{
				player.Velocity = velocity;
				player.MoveAndSlide();
				return;
			}

			if (TryStartJump(player))
			{
				return;
			}

			Vector2 inputDir = ReadInput2D();

			if (!Input.IsActionPressed("crouch"))
			{
				if (inputDir.LengthSquared() > player.Settings.InputThresholdSquared)
				{
					player.StateMachine.ChangeState(StateNames.Walking, player);
					return;
				}
				else
				{
					player.StateMachine.ChangeState(StateNames.Idle, player);
					return;
				}
			}

			if (inputDir.LengthSquared() < player.Settings.InputThresholdSquared)
			{
				ApplyHorizontal(Vector3.Zero, player.Settings.WalkSpeed, delta, ref velocity, player.Settings.CrouchStopDampingMultiplier);
			}
			else
			{
				Vector3 direction = ComputeWorldDirection(player, inputDir);
				ApplyHorizontal(direction, player.Settings.CrouchSpeed, delta, ref velocity);
			}

			player.Velocity = velocity;
			player.MoveAndSlide();
		}

		public override void Exit(Player player)
		{
			player.SetCrouchState(false);
		}

		
	}
}
