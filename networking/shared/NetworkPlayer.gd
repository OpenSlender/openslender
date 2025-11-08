extends RefCounted
class_name NetworkPlayer

## Represents a networked player in the game
## This class stores basic information about a player in a multiplayer session

var peer_id: int
var player_name: String = ""
var position: Vector3 = Vector3.ZERO
var rotation: Vector3 = Vector3.ZERO
var connected_at: int = 0

func _init(id: int = -1) -> void:
	peer_id = id
	connected_at = Time.get_ticks_msec()

func to_dict() -> Dictionary:
	return {
		"peer_id": peer_id,
		"player_name": player_name,
		"position": position,
		"rotation": rotation,
		"connected_at": connected_at
	}

static func from_dict(data: Dictionary) -> NetworkPlayer:
	var player = NetworkPlayer.new()
	player.peer_id = data.get("peer_id", -1)
	player.player_name = data.get("player_name", "")
	player.position = data.get("position", Vector3.ZERO)
	player.rotation = data.get("rotation", Vector3.ZERO)
	player.connected_at = data.get("connected_at", 0)
	return player
