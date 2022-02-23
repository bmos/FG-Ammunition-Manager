-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

local function setListValue(sValue)
	setValue(sValue);

	-- save node to weapon node when choosing ammo
	local nodeWeapon = getDatabaseNode().getParent();
	local nodeInventory = nodeWeapon.getChild('...inventorylist');
	if nodeInventory then
		for _,nodeItem in pairs(nodeInventory.getChildren()) do
			local sName = '';
			if LibraryData.getIDState("item", nodeItem, true) then
				sName = DB.getValue(nodeItem, 'name', '');
			else
				sName = DB.getValue(nodeItem, 'nonid_name', '');
			end
			if sValue == '' then
				DB.setValue(nodeWeapon, "ammoshortcut", "windowreference", "item", "");
			elseif sValue == sName then
				DB.setValue(nodeWeapon, "ammoshortcut", "windowreference", "item", "....inventorylist." .. nodeItem.getName());
			end
		end
	end

	local nodeOldNode = nodeWeapon.getChild('ammopickernode');
	if nodeOldNode then nodeOldNode.delete() end

	setTooltipText(sValue);
	refreshSelectionDisplay();
end

function onInit()
	if super then
		if super.onInit then
			super.onInit();
		end
		if super.setListValue then
			super.setListValue = setListValue;
		end
	end

	local aAutoFill = {};
	table.insert(aAutoFill, Interface.getString('none'));

	local bThrown = false;
	if User.getRulesetName() == "5E" then
		bThrown = DB.getValue(getDatabaseNode().getParent(), 'type', 0) == 2;
	end
	local nodeInventory = getDatabaseNode().getChild('....inventorylist');
	if nodeInventory then
		for _,nodeItem in pairs(nodeInventory.getChildren()) do
			if DB.getValue(nodeItem, 'carried', 0) ~= 0 then
				local sName = '';
				if LibraryData.getIDState("item", nodeItem, true) then
					sName = DB.getValue(nodeItem, 'name', '');
				else
					sName = DB.getValue(nodeItem, 'nonid_name', '');
				end
				local bAmmo = false;
				if itemsheetname[1] and nodeItem.getChild(itemsheetname[1]) then
					local sItemType = DB.getValue(nodeItem, itemsheetname[1], ''):lower();
					if bThrown then
						bAmmo = (bAmmo == true) or (sItemType:match('weapon') ~= nil);
					else
						bAmmo = (bAmmo == true) or (sItemType:match('ammunition') ~= nil) or (sItemType:match('ammo') ~= nil);
					end
				end
				if itemsheetaltname[1] and nodeItem.getChild(itemsheetaltname[1]) then
					local sItemAltType = DB.getValue(nodeItem, itemsheetaltname[1], ''):lower();
					if bThrown then
						bAmmo = (bAmmo == true) or (sItemAltType:match('weapon') ~= nil);
					else
						bAmmo = (bAmmo == true) or (sItemAltType:match('ammunition') ~= nil) or (sItemAltType:match('ammo') ~= nil);
					end
				end
				if bAmmo then
					if sName ~= '' then
						table.insert(aAutoFill, sName);
					end
				end
			end
		end
	end
	addItems(aAutoFill);
end