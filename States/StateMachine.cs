using Godot;
using System.Collections.Generic;

namespace OpenSlender.States
{
    public partial class StateMachine : Node
    {
        private IState _currentState;
        private Dictionary<string, IState> _states;

        [Signal]
        public delegate void StateChangedEventHandler(string fromState, string toState);

        public string CurrentStateName => _currentState?.GetStateName() ?? "None";
        public IState CurrentState => _currentState;

        public override void _Ready()
        {
            _states = new Dictionary<string, IState>();
        }

        public void AddState(string name, IState state)
        {
            _states[name] = state;
        }

        public void ChangeState(string stateName, Player player)
        {
            if (!_states.ContainsKey(stateName))
            {
                GD.PrintErr($"State '{stateName}' not found in state machine");
                return;
            }

            if (_currentState != null && _currentState.GetStateName() == stateName)
            {
                return;
            }

            string previousStateName = _currentState?.GetStateName() ?? "None";

            _currentState?.Exit(player);

            _currentState = _states[stateName];
            _currentState.Enter(player);

            EmitSignal(SignalName.StateChanged, previousStateName, stateName);

            GD.Print($"State transition: {previousStateName} -> {stateName}");
        }

        public void SetInitialState(string stateName, Player player)
        {
            if (!_states.ContainsKey(stateName))
            {
                GD.PrintErr($"Initial state '{stateName}' not found in state machine");
                return;
            }

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
    }
}
