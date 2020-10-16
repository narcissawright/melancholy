extends Resource

# AABB Data
export var aabb_array:Array # contains a list of bounding boxes that surround areas where grass exists.
export var aabb_offsets:Array # how far do you jump to reach the data (in path_collision_img) for the AABB
export var aabb_tex:ImageTexture

# Image Data
export var path_collision_img:Image
export var path_collision_tex:ImageTexture
