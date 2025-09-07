using Godot;

namespace OpenSlender.States
{
    public class LandingState : BaseState
    {
        private double _landingTimer = 0.0;

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
                velocity.Y -= StateUtils.Gravity * (float)delta;

                player.StateMachine.ChangeState(StateNames.Falling, player);
                return;
            }

            Vector2 inputDir = Input.GetVector("left", "right", "up", "down");

            if (Input.IsActionJustPressed("ui_accept"))
            {
                player.StateMachine.ChangeState(StateNames.Jumping, player);
                return;
            }

            if (_landingTimer >= player.Settings.LandingDuration)
            {
                if (Input.IsActionPressed("crouch"))
                {
                    player.StateMachine.ChangeState(StateNames.Crouching, player);
                    return;
                }
                
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

            velocity.X = Mathf.MoveToward(velocity.X, 0, player.Settings.WalkSpeed * (float)delta * player.Settings.LandingStopDampingMultiplier);
            velocity.Z = Mathf.MoveToward(velocity.Z, 0, player.Settings.WalkSpeed * (float)delta * player.Settings.LandingStopDampingMultiplier);

            player.Velocity = velocity;
            player.MoveAndSlide();
        }

        public override void Exit(Player player)
        {
            _landingTimer = 0.0;
        }

        
    }
}
