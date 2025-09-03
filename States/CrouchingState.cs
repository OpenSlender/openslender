using Godot;

namespace OpenSlender.States
{
	public class CrouchingState : BaseState
	{
		public override void Enter(Player player)
		{
			player.SetCrouchState(true);
		}

		public override void PhysicsUpdate(Player player, double delta)
		{
			Vector3 velocity = player.Velocity;

			if (!player.IsOnFloor())
			{
				velocity.Y -= (float)ProjectSettings.GetSetting("physics/3d/default_gravity") * (float)delta;
				player.StateMachine.ChangeState("Falling", player);
				return;
			}

			if (Input.IsActionJustPressed("ui_accept"))
			{
				player.StateMachine.ChangeState("Jumping", player);
				return;
			}

			Vector2 inputDir = Input.GetVector("left", "right", "up", "down");

			if (!Input.IsActionPressed("crouch"))
			{
				if (inputDir.LengthSquared() > 0.1f)
				{
					player.StateMachine.ChangeState("Walking", player);
					return;
				}
				else
				{
					player.StateMachine.ChangeState("Idle", player);
					return;
				}
			}

			if (inputDir.LengthSquared() < 0.1f)
			{
				velocity.X = Mathf.MoveToward(velocity.X, 0, Player.Speed * (float)delta * 3f);
				velocity.Z = Mathf.MoveToward(velocity.Z, 0, Player.Speed * (float)delta * 3f);
			}
			else
			{
				Vector3 direction = (player.Transform.Basis * new Vector3(inputDir.X, 0, inputDir.Y)).Normalized();

				if (direction != Vector3.Zero)
				{
					velocity.X = direction.X * Player.CrouchSpeed;
					velocity.Z = direction.Z * Player.CrouchSpeed;
				}
			}

			player.Velocity = velocity;
			player.MoveAndSlide();
		}

		public override void Exit(Player player)
		{
			player.SetCrouchState(false);
		}

		public override string GetStateName()
		{
			return "Crouching";
		}
	}
}
