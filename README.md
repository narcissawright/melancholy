# Melancholy (not final title)

- 3D game project (Godot Engine)
- Kind of like Castlevania N64 (structured levels) with some Zelda-ish mechanics (Z-Targeting) sprinkled in?

## Two Characters

- Melanie. Uses Sword & Shield. More "Link-like."
- Melancholy. Uses sorcery. More "Carrie-like."

## Melanie - Sword & Shield - in-progress

3D modeling and animations are in progress, but it is a long and slow process. 

#### `Completed Mechanics:`
- Naturally sprints when holding joystick fully (3s to build to full speed, subtle increase).
- Jumping. Variable Jump Height. Leniency when falling off a ledge.
- Impact landing. Landing from a height will result damage or being unable to move for a time.
- Shielding. Melanie has a big shield. She moves slower with the shield up. The shield bounces projectiles off. 
- Shield bash. Quickly releasing and re-pressing results in a shield bash. Reflects projectiles w/ higher velocity.
- Subweapon: Bombs. Pull bomb (hold overhead). Cannot pull while area above head is blocked. Can throw bombs. Bombs explode on impact. Bomb will drop if damaged or if you shield. Shielding a bomb will give you shield knockback but no damage. Getting hit by a bomb directly can boost you, but does damage.

#### `Partially Done`
- Damaged. All damage right now simply locks you for a certain amount of frames. Would like to add other kinds of damage maybe. There is no death animation or anything yet.
- Interacting. Item pickup is functional (no animation).

#### `To Do`
- Proper movement & physics on slopes and small ledges
- Sword (Primary Attack). Sword draw, sword slash, heavy sword slash, air slash, put away.
- Subweapon: Bow & Arrow. Manual aiming, targeted aiming. Think Link from OoT
- Additional Subweapons.
- Ledge grab. Ledge movement (left or right), Ledge climb. Ledge release.
- Crouch. Crouch movement. Slidekick (crouch while running). Divekick (crouch while in air)
- Respawn animation.
- Power up system.

#### `Maybe`
- Sword clank mechanic.
- Secondary Attack. (Does Melanie need this? Melancholy does...)


## Melancholy - Magic & Sorcery

#### `Progress: 0%`

- Only has 1/4th the Max HP that Melanie has. Uses a magic meter instead of jewels. `Might not use a meter actually...?`
- Immediately at her top grounded speed (slightly slower than Melanie's top grounded speed) while holding joystick fully. Glides across the ground instead of sprinting.
- Has a bubble shield. Can absorb jewels (subweapon ammo) from afar.
- Primary Attack - Orb (charge attack, can charge while doing any action. Lose charge upon damage). Only 1 Orb may be present at a time. Orb is a seeking projectile when charged.
- Secondary Attack - (not fleshed out, but definitely some very weak close range attack).
- Spells instead of subweapons. `Maybe. I guess.` Jewels get converted into mana (magic meter, exclusive mechanic)
1. Lightning - Attacks all enemies nearby. If no enemies nearby, attacks you instead.
2. Beam - big laser projectile, aimable in any direction. Some kind of teleport mechanic to travel along the beam.
3. Airwalker - stand in mid air as if it is solid ground. Each step costs mana. Can jump from the air.
4. Tree - summon a tree from the earth. Massive damage and knockback. Can be cut down via lightning. May spawn health apples.
5. Vitriol - I might replace Tree with this actually. Holy water item. Maybe damages you upon use.
- Repeatedly jumping can gain more speed. Sort of like traveling on a sine-wave, she can re-jump close to the ground w/o touching it directly and curve back upwards. Has a unique mechanic that allows her to airjump when tapping Jump at ledgegrab height.
- Maybe the same landing mechanics as Melanie but with the ability to curb your fall dmg with a landing "jump"
- Ledgegrab same as Melanie
- Crawl same as Melanie. Use belly slide attack instead of slide kick. No divekick from air, rather fall straight down very rapidly?
- First person view same as Melanie.
- Same damaged states, swimming states, interacting states, respawning state.


## Camera & Targeting system:

#### `Completed:`
- Right stick for free cam (rotate to any position)
- Hold ZL to target stuff. While targeting, the player faces the target. The camera pans to show both yourself and the target. Sprinting is not possible while targeting, and all directions of movement other than forward become slower.
- When there is nothing to target, pressing ZL will move the camera to the default position. If you're hugging the wall during this, your character becomes aligned with the wall normal. 
- Retarget: If you are targeting something and release and repress, it will change to the next most relevant target.
- Pause Mode: Press + to pause the game. Left stick pans the camera. X and A to zoom.
- Autocamera: When the player is moving left or right relative to the camera, the camera will automatically rotate towards the back of the player. This won't happen if you've used the right stick for free cam.
- 1st person view. Press R3 to initiate. Automatically puts away shield, drops bomb. If you take damage, leaves first person.

#### `Low Priority:`
- Autocamera should peer down if you're standing near a high ledge.
- Autocamera should rotate to a higher position while the player is falling
- Pause Cam should allow you to slide the pan position across solid surfaces.


## User Interface:

#### `Done`
- Heart symbol, with a heart beat animation, normal map, and time of day lighting.
- Functional HP bar
- Jewel count
- Clock (Time of day)
- Joystick Calibration screen

#### `Partially done`:
- Current subweapon
- Powerup container (5 orbs, should look like they are energized.)
- Contextual button hints (X to interact)
- Button Remap screen (non functional atm but the design is partially there. has input display.)
- Items

#### `To do`
- Speedrun timer
- Serendipity
- More pause menu features: Camera axis invert, Camera distance setting.

#### `Maybe`
- Current camera mode indicator
- Boss health

## Other Mechanics and Features:

##### Time of day system
- Melanie is strongest at noon, Melancholy strongest at midnight.
- Certain events or enemies may only exist at certain times.
- Item to change time of day rapidly. (Sun Card / Moon Card)

##### Power Ups
- Five Levels of Primary weapon power. Obtaining a powerup item will level you up.
- Color scheme should be dull red -> yellow -> green -> cyan -> piercing blue
- Lose 1 stage of power upon death.
- Melancholy will lose 1 stage of power upon Magic Meter being fully used. (Will refill immediately if not at powerup lvl 1)

##### Serendipity system.
- Gimmick! (NES) had a score system that accounted for all drops. I want to use a system like this to avoid RNG. Essentially it is a predictable generator of numbers that are used for all "random" events. A good player could utilize this to their advantage. It must be visible or "readable" somehow while playing so you can re-sync yourself if you end up with the wrong value.

##### Items
- Healing items. Green apples, other stuff.

#### `Would like to add`

- Dynamic grass, grass trampling, desire paths saved to a file on hard drive.

#### `Maybe?`
- Swimming
- Ladder climb
- Stairs
- Shop
- Keys
- Status (Poisoned etc)
- Double Jump
- Wall Jump


## First Area: Field of Falling Stars
#### `Progress: 0%`
- Sort of a Menu World / playground. Has all the geometry needed for testing mechanics.
- Unlock stuff here as you progress in the game
- Peaceful music, a safe area
- Could have a semi transparent hexagonal or triangular boundary at the edge of the world like you're encased in a glass dome or something.
- you should spawn from a falling star(?) and it should happen rather quickly
- May proceed to the actual Full Game from this area.
- Eventually unlock wardrobe. 
- Unlock Melancholy by completing Full Game w/ Melanie.
- Separate time trials for each character, to be expanded upon later.

## Stages:
#### `Progress: 0%`
- Aiming for ~10 main stages per character. Some fully unique, some shared, some altered.
- Try to keep a bit of "arcade scenario" -- gameplay design focused levels, but not too arcadey. Ideally each stage is minutes (3-15) long if you know what you're doing.
- Checkpoints exist. 
- Secret exits exist (taking you to secret levels)
- Secret Exit in level 1 should involve going out of your way to find bomb subweapon, then heading back to beginning to bomb boost yourself up to higher ledge. Bombs should also allow you to blow open certain breakable walls and obtain powerups etc.
- There needs to be a level with 3 "laps" that are each somewhat different. I need to think about this level's structure more. but it is gonna happen.
- There needs to be a typical ice level with slippery sections.
- Some subweapons could be stage-specific. Like a level with a grappling hook that you can swing from.

## Character Design:
- Melanie should have shorter hair than Melancholy. Neither character will have bangs.
- The hair covering Melanie's eye should not cover it much. Melancholy will have her eye more obscured.
- Would like to include a Cardigan for Melanie but would need to figure out the state of cloth simulation in Godot, and my GPU is old right now.
- Melancholy should have a dress or medium length skirt. Might keep same boots (I like this design, but perhaps black instead of brown). Unsure about other aspects of the outfit. Leggings/Tights probably good for both.
- Melanie will have plum colored hair, Melancholy a blue color. The eye color should be different, too.
- Melancholy's heartbeat should be slower (seen in the UI).
- Melancholy should have slight "raccoon eyes," and look more tired and pale.


## Current Limitations

#### Clean line shader

I wanted to make clean outlines (and inner lines) using combined depth+normals of the entire scene. right now getting this in a shader requires you to do a really complicated 2nd pass where everything renders only their normals first, I guess. it's annoying and bad. so hopefully Vulkan in Godot 4 will allow this kind of stuff. BUT, actually GDQuest released an interesting technique in the "Shader secrets" project. It also uses a 2nd pass shader but the lines came out cleaner than I imagined without having the normal data. So it might still be doable now, but it's not a priority.

#### Inverse Kinematics

IK can be achieved though animations that are exported, but having dynamic IK in-game (for sloped ground, etc), doesn't seem plausible with the current state of SkeletonIK. I will avoid this until SkeletonIK in Godot is much improved.

#### Modeling, Animations, and Importing

I feel like I need to write down some of the things I've learned after trying to get my 3D character working in Godot. 

- You can make complex rigs with control bones, etc for animation in Blender. The animations will still come through, although the constraints and controls will not. Any kind of constraint or control (such as giving the eyes a look target, or the head a look target), needs to be created entirely in Godot (once you have confirmed that the head or eyes are cleanly capable of rotation in blender)

- Preserve Volume in the Armature modifier does not exist in Godot; therefore all deformations will ignore this option. This means making clean deformations is more difficult, but you can still get 1:1 deformations afaik as long as you do not enable this.

- Inherit Rotation, under an individual bone setting, must remain on. Disabling this will be ignored in Godot, and the animations will be incorrect. I don't believe that "Bake animation" will help with these issues either. Unfortunately, forcing inherited rotation makes certain aspects of animation more difficult, like keeping a foot flat on the ground as the shin moves and rotates.

- GLTF works for now. I haven't explored other new options (such as the somewhat recent FBX support).

- Writing an import script for complex models is helpful, as you can set all the needed materials, set up lighting etc. the moment the import occurs.

- Currently, my animations import but the keyframes don't seem identical, and are set at a fixed interval (every tenth of a second). I don't know how to avoid this, perhaps making the animation a lot slower or spacing out the keyframes more in blender, then playing the animation faster in Godot. Currently this hasn't really resulted in a loss of animation quality though so far, so maybe this is a non-issue. 

- Vertex Colors in shader. These come through already in SRGB form afaik, so when you read COLOR in a shader, something like 0.5 red in blender will turn into ~0.23 or something. This is very awkward for "Occlusion painting" as seen in the GGXrd graphical presentation, but it can certainly be worked around.