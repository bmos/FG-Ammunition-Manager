--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

-- luacheck: globals missedshots label_missedshots recovermisses hitshots
-- luacheck: globals label_hitshots recoverhits altammopicker label_altammopicker

local function linkAmmo(nodeWeapon)
	local nodeAmmoLink = AmmunitionManager.getAmmoNode(nodeWeapon)
	if nodeAmmoLink then
		local nodeAmmoMisses = DB.getChild(nodeAmmoLink, 'missedshots')
		if not nodeAmmoMisses then
			DB.setValue(nodeAmmoLink, 'missedshots', 'number', 0)
			nodeAmmoMisses = DB.getChild(nodeAmmoLink, 'missedshots')
		end
		missedshots.setLink(nodeAmmoMisses, true)

		local nodeAmmoHits = DB.getChild(nodeAmmoLink, 'hitshots')
		if not nodeAmmoHits then
			DB.setValue(nodeAmmoLink, 'hitshots', 'number', 0)
			nodeAmmoHits = DB.getChild(nodeAmmoLink, 'hitshots')
		end
		hitshots.setLink(nodeAmmoHits, true)
	else
		missedshots.setLink()
		hitshots.setLink()
	end
end

local function setAmmoVisibility(nodeWeapon)
	local bRanged = DB.getValue(nodeWeapon, 'type', 0) == 1
	if User.getRulesetName() == '5E' then bRanged = bRanged or DB.getValue(nodeWeapon, 'type', 0) == 2 end

	header_ammo.setVisible(bRanged)

	ammopicker.setComboBoxVisible(bRanged)
	label_ammopicker.setVisible(bRanged)

	altammopicker.setComboBoxVisible(bRanged)
	label_altammopicker.setVisible(bRanged)

	recoverypercentage.setVisible(bRanged)
	label_recoverypercentage.setVisible(bRanged)

	label_ammopercentof.setVisible(bRanged)

	missedshots.setVisible(bRanged)
	label_missedshots.setVisible(bRanged)
	recovermisses.setVisible(bRanged)

	hitshots.setVisible(bRanged)
	label_hitshots.setVisible(bRanged)
	recoverhits.setVisible(bRanged)
end

-- luacheck: globals onDataChanged
function onDataChanged()
	if super and super.onDataChanged then super.onDataChanged() end
	local nodeWeapon = getDatabaseNode()
	setAmmoVisibility(nodeWeapon)
	linkAmmo(nodeWeapon)
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
