-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

local function reduceItemCount(nodeWeapon, rActor, nAmmo)
	local nodeAmmo = AmmunitionManager.getAmmoNode(nodeWeapon, rActor);
	if nodeAmmo then
		local nCount = DB.getValue(nodeAmmo, "count", 0)

		if (nAmmo > 0) and (nCount > 0) then
			local nReload = (nCount - nAmmo)
			if nReload > 0 then
				DB.setValue(nodeWeapon, "ammo", 'number', 0)
			else
				DB.setValue(nodeWeapon, "ammo", 'number', nAmmo - nCount)
			end
		end
	end
	DB.setValue(nodeAmmo, "count", 'number', 0)
end

function onReloadAction(draginfo)
	local nodeWeapon = getDatabaseNode();
	local nodeChar = nodeWeapon.getChild("...")
	local rActor, rAttack = CharManager.getWeaponAttackRollStructures(nodeWeapon);						
	local nAmmo = DB.getValue(nodeWeapon, "ammo",0);
	local nUses = DB.getValue(nodeWeapon, "uses",0);	
	if nAmmo > 0 then
		if nUses == 1 then
			ChatManager.Message(Interface.getString("char_message_ammodrawn"), true, rActor);
			reduceItemCount(nodeWeapon, rActor, nAmmo);
		else
			ChatManager.Message(Interface.getString("char_message_reloadammo"), true, rActor);
			reduceItemCount(nodeWeapon, rActor, nAmmo);
		end
	else 
		ChatManager.Message(Interface.getString("char_message_ammofull"), true, rActor);
	end


	return true;
end