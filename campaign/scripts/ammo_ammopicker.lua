-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

local function setListValue(sValue)
	setValue(sValue);

	-- save node to weapon node when choosing ammo
	local nodeWeapon = getDatabaseNode().getParent()
	local nodeInventory = nodeWeapon.getChild('...inventorylist')
	if nodeInventory then
		for _,nodeItem in pairs(nodeInventory.getChildren()) do
			if sValue == '' then
				DB.setValue(nodeWeapon, 'ammopickernode', 'string', '')
			elseif sValue == DB.getValue(nodeItem, 'name', '') then
				DB.setValue(nodeWeapon, 'ammopickernode', 'string', nodeItem.getNodeName())
			end
		end
	end

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
	local nodeInventory = getDatabaseNode().getChild('....inventorylist');
	if nodeInventory then
		for _,nodeItem in pairs(nodeInventory.getChildren()) do
			if nodeItem.getChild(itemsheetname[1]) and DB.getValue(nodeItem, 'carried', 0) ~= 0 then
				local sName = '';
				if ItemManager.getIDState(nodeItem) then
					sName = DB.getValue(nodeItem, 'name', '');
				else
					sName = DB.getValue(nodeItem, 'nonid_name', '');
				end
				local bAmmo = false;
				if itemsheetname[1] and nodeItem.getChild(itemsheetname[1]) then
					local sItemType = DB.getValue(nodeItem, itemsheetname[1], ''):lower();
					bAmmo = bAmmo or (sItemType:match('ammunition') ~= nil) or (sItemType:match('ammo') ~= nil);
				end
				if itemsheetname[2] and nodeItem.getChild(itemsheetname[2]) then
					local sItemSubType = DB.getValue(nodeItem, itemsheetname[2], ''):lower();
					bAmmo = bAmmo or (sItemSubType:match('ammunition') ~= nil) or (sItemSubType:match('ammo') ~= nil);
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