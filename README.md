# PFRPG Ammunition Manager
This extension aids in tracking whether some ranged weapons are loaded and assists in ammo tracking for all ranged weapons.

# Features
* Adds a checkbox to the left of the ammo label on the weapons section of the actions tab; this checkbox is only shown for some weapons (those with 'firearm', 'crossbow', 'javelin', 'ballista', 'windlass', 'pistol', 'rifle', or 'loadaction' in the weapon name). Loading these weapon will post a message to chat to help monitor the action-economy. Attacks attempted with these weapons without loading first will post a message to chat.

* Double-clicking the ammo limit field will reload the quiver/magazine/etc from the inventory item selected on the weapon details screen and decrement the quantity appropriately.

* For weapons that have their max ammo set to a number above 0, attacking will mark-off ammunition automatically. Attacking with these weapons will post to chat if there is no ammunition available or if the final arrow is used.

* Ranged attacks that miss will now increment a per-weapon counter. If you open the weapon details page from the actions tab, you can now enter a percentage of missed arrows to recover. Double-clicking on this percentage will add those arrows back to the quiver.

* An "INFAMMO" effect negates the counting of used ammo and missed shots (as per rules for Abundant Ammunition).

* Attack success/failure messages (range, melee, cmb, etc) for attack rolls will now also include a [BY 5+, 10+, etc] tag (for bull rush and such where there are tiers of success for each 5 that you exceed/fail the defensive stat).

* If used with my [Item Durability](https://github.com/bmos/FG-PFRPG-Item-Durability) extension, natural 1s rolled with a weapon with "fragile" in the properties field will be broken automatically. If the weapon is already broken, the weapon will be destroyed instead.

# Compatibility and Instructions
This extension has been tested with [FantasyGrounds Unity](https://www.fantasygrounds.com/home/FantasyGroundsUnity.php) 4.1.4 (2021-06-08).

This extension works with the 3.5E, PFRPG, SFRPG, and 4E rulesets.

# Video Demonstration (click for video)
[<img src="https://i.ytimg.com/vi_webp/ORv6Ild71ek/hqdefault.webp">](https://www.youtube.com/watch?v=ORv6Ild71ek)
