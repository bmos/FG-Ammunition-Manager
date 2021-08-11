-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function action(draginfo)
	local rActor, rAttack = CharManager.getWeaponAttackRollStructures(window.getDatabaseNode());
	rAttack.modifier = getValue();
	rAttack.order = tonumber(string.sub(getName(), 7)) or 1;

	local nodeWeapon = window.getDatabaseNode();
	local nMaxAmmo, nMaxAttacks
	local nodeAmmo = AmmunitionManager.isAmmoPicker(nodeWeapon, rActor)
	if not nodeAmmo then
		nMaxAmmo = DB.getValue(nodeWeapon, 'maxammo', 0)
		nMaxAttacks = nMaxAmmo - DB.getValue(nodeWeapon, 'ammo', 0)
	else
		nMaxAmmo = DB.getValue(nodeAmmo, 'count', 0)
		nMaxAttacks = DB.getValue(nodeAmmo, 'count', 0)
	end

	if not (nMaxAmmo > 0) or (nMaxAttacks >= 1) then	
		ActionAttack.performRoll(draginfo, rActor, rAttack);
		return true;
	end
end
function onDoubleClick(x,y)
	if not window.automateAmmo(window.getDatabaseNode()) then return action(); end
end