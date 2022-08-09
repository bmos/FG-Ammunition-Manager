[![Build FG-Usable File](https://github.com/bmos/FG-Ammunition-Manager/actions/workflows/create-ext.yml/badge.svg)](https://github.com/bmos/FG-Ammunition-Manager/actions/workflows/create-ext.yml) [![Luacheck](https://github.com/bmos/FG-Ammunition-Manager/actions/workflows/luacheck.yml/badge.svg)](https://github.com/bmos/FG-Ammunition-Manager/actions/workflows/luacheck.yml)

# Ammunition Manager
This extension aids in tracking whether some ranged weapons are loaded and assists in ammo tracking for all ranged weapons.

# Compatibility and Instructions
This extension has been tested with [FantasyGrounds Unity](https://www.fantasygrounds.com/home/FantasyGroundsUnity.php) 4.2.2 (2022-06-07).

This extension works with the 3.5E, PFRPG, SFRPG, 4E, and 5E rulesets.

# Features
* Adds a checkbox to the left of the ammo label on the weapons section of the actions tab; this checkbox is only shown for some weapons (those with 'firearm', 'crossbow', 'javelin', 'ballista', 'windlass', 'pistol', 'rifle', or 'loadaction' in the weapon name). Loading these weapon will post a message to chat to help monitor the action-economy. Attacks attempted with these weapons without loading first will post a message to chat and the attack will not go through. If you want to disable this on a per-weapon basis, add the weapon property 'noload.'

* Opening the weapon details page from the actions tab will allow swapping between ammo types. When an ammo type is selected here it will hide the normal ammo tracker and use the inventory count directly.

* Attacking will mark-off ammunition automatically. Messages will post to chat if there is no ammunition available or if the final arrow is used.

* Ranged attacks that miss will now increment a per-ammo-type counter. If you open the weapon details page from the actions tab, you can now enter a percentage of missed arrows to recover. Clicking the green circle with + symbol will add this percentage of missed arrows back to the quiver.

* An "INFAMMO" effect negates the counting of used ammo and missed shots (as per rules for Abundant Ammunition).

* Attack success/failure messages (range, melee, cmb, etc) for attack rolls will now also include a [BY 5+, 10+, etc] tag (for bull rush and such where there are tiers of success for each 5 that you exceed/fail the defensive stat).

* If used with my [Item Durability](https://github.com/bmos/FG-PFRPG-Item-Durability) extension for Pathfinder and 3.5E, natural 1s rolled with a weapon with "fragile" in the properties field will be broken automatically. If the weapon is already broken, the weapon will be destroyed instead.

* If used with [Advanced Effects for Pathfinder and 3.5E](https://forge.fantasygrounds.com/shop/items/33/view) or [5E Advanced Effects](https://forge.fantasygrounds.com/shop/items/68/view), "Action Only" effects attached to equipped ammmunition used in an attack will be included in the roll.
This allowed things like "Magic Arrow; ATK: 1 enhancement" to be added to the arrow effects list and it will only be used to modify the attack when the archer uses **those** arrows (even if those arrows are equipped constantly in the inventory).

* Enabling the "Chat: Show weapon name in results" option will add the weapon name to attack results in chat such as "Attack [16] -> [at Goblin] with Shortsword [HIT]" instead of "Attack [16] -> [at Goblin] [HIT]".

* NOTE: Some modules contain entries like "Arrows (20)". If you have quantity 1 of "Arrows (20)" and select this as your weapon, it will reduce you to quantity 0 of "Arrows (20)". You should instead (in this example) change it to quantity 20 of "Arrow" and divide the weight by 20 as well. I'm not sure why the module authors often ignore this detail, but this is how to work around it.

# Video Demonstration (click for video)
[<img src="https://i.ytimg.com/vi_webp/i_vmW9WVkbM/hqdefault.webp">](https://www.youtube.com/watch?v=i_vmW9WVkbM)
# Video Demonstration - Starfinder (click for video)
[<img src="https://i.ytimg.com/vi_webp/b-zeWXdpPXM/hqdefault.webp">](https://www.youtube.com/watch?v=b-zeWXdpPXM)
