using Godot;
using System.Collections.Generic;

namespace OpenSlender.States
{
    public partial class StateMachine : Node
    {
        private IState _currentState;
        private Dictionary<string, IState> _states;
        private IState _previousState;

        [Signal]
        public delegate void StateChangedEventHandler(string fromState, string toState);

        public string CurrentStateName => _currentState?.GetStateName() ?? "None";
        public IState CurrentState => _currentState;
        public string PreviousStateName => _previousState?.GetStateName() ?? "None";
        public IState PreviousState => _previousState;
        public bool DebugLogging { get; set; } = false;

        public override void _Ready()
        {
            _states = new Dictionary<string, IState>();
        }

        public void AddState(string name, IState state)
        {
            _states[name] = state;
        }

        public void AddState(IState state)
        {
            if (state == null)
            {
                GD.PrintErr("Attempted to add a null state to the state machine");
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

        public void ChangeState(string stateName, Player player)
        {
            TryChangeState(stateName, player);
        }

        public bool TryChangeState(string stateName, Player player)
        {
            if (!_states.ContainsKey(stateName))
            {
                GD.PrintErr($"State '{stateName}' not found in state machine");
                return false;
            }

            if (_currentState != null && _currentState.GetStateName() == stateName)
            {
                return false;
            }

            string previousStateName = _currentState?.GetStateName() ?? "None";

            _currentState?.Exit(player);

            _previousState = _currentState;
            _currentState = _states[stateName];
            _currentState.Enter(player);

            if (DebugLogging)
            {
                GD.Print($"State change: {previousStateName} -> {stateName}");
            }

            EmitSignal(SignalName.StateChanged, previousStateName, stateName);
            return true;
        }

        public void SetInitialState(string stateName, Player player)
        {
            if (!_states.ContainsKey(stateName))
            {
                GD.PrintErr($"Initial state '{stateName}' not found in state machine");
                return;
            }

            _previousState = null;
            _currentState = _states[stateName];
            _currentState.Enter(player);

            GD.Print($"Initial state set to: {stateName}");
        }

        public void Update(Player player, double delta)
        {
            _currentState?.Update(player, delta);
        }

        public void PhysicsUpdate(Player player, double delta)
        {
            _currentState?.PhysicsUpdate(player, delta);
        }

        public void HandleInput(Player player, InputEvent inputEvent)
        {
            _currentState?.HandleInput(player, inputEvent);
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

        public void ChangeState<TState>(Player player) where TState : IState
        {
            TryChangeState<TState>(player);
        }

        public bool TryChangeState<TState>(Player player) where TState : IState
        {
            string stateName = typeof(TState).Name.Replace("State", "");
            return TryChangeState(stateName, player);
        }
    }
}
