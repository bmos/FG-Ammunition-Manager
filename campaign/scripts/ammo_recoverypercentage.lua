-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onDoubleClick(x,y)
	local nMisses = window.missedshots.getValue() or 0
	if nMisses >= 1 then
		local nPercent = 0.01 * (getValue() or 50)
		local nAmmoRecovered = math.floor(nMisses * nPercent)
		ChatManager.SystemMessage(string.format(Interface.getString('char_actions_recoveredammunition'), nAmmoRecovered))

		local nodeWeapon = window.getDatabaseNode();
		local nAmmoUsed = DB.getValue(nodeWeapon, 'ammo', 0) - nAmmoRecovered
		if nAmmoUsed and nAmmoUsed < 0 then ChatManager.SystemMessage(string.format(Interface.getString('char_actions_excessammunition'), -1 * nAmmoUsed)) end
		DB.setValue(nodeWeapon, 'ammo', 'number', math.max(nAmmoUsed, 0))

		window.missedshots.setValue(0)
	end
end
