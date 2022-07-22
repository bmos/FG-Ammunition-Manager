--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

--	luacheck: globals onDoubleClick
function onDoubleClick()
    -- Reloading
    local nodeWeapon = window.getDatabaseNode()
    Interface.openWindow("char_weapon_reload", nodeWeapon);
    local rActor = CharManager.getWeaponAttackRollStructures(nodeWeapon);
    ChatManager.Message(Interface.getString("char_message_reloadammo"), true, rActor)
end
