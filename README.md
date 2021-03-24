# PFRPG Ammunition Manager
This extension aids in tracking whether some ranged weapons are loaded and assists in ammo tracking for all ranged weapons.
To do this, it adds a checkbox to the left of the ammo label on the weapons section of the actions tab; this checkbox is only shown for some weapons (those with 'firearm', 'crossbow', 'javelin', 'ballista', 'windlass', 'pistol', 'rifle', or 'loadaction' in the weapon name).
Loading these weapon will post a message to chat to help monitor the action-economy.
Attacks made with these weapons without loading first will post a message to chat.

Furthermore, for weapons that have their max ammo set to a number above 0, attacking will mark-off ammunition automatically.
Attacking will post to chat if there is no ammunition available or if the final arrow is used.

Ranged attacks that miss will now increment a per-weapon counter.
If you open the weapon details page from the actions tab, you can now enter a percentage of missed arrows to recover.
Double-clicking on this percentage will add those arrows back to the quiver.

An "INFAMMO" effect negates the counting of used ammo and missed shots (as per rules for Abundant Ammunition).

Any attack success/failure messages (range, melee, cmb, etc) for attack rolls will now also include by how much (for bull rush and such where there are tiers of success for each 5 that you exceed/fail the defensive stat).

# Compatibility and Instructions
This extension has been tested with [FantasyGrounds Unity](https://www.fantasygrounds.com/home/FantasyGroundsUnity.php) 4.0.10 (2021-02-04). It works with the 3.5E, PFRPG, and 4E rulesets.

# Video Demonstration (click for video)
[<img src="https://i.ytimg.com/vi_webp/svmaG5UvHlI/hqdefault.webp">](https://www.youtube.com/watch?v=svmaG5UvHlI)
