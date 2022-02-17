-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function action(draginfo)
	local rActor, rAttack = CharManager.getWeaponAttackRollStructures(window.getDatabaseNode());
	rAttack.modifier = getValue();
	rAttack.order = tonumber(string.sub(getName(), 7)) or 1;

	local nodeWeapon = window.getDatabaseNode();
	local nAmmo, bInfiniteAmmo = AmmunitionManager.getAmmoRemaining(rActor, nodeWeapon, AmmunitionManager.getAmmoNode(nodeWeapon, rActor))

	if (bInfiniteAmmo or nAmmo > 0) then
		ActionAttack.performRoll(draginfo, rActor, rAttack);
		return true;
	end
end
function onDoubleClick(x,y)
	if not window.automateAmmo(window.getDatabaseNode()) then return action(); end
end