extends Node

# signals with no comment do not send any data.

signal player_respawning
signal player_damaged
signal pause # true/false
signal checkpoint # global_transform.origin of checkpoint, to be refined later.
signal jewel_count_changed
