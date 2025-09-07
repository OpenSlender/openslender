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
                float desiredMaxSpeed = targetSpeed * player.Settings.JumpDesiredSpeedFactor;

                Vector3 dir = new Vector3(direction.X, 0, direction.Z);
                Vector3 currentHorizontal = new Vector3(velocity.X, 0, velocity.Z);

                float speedAlong = currentHorizontal.Dot(dir);
                float needed = desiredMaxSpeed - speedAlong;

                if (needed > 0.0f)
                {
                    float maxDelta = player.Settings.AirControlAcceleration * (float)delta;
                    float accel = Mathf.Min(needed, maxDelta);
                    currentHorizontal += dir * accel;
                }

                velocity.X = currentHorizontal.X;
                velocity.Z = currentHorizontal.Z;
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
