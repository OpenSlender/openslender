using Godot;

namespace OpenSlender.MonsterStates
{
    public class ChasingState : BaseMonsterState
    {
        public override void Enter(Monster monster)
        {
            // Could trigger chasing animation or sound here
        }

        public override void PhysicsUpdate(Monster monster, double delta)
        {
            Node3D target = monster.FindVisibleTarget();

            if (target != null)
            {
                monster.LastKnownPosition = target.GlobalPosition;
                monster.NavigationAgent.TargetPosition = target.GlobalPosition;

                Vector3 nextPathPosition = monster.NavigationAgent.GetNextPathPosition();
                Vector3 direction = (nextPathPosition - monster.GlobalPosition).Normalized();
                monster.Velocity = direction * monster.Speed;
                monster.MoveAndSlide();
            }
            else
            {
                if (monster.LastKnownPosition != Vector3.Zero)
                {
                    monster.StateMachine.ChangeState(MonsterStateNames.Investigating, monster);
                }
                else
                {
                    monster.StateMachine.ChangeState(MonsterStateNames.Wandering, monster);
                }
            }
        }
    }
}
