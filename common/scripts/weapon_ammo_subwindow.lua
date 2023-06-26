--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

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
	for _, sCounter in ipairs({ 'missedshots', 'hitshots' }) do
		local nodeShotCounter = createShotCounter(nodeAmmoLink, sCounter)
		self[sCounter].setLink(nodeShotCounter, nodeShotCounter ~= nil)
	end
end

-- luacheck: globals onDataChanged
function onDataChanged()
	if super and super.onDataChanged then super.onDataChanged() end

	linkShotCounters(getDatabaseNode())
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
