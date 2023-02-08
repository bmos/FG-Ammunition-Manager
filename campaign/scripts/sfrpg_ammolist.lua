--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals getAmmoType onFilter onInit

function getAmmoType(itemNode)
	local _, ammoType = AmmunitionManager.parseWeaponCapacity(DB.getValue(itemNode, 'capacity', ''))
	if ammoType:find('grenade') then return 'Grenade' end
	return 'Ammunition'
end

local attackNode, itemNode, ammoSubtype

function onInit()
	attackNode = window.parentcontrol.window.getDatabaseNode()
	itemNode = AmmunitionManager.getShortcutNode(attackNode)
	ammoSubtype = getAmmoType(itemNode)
end

function onFilter(w) return w.subtype.getValue() == ammoSubtype and w.location.getValue() == '' end
