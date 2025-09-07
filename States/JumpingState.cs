using Godot;

namespace OpenSlender.States
{
    public class JumpingState : BaseState
    {
        private float _initialSpeed;

        public override void Enter(Player player)
        {
            Vector3 velocity = player.Velocity;

            float currentHorizontalSpeed = new Vector2(velocity.X, velocity.Z).Length();
            _initialSpeed = currentHorizontalSpeed;

            velocity.Y = player.Settings.JumpVelocity;
            player.Velocity = velocity;
        }

        public override void PhysicsUpdate(Player player, double delta)
        {
            Vector3 velocity = player.Velocity;

            velocity.Y -= StateUtils.Gravity * (float)delta;

            if (Input.IsActionPressed("crouch"))
            {
                player.SetCrouchState(true);
            }
            else
            {
                player.SetCrouchState(false);
            }

            if (velocity.Y <= 0)
            {
                player.StateMachine.ChangeState(StateNames.Falling, player);
                return;
            }

            Vector2 inputDir = Input.GetVector("left", "right", "up", "down");
            Vector3 direction = (player.Transform.Basis * new Vector3(inputDir.X, 0, inputDir.Y)).Normalized();

            float targetSpeed = Input.IsActionPressed("run") ? player.Settings.RunSpeed : player.Settings.WalkSpeed;
            float currentSpeed = new Vector2(velocity.X, velocity.Z).Length();

            if (direction != Vector3.Zero)
            {
                float desiredSpeed = Mathf.Max(_initialSpeed, targetSpeed);
                desiredSpeed = Mathf.MoveToward(desiredSpeed, targetSpeed * player.Settings.JumpDesiredSpeedFactor, (float)delta * player.Settings.AirSpeedLerpRate);

                velocity.X = direction.X * desiredSpeed;
                velocity.Z = direction.Z * desiredSpeed;

                _initialSpeed = desiredSpeed;
            }
            else
            {
                velocity.X = Mathf.MoveToward(velocity.X, 0, player.Settings.WalkSpeed * player.Settings.JumpNoInputDampingFactor * (float)delta);
                velocity.Z = Mathf.MoveToward(velocity.Z, 0, player.Settings.WalkSpeed * player.Settings.JumpNoInputDampingFactor * (float)delta);
            }

            player.Velocity = velocity;
            player.MoveAndSlide();

            if (player.IsOnFloor() && velocity.Y <= 0)
            {
                player.StateMachine.ChangeState(StateNames.Landing, player);
                return;
            }
        }

        
    }
}
