--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

-- luacheck: globals hitshots missedshots

local function linkAmmo(nodeWeapon)
	if not missedshots then return end
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
	local bRanged = AmmunitionManager.isWeaponRanged(nodeWeapon)

	header_ammo.setVisible(bRanged)
	if bRanged then
		weapon_editor_ammunition_column.setValue('char_weapon_editor_ammo', getDatabaseNode())
	else
		weapon_editor_ammunition_column.setValue('', '')

	end
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
