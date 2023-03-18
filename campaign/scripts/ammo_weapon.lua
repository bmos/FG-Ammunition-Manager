--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

--	luacheck: globals hasLoadAction
function hasLoadAction(nodeWeapon)
	if not AmmunitionManager.isWeaponRanged(nodeWeapon) then return false end

	local sWeaponProps = string.lower(DB.getValue(nodeWeapon, 'properties', ''))
	local bNoLoad = string.lower(sWeaponProps):find('noload')

	for _, v in pairs(AmmunitionManager.tLoadWeaponProps) do
		if not bNoLoad and string.find(sWeaponProps, v) then
			return true
		end
	end

	local sWeaponName = string.lower(DB.getValue(nodeWeapon, 'name', 'ranged weapon'))
	for _, v in pairs(AmmunitionManager.tLoadWeapons) do
		if not bNoLoad and string.find(sWeaponName, v) then
			return true
		end
	end

	return false
end

--	luacheck: globals automateAmmo
function automateAmmo(nodeWeapon)
	local bNotLoaded = (DB.getValue(nodeWeapon, 'isloaded') == 0)
	DB.setValue(nodeWeapon, 'isloaded', 'number', 0)
	if hasLoadAction(nodeWeapon) and bNotLoaded then
		local rActor = ActorManager.resolveActor(DB.getChild(nodeWeapon, '...'))
		local sWeaponName = string.lower(DB.getValue(nodeWeapon, 'name', 'ranged weapon'))

		local messagedata = { text = '', sender = rActor.sName, font = 'emotefont' }
		messagedata.text = string.format(Interface.getString('char_actions_notloaded'), sWeaponName)
		Comm.deliverChatMessage(messagedata)

		return true
	end
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
