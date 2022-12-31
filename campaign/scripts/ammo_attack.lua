--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
--	luacheck: globals action getValue getName onDoubleClick
function action(draginfo)
	local rActor, rAttack = CharManager.getWeaponAttackRollStructures(window.getDatabaseNode())

	rAttack.modifier = getValue()
	rAttack.order = tonumber(string.sub(getName(), 7)) or 1

	local nodeWeapon = window.getDatabaseNode()
	local nAmmo, bInfiniteAmmo = AmmunitionManager.getAmmoRemaining(rActor, nodeWeapon, AmmunitionManager.getAmmoNode(nodeWeapon))

	if window.automateAmmo(window.getDatabaseNode()) then return end

	if bInfiniteAmmo or nAmmo > 0 then
		ActionAttack.performRoll(draginfo, rActor, rAttack)
		return true
	end
end

function onInit()
	if super and super.onInit then super.onInit() end
	if super then super.action = action end
end
