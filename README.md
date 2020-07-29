# Melancholy (not final title)
3D game project (Godot Engine)

## Two Characters
- Melanie
- Melancholy

Kind of like Castlevania N64. Aiming for ~10 main stages per character. Some fully unique, some shared, some altered.

## Melanie - Sword & Shield

- Naturally Sprints when holding joystick fully (3s to build to full speed, subtle). 8-10 speed.
- Has a big shield. Shield put-away takes time. flicking the button results in shield bash.
- Primary Attack - Sword (this could end up complex, maybe just 2 of these for now, and an air version)
- Secondary Attack (maybe I don't need this but I might have this too), can be used in air
- Subweapons. All require the same ammo type (jewels or whatever)
1. Bombs: Bomb Pull (happens quickly), Bomb Throw (also fast). Throw distance may vary if you are targeting something. Big hitbox
2. HolyWater ripoff item: Big damage for innermost (smallest) hitbox. 
3. Bow & Arrow: Manual aiming (1st person?), targeted aiming (3rd person)
4. Unknown 4th subweapon. TBD
- Jumping. Variable Jump Height. Leniency when falling off a ledge.
- Landing. Fall dmg. Impact landing etc.
- Ledgegrab. Ledgecrawl (left or right), Ledgeclimb. Ledge release.
- Crawl (crouch while not moving). Slide attack (crouch while running). Divekick (crouch while in air)
- First person view
- Damaged (mobile, immobile, knockdown). Dying.
- Swimming. Drowning.
- Interacting. Opening door. Pickup item (on ground, or in front)
- Respawning.

## Melancholy - Magic & Sorcery

- Only has 1/4th the Max HP that Melanie has. Uses a magic meter instead of jewels.
- Immediately at 9 speed while holding joystick fully. Glides across the ground instead of runs.
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

## Targeting system:
- basically like Zelda, hold ZL to target stuff. Aligns with wall, resets camera, etc.

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
- Try to keep a bit of "arcade scenario" -- gameplay design focused levels, but not too arcadey. Ideally each stage is minutes (3-15) long if you know what you're doing.
- Checkpoints exist.

## Power Ups
- Five Levels of Primary weapon power. Obtaining a powerup item will level you up.
- Color scheme should be dull red -> yellow -> green -> cyan -> piercing blue
- Lose 1 stage of power upon death.
- Melancholy will lose 1 stage of power upon Magic Meter being fully used. (Will refill immediately if not at powerup lvl 1)

## Shop
- Should this exist?
- Power Ups
- Subweapons
- Keys
- Time Change
- Maybe status cure if that exists
- Health

## "Score" / XP / RNG system
- Gimmick! (NES) had a score system that accounted for all drops. I want to use a system like this to avoid RNG.
Only issue is if it is hidden, then it becomes very difficult to "resync" yourself. so it would have to be shown somehow...

## Time of Day
- Melanie is strongest at noon, Melancholy strongest at midnight.
- Different events may happen depending on the time of day.

## Story Stuff
- Melanie becomes Melancholy at end of full game. A trascendent moment. A pensive sadness, and a new purpose.