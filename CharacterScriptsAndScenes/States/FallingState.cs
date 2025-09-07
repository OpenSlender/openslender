using Godot;

namespace OpenSlender.States
{
    public class FallingState : BaseState
    {
        private float _initialSpeed;

        public override void Enter(Player player)
        {
            Vector3 velocity = player.Velocity;
            _initialSpeed = new Vector2(velocity.X, velocity.Z).Length();
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

            Vector2 inputDir = Input.GetVector("left", "right", "up", "down");
            Vector3 direction = (player.Transform.Basis * new Vector3(inputDir.X, 0, inputDir.Y)).Normalized();

            float targetSpeed = Input.IsActionPressed("run") ? player.Settings.RunSpeed : player.Settings.WalkSpeed;

            if (direction != Vector3.Zero)
            {
                float desiredMaxSpeed = targetSpeed * player.Settings.FallDesiredSpeedFactor;

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

            if (player.IsOnFloor())
            {
                player.StateMachine.ChangeState(StateNames.Landing, player);
                return;
            }
        }


    }
}
