--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
--	luacheck: globals action getValue getName onDoubleClick
function action(draginfo)
	local rActor, rAttack = CharManager.getWeaponAttackRollStructures(window.getDatabaseNode());
	rAttack.modifier = getValue();
	rAttack.order = tonumber(string.sub(getName(), 7)) or 1;

	local nodeWeapon = window.getDatabaseNode();
	local nAmmo, bInfiniteAmmo = AmmunitionManager.getAmmoRemaining(rActor, nodeWeapon, AmmunitionManager.getAmmoNode(nodeWeapon))

	if (bInfiniteAmmo or nAmmo > 0) then
		ActionAttack.performRoll(draginfo, rActor, rAttack);
		return true;
	end
end

--	luacheck: globals onDoubleClick
function onDoubleClick() if not window.automateAmmo(window.getDatabaseNode()) then return action(); end end
