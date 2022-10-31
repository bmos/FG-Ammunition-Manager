--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals itemsheetname itemsheetaltname setValue setTooltipText

local function isAmmo(nodeItem, sTypeField)
	local bThrown = false;
	if User.getRulesetName() == '5E' then bThrown = DB.getValue(getDatabaseNode().getParent(), 'type', 0) == 2; end
	if sTypeField and nodeItem.getChild(sTypeField) then
		local sItemType = DB.getValue(nodeItem, sTypeField, ''):lower();
		if bThrown then
			return (sItemType:match('weapon') ~= nil);
		else
			return (sItemType:match('ammunition') ~= nil) or (sItemType:match('ammo') ~= nil);
		end
	end
end

local function getContainedItems(nodeContainer)
	local containerName = ItemManager.getSortName(nodeContainer)
	local containedItems = {}
	if containerName ~= '' then
		for _, nodeItem in pairs(nodeContainer.getParent().getChildren()) do
			if DB.getValue(nodeItem, 'carried', 0) ~= 0 then
				local itemContainerName = StringManager.trim(DB.getValue(nodeItem, 'location', '')):lower()
				if itemContainerName == containerName then
					table.insert(containedItems, nodeItem)
				end
			end
		end
	end
	return containedItems
end

local function parseWeaponCapacity(capacity)
	local splitCapacity = StringManager.splitWords(capacity)
	return tonumber(splitCapacity[1]), splitCapacity[2]
end

local function populateAmmo()
	local weaponActionNode = getDatabaseNode().getParent()
	local weaponInventoryNode = AmmunitionManager.getShortcutNode(weaponActionNode, 'shortcut')
	
	local loadedAmmoNode = getContainedItems(weaponInventoryNode)[1]
	if loadedAmmoNode then
		for _, itemNode in pairs(weaponInventoryNode.getParent().getChildren()) do
			local itemName = ItemManager.getDisplayName(itemNode, true)
			if itemName ~= '' and loadedAmmoNode ~= itemNode and (isAmmo(itemNode, 'subtype') or isAmmo(itemNode, 'type')) then
				super.add(itemName)
				Debug.chat(itemNode.getPath())
			end
		end
	end

	
	-- local maxAmmo, ammoType = parseWeaponCapacity(DB.getValue(weaponInventoryNode, 'capacity', ''))
	-- local ammoNode = dbnode.getParent()
	-- local clonedNode = ammoNode.getParent().createChild()
	-- local results = DB.copyNode(ammoNode, clonedNode)

end

local function moveInventoryAmmunition(weaponActionNode, newAmmunitionNode)
	local weaponInventoryNode = AmmunitionManager.getShortcutNode(weaponActionNode, 'shortcut')
	local loadedAmmoNode = getContainedItems(weaponInventoryNode)[1]
	local maxAmmo, ammoType = parseWeaponCapacity(DB.getValue(weaponInventoryNode, 'capacity', ''))
	local weaponName = ItemManager.getDisplayName(weaponInventoryNode, true)
	if ammoType == 'charges' then
		DB.deleteNode(loadedAmmoNode.getChild('location'))
		DB.setValue(newAmmunitionNode, 'location', 'string', weaponName)
	else
		local newAmmoCount = DB.getValue(newAmmunitionNode, 'count', 0)
		if loadedAmmoNode then
			local currentCount = DB.getValue(loadedAmmoNode, 'count', 0)
			local ammoNeeded = maxAmmo - currentCount
			if newAmmoCount <= ammoNeeded then
				DB.setValue(loadedAmmoNode, 'count', 'number', newAmmoCount)
				DB.deleteNode(newAmmunitionNode)
			else
				DB.setValue(loadedAmmoNode, 'count', 'number', ammoNeeded)
				DB.setValue(newAmmunitionNode, 'count', 'number', newAmmoCount - ammoNeeded)
			end
		else
			if newAmmoCount <= maxAmmo then
				DB.setValue(newAmmunitionNode, 'location', 'string', weaponName)
			else
				local clonedNode = newAmmunitionNode.getParent().createChild()
				clonedNode = DB.copyNode(newAmmunitionNode, clonedNode)
				DB.setValue(clonedNode, 'count', 'number', maxAmmo)
				DB.setValue(newAmmunitionNode, 'count', 'number', newAmmoCount - maxAmmo)
			end
		end
	end
end

function onInit()
	if super then
		if super.onInit then super.onInit() end

		local function setListValue_new(sValue)
			setValue(sValue)

			-- save node to weapon node when choosing ammo
			local nodeWeapon = getDatabaseNode().getParent()
			local nodeInventory = nodeWeapon.getChild('...inventorylist')
			if nodeInventory then
				for _, nodeItem in pairs(nodeInventory.getChildren()) do
					local sName = ItemManager.getDisplayName(nodeItem, true)
					if sValue == '' then
						DB.setValue(nodeWeapon, 'ammoshortcut', 'windowreference', 'item', '')
					elseif sValue == sName then
						moveInventoryAmmunition(nodeWeapon, nodeItem)
						DB.setValue(nodeWeapon, 'ammoshortcut', 'windowreference', 'item', '....inventorylist.' .. nodeItem.getName())
					end
				end
			end

			local nodeOldNode = nodeWeapon.getChild('ammopickernode')
			if nodeOldNode then nodeOldNode.delete() end

			setTooltipText(sValue)
			super.refreshSelectionDisplay()
		end

		super.setListValue = setListValue_new
	end

	populateAmmo()
end
