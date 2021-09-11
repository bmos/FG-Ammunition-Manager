-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onClickRelease(target, button, image, ...)
	if super and super.onDoubleClick then
		super.onClickRelease(target, button, image, ...);
	end

	local nodeWeapon = window.getDatabaseNode();
	local rActor = ActorManager.resolveActor(nodeWeapon.getChild('...'));
	local nodeAmmo = AmmunitionManager.getAmmoNode(nodeWeapon, rActor);

	if nodeAmmo then
		local nCount = DB.getValue(nodeAmmo, count[1], 0)
		local nAmmo = DB.getValue(nodeWeapon, ammo[1], 0)

		if (nAmmo > 0) and (nCount > 0) then
			local nReload = (nCount - nAmmo)
			if nReload > -1 then
				DB.setValue(nodeWeapon, ammo[1], 'number', 0)
				DB.setValue(nodeAmmo, count[1], 'number', nReload)
				ChatManager.Message(Interface.getString("char_actions_reload_full"), true, rActor);
			else
				DB.setValue(nodeWeapon, ammo[1], 'number', nAmmo - nCount)
				DB.setValue(nodeAmmo, count[1], 'number', 0)
				ChatManager.Message(Interface.getString("char_actions_reload_partial"), true, rActor);
			end
		end
	end
end
