--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

--	luacheck: globals onDoubleClick
function onDoubleClick(x,y)
    -- Reloading
    local nodeWeapon = window.getDatabaseNode()
    Interface.openWindow("char_weapon_reload", nodeWeapon);
    local rActor, _ = CharManager.getWeaponAttackRollStructures(nodeWeapon);
    ChatManager.Message(Interface.getString("char_message_reloadammo"), true, rActor)
end
