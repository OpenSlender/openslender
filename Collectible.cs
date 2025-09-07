using Godot;
using System;

public partial class Collectible : Area3D
{
    [Export] public bool OneShot { get; set; } = true;
    [Export] public NodePath MeshNodePath;
    private bool _collected = false;

    private MeshInstance3D _meshInstance;
    private MeshInstance3D _outlineInstance;

    public override void _EnterTree()
    {
        AddToGroup("collectible");
    }

    public override void _Ready()
    {
        _meshInstance = GetNodeOrNull<MeshInstance3D>(MeshNodePath);
        if (_meshInstance == null)
        {
            _meshInstance = GetNodeOrNull<MeshInstance3D>("MeshInstance3D");
        }

        CreateOutlineIfMissing();
    }

    private void CreateOutlineIfMissing()
    {
        if (_outlineInstance != null || _meshInstance == null || _meshInstance.Mesh == null)
        {
            return;
        }

        _outlineInstance = new MeshInstance3D();
        _outlineInstance.Mesh = _meshInstance.Mesh;

        var outlineMaterial = new StandardMaterial3D();
        outlineMaterial.AlbedoColor = Colors.White;
        outlineMaterial.EmissionEnabled = true;
        outlineMaterial.Emission = Colors.White;
        outlineMaterial.ShadingMode = BaseMaterial3D.ShadingModeEnum.Unshaded;
        outlineMaterial.CullMode = BaseMaterial3D.CullModeEnum.Front;

        _outlineInstance.MaterialOverride = outlineMaterial;
        _outlineInstance.CastShadow = GeometryInstance3D.ShadowCastingSetting.Off;
        _outlineInstance.Scale = new Vector3(1.03f, 1.03f, 1.03f);
        _outlineInstance.Visible = false;
        AddChild(_outlineInstance);
    }

    public void SetHighlighted(bool highlighted)
    {
        if (!GodotObject.IsInstanceValid(this)) return;
        if (_outlineInstance == null)
        {
            CreateOutlineIfMissing();
        }
        if (_outlineInstance != null)
        {
            _outlineInstance.Visible = highlighted;
        }
    }

    public void TryPickup()
    {
        if (_collected) return;

        _collected = true;
        GameManager.Instance?.CollectCollectible();

        SetHighlighted(false);
        Visible = false;
        Monitoring = false;
        if (OneShot)
        {
            QueueFree();
        }
    }

}
