--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

local function hasSubstring(string, table)
	for _, v in pairs(table) do
		if string.find(string, v) then return true end
	end
end

--	luacheck: globals hasLoadAction
function hasLoadAction(nodeWeapon)
	if not AmmunitionManager.isWeaponRanged(nodeWeapon) then return false end

	local sWeaponProps = string.lower(DB.getValue(nodeWeapon, 'properties', ''))
	local bNoLoad = string.lower(sWeaponProps):find('noload')
	if bNoLoad then return false end

	local sWeaponName = string.lower(DB.getValue(nodeWeapon, 'name', ''))
	return hasSubstring(sWeaponProps, AmmunitionManager.tLoadWeaponProps) or hasSubstring(sWeaponName, AmmunitionManager.tLoadWeapons)
end

--	luacheck: globals automateAmmo
function automateAmmo(nodeWeapon)
	local nodeAmmoManager = DB.getChild(nodeWeapon, 'ammunitionmanager')
	local bIsLoaded = DB.getValue(nodeAmmoManager, 'isloaded') == 1
	DB.setValue(nodeAmmoManager, 'isloaded', 'number', 0)

	if not hasLoadAction(nodeWeapon) or bIsLoaded then return false end
	local rActor = ActorManager.resolveActor(DB.getChild(nodeWeapon, '...'))
	local sWeaponName = string.lower(DB.getValue(nodeWeapon, 'name', 'ranged weapon'))

	local messagedata = { text = '', sender = rActor.sName, font = 'emotefont' }
	messagedata.text = string.format(Interface.getString('char_actions_notloaded'), sWeaponName)
	Comm.deliverChatMessage(messagedata)

	return true
end

-- luacheck: globals onDataChanged maxammo.setLink
function onDataChanged()
	super.onLinkChanged()
	super.onDamageChanged()

	local nodeWeapon = getDatabaseNode()
	local nodeAmmoLink = AmmunitionManager.getAmmoNode(nodeWeapon)
	local rActor = ActorManager.resolveActor(DB.getChild(nodeWeapon, '...'))
	local _, bInfiniteAmmo = AmmunitionManager.getAmmoRemaining(rActor, nodeWeapon, nodeAmmoLink)

	--	luacheck: globals type
	local bRanged = AmmunitionManager.isWeaponRanged(nodeWeapon)
	label_range.setVisible(bRanged)
	rangeincrement.setVisible(bRanged)

	isloaded.setVisible(bRanged and hasLoadAction(nodeWeapon))
	label_ammo.setVisible(bRanged)
	maxammo.setVisible(bRanged)
	ammocounter.setVisible(bRanged and not bInfiniteAmmo and not nodeAmmoLink)

	if not maxammo.setLink then return end

	local nodeLinkedCount = DB.getChild(nodeAmmoLink, AmmunitionManager.sLinkedCount)
	maxammo.setLink(nodeLinkedCount, nodeLinkedCount ~= nil)
end

function onInit()
	if super and super.onInit then super.onInit() end
	local sNode = DB.getPath(getDatabaseNode())
	DB.addHandler(sNode, 'onChildUpdate', onDataChanged)
	onDataChanged()
end

function onClose()
	if super and super.onClose then super.onClose() end
	local sNode = DB.getPath(getDatabaseNode())
	DB.removeHandler(sNode, 'onChildUpdate', onDataChanged)
end
