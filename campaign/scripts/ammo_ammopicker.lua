--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
local function isAmmo(nodeItem, sTypeField)
	local bThrown = false
	if User.getRulesetName() == '5E' then
		local nodeWeapon = DB.getChild(getDatabaseNode(), '...')
		bThrown = DB.getValue(nodeWeapon, 'type', 0) == 2
	end
	if sTypeField and DB.getChild(nodeItem, sTypeField) then
		local sItemType = DB.getValue(nodeItem, sTypeField, ''):lower()
		if bThrown then
			return (sItemType:match('weapon') ~= nil)
		else
			return (sItemType:match('ammunition') ~= nil) or (sItemType:match('ammo') ~= nil)
		end
	end
end

-- luacheck: globals itemsheetname setValue setTooltipText defaultvalue
function onInit()
	if super then
		if super.onInit then super.onInit() end

		local function setListValue_new(sValue)
			setValue(sValue)
			setTooltipText(sValue)
			super.refreshSelectionDisplay()

			-- save node to weapon node when choosing ammo
			local nodeWeapon = DB.getChild(getDatabaseNode(), '...')

			local nodeInventory = DB.getChild(nodeWeapon, '...inventorylist')
			local nodeAmmoManager = DB.getChild(nodeWeapon, 'ammunitionmanager')
			if not nodeAmmoManager or not nodeInventory then return end

			local sDefaultValue = Interface.getString(defaultvalue[1])
			for _, nodeItem in ipairs(DB.getChildList(nodeInventory)) do
				local sName = ItemManager.getDisplayName(nodeItem, true)
				local sShortcutNodeName = DB.getName(getDatabaseNode()) .. 'shortcut'
				if sValue == sDefaultValue then
					DB.setValue(nodeAmmoManager, sShortcutNodeName, 'windowreference', 'item', '')
				elseif sValue == sName then
					DB.setValue(nodeAmmoManager, sShortcutNodeName, 'windowreference', 'item', '.....inventorylist.' .. DB.getName(nodeItem))
				end
			end
		end

		super.setListValue = setListValue_new
	end

	local aAutoFill = {}
	table.insert(aAutoFill, Interface.getString(defaultvalue[1]))

	local nodeInventory = DB.getChild(getDatabaseNode(), '.....inventorylist')
	if nodeInventory then
		for _, nodeItem in ipairs(DB.getChildList(nodeInventory)) do
			if DB.getValue(nodeItem, 'carried', 0) ~= 0 and itemsheetname and type(itemsheetname[1]) == 'table' then
				local sName = ItemManager.getDisplayName(nodeItem, true)
				for _, v in ipairs(itemsheetname) do
					if v.field and type(v.field) == 'table' and v.string and isAmmo(nodeItem, v.field[1]) then table.insert(aAutoFill, sName) end
				end
			end
		end
	end
	super.addItems(aAutoFill)
end
