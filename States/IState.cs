using Godot;

namespace OpenSlender.States
{
    public interface IState
    {
        void Enter(Player player);
        void Update(Player player, double delta);
        void PhysicsUpdate(Player player, double delta);
        void HandleInput(Player player, InputEvent inputEvent);
        void Exit(Player player);
        string GetStateName();
    }

    public abstract class BaseState : IState
    {
        public virtual void Enter(Player player) { }

        public virtual void Update(Player player, double delta) { }

        public virtual void PhysicsUpdate(Player player, double delta) { }

        public virtual void HandleInput(Player player, InputEvent inputEvent) { }

        public virtual void Exit(Player player) { }

        public virtual string GetStateName()
        {
            return GetType().Name.Replace("State", "");
        }
    }
}
