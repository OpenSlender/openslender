using Godot;

namespace OpenSlender.MonsterStates
{
    public interface IMonsterState
    {
        void Enter(Monster monster);
        void Update(Monster monster, double delta);
        void PhysicsUpdate(Monster monster, double delta);
        void Exit(Monster monster);
        string GetStateName();
    }

    public abstract class BaseMonsterState : IMonsterState
    {
        public virtual void Enter(Monster monster) { }

        public virtual void Update(Monster monster, double delta) { }

        public virtual void PhysicsUpdate(Monster monster, double delta) { }

        public virtual void Exit(Monster monster) { }

        public virtual string GetStateName()
        {
            return GetType().Name.Replace("State", "");
        }
    }
}
