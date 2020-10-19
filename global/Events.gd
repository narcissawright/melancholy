extends Node

# signals with no comment do not send any data.

signal respawn
signal player_damaged
signal pause # true/false
signal checkpoint # global_transform.origin of checkpoint, to be refined later.
signal jewel_count_changed
signal current_subweapon_changed
signal jewel_cost_too_high
signal error_no_subweapon
signal path_collision # position:Vector3, velocity_length:float
signal debug_view # true/false
signal grass_data_reset
signal unpause_game
signal quit_game
