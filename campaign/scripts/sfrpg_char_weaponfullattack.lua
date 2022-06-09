--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function useWeaponAmmo(nodeWeapon)
	local sSpecial = DB.getValue(nodeWeapon, "special",""):lower()
	if string.find(sSpecial, "powered") then
		return true
	end
    local nodeAmmo = AmmunitionManager.getAmmoNode(nodeWeapon)
    if nodeAmmo then
        local ammoCount = DB.getValue(nodeAmmo, "count", 0)
        local nodeLinkedWeapon = AmmunitionManager.getShortcutNode(nodeWeapon, 'shortcut')
        local weaponUsage = tonumber(DB.getValue(nodeLinkedWeapon, 'usage', 1))
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
    local nValue = getValue();
    local nodeWeapon = window.getDatabaseNode();
    local rActor, rAttack = CharManager.getWeaponAttackRollStructures(nodeWeapon);
    local rRolls = {};
    local sAttack, aAttackDice, nAttackMod;
    local bAttack = true;
    local i=1;
    local sSpecial = DB.getValue(nodeWeapon, "special",""):lower();

    --Check Ammo for # to set Attacks allowed
    -- if string.find(sSpecial, "powered") then
    -- else
    --     local nUses = DB.getValue(nodeWeapon, "uses", 0);
    --     if nUses > 0 then
    --         local nUsedAmmo = DB.getValue(nodeWeapon, "ammo", 0);
    --         if (nUses - nUsedAmmo) >= nValue then   --more ammo than # of attacks
    --             bAttack = true;
    --             DB.setValue(nodeWeapon, "ammo", "number", nUsedAmmo + nValue );
    --         elseif (nUses - nUsedAmmo) < nValue and (nUses ~= nUsedAmmo) then
    --             bAttack = true;
    --             nValue = (nUses - nUsedAmmo);
    --             DB.setValue(nodeWeapon, "ammo", "number", nUsedAmmo + nValue );
    --             local sWeapon = DB.getValue(nodeWeapon, "name", "");
    --             ChatManager.Message(Interface.getString("char_message_atkwithpartammo"), true, rActor);
    --         else-- Out of Ammo
    --             local sWeapon = DB.getValue(nodeWeapon, "name", "");
    --             ChatManager.Message(Interface.getString("char_message_atkwithnoammo"), true, rActor);
    --             bAttack = false;
    --         end
    --     end
    -- end
    for i = 1, nValue do

        if not useWeaponAmmo(nodeWeapon) then
            if i == 1 then
                ChatManager.Message(Interface.getString("char_message_atkwithnoammo"), true, rActor)
                bAttack = false
            else
                ChatManager.Message(Interface.getString("char_message_atkwithpartammo"), true, rActor)
            end
            break
        end

        rAttack.modifier = DB.getValue(nodeWeapon, "attack0", 0);
        rAttack.modifier = rAttack.modifier + DB.getValue(nodeWeapon, "attack2modifier", 0);
        
        -- SubType Weapon Used
        local sClass, sRecord = DB.getValue(nodeWeapon, "shortcut", "", "");
        local nodeWeaponSource = CharManager.resolveRefNode(sRecord);
        local sType = (DB.getValue(nodeWeaponSource, "subtype", ""));
        local nProf = DB.getValue(nodeWeapon, "prof", 0)
        rAttack.order = i;
        table.insert(rRolls, ActionAttack.getRoll(rActor, rAttack));
        v = rRolls;
        if nProf == 1 then
            v[i].sDesc = v[i].sDesc .. " [NONPROF -4]";
            v[i].nMod = v[i].nMod - 8;
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

            v[i].sDesc = v[i].sDesc .. " [WEAPON FOCUS +" .. nFocusBonus .. "]";
            v[i].nMod = v[i].nMod + nFocusBonus - 4;
        else
            v[i].nMod = v[i].nMod - 4;
        end

        i=i+1;
    end

    if not OptionsManager.isOption("RMMT", "off") and #rRolls > 1 then
        for _,v in ipairs(rRolls) do
            v.sDesc = v.sDesc .. " [FULL]";
        end
    end
    if bAttack then
        ActionsManager.performMultiAction(draginfo, rActor, "attack", rRolls);
    end
    return true;
end

super.action = action
