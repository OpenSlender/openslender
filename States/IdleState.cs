using Godot;

namespace OpenSlender.States
{

    public class IdleState : BaseState
    {
        public override void Enter(Player player)
        {
            // Could trigger idle animation here
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

            if (inputDir.LengthSquared() > 0.1f)
            {
                if (Input.IsActionPressed("run"))
                {
                    player.StateMachine.ChangeState("Running", player);
                    return;
                }

                player.StateMachine.ChangeState("Walking", player);
                return;
            }

            velocity.X = Mathf.MoveToward(velocity.X, 0, Player.Speed * (float)delta * 3f);
            velocity.Z = Mathf.MoveToward(velocity.Z, 0, Player.Speed * (float)delta * 3f);

            player.Velocity = velocity;
            player.MoveAndSlide();
        }

        public override string GetStateName()
        {
            return "Idle";
        }
    }
}
