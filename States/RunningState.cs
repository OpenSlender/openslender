using Godot;

namespace OpenSlender.States
{
    public class RunningState : BaseLocomotionState
    {
        public override void Enter(Player player)
        {
            // Could trigger running animation here
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

            if (TryStartJump(player)) { return; }
            if (TryStartCrouch(player)) { return; }

            if (inputDir.LengthSquared() < player.Settings.InputThresholdSquared)
            {
                player.StateMachine.ChangeState(StateNames.Idle, player);
                return;
            }

            if (!Input.IsActionPressed("run"))
            {
                player.StateMachine.ChangeState(StateNames.Walking, player);
                return;
            }

            Vector3 direction = ComputeWorldDirection(player, inputDir);
            ApplyHorizontal(direction, player.Settings.RunSpeed, delta, ref velocity);

            player.Velocity = velocity;
            player.MoveAndSlide();
        }

        
    }
}
