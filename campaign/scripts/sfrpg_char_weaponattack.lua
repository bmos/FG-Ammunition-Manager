-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local function getWeaponUsage(nodeWeapon)
	local _,sShortcut = DB.getValue(nodeWeapon, 'shortcut', '');
	if sShortcut and sShortcut ~= '' then
		local nodeLinkedWeapon = CharManager.resolveRefNode(sShortcut)
		if nodeLinkedWeapon then
			return tonumber(DB.getValue(nodeLinkedWeapon, 'usage', 1))
		end
	end
	return 1
end

local function useWeaponAmmo(nodeWeapon)
	local sSpecial = DB.getValue(nodeWeapon, "special",""):lower()
	if string.find(sSpecial, "powered") then
		return true
	end
    local nodeAmmo = AmmunitionManager.getAmmoNode(nodeWeapon)
    if nodeAmmo then
        local ammoCount = DB.getValue(nodeAmmo, "count", 0)
        local weaponUsage = getWeaponUsage(nodeWeapon)
        if  ammoCount >= weaponUsage then
            local remainingAmmo = ammoCount - weaponUsage
            DB.setValue(nodeAmmo, 'count', 'number', remainingAmmo)
        else
            return false;
        end
    end
    return true
end

function action(draginfo)
	local nodeWeapon = window.getDatabaseNode();
	local rActor, rAttack = CharManager.getWeaponAttackRollStructures(nodeWeapon);
	rAttack.modifier = getValue();
	rAttack.order = tonumber(string.sub(getName(), 7)) or 1;

	local rRoll = ActionAttack.getRoll(rActor, rAttack);
	local sClass, sRecord = DB.getValue(nodeWeapon, "shortcut", "", "");
	local nodeWeaponSource = CharManager.resolveRefNode(sRecord);
	local sType = (DB.getValue(nodeWeaponSource, "subtype", ""));
	local nLevel = (DB.getValue(nodeWeaponSource, "level", ""));
	local nProf = DB.getValue(nodeWeapon, "prof", 0);
	local bTooHeavy = CharManager.isWeaponTooHeavy(ActorManager.getCreatureNode(rActor), sType, nLevel);

	if nProf == 1 then
        rRoll.sDesc = rRoll.sDesc .. " [NONPROF -4]";
    elseif nProf == 2 then
    	local nCharLevel = DB.getValue(nodeWeapon.getParent().getParent(), "level", 0);
    	local nBAB = DB.getValue(nodeWeapon.getParent().getParent(), "attackbonus.base", 0);
    	local bLowBAB = (nBAB <= nCharLevel - 3);
    	local nFocusBonus = 0;

		if bLowBAB then
			nFocusBonus = 2;
		else
			nFocusBonus = 1;
		end

        rRoll.sDesc = rRoll.sDesc .. " [WEAPON FOCUS +" .. nFocusBonus .. "]";
	end

	if bTooHeavy then
		rRoll.sDesc = rRoll.sDesc .. " [TOOHEAVY -2]";
	end

	-- Decrement ammo
	if useWeaponAmmo(nodeWeapon) then
		ActionsManager.performAction(draginfo, rActor, rRoll);
	else
		ChatManager.Message(Interface.getString("char_message_atkwithnoammo"), true, rActor);
	end

	return true;
end

super.action = action
