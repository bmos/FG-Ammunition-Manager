--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--
local sRuleset

-- luacheck: globals onClickRelease recoverAmmo
local function increaseAmmo(messagedata, nodeAmmo, nodeWeapon, nExcess)
	if nodeAmmo then
		local nodeItem = AmmunitionManager.getShortcutNode(nodeWeapon, 'altammopickershortcut') or nodeAmmo
		local nCount = DB.getValue(nodeItem, 'count', 0)
		DB.setValue(nodeItem, 'count', 'number', nCount + nExcess)
		messagedata.text = string.format(Interface.getString('char_actions_excessammunition_auto'), nExcess)
	else
		DB.setValue(nodeWeapon, 'ammo', 'number', math.max(-1 * nExcess, 0))
		messagedata.text = string.format(Interface.getString('char_actions_excessammunition'), nExcess)
	end
	Comm.deliverChatMessage(messagedata)
end

local function excessAmmoQuantity(nodeWeapon, nAmmoRecovered)
	local nAmmoUsed = DB.getValue(nodeWeapon, 'ammo', 0)
	return math.max(nAmmoRecovered - nAmmoUsed, 0)
end

local function notifyQuantity(messagedata, nAmmoRecovered)
	messagedata.text = string.format(Interface.getString('char_actions_recoveredammunition'), nAmmoRecovered)
	Comm.deliverChatMessage(messagedata)
end

local function quantityRecovered(nodeWeapon, nodeAmmo)
	local nRecoverCount = DB.getValue(nodeAmmo, target[1], 0)
	local nPercent = DB.getValue(nodeWeapon, 'recoverypercentage', 50) / 100

	return math.floor(nRecoverCount * nPercent)
end

function recoverAmmo()
	local nodeWeapon = window.getDatabaseNode()
	local nodeAmmo = AmmunitionManager.getAmmoNode(nodeWeapon)

	local nAmmoRecovered = quantityRecovered(nodeWeapon, nodeAmmo)
	local messagedata = { text = '', sender = ActorManager.resolveActor(DB.getChild(nodeWeapon, '...')).sName, font = 'emotefont' }
	notifyQuantity(messagedata, nAmmoRecovered)

	-- reset ammo-specific counter of missed shots
	DB.setValue(nodeAmmo, target[1], 'number', 0)

	local nExcess = excessAmmoQuantity(nodeWeapon, nAmmoRecovered)
	increaseAmmo(messagedata, nodeAmmo, nodeWeapon, nExcess)
end

function onClickRelease() recoverAmmo() end

function onInit()
	if super and super.onInit then super.onInit() end
	sRuleset = User.getRulesetName()
end