using Godot;

namespace OpenSlender.States
{
    public class FallingState : BaseState
    {
        public override void Enter(Player player)
        {
            // Could trigger falling animation here
        }

        public override void PhysicsUpdate(Player player, double delta)
        {
            Vector3 velocity = player.Velocity;

            velocity.Y -= (float)ProjectSettings.GetSetting("physics/3d/default_gravity") * (float)delta;

            Vector2 inputDir = Input.GetVector("left", "right", "up", "down");
            Vector3 direction = (player.Transform.Basis * new Vector3(inputDir.X, 0, inputDir.Y)).Normalized();

            if (direction != Vector3.Zero)
            {
                float airControl = Player.Speed * 0.6f;
                velocity.X = direction.X * airControl;
                velocity.Z = direction.Z * airControl;
            }
            else
            {
                velocity.X = Mathf.MoveToward(velocity.X, 0, Player.Speed * 0.3f * (float)delta);
                velocity.Z = Mathf.MoveToward(velocity.Z, 0, Player.Speed * 0.3f * (float)delta);
            }

            player.Velocity = velocity;
            player.MoveAndSlide();

            if (player.IsOnFloor())
            {
                player.StateMachine.ChangeState("Landing", player);
                return;
            }
        }

        public override string GetStateName()
        {
            return "Falling";
        }
    }
}
