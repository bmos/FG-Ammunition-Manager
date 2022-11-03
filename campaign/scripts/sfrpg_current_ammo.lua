--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

--	luacheck: globals onDoubleClick
function onDoubleClick()
	Interface.openWindow('char_weapon_reload', window.getDatabaseNode())
end
