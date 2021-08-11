-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onButtonPress()
	local rActor = ActorManager.resolveActor(getDatabaseNode().getChild('....'));
	local nodeWeapon = window.getDatabaseNode();
	local sWeaponName = string.lower(DB.getValue(nodeWeapon, 'name', 'ranged weapon'));

	local nMaxAmmo, nMaxAttacks
	local nodeAmmo = AmmunitionManager.isAmmoPicker(nodeWeapon, rActor)
	if not nodeAmmo then
		nMaxAmmo = DB.getValue(nodeWeapon, 'maxammo', 0)
		nMaxAttacks = nMaxAmmo - DB.getValue(nodeWeapon, 'ammo', 0)
	else
		nMaxAmmo = DB.getValue(nodeAmmo, 'count', 0) + 1
		nMaxAttacks = DB.getValue(nodeAmmo, 'count', 0)
	end

	if (getValue() == 1) and nMaxAttacks >= 0 then
		ChatManager.Message(string.format(Interface.getString('char_actions_load'), sWeaponName), true, rActor)
	end
end
