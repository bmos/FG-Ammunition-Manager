--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--	luacheck: globals action
function action(draginfo)
    local nodeWeapon = window.getDatabaseNode();
	local rActor, rAttack = CharManager.getWeaponAttackRollStructures(nodeWeapon);
	rAttack.modifier = DB.getValue(nodeWeapon, "attack1", 0);
    local nAttackCount = getValue()

	local rRolls, bAttack = window.generateAttackRolls(rActor, nodeWeapon, rAttack, nAttackCount)
	if bAttack then
        ActionsManager.performMultiAction(draginfo, rActor, "attack", rRolls);
    end

    return true;
end

super.action = action
