--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

--	luacheck: globals loadAmmo

function loadAmmo(ammoItem)
	Debug.chat(self, ammoItem)

	local nodeWeapon = getDatabaseNode()
	local rActor = CharManager.getWeaponAttackRollStructures(nodeWeapon)
	local messagedata = {
		text = Interface.getString('char_message_reloadammo'),
		sender = rActor.sName,
		font = 'emotefont'
	}
	Comm.deliverChatMessage(messagedata)

	parentcontrol.window.close()
end
