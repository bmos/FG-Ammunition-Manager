-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onSourceUpdate()
	local nodeWin = window.getDatabaseNode();
	local sMech = DB.getValue(nodeWin, "mechpath", "");

	if sMech == "" then
		charSourceUpdate(nodeWin);
	else
		charMechSourceUpdate(nodeWin);
	end
end

function charMechSourceUpdate(nodeWin)
	local nType = DB.getValue(nodeWin, "type", 0);
	local nodeChar = nodeWin.getParent().getParent();
	local sClass, sWeaponRecord = DB.getValue(nodeWin, "shortcut", "");
	local nodeMech = DB.findNode(sWeaponRecord).getParent().getParent();
	local nCharBAB = DB.getValue(nodeChar, "attackbonus.base", 0);
	local nCharPilot = CharManager.getSkillRanks(nodeChar, "piloting");
	local nMechBAB = DB.getValue(nodeMech, "attack.base", 0);
	local nMechMeleeBonus = DB.getValue(nodeMech, "attack.melee", 0);
	local nMechRangedBonus = DB.getValue(nodeMech, "attack.ranged", 0);
	local nFinalPilotBonus = 0;

	if nCharBAB >= nCharPilot then
		nFinalPilotBonus = nCharBAB;
	else
		nFinalPilotBonus = nCharPilot;
	end

	local nValue = 0;
	if nType == 2 then
		--Grapple/Melee
		nValue = nMechBAB + nFinalPilotBonus + nMechMeleeBonus;
	elseif nType == 1 then
		--Range
		nValue = nMechBAB + nFinalPilotBonus + nMechRangedBonus;
	else
		--Melee
		nValue = nMechBAB + nFinalPilotBonus + nMechMeleeBonus;
	end

	setValue(nValue + (modifier[1] or 0));
end

function charSourceUpdate(nodeWin)
	local nodeChar = nodeWin.getParent().getParent();
	local nType = DB.getValue(nodeWin, "type", 0);
	local sAttackStat = DB.getValue(nodeWin, "attackstat", "");
	local nValue = calculateSources() + (modifier[1] or 0);
	local nAtkBonusBase = DB.getValue(nodeWin, "...attackbonus.base", 0);

	nValue = nValue + nAtkBonusBase;

	if sAttackStat == "" then
		if nType == 2 then
			sAttackStat = DB.getValue(nodeWin, "...attackbonus.grapple.ability", "");
		elseif nType == 1 then
			sAttackStat = DB.getValue(nodeWin, "...attackbonus.ranged.ability", "");
		else
			sAttackStat = DB.getValue(nodeWin, "...attackbonus.melee.ability", "");
		end
	end
	if sAttackStat == "" then
		if nType == 2 then
			sAttackStat = "strength";
		elseif nType == 1 then
			sAttackStat = "dexterity";
		else
			sAttackStat = "strength";
		end
	end

	nValue = nValue + DB.getValue(nodeWin, "...abilities." .. sAttackStat .. ".bonus", 0);
	
	if nType == 2 then
		local nGrappleMisc = DB.getValue(nodeWin, "...attackbonus.grapple.misc", 0);
		local nGrappleSize = DB.getValue(nodeWin, "...attackbonus.grapple.size", 0);
		local nGrappleTemp = DB.getValue(nodeWin, "...attackbonus.grapple.temporary", 0);

		nValue = nValue + nGrappleMisc;
		nValue = nValue + nGrappleSize;
		nValue = nValue + nGrappleTemp;
	elseif nType == 1 then
		local nAtkBonusRngMisc = DB.getValue(nodeWin, "...attackbonus.ranged.misc", 0);
		local nAtkBonusRngSize = DB.getValue(nodeWin, "...attackbonus.ranged.size", 0);
		local nAtkBonusRngTemp = DB.getValue(nodeWin, "...attackbonus.ranged.temporary", 0);

		nValue = nValue + nAtkBonusRngMisc;
		nValue = nValue + nAtkBonusRngSize;
		nValue = nValue + nAtkBonusRngTemp;
	else
		local nAtkBonusMeleeMisc = DB.getValue(nodeWin, "...attackbonus.melee.misc", 0);
		local nAtkBonusMeleeSize = DB.getValue(nodeWin, "...attackbonus.melee.size", 0);
		local nAtkBonusMeleeTemp = DB.getValue(nodeWin, "...attackbonus.melee.temporary", 0);

		nValue = nValue + nAtkBonusMeleeMisc;
		nValue = nValue + nAtkBonusMeleeSize;
		nValue = nValue + nAtkBonusMeleeTemp;
	end

	local sClass, sRecord = DB.getValue(nodeWin, "shortcut", "", "");
	local nodeWeaponSource = CharManager.resolveRefNode(sRecord);
	local sType = (DB.getValue(nodeWeaponSource, "subtype", ""));
	local nLevel = (DB.getValue(nodeWeaponSource, "level", ""));
    local nProf = DB.getValue(nodeWin, "prof", 0)
	local bTooHeavy = CharManager.isWeaponTooHeavy(ActorManager.getCreatureNode(nodeChar), sType, nLevel);

	if nProf == 1 then
		nValue = nValue - 4;
    elseif nProf == 2 then
    	local nCharLevel = DB.getValue(nodeWin.getParent().getParent(), "level", 0);
    	local nBAB = DB.getValue(nodeWin.getParent().getParent(), "attackbonus.base", 0);
    	local bLowBAB = (nBAB <= nCharLevel - 3);
    	local nFocusBonus = 0;

		if bLowBAB then
			nFocusBonus = 2;
		else
			nFocusBonus = 1;
		end

		nValue = nValue + nFocusBonus;
	end

	if bTooHeavy then
		nValue = nValue - 2;
	end

	setValue(nValue);
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
	local nUses = DB.getValue(nodeWeapon, "uses", 0);		
	if nUses > 0 then
		local nUsedAmmo = DB.getValue(nodeWeapon, "ammo", 0);
		if nUsedAmmo >= nUses then
		    local sWeapon = DB.getValue(nodeWeapon, "name", "");
			ChatManager.Message(Interface.getString("char_message_atkwithnoammo"), true, rActor);
			bAttack = false;
		else			
			DB.setValue(nodeWeapon, "ammo", "number", nUsedAmmo + 1 );
		end
	end

	ActionsManager.performAction(draginfo, rActor, rRoll);
	return true;
end

function onDragStart(button, x, y, draginfo)
	return action(draginfo);
end

function onDoubleClick(x,y)
	return action();
end
