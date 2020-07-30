# Melancholy (not final title)

- 3D game project (Godot Engine)
- Kind of like Castlevania N64 (structured levels) with some Zelda-ish mechanics (Z-Targeting) sprinkled in?


## Two Characters

- Melanie (sword & shield)
- Melancholy (magic & sorcery)


## Melanie - Sword & Shield - in-progress
- Graphics and visual design are currently taking a backseat to working on core mechanics w/ placeholder art.

#### `Completed:`
- Naturally sprints when holding joystick fully (3s to build to full speed, subtle increase).
- Jumping. Variable Jump Height. Leniency when falling off a ledge.
- Shielding. Melanie has a big shield. She moves slower with the shield up. The shield bounces projectiles off. 

#### `Mostly Done`
- Shield bash. Quickly releasing and re-pressing results in a shield bash.
- Impact landing. Landing from a height will result damage or being unable to move for a time.

#### `To Do`
- Proper movement & physics on slopes and small ledges
- Sword (Primary Attack). Sword draw, sword slash, heavy sword slash, air slash, put away.
- Subweapons. All require the same ammo type (jewels or whatever)
1. Bombs: Bomb Pull (happens quickly), Bomb Throw (also fast). Throw distance may vary if you are targeting or moving. Big-ish hitbox.
2. HolyWater ripoff item: Big damage for innermost (smallest) hitbox. 
3. Bow & Arrow: Manual aiming (1st person?), targeted aiming (3rd person). Think Link from OoT
4. Unknown 4th subweapon. TBD

- Ledge grab. Ledge movement (left or right), Ledge climb. Ledge release.
- Crawl (crouch while not moving). Slide attack (crouch while running). Divekick (crouch while in air)
- First person view. This should interact with Bow & Arrow similarly to Zelda I guess.
- Damaged (mobile, immobile, knockdown). Dying.
- Drowning.
- Interacting. Opening door. Item pickup (on floor or in front as two diff animations?)
- Respawn animation.
- Power up system.

#### `Maybe`
- Sword clank mechanic.
- Secondary Attack. (Does Melanie need this? Melancholy does...)


## Melancholy - Magic & Sorcery

- Only has 1/4th the Max HP that Melanie has. Uses a magic meter instead of jewels.
- Immediately at her top grounded speed (slightly slower than Melanie's top grounded speed) while holding joystick fully. Glides across the ground instead of sprinting.
- Has a bubble shield. Can absorb jewels (subweapon ammo) from afar.
- Primary Attack - Orb (charge attack, can charge while doing any action. Lose charge upon damage). Only 1 Orb may be present at a time. Orb is a seeking projectile when charged.
- Secondary Attack - (not fleshed out, but definitely some very weak close range attack).
- Spells instead of subweapons. Jewels get converted into mana (magic meter, exclusive mechanic)
1. Lightning - Attacks all enemies nearby. If no enemies nearby, attacks you instead.
2. Beam - big laser projectile, aimable in any direction. Some kind of teleport mechanic to travel along the beam.
3. Airwalker - stand in mid air as if it is solid ground. Each step costs mana. Can jump from the air.
4. Tree - summon a tree from the earth. Massive damage and knockback. Can be cut down via lightning. May spawn health apples.
- Repeatedly jumping can gain more speed. Sort of like traveling on a sine-wave, she can re-jump close to the ground w/o touching it directly and curve back upwards. Has a unique mechanic that allows her to airjump when tapping Jump at ledgegrab height.
- Maybe the same landing mechanics as Melanie but with the ability to curb your fall dmg with a landing "jump"
- Ledgegrab same as Melanie
- Crawl same as Melanie. Use belly slide attack instead of slide kick. No divekick from air, rather fall straight down very rapidly?
- First person view same as Melanie.
- Same damaged states, swimming states, interacting states, respawning state.


## Camera & Targeting system:

#### `Completed:`
- Right stick for free movement.
- R3 to change zoom level.
- Hold ZL to target stuff. While targeting, the player faces the target. The camera pans to show both yourself and the target. Sprinting is not possible while targeting, and all directions of movement other than forward become slower.
- When there is nothing to target, pressing ZL will move the camera to the default position. If you're hugging the wall during this, your character becomes aligned with the wall normal. 
- Press + to pause the game, D-Pad then allows for free camera panning. 

#### `To do:`
- Target swapping: Release and repress to change target.
- Better features when paused (better control over zoom, less glitchy behavior while panning through walls etc.)
- Autocamera... I envision this as a togglable option.
1. It should naturally look in the same direction that you're going. 
2. It look down from a higher angle when approaching ledges.
3. Better avoidance of walls (avoid abruptly crashing into them.
4. Perhaps incorporate a custom zoom amount when targeting things that end up on the screen edge.


## Other Mechanics and Features:

#### `To Do`

##### Power Ups
- Five Levels of Primary weapon power. Obtaining a powerup item will level you up.
- Color scheme should be dull red -> yellow -> green -> cyan -> piercing blue
- Lose 1 stage of power upon death.
- Melancholy will lose 1 stage of power upon Magic Meter being fully used. (Will refill immediately if not at powerup lvl 1)

##### Time of day system
- Melanie is strongest at noon, Melancholy strongest at midnight.
- Certain events or enemies may only exist at certain times.
- Item or method to change time of day rapidly. (Sun Card / Moon Card)

##### "Score / XP / RNG" system.
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
- Sort of a Menu World / playground. Has all the geometry needed for testing mechanics.
- Unlock stuff here as you progress in the game
- Peaceful music, a safe area
- Could have a semi transparent hexagonal or triangular boundary at the edge of the world like you're encased in a glass dome or something.
- you should spawn from a falling star and it should happen rather quickly
- May proceed to the actual Full Game from this area.
- Eventually unlock wardrobe. 
- Unlock Melancholy by completing Full Game w/ Melanie.
- Separate time trials for each character, to be expanded upon later.

## Thoughts on the actual stages:
- Aiming for ~10 main stages per character. Some fully unique, some shared, some altered.
- Try to keep a bit of "arcade scenario" -- gameplay design focused levels, but not too arcadey. Ideally each stage is minutes (3-15) long if you know what you're doing.
- Checkpoints exist.
- One stage should have slippery ice in it. lol.

## Story Stuff
- Melanie becomes Melancholy at end of full game. A trascendent moment. A pensive sadness, and a new purpose.