--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

--	luacheck: globals loadAmmo

local function parseWeaponCapacity(capacity)
	local splitCapacity = StringManager.splitWords(capacity)
	return tonumber(splitCapacity[1]), splitCapacity[2]
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

local function moveInventoryAmmunition(weaponActionNode, newAmmunitionNode)
	local weaponInventoryNode = AmmunitionManager.getShortcutNode(weaponActionNode, 'shortcut')
	local loadedAmmoNode = getContainedItems(weaponInventoryNode)[1]
	local maxAmmo, ammoType = parseWeaponCapacity(DB.getValue(weaponInventoryNode, 'capacity', ''))
	local weaponName = ItemManager.getDisplayName(weaponInventoryNode, true)
	if ammoType == 'charges' then
		DB.setValue(loadedAmmoNode, 'location', 'string', '')
		DB.setValue(newAmmunitionNode, 'location', 'string', weaponName)
		return newAmmunitionNode
	else
		local newAmmoCount = DB.getValue(newAmmunitionNode, 'count', 0)
		if loadedAmmoNode then
			local currentCount = DB.getValue(loadedAmmoNode, 'count', 0)
			local ammoNeeded = maxAmmo - currentCount
			if newAmmoCount <= ammoNeeded then
				DB.setValue(loadedAmmoNode, 'count', 'number', newAmmoCount)
				DB.deleteNode(newAmmunitionNode)
				return loadedAmmoNode
			else
				DB.setValue(loadedAmmoNode, 'count', 'number', maxAmmo)
				DB.setValue(newAmmunitionNode, 'count', 'number', newAmmoCount - ammoNeeded)
				return loadedAmmoNode
			end
		else
			if newAmmoCount <= maxAmmo then
				DB.setValue(newAmmunitionNode, 'location', 'string', weaponName)
				return newAmmunitionNode
			else
				local clonedNode = newAmmunitionNode.getParent().createChild()
				clonedNode = DB.copyNode(newAmmunitionNode, clonedNode)
				DB.setValue(clonedNode, 'count', 'number', maxAmmo)
				DB.setValue(newAmmunitionNode, 'count', 'number', newAmmoCount - maxAmmo)
				return clonedNode
			end
		end
	end
end

function loadAmmo(ammoItem)
	local nodeWeapon = getDatabaseNode()
	local nodeAmmoItem = ammoItem.getDatabaseNode()
	local loadedAmmo = moveInventoryAmmunition(nodeWeapon, nodeAmmoItem)
	DB.setValue(nodeWeapon, 'ammopicker', 'string', ItemManager.getDisplayName(nodeAmmoItem, true))
	DB.setValue(nodeWeapon, 'ammoshortcut', 'windowreference', 'item', '....inventorylist.' .. loadedAmmo.getName())
	local rActor = CharManager.getWeaponAttackRollStructures(nodeWeapon)
	local messagedata = {
		text = Interface.getString('char_message_reloadammo'),
		sender = rActor.sName,
		font = 'emotefont'
	}
	Comm.deliverChatMessage(messagedata)

	parentcontrol.window.close()
end
