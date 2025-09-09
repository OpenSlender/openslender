using Godot;

namespace OpenSlender.MonsterStates
{
    public class InvestigatingState : BaseMonsterState
    {
        public override void Enter(Monster monster)
        {
            if (monster.LastKnownPosition != Vector3.Zero)
            {
                monster.NavigationAgent.TargetPosition = monster.LastKnownPosition;
            }
        }

        public override void PhysicsUpdate(Monster monster, double delta)
        {
            // Check for visible target
            Node3D target = monster.FindVisibleTarget();
            if (target != null)
            {
                monster.StateMachine.ChangeState(MonsterStateNames.Chasing, monster);
                return;
            }

            if (monster.LastKnownPosition == Vector3.Zero)
            {
                monster.StateMachine.ChangeState(MonsterStateNames.Wandering, monster);
                return;
            }

            // Move towards last known position
            Vector3 nextPathPosition = monster.NavigationAgent.GetNextPathPosition();
            Vector3 direction = (nextPathPosition - monster.GlobalPosition).Normalized();
            monster.Velocity = direction * monster.Speed;
            monster.MoveAndSlide();

            // Check if reached
            if (monster.NavigationAgent.IsTargetReached())
            {
                monster.LastKnownPosition = Vector3.Zero;
                monster.StateMachine.ChangeState(MonsterStateNames.Wandering, monster);
            }
        }
    }
}
