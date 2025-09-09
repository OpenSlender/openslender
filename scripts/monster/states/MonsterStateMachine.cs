using Godot;
using System.Collections.Generic;

namespace OpenSlender.MonsterStates
{
    public partial class MonsterStateMachine : Node
    {
        private IMonsterState _currentState;
        private Dictionary<string, IMonsterState> _states;
        private IMonsterState _previousState;

        [Signal]
        public delegate void StateChangedEventHandler(string fromState, string toState);

        public string CurrentStateName => _currentState?.GetStateName() ?? "None";
        public IMonsterState CurrentState => _currentState;
        public string PreviousStateName => _previousState?.GetStateName() ?? "None";
        public IMonsterState PreviousState => _previousState;
        public bool DebugLogging { get; set; } = false;

        public override void _Ready()
        {
            _states = new Dictionary<string, IMonsterState>();
        }

        public void AddState(string name, IMonsterState state)
        {
            _states[name] = state;
        }

        public void AddState(IMonsterState state)
        {
            if (state == null)
            {
                GD.PrintErr("Attempted to add a null state to the monster state machine");
                return;
            }

            string name = state.GetStateName();
            if (string.IsNullOrWhiteSpace(name))
            {
                GD.PrintErr("Attempted to add a state with an empty name");
                return;
            }

            _states[name] = state;
        }

        public void ChangeState(string stateName, Monster monster)
        {
            TryChangeState(stateName, monster);
        }

        public bool TryChangeState(string stateName, Monster monster)
        {
            if (!_states.ContainsKey(stateName))
            {
                GD.PrintErr($"State '{stateName}' not found in monster state machine");
                return false;
            }

            if (_currentState != null && _currentState.GetStateName() == stateName)
            {
                return false;
            }

            string previousStateName = _currentState?.GetStateName() ?? "None";

            _currentState?.Exit(monster);

            _previousState = _currentState;
            _currentState = _states[stateName];
            _currentState.Enter(monster);

            if (DebugLogging)
            {
                GD.Print($"Monster state change: {previousStateName} -> {stateName}");
            }

            EmitSignal(SignalName.StateChanged, previousStateName, stateName);
            return true;
        }

        public void SetInitialState(string stateName, Monster monster)
        {
            if (!_states.ContainsKey(stateName))
            {
                GD.PrintErr($"Initial state '{stateName}' not found in monster state machine");
                return;
            }

            _previousState = null;
            _currentState = _states[stateName];
            _currentState.Enter(monster);

            GD.Print($"Monster initial state set to: {stateName}");
        }

        public void Update(Monster monster, double delta)
        {
            _currentState?.Update(monster, delta);
        }

        public void PhysicsUpdate(Monster monster, double delta)
        {
            _currentState?.PhysicsUpdate(monster, delta);
        }

        public string[] GetAvailableStates()
        {
            var stateNames = new string[_states.Count];
            _states.Keys.CopyTo(stateNames, 0);
            return stateNames;
        }

        public bool HasState(string stateName)
        {
            return _states.ContainsKey(stateName);
        }

        public bool IsInState(string stateName)
        {
            return _currentState != null && _currentState.GetStateName() == stateName;
        }

        public void ChangeState<TState>(Monster monster) where TState : IMonsterState
        {
            TryChangeState<TState>(monster);
        }

        public bool TryChangeState<TState>(Monster monster) where TState : IMonsterState
        {
            string stateName = typeof(TState).Name.Replace("State", "");
            return TryChangeState(stateName, monster);
        }
    }
}
