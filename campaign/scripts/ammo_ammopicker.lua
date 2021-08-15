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
	for _,v in pairs(getDatabaseNode().getChild('....inventorylist').getChildren()) do
		local sName = DB.getValue(v, "name", "");
		local sItemType = DB.getValue(v, itemsheetname[1], ""):lower()
		local bAmmo = sItemType:match("ammunition") or sItemType:match("ammo");
		if bAmmo then
			if sName ~= "" then
				table.insert(aAutoFill, sName);
			end
		end
	end
	addItems(aAutoFill)
end

--
-- Change visibility when ammopicker is changed
--

function onValueChanged()
	if super and super.onValueChanged then
		super.onValueChanged();
	end
	if window and window.switchAmmo then
		window.switchAmmo(window.type.getValue() == 1)
	end
end