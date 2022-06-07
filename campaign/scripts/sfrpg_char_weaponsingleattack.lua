-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local widgets = {};
local offsetx = 0;
local offsety = 0;

function onInit()
	offsetx = tonumber(icons[1].offsetx[1]);
	offsety = tonumber(icons[1].offsety[1]);

	--updateWidgets();
	updateAttackFields();
end

function onValueChanged()
	--updateWidgets();
	updateAttackFields();
end

function updateWidgets()
	for k, v in ipairs(widgets) do
		v.destroy();
	end

	widgets = {};

	local wt = window[icons[1].container[1]];
	local c = getValue();

	local w, h = getSize();

	for i = 1, c do
		local widget = wt.addBitmapWidget(icons[1].icon[1]);
		widget.setSize(10, 10);

		local ox = offsetx;
		if (i % 2) == 1 then
			ox = ox - 8;
		else
			ox = ox + 8;
		end
		local oy = offsety;
		if i <= 2 then
			oy = oy - 5;
		else
			oy = oy + 5;
		end
		widget.setPosition("center", ox, oy);

		widgets[i] = widget;
	end
end

function updateAttackFields()
	local c = getValue();

	if not isReadOnly() then
		window.attack1.setVisible(c >= 1);
	end
end

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

function useWeaponAmmo(nodeWeapon)
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
            ChatManager.Message(Interface.getString("char_message_atkwithnoammo"), true, rActor);
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
    for i = 1, getValue() do
		rAttack.modifier = DB.getValue(nodeWeapon, "attack0", 0);

		-- SubType Weapon Used
		local sClass, sRecord = DB.getValue(nodeWeapon, "shortcut", "", "");
		local nodeWeaponSource = CharManager.resolveRefNode(sRecord);
		local sType = (DB.getValue(nodeWeaponSource, "subtype", ""));
		local nLevel = (DB.getValue(nodeWeaponSource, "level", ""));
        local nProf = DB.getValue(nodeWeapon, "prof", 0);
		local bTooHeavy = CharManager.isWeaponTooHeavy(ActorManager.getCreatureNode(rActor), sType, nLevel);

		rAttack.order = i;		
        table.insert(rRolls, ActionAttack.getRoll(rActor, rAttack));	

        if nProf == 1 then
            for _,v in ipairs(rRolls) do
                v.sDesc = v.sDesc .. " [NONPROF -4]";
            end
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
        	for _,v in ipairs(rRolls) do
        		
                v.sDesc = v.sDesc .. " [WEAPON FOCUS +" .. nFocusBonus .. "]";
            end
		end

		if bTooHeavy then
            for _,v in ipairs(rRolls) do
                v.sDesc = v.sDesc .. " [TOOHEAVY -2]";
            end
		end

		-- Decrement ammo
		bAttack = useWeaponAmmo(nodeWeapon)
		-- local sSpecial = DB.getValue(nodeWeapon, "special",""):lower();	
		-- if string.find(sSpecial, "powered") then
		-- else
		-- 	local nUses = DB.getValue(nodeWeapon, "uses", 0);		
		-- 	if nUses > 0 then
		-- 		local nUsedAmmo = DB.getValue(nodeWeapon, "ammo", 0);
		-- 		if nUsedAmmo >= nUses then
		-- 		    local sWeapon = DB.getValue(nodeWeapon, "name", "");
		-- 			ChatManager.Message(Interface.getString("char_message_atkwithnoammo"), true, rActor);
		-- 			bAttack = false;
		-- 		else			
		-- 			DB.setValue(nodeWeapon, "ammo", "number", nUsedAmmo + 1 );
		-- 		end
		-- 	end
		-- end
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


function onDragStart(button, x, y, draginfo)
	return action(draginfo);
end

function onDoubleClick(x,y)
	return action();
end			
