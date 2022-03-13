--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--

function action(draginfo)
	local nodeWeapon = window.getDatabaseNode();
	local rActor, rAttack = CharManager.getWeaponAttackRollStructures(nodeWeapon);

	local rRolls = {};
	for i = 1, getValue() do
		rAttack.modifier = DB.getValue(nodeWeapon, "attack" .. i, 0);
		rAttack.order = i;

		local nAmmo, bInfiniteAmmo = AmmunitionManager.getAmmoRemaining(rActor, nodeWeapon, AmmunitionManager.getAmmoNode(nodeWeapon))

		if (bInfiniteAmmo or nAmmo >= i) then	
			table.insert(rRolls, ActionAttack.getRoll(rActor, rAttack));
		else
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

function onDoubleClick()
	if not window.automateAmmo(window.getDatabaseNode()) then return action(); end
end
