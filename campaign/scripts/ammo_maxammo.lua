-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onValueChanged()
	if super and super.onValueChanged then
		super.onValueChanged();
	end
	if window and window.switchAmmo then
		window.switchAmmo(window.type.getValue() == 1)
	end
end

function onDoubleClick(x, y)
	if super and super.onDoubleClick then
		super.onDoubleClick(x, y);
	end

	local nodeWeapon = window.getDatabaseNode();
	local rActor = ActorManager.resolveActor(nodeWeapon.getChild('...'));
	local nodeAmmo = AmmunitionManager.getAmmoNode(nodeWeapon, rActor);

	if nodeAmmo then
		local nCount = DB.getValue(nodeAmmo, count[1], 0)
		local nAmmo = DB.getValue(nodeWeapon, ammo[1], 0)

		if (nAmmo > 0) and (nCount > 0) then
			local nReload = (nCount - nAmmo)
			if nReload > 0 then
				DB.setValue(nodeWeapon, ammo[1], 'number', 0)
				DB.setValue(nodeAmmo, count[1], 'number', nReload)
			else
				DB.setValue(nodeWeapon, ammo[1], 'number', nAmmo - nCount)
				DB.setValue(nodeAmmo, count[1], 'number', 0)
			end
		end
	end
end