-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onClickRelease(target, button, image)
	local nMisses = window.missedshots.getValue() or 0
	if nMisses > 0 then
		local nPercent = (window.recoverypercentage.getValue() or 50) / 100
		local nAmmoRecovered = math.floor(nMisses * nPercent)
		ChatManager.SystemMessage(string.format(Interface.getString('char_actions_recoveredammunition'), nAmmoRecovered))

		local nodeWeapon = window.getDatabaseNode();
		local nAmmoUsed = DB.getValue(nodeWeapon, 'ammo', 0)
		local nExcess = nAmmoRecovered - nAmmoUsed
		DB.setValue(nodeWeapon, 'ammo', 'number', math.max(-1 * nExcess, 0))

		if nExcess > 0 then
			local nodeAmmo = AmmunitionManager.getAmmoNode(nodeWeapon)
			if nodeAmmo then
				local nCount = DB.getValue(nodeAmmo, 'count', 0)
				DB.setValue(nodeAmmo, 'count', 'number', nCount + nExcess)
				ChatManager.SystemMessage(string.format(Interface.getString('char_actions_excessammunition_auto'), nExcess))
			else
				ChatManager.SystemMessage(string.format(Interface.getString('char_actions_excessammunition'), nExcess))
			end
		end

		window.missedshots.setValue(0)
	end
end
