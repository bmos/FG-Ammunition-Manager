--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--

--	luacheck: globals toggleDetail maxammo.setLink
function toggleDetail()
	if super and super.toggleDetail then super.toggleDetail() end

	local nodeWeapon = getDatabaseNode()
	local bRanged = AmmunitionManager.isWeaponRanged(nodeWeapon)
	isloaded.setVisible(bRanged and AmmunitionManager.hasLoadAction(nodeWeapon))

	local rActor = ActorManager.resolveActor(DB.getChild(nodeWeapon, '...'))
	local nodeAmmoLink = AmmunitionManager.getAmmoNode(nodeWeapon)
	local _, bInfiniteAmmo = AmmunitionManager.getAmmoRemaining(rActor, nodeWeapon, nodeAmmoLink)

	ammo_label.setVisible(bRanged)
	if nodeAmmoLink then
		if maxammo then maxammo.setLink(DB.getChild(nodeAmmoLink, 'count'), true) end
		if missedshots then missedshots.setLink(DB.getChild(nodeAmmoLink, 'missedshots'), true) end
	else
		if maxammo then maxammo.setLink() end
		if missedshots then missedshots.setLink() end
	end

	ammocounter.setVisible(bRanged and not bInfiniteAmmo and not nodeAmmoLink)

	local bShow = bRanged and activatedetail and (activatedetail.getValue() == 1)

	-- re-build ammopicker list when opening details
	ammopicker.clear()
	ammopicker.findItems()

	if ammunition_label then ammunition_label.setVisible(bShow) end
	if missrecoverypercentage then missrecoverypercentage.setVisible(bShow) end
	if label_missammopercentof then label_missammopercentof.setVisible(bShow) end
	if missedshots then missedshots.setVisible(bShow) end
	if recoverammo then recoverammo.setVisible(bShow) end
	if ammopicker then ammopicker.setComboBoxVisible(bShow) end
end

--	luacheck: globals onTypeChanged
function onTypeChanged()
	if super and super.onTypeChanged then super.onTypeChanged() end
	toggleDetail()
end

function onInit()
	if super and super.onInit then super.onInit() end
	DB.addHandler(DB.getPath(getDatabaseNode()), 'onChildUpdate', toggleDetail)
	toggleDetail()
end

function onClose()
	if super and super.onClose then super.onClose() end
	DB.removeHandler(DB.getPath(getDatabaseNode()), 'onChildUpdate', toggleDetail)
end
