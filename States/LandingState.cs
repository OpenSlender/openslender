using Godot;
using OpenSlender;

namespace OpenSlender.States
{
    public class LandingState : BaseState
    {
        private double _landingTimer = 0.0;
        private const double LandingDuration = 0.1;

        public override void Enter(Player player)
        {
            _landingTimer = 0.0;

            Vector3 velocity = player.Velocity;
            if (velocity.Y < 0)
            {
                velocity.Y = 0;
                player.Velocity = velocity;
            }

        }

        public override void PhysicsUpdate(Player player, double delta)
        {
            _landingTimer += delta;

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

            if (_landingTimer >= LandingDuration)
            {
                if (Input.IsActionPressed("crouch"))
                {
                    player.StateMachine.ChangeState("Crouching", player);
                    return;
                }
                
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

            velocity.X = Mathf.MoveToward(velocity.X, 0, Player.Speed * (float)delta * 2f);
            velocity.Z = Mathf.MoveToward(velocity.Z, 0, Player.Speed * (float)delta * 2f);

            player.Velocity = velocity;
            player.MoveAndSlide();
        }

        public override void Exit(Player player)
        {
            _landingTimer = 0.0;
        }

        public override string GetStateName()
        {
            return "Landing";
        }
    }
}
