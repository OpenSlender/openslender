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

            velocity.Y = Player.JumpVelocity;
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

            float targetSpeed = Input.IsActionPressed("run") ? Player.RunSpeed : Player.Speed;
            float currentSpeed = new Vector2(velocity.X, velocity.Z).Length();

            if (direction != Vector3.Zero)
            {
                float desiredSpeed = Mathf.Max(_initialSpeed, targetSpeed);
                desiredSpeed = Mathf.MoveToward(desiredSpeed, targetSpeed * 0.7f, (float)delta * 2.0f);

                velocity.X = direction.X * desiredSpeed;
                velocity.Z = direction.Z * desiredSpeed;

                _initialSpeed = desiredSpeed;
            }
            else
            {
                velocity.X = Mathf.MoveToward(velocity.X, 0, Player.Speed * 0.5f * (float)delta);
                velocity.Z = Mathf.MoveToward(velocity.Z, 0, Player.Speed * 0.5f * (float)delta);
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
