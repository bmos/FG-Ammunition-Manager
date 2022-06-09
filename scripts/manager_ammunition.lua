--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--
--	This table exists so people can add search terms for weapons that should have a load button.
--	luacheck: globals tLoadWeapons MirrorImageHandler
tLoadWeapons = { 'loadaction' }

--	luacheck: globals getShortcutNode
function getShortcutNode(node, shortcutName)
	shortcutName = shortcutName or 'shortcut'
	local _,sRecord = DB.getValue(node, shortcutName, '', '');
	if sRecord and sShortcut ~= '' then
		return DB.findNode(sRecord)
	end
end

---	This function finds the correct node for a weapon's ammunition.
--	It first checks for a path saved in ammoshortcut. If found, databasenode record is returned.
--	If no path is found, it checks to see if the ammo name is known.
--	If ammo name is available, it searches through the inventory for a match.
--	If found, databasenode record is returned.
--	If no match is found, nothing is returned.
--	luacheck: globals getAmmoNode
function getAmmoNode(nodeWeapon)
	local ammoNode = getShortcutNode(nodeWeapon, 'ammoshortcut')
	if ammoNode then
		return ammoNode
	end

	-- if ammoshortcut does not provide a good node, try searching the inventory.
	local sAmmo = DB.getValue(nodeWeapon, 'ammopicker', '');
	if sAmmo ~= '' then
		Debug.console(Interface.getString('debug_ammo_noammoshortcutfound'));
		local nodeInventory = nodeWeapon.getChild('...inventorylist');
		if nodeInventory.getName() == 'inventorylist' then
			for _, nodeItem in pairs(nodeInventory.getChildren()) do
				if ItemManager.getIDState(nodeItem) then
					if DB.getValue(nodeItem, 'name', '') == sAmmo then return nodeItem; end
				else
					if DB.getValue(nodeItem, 'nonid_name', '') == sAmmo then return nodeItem; end
				end
			end
			Debug.console(Interface.getString('debug_ammo_itemnotfound'));
		else
			Debug.console(Interface.getString('debug_ammo_noinventoryfound'));
		end
	end
end

--	luacheck: globals getWeaponName
function getWeaponName(s)
	local sWeaponName = s:gsub('%[ATTACK %(%u%)%]', '');
	sWeaponName = sWeaponName:gsub('%[ATTACK #%d+ %(%u%)%]', '');
	sWeaponName = sWeaponName:gsub('%[%u+%]', '');
	if sWeaponName:match('%[USING ') then sWeaponName = sWeaponName:match('%[USING (.-)%]'); end
	sWeaponName = sWeaponName:gsub('%[.+%]', '');
	sWeaponName = sWeaponName:gsub(' %(vs%. .+%)', '');
	sWeaponName = StringManager.trim(sWeaponName);

	return sWeaponName or ''
end

local sRuleset;
local EffectManagerRuleset;
--	luacheck: globals getAmmoRemaining
function getAmmoRemaining(rSource, nodeWeapon, nodeAmmoLink)
	local function isInfiniteAmmo()
		local bInfiniteAmmo = DB.getValue(nodeWeapon, 'type', 0) ~= 1;
		if sRuleset == "5E" then
			local bThrown = DB.getValue(nodeWeapon, 'type', 0) == 2
			bInfiniteAmmo = (bInfiniteAmmo and not bThrown)
		end
		return bInfiniteAmmo or EffectManagerRuleset.hasEffectCondition(rSource, 'INFAMMO')
	end

	local bInfiniteAmmo = isInfiniteAmmo()

	local nAmmo = 0;
	if not bInfiniteAmmo then
		if nodeAmmoLink then
			nAmmo = DB.getValue(nodeAmmoLink, 'count', 0);
		else
			local nMaxAmmo = DB.getValue(nodeWeapon, 'maxammo', 0);
			local nAmmoUsed = DB.getValue(nodeWeapon, 'ammo', 0);
			nAmmo = nMaxAmmo - nAmmoUsed
			if nMaxAmmo == 0 then bInfiniteAmmo = true end
		end
	end
	return nAmmo, bInfiniteAmmo
end

--	tick off used ammunition, count misses, post 'out of ammo' chat message
--	luacheck: globals ammoTracker
function ammoTracker(rSource, sDesc, sResult, bCountAll)

	local function writeAmmoRemaining(nodeWeapon, nodeAmmoLink, nAmmoRemaining, sWeaponName)
		if nodeAmmoLink then
			if nAmmoRemaining == 0 then
				ChatManager.Message(string.format(Interface.getString('char_actions_usedallammo'), sWeaponName), true, rSource);
				DB.setValue(nodeAmmoLink, 'count', 'number', nAmmoRemaining);
			else
				DB.setValue(nodeAmmoLink, 'count', 'number', nAmmoRemaining);
			end
		else
			if nAmmoRemaining <= 0 then
				ChatManager.Message(string.format(Interface.getString('char_actions_usedallammo'), sWeaponName), true, rSource);
			end
			local nMaxAmmo = DB.getValue(nodeWeapon, 'maxammo', 0);
			DB.setValue(nodeWeapon, 'ammo', 'number', nMaxAmmo - nAmmoRemaining);
		end
	end

	local function countMissedShots(nodeAmmoLink)
		if bCountAll or (sResult == 'miss' or sResult == 'fumble') then -- counting misses
			DB.setValue(nodeAmmoLink, 'missedshots', 'number', DB.getValue(nodeAmmoLink, 'missedshots', 0) + 1);
		end
	end

	--	if weapon is fragile, set as broken or destroyed and post a chat message.
	local function breakWeapon(nodeWeapon, sWeaponName)

		-- examine weapon properties to check if fragile
		local function isFragile()
			local sWeaponProperties = DB.getValue(nodeWeapon, 'properties', ''):lower();
			local bIsFragile = (sWeaponProperties:find('fragile') or 0) > 0;
			local bIsMasterwork = sWeaponProperties:find('masterwork') or false;
			local bIsBone = sWeaponProperties:find('bone') or false;
			local bIsMagic = DB.getValue(nodeWeapon, 'bonus', 0) > 0;
			return (bIsFragile and not bIsMagic and (not bIsMasterwork or bIsBone))
		end

		if nodeWeapon and isFragile() then
			local nBroken = DB.getValue(nodeWeapon, 'broken', 0);
			local nItemHitpoints = DB.getValue(nodeWeapon, 'hitpoints', 0);
			local nItemDamage = DB.getValue(nodeWeapon, 'itemdamage', 0);
			if nBroken == 0 then
				DB.setValue(nodeWeapon, 'broken', 'number', 1);
				DB.setValue(nodeWeapon, 'itemdamage', 'number', math.floor(nItemHitpoints / 2) + math.max(nItemDamage, 1));
				ChatManager.Message(string.format(Interface.getString('char_actions_fragile_broken'), sWeaponName), true, rSource);
			elseif nBroken == 1 then
				DB.setValue(nodeWeapon, 'broken', 'number', 2);
				DB.setValue(nodeWeapon, 'itemdamage', 'number', nItemHitpoints + math.max(nItemDamage, 1));
				ChatManager.Message(string.format(Interface.getString('char_actions_fragile_destroyed'), sWeaponName), true, rSource);
			end
		end
	end

	local sWeaponName = getWeaponName(sDesc)
	if not sDesc:match('%[CONFIRM%]') and sWeaponName ~= '' then
		local nodeWeaponList = ActorManager.getCreatureNode(rSource).getChild('.weaponlist');
		for _, nodeWeapon in pairs(nodeWeaponList.getChildren()) do
			local sWeaponNameFromNode = getWeaponName(DB.getValue(nodeWeapon, 'name', ''))
			if sWeaponNameFromNode == sWeaponName then
				if sResult == 'fumble' then -- break fragile weapon on natural 1
					local _, sWeaponNode = DB.getValue(nodeWeapon, 'shortcut', '')
					local nodeWeaponLink = DB.findNode(sWeaponNode)
					breakWeapon(nodeWeaponLink, sWeaponName)
				end
				local bMelee = DB.getValue(nodeWeapon, 'type', 0) == 0
				if (sDesc:match('%[ATTACK %(R%)%]') or sDesc:match('%[ATTACK #%d+ %(R%)%]')) and not bMelee then
					local nodeAmmoLink = getAmmoNode(nodeWeapon)
					local nAmmoRemaining, bInfiniteAmmo = getAmmoRemaining(rSource, nodeWeapon, nodeAmmoLink)
					if not bInfiniteAmmo then
						writeAmmoRemaining(nodeWeapon, nodeAmmoLink, nAmmoRemaining - 1, sWeaponName)
						countMissedShots(nodeAmmoLink or nodeWeapon)
					end
				end
			end
		end
	end
end

--	calculate how much attacks hit/miss by
--	luacheck: globals calculateMargin
function calculateMargin(nDC, nTotal)
	if nDC and nTotal then
		local nMargin = 0
		if (nTotal - nDC) > 0 then
			nMargin = nTotal - nDC
		elseif (nTotal - nDC) < 0 then
			nMargin = nDC - nTotal
		end
		nMargin = math.floor(nMargin / 5) * 5

		if nMargin > 0 then return nMargin; end
	end
end

local function onAttack_pfrpg(rSource, rTarget, rRoll) -- luacheck: ignore
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	local bIsSourcePC = ActorManager.isPC(rSource);
	local bAllowCC = OptionsManager.isOption("HRCC", "on") or (not bIsSourcePC and OptionsManager.isOption("HRCC", "npc"));

	if rRoll.sDesc:match("%[CMB") then
		rRoll.sType = "grapple";
	end

	rRoll.nTotal = ActionsManager.total(rRoll);
	rRoll.aMessages = {};

	-- If we have a target, then calculate the defense we need to exceed
	local nDefenseVal, nAtkEffectsBonus, nDefEffectsBonus, nMissChance;
	if rRoll.sType == "critconfirm" then
		local sDefenseVal = rRoll.sDesc:match(" %[AC (%d+)%]");
		if sDefenseVal then
			nDefenseVal = tonumber(sDefenseVal);
		end
		nMissChance = tonumber(rRoll.sDesc:match("%[MISS CHANCE (%d+)%%%]")) or 0;
		rMessage.text = rMessage.text:gsub(" %[AC %d+%]", "");
		rMessage.text = rMessage.text:gsub(" %[MISS CHANCE %d+%%%]", "");
	else
		nDefenseVal, nAtkEffectsBonus, nDefEffectsBonus, nMissChance = ActorManager35E.getDefenseValue(rSource, rTarget, rRoll);
		if nAtkEffectsBonus ~= 0 then
			rRoll.nTotal = rRoll.nTotal + nAtkEffectsBonus;
			local sFormat = "[" .. Interface.getString("effects_tag") .. " %+d]";
			table.insert(rRoll.aMessages, string.format(sFormat, nAtkEffectsBonus));
		end
		if nDefEffectsBonus ~= 0 then
			nDefenseVal = nDefenseVal + nDefEffectsBonus;
			local sFormat = "[" .. Interface.getString("effects_def_tag") .. " %+d]";
			table.insert(rRoll.aMessages, string.format(sFormat, nDefEffectsBonus));
		end
	end

	-- for compatibility with mirror image handler, add this here in your onAttack function
	if MirrorImageHandler then
		-- Get the misfire threshold
		local sMisfireRange = string.match(rRoll.sDesc, "%[MISFIRE (%d+)%]");
		if sMisfireRange then rRoll.nMisfire = tonumber(sMisfireRange) or 0; end
	end
	-- end compatibility with mirror image handler

	-- Get the crit threshold
	rRoll.nCrit = 20;
	local sAltCritRange = string.match(rRoll.sDesc, "%[CRIT (%d+)%]");
	if sAltCritRange then
		rRoll.nCrit = tonumber(sAltCritRange) or 20;
		if (rRoll.nCrit <= 1) or (rRoll.nCrit > 20) then
			rRoll.nCrit = 20;
		end
	end

	rRoll.nFirstDie = 0;
	if #(rRoll.aDice) > 0 then
		rRoll.nFirstDie = rRoll.aDice[1].result or 0;
	end
	rRoll.bCritThreat = false;
	if rRoll.nFirstDie >= 20 then
		rRoll.bSpecial = true;
		if rRoll.sType == "critconfirm" then
			rRoll.sResult = "crit";
			table.insert(rRoll.aMessages, "[CRITICAL HIT]");
		elseif rRoll.sType == "attack" then
			if bAllowCC then
				rRoll.sResult = "hit";
				rRoll.bCritThreat = true;
				table.insert(rRoll.aMessages, "[AUTOMATIC HIT]");
			else
				rRoll.sResult = "crit";
				table.insert(rRoll.aMessages, "[CRITICAL HIT]");
			end
		else
			rRoll.sResult = "hit";
			table.insert(rRoll.aMessages, "[AUTOMATIC HIT]");
		end
	elseif rRoll.nFirstDie == 1 then
		if rRoll.sType == "critconfirm" then
			table.insert(rRoll.aMessages, "[CRIT NOT CONFIRMED]");
			rRoll.sResult = "miss";
		else
			-- for compatibility with mirror image handler, add this here in your onAttack function
			if MirrorImageHandler and rRoll.nMisfire and rRoll.sType == "attack" then
				table.insert(rRoll.aMessages, "[MISFIRE]");
				rRoll.sResult = "miss";
			else
				-- end compatibility with mirror image handler

				table.insert(rRoll.aMessages, "[AUTOMATIC MISS]");
				rRoll.sResult = "fumble";
			end
		end

		-- for compatibility with mirror image handler, add this here in your onAttack function
	elseif MirrorImageHandler and rRoll.nMisfire and rRoll.nFirstDie <= rRoll.nMisfire and rRoll.sType == "attack" then
		table.insert(rRoll.aMessages, "[MISFIRE]");
		rRoll.sResult = "miss";
		-- end compatibility with mirror image handler

	elseif nDefenseVal then
		if rRoll.nTotal >= nDefenseVal then
			if rRoll.sType == "critconfirm" then
				rRoll.sResult = "crit";
				table.insert(rRoll.aMessages, "[CRITICAL HIT]");
			elseif rRoll.sType == "attack" and rRoll.nFirstDie >= rRoll.nCrit then
				if bAllowCC then
					rRoll.sResult = "hit";
					rRoll.bCritThreat = true;
					table.insert(rRoll.aMessages, "[CRITICAL THREAT]");
				else
					rRoll.sResult = "crit";
					table.insert(rRoll.aMessages, "[CRITICAL HIT]");
				end
			else
				rRoll.sResult = "hit";
				table.insert(rRoll.aMessages, "[HIT]");
			end
		else
			rRoll.sResult = "miss";
			if rRoll.sType == "critconfirm" then
				table.insert(rRoll.aMessages, "[CRIT NOT CONFIRMED]");
			else
				table.insert(rRoll.aMessages, "[MISS]");
			end
		end
	elseif rRoll.sType == "critconfirm" then
		rRoll.sResult = "crit";
		table.insert(rRoll.aMessages, "[CHECK FOR CRITICAL]");
	elseif rRoll.sType == "attack" and rRoll.nFirstDie >= rRoll.nCrit then
		if bAllowCC then
			rRoll.sResult = "hit";
			rRoll.bCritThreat = true;
		else
			rRoll.sResult = "crit";
		end
		table.insert(rRoll.aMessages, "[CHECK FOR CRITICAL]");
	end

	if ((rRoll.sType == "critconfirm") or not rRoll.bCritThreat) and (nMissChance > 0) then
		table.insert(rRoll.aMessages, "[MISS CHANCE " .. nMissChance .. "%]");
	end

	--	bmos adding weapon name to chat
	--	for compatibility with ammunition tracker, add this here in your onAttack function
	if AmmunitionManager and OptionsManager.isOption('ATKRESULTWEAPON', 'on') then
		table.insert(rRoll.aMessages, 'with ' .. AmmunitionManager.getWeaponName(rRoll.sDesc));
	end
	--	end bmos adding automatic ammunition ticker and chat messaging

	--	bmos adding hit margin tracking
	--	for compatibility with ammunition tracker, add this here in your onAttack function
	if AmmunitionManager then
		local nHitMargin = AmmunitionManager.calculateMargin(nDefenseVal, rRoll.nTotal)
		if nHitMargin then table.insert(rRoll.aMessages, '[BY ' .. nHitMargin .. '+]') end
	end
	--	end bmos adding hit margin tracking

	Comm.deliverChatMessage(rMessage);

	--	bmos adding automatic ammunition ticker and chat messaging
	--	for compatibility with ammunition tracker, add this here in your onAttack function
	if AmmunitionManager and ActorManager.isPC(rSource) then AmmunitionManager.ammoTracker(rSource, rRoll.sDesc, rRoll.sResult); end
	--	end bmos adding automatic ammunition ticker and chat messaging

	if rRoll.sResult == "crit" then
		ActionAttack.setCritState(rSource, rTarget);
	end

	local bRollMissChance = false;
	if rRoll.sType == "critconfirm" then
		bRollMissChance = true;
	else
		if rRoll.bCritThreat then
			local rCritConfirmRoll = { sType = "critconfirm", aDice = {"d20"}, bTower = rRoll.bTower, bSecret = rRoll.bSecret };

			local nCCMod = EffectManager35E.getEffectsBonus(rSource, {"CC"}, true, nil, rTarget);
			if nCCMod ~= 0 then
				rCritConfirmRoll.sDesc = string.format("%s [CONFIRM %+d]", rRoll.sDesc, nCCMod);
			else
				rCritConfirmRoll.sDesc = rRoll.sDesc .. " [CONFIRM]";
			end
			if nMissChance > 0 then
				rCritConfirmRoll.sDesc = rCritConfirmRoll.sDesc .. " [MISS CHANCE " .. nMissChance .. "%]";
			end
			rCritConfirmRoll.nMod = rRoll.nMod + nCCMod;

			if nDefenseVal then
				rCritConfirmRoll.sDesc = rCritConfirmRoll.sDesc .. " [AC " .. nDefenseVal .. "]";
			end

			if nAtkEffectsBonus and nAtkEffectsBonus ~= 0 then
				local sFormat = "[" .. Interface.getString("effects_tag") .. " %+d]";
				rCritConfirmRoll.sDesc = rCritConfirmRoll.sDesc .. " " .. string.format(sFormat, nAtkEffectsBonus);
			end

			ActionsManager.roll(rSource, { rTarget }, rCritConfirmRoll, true);
		elseif (rRoll.sResult ~= "miss") and (rRoll.sResult ~= "fumble") then
			bRollMissChance = true;

			-- for compatibility with mirror image handler, add this here in your onAttack function
		elseif MirrorImageHandler and (rRoll.sResult == "miss") and (nDefenseVal - rRoll.nTotal <= 5) then
			bRollMissChance = true;
			nMissChance = 0;
			-- end compatibility with mirror image handler

		end
	end
	if bRollMissChance and (nMissChance > 0) then
		local aMissChanceDice = { 'd100' };
		local sMissChanceText;
		sMissChanceText = string.gsub(rMessage.text, ' %[CRIT %d+%]', '');
		sMissChanceText = string.gsub(sMissChanceText, ' %[CONFIRM%]', '');
		local rMissChanceRoll = {
			sType = 'misschance',
			sDesc = sMissChanceText .. ' [MISS CHANCE ' .. nMissChance .. '%]',
			aDice = aMissChanceDice,
			nMod = 0,
		};
		ActionsManager.roll(rSource, rTarget, rMissChanceRoll);

		-- for compatibility with mirror image handler, add this here in your onAttack function
	elseif MirrorImageHandler and bRollMissChance then
		local nMirrorImageCount = MirrorImageHandler.getMirrorImageCount(rTarget);
		if nMirrorImageCount > 0 then
			if rRoll.sResult == "hit" or rRoll.sResult == "crit" or rRoll.sType == "critconfirm" then
				local rMirrorImageRoll = MirrorImageHandler.getMirrorImageRoll(nMirrorImageCount, rRoll.sDesc);
				ActionsManager.roll(rSource, rTarget, rMirrorImageRoll);
			elseif rRoll.sType ~= "critconfirm" then
				MirrorImageHandler.removeImage(rSource, rTarget);
				table.insert(rRoll.aMessages, "[MIRROR IMAGE REMOVED BY NEAR MISS]");
			end
		end
		-- end compatibility with mirror image handler
	end

	if rTarget then
		ActionAttack.notifyApplyAttack(rSource, rTarget, rRoll.bTower, rRoll.sType, rRoll.sDesc, rRoll.nTotal, table.concat(rRoll.aMessages, " ")); -- luacheck: ignore

		-- REMOVE TARGET ON MISS OPTION
		if (rRoll.sResult == "miss" or rRoll.sResult == "fumble") and rRoll.sType ~= "critconfirm" and not string.match(rRoll.sDesc, "%[FULL%]") then -- luacheck: ignore
			local bRemoveTarget = false;
			if OptionsManager.isOption("RMMT", "on") then
				bRemoveTarget = true;
			elseif rRoll.bRemoveOnMiss then
				bRemoveTarget = true;
			end

			if bRemoveTarget then
				TargetingManager.removeTarget(ActorManager.getCTNodeName(rSource), ActorManager.getCTNodeName(rTarget));
			end
		end
	end

	ActionAttack.onPostAttackResolve(rRoll);
end

local function onAttack_4e(rSource, rTarget, rRoll) -- luacheck: ignore
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	rRoll.nTotal = ActionsManager.total(rRoll);
	rRoll.aMessages = {};

	-- If we have a target, then calculate the defense we need to exceed
	local nDefenseVal, nAtkEffectsBonus, nDefEffectsBonus = ActorManager4E.getDefenseValue(rSource, rTarget, rRoll);
	if nAtkEffectsBonus ~= 0 then
		rRoll.nTotal = rRoll.nTotal + nAtkEffectsBonus;
		local sFormat = "[" .. Interface.getString("effects_tag") .. " %+d]"
		table.insert(rRoll.aMessages, string.format(sFormat, nAtkEffectsBonus));
	end
	if nDefEffectsBonus ~= 0 then
		nDefenseVal = nDefenseVal + nDefEffectsBonus;
		local sFormat = "[" .. Interface.getString("effects_def_tag") .. " %+d]"
		table.insert(rRoll.aMessages, string.format(sFormat, nDefEffectsBonus));
	end

	-- Get the crit threshold
	rRoll.nCrit = 20;
	local sAltCritRange = string.match(rRoll.sDesc, "%[CRIT (%d+)%]");
	if sAltCritRange then
		rRoll.nCrit = tonumber(sAltCritRange) or 20;
		if (rRoll.nCrit <= 1) or (rRoll.nCrit > 20) then
			rRoll.nCrit = 20;
		end
	end

	rRoll.nFirstDie = 0;
	if #(rRoll.aDice) > 0 then
		rRoll.nFirstDie = rRoll.aDice[1].result or 0;
	end
	if rRoll.nFirstDie >= 20 then
		rRoll.bSpecial = true;
		if nDefenseVal then
			if rRoll.nTotal >= nDefenseVal then
				rRoll.sResult = "crit";
				table.insert(rRoll.aMessages, "[CRITICAL HIT]");
			else
				rRoll.sResult = "hit";
				table.insert(rRoll.aMessages, "[AUTOMATIC HIT]");
			end
		else
			table.insert(rRoll.aMessages, "[AUTOMATIC HIT, CHECK FOR CRITICAL]");
		end
	elseif rRoll.nFirstDie == 1 then
		rRoll.sResult = "fumble";
		table.insert(rRoll.aMessages, "[AUTOMATIC MISS]");
	elseif nDefenseVal then
		if rRoll.nTotal >= nDefenseVal then
			if rRoll.nFirstDie >= rRoll.nCrit then
				rRoll.sResult = "crit";
				table.insert(rRoll.aMessages, "[CRITICAL HIT]");
			else
				rRoll.sResult = "hit";
				table.insert(rRoll.aMessages, "[HIT]");
			end
		else
			rRoll.sResult = "miss";
			table.insert(rRoll.aMessages, "[MISS]");
		end
	elseif rRoll.nFirstDie >= rRoll.nCrit then
		rRoll.sResult = "crit";
		table.insert(rRoll.aMessages, "[CHECK FOR CRITICAL]");
	end

	--	bmos adding weapon name to chat
	--	for compatibility with ammunition tracker, add this here in your onAttack function
	if AmmunitionManager and OptionsManager.isOption('ATKRESULTWEAPON', 'on') then
		table.insert(rRoll.aMessages, 'with ' .. getWeaponName(rRoll.sDesc))
	end
	--	end bmos adding automatic ammunition ticker and chat messaging

	--	bmos adding hit margin tracking
	--	for compatibility with ammunition tracker, add this here in your onAttack function
	if AmmunitionManager then
		local nHitMargin = AmmunitionManager.calculateMargin(nDefenseVal, rRoll.nTotal);
		if nHitMargin then table.insert(rRoll.aMessages, '[BY ' .. nHitMargin .. '+]') end
	end
	--	end bmos adding hit margin tracking

	Comm.deliverChatMessage(rMessage);

	--	bmos adding automatic ammunition ticker and chat messaging
	--	for compatibility with ammunition tracker, add this here in your onAttack function
	if AmmunitionManager and ActorManager.isPC(rSource) then AmmunitionManager.ammoTracker(rSource, rRoll.sDesc, rRoll.sResult) end
	--	end bmos adding automatic ammunition ticker and chat messaging

	if rTarget then
		ActionAttack.notifyApplyAttack(rSource, rTarget, rRoll.bTower, rRoll.sType, rRoll.sDesc, rRoll.nTotal, table.concat(rRoll.aMessages, " ")); -- luacheck: ignore
	end

	-- TRACK CRITICAL STATE
	if rRoll.sResult == "crit" then
		ActionAttack.setCritState(rSource, rTarget);
	end

	-- REMOVE TARGET ON MISS OPTION
	if rTarget then
		if (rRoll.sResult == "miss") or (rRoll.sResult == "fumble") then
			local bRemoveTarget = false;
			if OptionsManager.isOption("RMMT", "on") then
				bRemoveTarget = true;
			elseif string.match(rRoll.sDesc, "%[RM%]") then
				bRemoveTarget = true;
			end

			if bRemoveTarget then
				TargetingManager.removeTarget(ActorManager.getCTNodeName(rSource), ActorManager.getCTNodeName(rTarget));
			end
		end
	end

	ActionAttack.onPostAttackResolve(rRoll);
end

local function decrementAmmo_5e() end

local function onAttack_5e(rSource, rTarget, rRoll) -- luacheck: ignore
	ActionsManager2.decodeAdvantage(rRoll);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.text = string.gsub(rMessage.text, " %[MOD:[^]]*%]", "");

	rRoll.nTotal = ActionsManager.total(rRoll);
	rRoll.aMessages = {};

	local nDefenseVal, nAtkEffectsBonus, nDefEffectsBonus = ActorManager5E.getDefenseValue(rSource, rTarget, rRoll);
	if nAtkEffectsBonus ~= 0 then
		rRoll.nTotal = rRoll.nTotal + nAtkEffectsBonus;
		local sFormat = "[" .. Interface.getString("effects_tag") .. " %+d]"
		table.insert(rRoll.aMessages, string.format(sFormat, nAtkEffectsBonus));
	end
	if nDefEffectsBonus ~= 0 then
		nDefenseVal = nDefenseVal + nDefEffectsBonus;
		local sFormat = "[" .. Interface.getString("effects_def_tag") .. " %+d]"
		table.insert(rRoll.aMessages, string.format(sFormat, nDefEffectsBonus));
	end

	local sCritThreshold = string.match(rRoll.sDesc, "%[CRIT (%d+)%]");
	local nCritThreshold = tonumber(sCritThreshold) or 20;
	if nCritThreshold < 2 or nCritThreshold > 20 then
		nCritThreshold = 20;
	end

	rRoll.nFirstDie = 0;
	if #(rRoll.aDice) > 0 then
		rRoll.nFirstDie = rRoll.aDice[1].result or 0;
	end
	if rRoll.nFirstDie >= nCritThreshold then
		rRoll.bSpecial = true;
		rRoll.sResult = "crit";
		table.insert(rRoll.aMessages, "[CRITICAL HIT]");
	elseif rRoll.nFirstDie == 1 then
		rRoll.sResult = "fumble";
		table.insert(rRoll.aMessages, "[AUTOMATIC MISS]");
	elseif nDefenseVal then
		if rRoll.nTotal >= nDefenseVal then
			rRoll.sResult = "hit";
			table.insert(rRoll.aMessages, "[HIT]");
		else
			rRoll.sResult = "miss";
			table.insert(rRoll.aMessages, "[MISS]");
		end
	end

	--	bmos adding weapon name to chat
	--	for compatibility with ammunition tracker, add this here in your onAttack function
	if AmmunitionManager and OptionsManager.isOption('ATKRESULTWEAPON', 'on') then
		table.insert(rRoll.aMessages, 'with ' .. AmmunitionManager.getWeaponName(rRoll.sDesc))
	end
	--	end bmos adding automatic ammunition ticker and chat messaging

	if not rTarget then
		rMessage.text = rMessage.text .. " " .. table.concat(rRoll.aMessages, " ");
	end

	--	bmos adding hit margin tracking
	--	for compatibility with ammunition tracker, add this here in your onAttack function
	if AmmunitionManager then
		local nHitMargin = AmmunitionManager.calculateMargin(nDefenseVal, rRoll.nTotal);
		if nHitMargin then table.insert(rRoll.aMessages, '[BY ' .. nHitMargin .. '+]') end
	end
	--	end bmos adding hit margin tracking

	Comm.deliverChatMessage(rMessage);

	--	bmos adding automatic ammunition ticker and chat messaging
	--	for compatibility with ammunition tracker, add this here in your onAttack function
	if AmmunitionManager and ActorManager.isPC(rSource) then AmmunitionManager.ammoTracker(rSource, rRoll.sDesc, rRoll.sResult, true) end
	--	end bmos adding automatic ammunition ticker and chat messaging

	if rTarget then
		ActionAttack.notifyApplyAttack(rSource, rTarget, rRoll.bTower, rRoll.sType, rRoll.sDesc, rRoll.nTotal, table.concat(rRoll.aMessages, " ")); -- luacheck: ignore
	end

	-- TRACK CRITICAL STATE
	if rRoll.sResult == "crit" then
		ActionAttack.setCritState(rSource, rTarget);
	end

	-- REMOVE TARGET ON MISS OPTION
	if rTarget then
		if (rRoll.sResult == "miss" or rRoll.sResult == "fumble") then
			if rRoll.bRemoveOnMiss then
				TargetingManager.removeTarget(ActorManager.getCTNodeName(rSource), ActorManager.getCTNodeName(rTarget));
			end
		end
	end

	ActionAttack.onPostAttackResolve(rRoll);
end

-- Function Overrides
function onInit()
	sRuleset = User.getRulesetName();
	-- replace result handlers
	if sRuleset == "PFRPG" or sRuleset == "3.5E" then
		EffectManagerRuleset = EffectManager35E

		tLoadWeapons = { 'loadaction', 'firearm', 'crossbow', 'javelin', 'ballista', 'windlass', 'pistol', 'rifle', 'sling' };
		ActionsManager.unregisterResultHandler('attack');
		ActionsManager.registerResultHandler('attack', onAttack_pfrpg);
		ActionAttack.onAttack = onAttack_pfrpg;
	elseif sRuleset == "4E" then
		EffectManagerRuleset = EffectManager4E
		tLoadWeapons = { 'loadaction', 'ballista' };
		ActionsManager.unregisterResultHandler('attack');
		ActionsManager.registerResultHandler('attack', onAttack_4e);
		ActionAttack.onAttack = onAttack_4e;
	elseif sRuleset == "5E" then
		EffectManagerRuleset = EffectManager5E
		ActionsManager.unregisterResultHandler("attack");
		ActionsManager.registerResultHandler("attack", onAttack_5e);
		ActionAttack.onAttack = onAttack_5e;
		CharWeaponManager.decrementAmmo = decrementAmmo_5e
	elseif sRuleset == "SFRPG" then
		EffectManagerRuleset = EffectManagerSFRPG
	end

	OptionsManager.registerOption2(
					'ATKRESULTWEAPON', false, 'option_header_game', 'opt_lab_atkresultweaponname', 'option_entry_cycler',
					{ labels = 'option_val_on', values = 'on', baselabel = 'option_val_off', baseval = 'off', default = 'off' }
	);
end
