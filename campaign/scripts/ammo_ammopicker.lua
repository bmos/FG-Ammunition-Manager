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
			super.setListValue = setListValue
		end
	end

	local aAutoFill = {};
	table.insert(aAutoFill, Interface.getString('none'));
	local nodeInventory = getDatabaseNode().getChild('....inventorylist')
	if nodeInventory then
		for _,v in pairs(nodeInventory.getChildren()) do
			if v.getChild(itemsheetname[1]) and DB.getValue(v, 'carried', 0) ~= 0 then
				local sName = DB.getValue(v, 'name', '');
				local sItemType = DB.getValue(v, itemsheetname[1], ''):lower()
				local bAmmo = sItemType:match('ammunition') or sItemType:match('ammo');
				if bAmmo then
					if sName ~= '' then
						table.insert(aAutoFill, sName);
					end
				end
			end
		end
	end
	addItems(aAutoFill)
end