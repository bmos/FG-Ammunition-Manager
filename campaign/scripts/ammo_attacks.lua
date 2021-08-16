-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function action(draginfo)
	local nValue = getValue();
	local nodeWeapon = window.getDatabaseNode();
	local rActor, rAttack = CharManager.getWeaponAttackRollStructures(nodeWeapon);

	local rRolls = {};
	local sAttack, aAttackDice, nAttackMod;
	for i = 1, getValue() do
		rAttack.modifier = DB.getValue(nodeWeapon, "attack" .. i, 0);
		rAttack.order = i;

		local nMaxAmmo = DB.getValue(nodeWeapon, 'maxammo', 0)
		local nMaxAttacks = nMaxAmmo - DB.getValue(nodeWeapon, 'ammo', 0)

		if not (nMaxAmmo > 0) or (i <= nMaxAttacks) then	
			table.insert(rRolls, ActionAttack.getRoll(rActor, rAttack));
		elseif (nMaxAmmo > 0) then
			ChatManager.Message(Interface.getString('char_actions_noammo'), true, rActor);
		end
	end

	if not OptionsManager.isOption("RMMT", "off") and #rRolls > 1 then
		for _,v in ipairs(rRolls) do
			v.sDesc = v.sDesc .. " [FULL]";
		end
	end

	ActionsManager.performMultiAction(draginfo, rActor, "attack", rRolls);

	return true;
end
function onDoubleClick(x,y)
	if not window.automateAmmo(window.getDatabaseNode()) then return action(); end
end
