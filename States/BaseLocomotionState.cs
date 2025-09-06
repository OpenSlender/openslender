using Godot;

namespace OpenSlender.States
{
    public abstract class BaseLocomotionState : BaseState
    {
        protected const float InputThresholdSquared = 0.1f;

        protected bool HandleAirborne(Player player, ref Vector3 velocity, double delta)
        {
            if (!player.IsOnFloor())
            {
                velocity.Y -= StateUtils.Gravity * (float)delta;
                player.StateMachine.ChangeState(StateNames.Falling, player);
                return true;
            }

            return false;
        }

        protected static Vector2 ReadInput2D()
        {
            return Input.GetVector("left", "right", "up", "down");
        }

        protected static Vector3 ComputeWorldDirection(Player player, Vector2 inputDir)
        {
            return (player.Transform.Basis * new Vector3(inputDir.X, 0, inputDir.Y)).Normalized();
        }

        protected static bool TryStartJump(Player player)
        {
            if (Input.IsActionJustPressed("ui_accept"))
            {
                player.StateMachine.ChangeState(StateNames.Jumping, player);
                return true;
            }

            return false;
        }

        protected static bool TryStartCrouch(Player player)
        {
            if (Input.IsActionPressed("crouch"))
            {
                player.StateMachine.ChangeState(StateNames.Crouching, player);
                return true;
            }

            return false;
        }

        protected static void ApplyHorizontal(Vector3 direction, float speed, double delta, ref Vector3 velocity, float dampingMultiplier = 1.0f)
        {
            if (direction != Vector3.Zero)
            {
                velocity.X = direction.X * speed;
                velocity.Z = direction.Z * speed;
            }
            else
            {
                velocity.X = Mathf.MoveToward(velocity.X, 0, speed * (float)delta * dampingMultiplier);
                velocity.Z = Mathf.MoveToward(velocity.Z, 0, speed * (float)delta * dampingMultiplier);
            }
        }
    }
}


