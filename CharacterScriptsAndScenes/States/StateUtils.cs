using Godot;

namespace OpenSlender.States
{
    public static class StateUtils
    {
        public static readonly float Gravity = (float)ProjectSettings.GetSetting("physics/3d/default_gravity");
    }
}


