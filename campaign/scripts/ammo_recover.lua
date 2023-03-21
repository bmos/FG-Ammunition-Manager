--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

-- luacheck: globals onClickRelease recoverAmmo counter percent ammopicker
local function increaseAmmo(messagedata, nodeAmmo, nodeWeapon, nExcess)
	if nExcess < 1 then return end
	local sNameAmmoPickerShortcut = AmmunitionManager.sAmmunitionManagerSubnode .. ammopicker[1] .. 'shortcut'
	local nodeItem = AmmunitionManager.getShortcutNode(nodeWeapon, sNameAmmoPickerShortcut) or nodeAmmo
	if nodeItem then
		local nCount = DB.getValue(nodeItem, AmmunitionManager.sLinkedCount, 0)
		DB.setValue(nodeItem, AmmunitionManager.sLinkedCount, 'number', nCount + nExcess)
	else
		DB.setValue(nodeWeapon, AmmunitionManager.sUnlinkedAmmo, 'number', math.max(-1 * nExcess, 0))
		messagedata.text = string.format(Interface.getString('char_actions_excessammunition'), nExcess)
		Comm.deliverChatMessage(messagedata)
	end
end

local function excessAmmoQuantity(nodeWeapon, nAmmoRecovered)
	local nAmmoUsed = DB.getValue(nodeWeapon, AmmunitionManager.sUnlinkedAmmo, 0)
	return math.max(nAmmoRecovered - nAmmoUsed, 0)
end

local function notifyQuantity(messagedata, nAmmoRecovered)
	messagedata.text = string.format(Interface.getString('char_actions_recoveredammunition'), nAmmoRecovered)
	Comm.deliverChatMessage(messagedata)
end

local function quantityRecovered(nodeWeapon, nodeAmmo)
	local nRecoverCount = DB.getValue(nodeAmmo, counter[1], 0)
	local nPercent = DB.getValue(nodeWeapon, AmmunitionManager.sAmmunitionManagerSubnode .. percent[1], 50) / 100
	return math.floor(nRecoverCount * nPercent)
end

function recoverAmmo()
	local nodeWeapon = window.getDatabaseNode()
	local nodeAmmo = AmmunitionManager.getAmmoNode(nodeWeapon)

	local nAmmoRecovered = quantityRecovered(nodeWeapon, nodeAmmo)
	local messagedata = { text = '', sender = ActorManager.resolveActor(DB.getChild(nodeWeapon, '...')).sName, font = 'emotefont' }
	notifyQuantity(messagedata, nAmmoRecovered)

	-- reset ammo-specific counter of missed shots
	DB.setValue(nodeAmmo, counter[1], 'number', 0)

	local nExcess = excessAmmoQuantity(nodeWeapon, nAmmoRecovered)
	increaseAmmo(messagedata, nodeAmmo, nodeWeapon, nExcess)
end

function onClickRelease() recoverAmmo() end

function onInit()
	if super and super.onInit then super.onInit() end
end
