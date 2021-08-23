-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onAttackAction(draginfo)
	local nodeWeapon = getDatabaseNode();
	local nodeChar = nodeWeapon.getChild("...")

	-- Build basic attack action record
	local rAction = CharWeaponManager.buildAttackAction(nodeChar, nodeWeapon);

	-- Decrement ammo
	-- CharWeaponManager.decrementAmmo(nodeChar, nodeWeapon);

	-- bmos removing redundant ammo counting
	-- for compatibility with ammunition tracker, make this change in your char_weapon.lua
	-- this if section replaces the commented out line above: "CharWeaponManager.decrementAmmo(nodeChar, nodeWeapon);"
	if not AmmunitionManager then
		CharWeaponManager.decrementAmmo(nodeChar, nodeWeapon);
	end
	-- end bmos removing redundant ammo counting

	-- Perform action
	local rActor = ActorManager.resolveActor(nodeChar);
	-- ActionAttack.performRoll(draginfo, rActor, rAction);
	-- return true;

	-- bmos only allowing attacks when ammo is sufficient
	-- for compatibility with ammunition tracker, make this change in your char_weapon.lua
	-- this if section replaces the two commented out lines above:
	-- "ActionAttack.performRoll(draginfo, rActor, rAction);" and "return true;"
	local nMaxAmmo = DB.getValue(nodeWeapon, 'maxammo', 0)
	local nMaxAttacks = nMaxAmmo - DB.getValue(nodeWeapon, 'ammo', 0)
	if not AmmunitionManager or (not (nMaxAmmo > 0) or (nMaxAttacks >= 1)) then	
		ActionAttack.performRoll(draginfo, rActor, rAction);
		return true;
	else
		ChatManager.Message(Interface.getString("char_message_atkwithnoammo"), true, rActor);
	end
	-- end bmos only allowing attacks when ammo is sufficient
end