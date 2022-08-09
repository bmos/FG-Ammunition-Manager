--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--
-- luacheck: globals onClickRelease
function onClickRelease()
	local nodeWeapon = window.getDatabaseNode();
	local nodeAmmo = AmmunitionManager.getAmmoNode(nodeWeapon)

	local nMisses = DB.getValue(nodeAmmo, 'missedshots', 0)
	if nMisses > 0 then
		local nPercent = DB.getValue(nodeWeapon, 'recoverypercentage', 50) / 100
		local nAmmoRecovered = math.floor(nMisses * nPercent)
		local messagedata = { text = '', sender = ActorManager.resolveActor(nodeWeapon.getChild('...')).sName, font = "emotefont" }
		messagedata.text = string.format(Interface.getString('char_actions_recoveredammunition'), nAmmoRecovered)
		Comm.deliverChatMessage(messagedata)

		local nAmmoUsed = DB.getValue(nodeWeapon, 'ammo', 0)
		local nExcess = nAmmoRecovered - nAmmoUsed
		DB.setValue(nodeWeapon, 'ammo', 'number', math.max(-1 * nExcess, 0))

		if nExcess > 0 then
			if nodeAmmo then
				local nCount = DB.getValue(nodeAmmo, 'count', 0)
				DB.setValue(nodeAmmo, 'count', 'number', nCount + nExcess)
				messagedata.text = string.format(Interface.getString('char_actions_excessammunition_auto'), nExcess)
				Comm.deliverChatMessage(messagedata)
			else
				messagedata.text = string.format(Interface.getString('char_actions_excessammunition'), nExcess)
				Comm.deliverChatMessage(messagedata)
			end
		end

		DB.setValue(nodeAmmo, 'missedshots', 'number', 0)
	end
end
