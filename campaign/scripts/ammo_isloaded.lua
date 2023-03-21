--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals onClickRelease getValue
function onClickRelease()
	local rActor = ActorManager.resolveActor(DB.getChild(getDatabaseNode(), '.....'))
	local nodeWeapon = window.getDatabaseNode()

	local nAmmo, bInfiniteAmmo = AmmunitionManager.getAmmoRemaining(rActor, nodeWeapon, AmmunitionManager.getAmmoNode(nodeWeapon))

	if (getValue() == 0) and (bInfiniteAmmo or nAmmo > 0) then
		local sWeaponName = string.lower(DB.getValue(nodeWeapon, 'name', 'ranged weapon'))

		local messagedata = { text = '', sender = rActor.sName, font = 'emotefont' }
		messagedata.text = string.format(Interface.getString('char_actions_load'), sWeaponName)
		Comm.deliverChatMessage(messagedata)
	end
end
