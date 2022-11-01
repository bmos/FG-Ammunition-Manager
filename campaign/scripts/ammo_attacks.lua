--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
--	luacheck: globals action getValue
function action(draginfo)
	local nodeWeapon = window.getDatabaseNode()
	if window.automateAmmo(nodeWeapon) then return; end

	local rActor, rAttack = CharManager.getWeaponAttackRollStructures(nodeWeapon)

	local rRolls = {}
	for i = 1, getValue() do
		rAttack.modifier = DB.getValue(nodeWeapon, 'attack' .. i, 0)
		rAttack.order = i

		local nAmmo, bInfiniteAmmo = AmmunitionManager.getAmmoRemaining(rActor, nodeWeapon, AmmunitionManager.getAmmoNode(nodeWeapon))

		if bInfiniteAmmo or nAmmo >= i then
			table.insert(rRolls, ActionAttack.getRoll(rActor, rAttack))
		else
			local messagedata = { text = '', sender = rActor.sName, font = 'emotefont' }
			messagedata.text = Interface.getString('char_actions_noammo')
			Comm.deliverChatMessage(messagedata)
		end
	end

	if not OptionsManager.isOption('RMMT', 'off') and #rRolls > 1 then
		for _, v in ipairs(rRolls) do
			v.sDesc = v.sDesc .. ' [FULL]'
		end
	end

	ActionsManager.performMultiAction(draginfo, rActor, 'attack', rRolls)

	return true
end

function onInit()
	if super then
		super.action = action
	end
end