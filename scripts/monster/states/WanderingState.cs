using Godot;

namespace OpenSlender.MonsterStates
{
    public class WanderingState : BaseMonsterState
    {
        private float _wanderTimer = 0f;
        private float _wanderInterval = 3f; // Change target every 3 seconds
        private float _wanderRadius = 10f; // Wander within 10 units
        private float _timeSinceLastSeen = 0f;
        private const float TELEPORT_THRESHOLD = 30f; // Teleport after 30 seconds without seeing a player

        public override void Enter(Monster monster)
        {
            _wanderTimer = 0f;
            _timeSinceLastSeen = 0f;
            ChooseNewTarget(monster);
        }

        public override void PhysicsUpdate(Monster monster, double delta)
        {
            _wanderTimer += (float)delta;
            if (_wanderTimer >= _wanderInterval)
            {
                ChooseNewTarget(monster);
                _wanderTimer = 0f;
            }

            // Check for visible target
            Node3D target = monster.FindVisibleTarget();
            if (target != null)
            {
                _timeSinceLastSeen = 0f;
                monster.StateMachine.ChangeState(MonsterStateNames.Chasing, monster);
                return;
            }
            else
            {
                _timeSinceLastSeen += (float)delta;
                if (_timeSinceLastSeen >= TELEPORT_THRESHOLD)
                {
                    TeleportToRandomPlayer(monster);
                    _timeSinceLastSeen = 0f;
                }
            }

            // Move towards the target
            Vector3 nextPathPosition = monster.NavigationAgent.GetNextPathPosition();
            Vector3 direction = (nextPathPosition - monster.GlobalPosition).Normalized();
            monster.Velocity = direction * monster.Speed;
            monster.MoveAndSlide();
        }

        private void ChooseNewTarget(Monster monster)
        {
            // Random point in a circle around current position
            float angle = GD.Randf() * Mathf.Pi * 2;
            float distance = GD.Randf() * _wanderRadius;
            Vector3 offset = new Vector3(Mathf.Cos(angle) * distance, 0, Mathf.Sin(angle) * distance);
            Vector3 targetPosition = monster.GlobalPosition + offset;
            monster.NavigationAgent.TargetPosition = targetPosition;
        }

        private void TeleportToRandomPlayer(Monster monster)
        {
            var players = monster.GetTree().GetNodesInGroup("players");
            if (players.Count == 0) return;

            // Pick random player
            var randomPlayer = players[(int)(GD.Randf() * players.Count)] as Node3D;
            if (randomPlayer == null) return;

            // Find a random point near the player on navmesh
            var navMap = monster.NavigationAgent.GetNavigationMap();
            Vector3 playerPos = randomPlayer.GlobalPosition;

            // Try to find a point within 5-15 units from player
            for (int i = 0; i < 10; i++) // try 10 times
            {
                float angle = GD.Randf() * Mathf.Pi * 2;
                float distance = 5f + GD.Randf() * 10f;
                Vector3 offset = new Vector3(Mathf.Cos(angle) * distance, 0, Mathf.Sin(angle) * distance);
                Vector3 candidate = playerPos + offset;
                Vector3 closest = NavigationServer3D.MapGetClosestPoint(navMap, candidate);
                if (closest.DistanceTo(playerPos) >= 5f) // ensure at least 5 units away
                {
                    // Check line of sight
                    var query = new PhysicsRayQueryParameters3D();
                    query.From = playerPos;
                    query.To = closest;
                    query.CollisionMask = 1; // Adjust mask for obstacles
                    var result = monster.GetWorld3D().DirectSpaceState.IntersectRay(query);
                    if (result.Count == 0)
                    {
                        // Direct line of sight, reject
                        continue;
                    }
                    else
                    {
                        // Blocked by obstacle, good
                        monster.GlobalPosition = closest;
                        // Reset navigation target to current position to avoid immediate movement
                        monster.NavigationAgent.TargetPosition = closest;
                        return;
                    }
                }
            }

            // If no good point found, teleport to a random point on the map
            Vector3 randomPoint = NavigationServer3D.MapGetRandomPoint(navMap, 1, false);
            monster.GlobalPosition = randomPoint;
            monster.NavigationAgent.TargetPosition = randomPoint;
        }
    }
}
