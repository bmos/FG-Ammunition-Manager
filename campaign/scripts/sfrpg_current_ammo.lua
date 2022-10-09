--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

--	luacheck: globals onDoubleClick
function onDoubleClick()
	-- Reloading
	local nodeWeapon = window.getDatabaseNode()
	Interface.openWindow('char_weapon_reload', nodeWeapon)
	local rActor = CharManager.getWeaponAttackRollStructures(nodeWeapon)

	local messagedata = { text = '', sender = rActor.sName, font = 'emotefont' }
	messagedata.text = Interface.getString('char_message_reloadammo')
	Comm.deliverChatMessage(messagedata)
end
