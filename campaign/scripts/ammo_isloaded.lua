-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onClickRelease(target, button, image, ...)
	local rActor = ActorManager.resolveActor(getDatabaseNode().getChild('....'));
	local nodeWeapon = window.getDatabaseNode();

	local nMaxAmmo = DB.getValue(nodeWeapon, 'maxammo', 0)
	local nMaxAttacks = nMaxAmmo - DB.getValue(nodeWeapon, 'ammo', 0)

	if (getValue() == 0) and nMaxAttacks >= 0 then
		local sWeaponName = string.lower(DB.getValue(nodeWeapon, 'name', 'ranged weapon'));
		ChatManager.Message(string.format(Interface.getString('char_actions_load'), sWeaponName), true, rActor)
	end
end
