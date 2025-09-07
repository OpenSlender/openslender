using Godot;

namespace OpenSlender
{
	[GlobalClass]
	public partial class PlayerSettings : Resource
	{
		[Export] public float WalkSpeed { get; set; } = 5.0f;
		[Export] public float RunSpeed { get; set; } = 8.0f;
		[Export] public float CrouchSpeed { get; set; } = 2.5f;
		[Export] public float JumpVelocity { get; set; } = 4.5f;
		[Export] public float MouseSensitivity { get; set; } = 0.25f;

		[Export(PropertyHint.Range, "-90,90,1")] public float MaxPitchDegrees { get; set; } = 80.0f;
		[Export(PropertyHint.Range, "0,1,0.01")] public float CrouchHeightRatio { get; set; } = 0.7f;
		[Export] public float CrouchCameraHeight { get; set; } = -0.3f;
		[Export] public float CameraTransitionSpeed { get; set; } = 8.0f;
		[Export(PropertyHint.Range, "0,1,0.01")] public float InputThresholdSquared { get; set; } = 0.1f;
		[Export] public float IdleStopDampingMultiplier { get; set; } = 5.0f;
		[Export] public float CrouchStopDampingMultiplier { get; set; } = 5.0f;
		[Export] public float LandingStopDampingMultiplier { get; set; } = 3.0f;

		[Export] public float JumpNoInputDampingFactor { get; set; } = 0.5f;
		[Export] public float FallNoInputDampingFactor { get; set; } = 0.3f;

		[Export] public float JumpDesiredSpeedFactor { get; set; } = 0.7f;
		[Export] public float FallDesiredSpeedFactor { get; set; } = 0.6f;
		[Export] public float AirSpeedLerpRate { get; set; } = 2.0f;
		[Export] public float AirControlAcceleration { get; set; } = 10.0f;
		[Export] public double LandingDuration { get; set; } = 0.1;
	}
}


