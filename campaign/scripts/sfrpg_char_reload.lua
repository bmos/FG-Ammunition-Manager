--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

--	luacheck: globals loadAmmo

local function parseWeaponCapacity(capacity)
	capacity = capacity:lower()
	if capacity == 'drawn' then
		return 0, capacity
	end
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

local function loadCartridges(weaponActionNode, newAmmoNode, loadedAmmoNode)
	local weaponInventoryNode = AmmunitionManager.getShortcutNode(weaponActionNode, 'shortcut')
	local maxAmmo, ammoType = parseWeaponCapacity(DB.getValue(weaponInventoryNode, 'capacity', ''))
	local currentAmmoCount = 0
	if loadedAmmoNode then
		currentAmmoCount = DB.getValue(loadedAmmoNode, 'count', 0)
	else
		loadedAmmoNode = newAmmoNode.getParent().createChild()
		loadedAmmoNode = DB.copyNode(newAmmoNode, loadedAmmoNode)
		DB.setValue(loadedAmmoNode, 'location', 'string', ItemManager.getDisplayName(weaponInventoryNode, true))
	end
	local newAmmoCount = DB.getValue(newAmmoNode, 'count', 0)
	local ammoNeeded = maxAmmo - currentAmmoCount
	if ammoNeeded > newAmmoCount then
		ammoNeeded = newAmmoCount
	end
	DB.setValue(loadedAmmoNode, 'count', 'number', currentAmmoCount + ammoNeeded)
	DB.setValue(newAmmoNode, 'count', 'number', newAmmoCount - ammoNeeded)
	return loadedAmmoNode
end

local function isSameAmmo(ammo1, ammo2)
	return ammo1 and ammo2 and ItemManager.compareFields(ammo1, ammo2, true)
end

local function unloadAmmunition(loadedAmmoNode)
	if loadedAmmoNode then
		DB.setValue(loadedAmmoNode, 'location', 'string', '')
	end
end

local function moveInventoryAmmunition(weaponActionNode, newAmmoNode)
	local weaponInventoryNode = AmmunitionManager.getShortcutNode(weaponActionNode, 'shortcut')
	local loadedAmmoNode = getContainedItems(weaponInventoryNode)[1]
	if not newAmmoNode then -- no new ammo, unload old
		unloadAmmunition(loadedAmmoNode)
		return newAmmoNode
	end

	local maxAmmo, ammoType = parseWeaponCapacity(DB.getValue(weaponInventoryNode, 'capacity', ''))
	if ammoType == 'drawn' then
		return newAmmoNode
	end
	
	if ammoType == 'charges' then
		if loadedAmmoNode then
			DB.setValue(loadedAmmoNode, 'location', 'string', '')
		end
		DB.setValue(newAmmoNode, 'location', 'string', ItemManager.getDisplayName(weaponInventoryNode, true))
		return newAmmoNode
	end
	if isSameAmmo(loadedAmmoNode, newAmmoNode) then
		return loadCartridges(weaponActionNode, newAmmoNode, loadedAmmoNode)
	else
		unloadAmmunition(loadedAmmoNode)
		return loadCartridges(weaponActionNode, newAmmoNode)
	end
end

function loadAmmo(ammoItem)
	local nodeWeaponAction = getDatabaseNode()
	if ammoItem then
		local nodeAmmoItem = ammoItem.getDatabaseNode()
		local loadedAmmo = moveInventoryAmmunition(nodeWeaponAction, nodeAmmoItem)
		DB.setValue(nodeWeaponAction, 'ammopicker', 'string', ItemManager.getDisplayName(nodeAmmoItem, true))
		DB.setValue(nodeWeaponAction, 'ammoshortcut', 'windowreference', 'item', '....inventorylist.' .. loadedAmmo.getName())
		local rActor = CharManager.getWeaponAttackRollStructures(nodeWeaponAction)
		local messagedata = {
			text = Interface.getString('char_message_reloadammo'),
			sender = rActor.sName,
			font = 'emotefont'
		}
		Comm.deliverChatMessage(messagedata)
	else
		moveInventoryAmmunition(nodeWeaponAction)
		DB.setValue(nodeWeaponAction, 'ammopicker', 'string', '')
		DB.setValue(nodeWeaponAction, 'ammoshortcut', 'windowreference', 'item', '')
	end

	parentcontrol.window.close()
end
