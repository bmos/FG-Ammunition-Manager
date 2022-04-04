--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--

--	luacheck: globals onReloadAction
function onReloadAction()

	local function reduceItemCount(nodeWeapon, nAmmo)
	
		local function getWeaponUsage(nodeWeapon)
			local _, sShortcut = DB.getValue(nodeWeapon, 'shortcut', '');
			if sShortcut and sShortcut ~= '' then
				local nodeLinkedWeapon = DB.findNode(sShortcut)
				if nodeLinkedWeapon then return DB.getValue(nodeLinkedWeapon, 'usage', 1) end
			end
			return 1
		end
	
		local nodeAmmo = AmmunitionManager.getAmmoNode(nodeWeapon)
		if nodeAmmo then
			local nCount = DB.getValue(nodeAmmo, 'count', 0)
			if (nAmmo > 0) and (nCount > 0) then
				local nUsage = getWeaponUsage(nodeWeapon)
				local nReload = nCount - nAmmo * nUsage
				if nReload > 0 then
					DB.setValue(nodeWeapon, 'ammo', 'number', 0)
					DB.setValue(nodeAmmo, 'count', 'number', nReload)
				else
					local nAvailableUses = math.floor(nCount / nUsage)
					DB.setValue(nodeWeapon, 'ammo', 'number', nAmmo - nAvailableUses)
					DB.setValue(nodeAmmo, 'count', 'number', nCount - nAvailableUses * nUsage)
				end
			end
		end
	end

	local nodeWeapon = getDatabaseNode();
	local rActor, _ = CharManager.getWeaponAttackRollStructures(nodeWeapon);

	local nAmmo = DB.getValue(nodeWeapon, 'ammo', 0);
	local nUses = DB.getValue(nodeWeapon, 'uses', 0);
	if nAmmo > 0 then
		if nUses == 1 then
			ChatManager.Message(Interface.getString('char_message_ammodrawn'), true, rActor);
			reduceItemCount(nodeWeapon, nAmmo);
		else
			ChatManager.Message(Interface.getString('char_message_reloadammo'), true, rActor);
			reduceItemCount(nodeWeapon, nAmmo);
		end
	else
		ChatManager.Message(Interface.getString('char_message_ammofull'), true, rActor);
	end

	return true;
end
