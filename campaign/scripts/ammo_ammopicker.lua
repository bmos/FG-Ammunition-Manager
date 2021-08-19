-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if super and super.onInit then
		super.onInit();
	end

	local aAutoFill = {};
	table.insert(aAutoFill, Interface.getString("none"));
	local nodeInventory = getDatabaseNode().getChild('....inventorylist')
	if nodeInventory then
		for _,v in pairs(nodeInventory.getChildren()) do
			if v.getChild(itemsheetname[1]) then
				local sName = DB.getValue(v, "name", "");
				local sItemType = DB.getValue(v, itemsheetname[1], ""):lower()
				local bAmmo = sItemType:match("ammunition") or sItemType:match("ammo");
				if bAmmo then
					if sName ~= "" then
						table.insert(aAutoFill, sName);
					end
				end
			end
		end
	end
	addItems(aAutoFill)
end