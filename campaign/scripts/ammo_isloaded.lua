-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onClickRelease(target, button, image, ...)
	local rActor = ActorManager.resolveActor(getDatabaseNode().getChild('....'));
	local nodeWeapon = window.getDatabaseNode();

	local nAmmo, bInfiniteAmmo = AmmunitionManager.getAmmoRemaining(rActor, nodeWeapon, AmmunitionManager.getAmmoNode(nodeWeapon, rActor))

	if (getValue() == 0) and (bInfiniteAmmo or nAmmo > 0) then
		local sWeaponName = string.lower(DB.getValue(nodeWeapon, 'name', 'ranged weapon'));
		ChatManager.Message(string.format(Interface.getString('char_actions_load'), sWeaponName), true, rActor)
	end
end
