using Godot;

namespace OpenSlender.States
{

    public class IdleState : BaseLocomotionState
    {
        public override void Enter(Player player)
        {
            // Could trigger idle animation here
        }

        public override void PhysicsUpdate(Player player, double delta)
        {
            Vector3 velocity = player.Velocity;

            if (HandleAirborne(player, ref velocity, delta))
            {
                player.Velocity = velocity;
                player.MoveAndSlide();
                return;
            }

            Vector2 inputDir = ReadInput2D();

            if (TryStartJump(player))
            {
                return;
            }

            if (TryStartCrouch(player))
            {
                return;
            }

            if (inputDir.LengthSquared() > 0.1f)
            {
                if (Input.IsActionPressed("run"))
                {
                    player.StateMachine.ChangeState(StateNames.Running, player);
                    return;
                }

                player.StateMachine.ChangeState(StateNames.Walking, player);
                return;
            }

            ApplyHorizontal(Vector3.Zero, Player.Speed, delta, ref velocity, 3f);

            player.Velocity = velocity;
            player.MoveAndSlide();
        }

    }
}
