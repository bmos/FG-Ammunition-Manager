--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals ammo count onDoubleClick
function onDoubleClick(x, y, ...)
	if super and super.onDoubleClick then super.onDoubleClick(x, y, ...) end

	local nodeWeapon = window.getDatabaseNode()
	local nodeAmmo = AmmunitionManager.getAmmoNode(nodeWeapon)

	if nodeAmmo then
		local nCount = DB.getValue(nodeAmmo, count[1], 0)
		local nAmmo = DB.getValue(nodeWeapon, ammo[1], 0)

		if (nAmmo > 0) and (nCount > 0) then
			local nReload = (nCount - nAmmo)
			local rActor = ActorManager.resolveActor(DB.getChild(nodeWeapon, '...'))
			local messagedata = { text = '', sender = rActor.sName, font = 'emotefont' }
			if nReload > 0 then
				DB.setValue(nodeWeapon, ammo[1], 'number', 0)
				DB.setValue(nodeAmmo, count[1], 'number', nReload)

				messagedata.text = Interface.getString('char_actions_reload_full')
				Comm.deliverChatMessage(messagedata)
			else
				DB.setValue(nodeWeapon, ammo[1], 'number', nAmmo - nCount)
				DB.setValue(nodeAmmo, count[1], 'number', 0)

				messagedata.text = Interface.getString('char_actions_reload_partial')
				Comm.deliverChatMessage(messagedata)
			end
		end
	end
end
