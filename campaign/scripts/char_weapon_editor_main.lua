--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

-- luacheck: globals hitshots missedshots

-- Returns requested shots counter node. If not found, creates it.
local function createShotCounter(nodeAmmo, sShotCounter)
	local nodeShotCounter = DB.getChild(nodeAmmo, sShotCounter)
	if not nodeShotCounter then
		DB.setValue(nodeAmmo, sShotCounter, 'number', 0)
		nodeShotCounter = DB.getChild(nodeAmmo, sShotCounter)
	end
	return nodeShotCounter
end

-- Finds all configured shot counters and links them. If ammopicker has not been set, unlinks them.
local function linkShotCounters(nodeWeapon)
	local nodeAmmoLink = AmmunitionManager.getAmmoNode(nodeWeapon)
	for _, sCounter in ipairs({ 'missedshots' , 'hitshots' }) do
		local nodeShotCounter = createShotCounter(nodeAmmoLink, sCounter)
		self[sCounter].setLink(nodeShotCounter, nodeShotCounter ~= nil)
	end
end

-- luacheck: globals missammopicker label_missammopicker missrecoverypercentage label_missrecoverypercentage
-- luacheck: globals label_missammopercentof  missedshots label_missedshots recovermisses
local function setMissRecoveryVisibility(bRanged)
	missammopicker.setComboBoxVisible(bRanged)
	label_missammopicker.setVisible(bRanged)

	missrecoverypercentage.setVisible(bRanged)
	label_missrecoverypercentage.setVisible(bRanged)
	label_missammopercentof.setVisible(bRanged)
	missedshots.setVisible(bRanged)
	label_missedshots.setVisible(bRanged)
	recovermisses.setVisible(bRanged)
end

-- luacheck: globals hitammopicker label_hitammopicker hitrecoverypercentage label_hitrecoverypercentage
-- luacheck: globals label_hitammopercentof  hitshots label_hitshots recoverhits
local function setHitRecoveryVisibility(bRanged)
	hitammopicker.setComboBoxVisible(bRanged)
	label_hitammopicker.setVisible(bRanged)

	hitrecoverypercentage.setVisible(bRanged)
	label_hitrecoverypercentage.setVisible(bRanged)
	label_hitammopercentof.setVisible(bRanged)
	hitshots.setVisible(bRanged)
	label_hitshots.setVisible(bRanged)
	recoverhits.setVisible(bRanged)
end

local function setAmmoVisibility(nodeWeapon)
	local bRanged = AmmunitionManager.isWeaponRanged(nodeWeapon)

	header_ammo.setVisible(bRanged)

	ammopicker.setComboBoxVisible(bRanged)
	label_ammopicker.setVisible(bRanged)

	setMissRecoveryVisibility(bRanged)
	setHitRecoveryVisibility(bRanged)
end

-- luacheck: globals onDataChanged
function onDataChanged()
	if super and super.onDataChanged then super.onDataChanged() end
	local nodeWeapon = getDatabaseNode()
	setAmmoVisibility(nodeWeapon)
	linkShotCounters(nodeWeapon)
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
