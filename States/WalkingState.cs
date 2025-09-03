using Godot;

namespace OpenSlender.States
{

    public class WalkingState : BaseState
    {
        public override void Enter(Player player)
        {
            // Could trigger walking animation here
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

            Vector2 inputDir = Input.GetVector("left", "right", "up", "down");

            if (Input.IsActionJustPressed("ui_accept"))
            {
                player.StateMachine.ChangeState("Jumping", player);
                return;
            }

            if (Input.IsActionPressed("crouch"))
            {
                player.StateMachine.ChangeState("Crouching", player);
                return;
            }

            if (Input.IsActionPressed("run"))
            {
                player.StateMachine.ChangeState("Running", player);
                return;
            }

            if (inputDir.LengthSquared() < 0.1f)
            {
                player.StateMachine.ChangeState("Idle", player);
                return;
            }

            Vector3 direction = (player.Transform.Basis * new Vector3(inputDir.X, 0, inputDir.Y)).Normalized();

            if (direction != Vector3.Zero)
            {
                velocity.X = direction.X * Player.Speed;
                velocity.Z = direction.Z * Player.Speed;
            }
            else
            {
                velocity.X = Mathf.MoveToward(velocity.X, 0, Player.Speed * (float)delta);
                velocity.Z = Mathf.MoveToward(velocity.Z, 0, Player.Speed * (float)delta);
            }

            player.Velocity = velocity;
            player.MoveAndSlide();
        }

        public override string GetStateName()
        {
            return "Walking";
        }
    }
}
