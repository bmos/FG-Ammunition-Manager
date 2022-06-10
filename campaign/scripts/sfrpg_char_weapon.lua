--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--

function onDataChanged()
	super.onLinkChanged();
	super.onDamageChanged();

	local nodeWeapon = getDatabaseNode();
	local nodeWeaponSource = AmmunitionManager.getShortcutNode(nodeWeapon, "shortcut");
	local nodeAmmoLink = AmmunitionManager.getAmmoNode(nodeWeapon);
	local rActor = ActorManager.resolveActor(nodeWeapon.getChild('...'));

	--	luacheck: globals type
	local bRanged = (type.getValue() == 1);
	local _, bInfiniteAmmo = AmmunitionManager.getAmmoRemaining(rActor, nodeWeapon, nodeAmmoLink);
	local bDrawnCapacity = (DB.getValue(nodeWeaponSource, "capacity", ""):lower() == "drawn")
	
	label_range.setVisible(bRanged);
	rangeincrement.setVisible(bRanged);
	-- isloaded.setVisible(bRanged and hasLoadAction(nodeWeapon));
	label_ammo.setVisible(bRanged);
	-- uses.setVisible(bRanged and not nodeAmmoLink);
	current_ammo.setVisible(bRanged);
	ammocounter.setVisible(bRanged and not bInfiniteAmmo and not bDrawnCapacity);

	local sSpecial = DB.getValue(nodeWeapon, "special",""):lower();
	if string.find(sSpecial, "unwieldy") then
		bNoFull = true
	elseif string.find(sSpecial, "explode") then
		bNoFull = true
	elseif string.find(sSpecial, "thrown") and bRanged then
		bNoFull = true
	else
		bNoFull = false
	end

	if bNoFull then
		if getClass() == "charmini_weapon" then
			attacks.setVisible(false);
			attackicons.setVisible(false);
			attack2.setVisible(false);
		end
		attack1.setVisible(false);
	end

	local sSpecial = DB.getValue(nodeWeapon, "special",""):lower();	
	if string.find(sSpecial, "powered") then
		label_ammo.setVisible(true);
		-- uses.setVisible(not nodeAmmoLink);
		current_ammo.setVisible(true);
		ammocounter.setVisible(true);
	end

	if current_ammo.setLink then
		if nodeAmmoLink then
			current_ammo.setLink(nodeAmmoLink.getChild('count'))
		else
			current_ammo.setLink()
		end
	else
		Debug.chat("WARNING: NO AMMUNITION SET ON ITEM", DB.getValue(nodeWeapon, 'name'))
	end

	if ammocounter.setLink then
		if nodeAmmoLink then
			ammocounter.setLink(nodeAmmoLink.getChild('count'))
		else
			ammocounter.setLink()
		end
	else
		Debug.chat("WARNING: NO AMMUNITION SET ON ITEM", DB.getValue(nodeWeapon, 'name'))
	end
end
super.onDataChanged = onDataChanged

--	luacheck: globals hasLoadAction
function hasLoadAction(nodeWeapon)
	local bHasLoadAction
	--	luacheck: globals type
	local bRanged = (type.getValue() == 1);
	local sWeaponName = string.lower(DB.getValue(nodeWeapon, 'name', 'ranged weapon'));
	for _,v in pairs(AmmunitionManager.tLoadWeapons) do
		if string.find(sWeaponName, v) then bHasLoadAction = true; break; end
	end

	return (bRanged and bHasLoadAction)
end

--	luacheck: globals automateAmmo
function automateAmmo(nodeWeapon)
	local bNotLoaded = (DB.getValue(nodeWeapon, 'isloaded') == 0);
	DB.setValue(nodeWeapon, 'isloaded', 'number', 0);
	if hasLoadAction(nodeWeapon) and bNotLoaded then
		local rActor = ActorManager.resolveActor(nodeWeapon.getChild('...'));
		local sWeaponName = string.lower(DB.getValue(nodeWeapon, 'name', 'ranged weapon'));

		ChatManager.Message(string.format(Interface.getString('char_actions_notloaded'), sWeaponName), true, rActor);
		return true;
	end
end

function getWeaponUsage()
	local nodeLinkedWeapon = AmmunitionManager.getShortcutNode(getDatabaseNode(), 'shortcut')
	if nodeLinkedWeapon then
		return tonumber(DB.getValue(nodeLinkedWeapon, 'usage', 1)) or 1
	end
	return 1
end

function generateAttackRolls(rActor, nodeWeapon, rAttack, nAttacksCount)
	local function useWeaponAmmo()
		local sSpecial = DB.getValue(nodeWeapon, "special",""):lower()
		if string.find(sSpecial, "powered") then
			return true
		end
		local nodeAmmo = AmmunitionManager.getAmmoNode(nodeWeapon)
		local nAmmoCount, bInfiniteAmmo = AmmunitionManager.getAmmoRemaining(rActor, nodeWeapon, nodeAmmo)
		if bInfiniteAmmo then
			return true
		end
		if nAmmoCount == 0 then
			return false
		end
		local weaponUsage = getWeaponUsage()
		if  nAmmoCount >= weaponUsage then
			local remainingAmmo = nAmmoCount - weaponUsage
			DB.setValue(nodeAmmo, 'count', 'number', remainingAmmo)
		else
			return false;
		end
		return true
	end

	local sDesc = ""
	local nProf = DB.getValue(nodeWeapon, "prof", 0)
	if nProf == 1 then
        sDesc = sDesc .. " [NONPROF -4]";
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

        sDesc = sDesc .. " [WEAPON FOCUS +" .. nFocusBonus .. "]";
	end

	local nodeWeaponSource = AmmunitionManager.getShortcutNode(nodeWeapon)
	local sType = (DB.getValue(nodeWeaponSource, "subtype", ""))
	local nLevel = (DB.getValue(nodeWeaponSource, "level", ""))
	local bTooHeavy = CharManager.isWeaponTooHeavy(ActorManager.getCreatureNode(rActor), sType, nLevel)
	if bTooHeavy then
		sDesc = sDesc .. " [TOOHEAVY -2]";
	end

	if not OptionsManager.isOption("RMMT", "off") and nAttacksCount > 1 then
        sDesc = sDesc .. " [FULL]";
    end

	local bAttack = true
	local rRolls = {};
	for i = 1, nAttacksCount do
		if not useWeaponAmmo() then
            if i == 1 then
                ChatManager.Message(Interface.getString("char_message_atkwithnoammo"), true, rActor)
                bAttack = false
            else
                ChatManager.Message(Interface.getString("char_message_atkwithpartammo"), true, rActor)
            end
            break
        end
		rAttack.order = i
		local rRoll = ActionAttack.getRoll(rActor, rAttack)
		rRoll.sDesc = sDesc
		table.insert(rRolls, rRoll)
	end
	return rRolls, bAttack
end
