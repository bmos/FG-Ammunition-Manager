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
	
	-- Perform action
	local rActor = ActorManager.resolveActor(nodeChar);
	local nMaxAmmo = DB.getValue(nodeWeapon, 'maxammo', 0)
	local nMaxAttacks = nMaxAmmo - DB.getValue(nodeWeapon, 'ammo', 0)
	if not (nMaxAmmo > 0) or (nMaxAttacks >= 1) then	
		ActionAttack.performRoll(draginfo, rActor, rAction);
		return true;
	else
		ChatManager.Message(Interface.getString("char_message_atkwithnoammo"), true, rActor);
	end
end