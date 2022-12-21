--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--

--	luacheck: globals onDataChanged
function onDataChanged()
	super.onLinkChanged()
	super.onDamageChanged()

	local nodeWeapon = getDatabaseNode()
	local nodeWeaponSource = AmmunitionManager.getShortcutNode(nodeWeapon, 'shortcut')
	local nodeAmmoLink = AmmunitionManager.getAmmoNode(nodeWeapon)
	local rActor = ActorManager.resolveActor(nodeWeapon.getChild('...'))

	--	luacheck: globals type
	local bRanged = (type.getValue() == 1)
	local bLinkedAmmoEnabled = (DB.getValue(nodeWeapon, 'ammopicker_enabled', 1) == 1)
	local _, bInfiniteAmmo = AmmunitionManager.getAmmoRemaining(rActor, nodeWeapon, nodeAmmoLink)
	local bDrawnCapacity = (DB.getValue(nodeWeaponSource, 'capacity', ''):lower() == 'drawn')
	local sSpecial = DB.getValue(nodeWeapon, 'special', ''):lower()
	local bThrownAttack = (string.find(sSpecial, 'thrown') and bRanged)

	label_range.setVisible(bRanged)
	rangeincrement.setVisible(bRanged)
	-- isloaded.setVisible(bRanged and hasLoadAction(nodeWeapon));
	label_ammo.setVisible(bRanged)
	uses.setVisible(bRanged and not bLinkedAmmoEnabled)
	current_ammo.setVisible(bRanged and bLinkedAmmoEnabled)
	ammocounter.setVisible(bRanged and not bInfiniteAmmo and not (bDrawnCapacity or bThrownAttack and bLinkedAmmoEnabled))


	local bNoFull = false
	if string.find(sSpecial, 'unwieldy') then
		bNoFull = true
	elseif string.find(sSpecial, 'explode') then
		bNoFull = true
	elseif bThrownAttack then
		bNoFull = true
	end

	if bNoFull then
		--	luacheck: globals getClass
		if getClass() == 'charmini_weapon' then
			attacks.setVisible(false)
			attackicons.setVisible(false)
			attack2.setVisible(false)
		end
		attack1.setVisible(false)
	end

	if string.find(sSpecial, 'powered') then
		label_ammo.setVisible(true)
		uses.setVisible(not bLinkedAmmoEnabled)
		current_ammo.setVisible(bLinkedAmmoEnabled)
		ammocounter.setVisible(true)
	end

	if nodeAmmoLink then
		current_ammo.setLink(nodeAmmoLink.getChild('count'), true)
		ammocounter.setLink(nodeAmmoLink.getChild('count'), true)
	else
		current_ammo.setLink()
		ammocounter.setLink()
	end
end
super.onDataChanged = onDataChanged

--	luacheck: globals hasLoadAction
function hasLoadAction(nodeWeapon)
	local bHasLoadAction
	--	luacheck: globals type
	local bRanged = (type.getValue() == 1)
	local sWeaponName = string.lower(DB.getValue(nodeWeapon, 'name', 'ranged weapon'))
	for _, v in pairs(AmmunitionManager.tLoadWeapons) do
		if string.find(sWeaponName, v) then
			bHasLoadAction = true
			break
		end
	end
	local bNoLoad = string.lower(DB.getValue(nodeWeapon, 'properties', '')):find('noload')

	return (bRanged and bHasLoadAction and not bNoLoad)
end

--	luacheck: globals automateAmmo
function automateAmmo(nodeWeapon)
	local bNotLoaded = (DB.getValue(nodeWeapon, 'isloaded') == 0)
	DB.setValue(nodeWeapon, 'isloaded', 'number', 0)
	if hasLoadAction(nodeWeapon) and bNotLoaded then
		local rActor = ActorManager.resolveActor(nodeWeapon.getChild('...'))
		local sWeaponName = string.lower(DB.getValue(nodeWeapon, 'name', 'ranged weapon'))

		local messagedata = { text = '', sender = rActor.sName, font = 'emotefont' }
		messagedata.text = string.format(Interface.getString('char_actions_notloaded'), sWeaponName)
		Comm.deliverChatMessage(messagedata)

		return true
	end
end

--	luacheck: globals generateAttackRolls
function generateAttackRolls(rActor, nodeWeapon, rAttack, nAttacksCount)
	local function useWeaponAmmo(attackCount)
		local sSpecial = DB.getValue(nodeWeapon, 'special', ''):lower()
		if string.find(sSpecial, 'powered') then return true end
		local nodeAmmo = AmmunitionManager.getAmmoNode(nodeWeapon)
		local nAmmoCount, bInfiniteAmmo = AmmunitionManager.getAmmoRemaining(rActor, nodeWeapon, nodeAmmo)
		if bInfiniteAmmo then return true end
		if nAmmoCount == 0 then return false end
		local weaponUsage = AmmunitionManager.getWeaponUsage(nodeWeapon)
		if nAmmoCount < weaponUsage * attackCount then
			return false
		else
			-- local remainingAmmo = nAmmoCount - weaponUsage
			-- DB.setValue(nodeAmmo, 'count', 'number', remainingAmmo)
			return true
		end
	end

	local sDesc = ''
	local nProf = DB.getValue(nodeWeapon, 'prof', 0)
	if nProf == 1 then
		sDesc = sDesc .. ' [NONPROF -4]'
	elseif nProf == 2 then
		local nCharLevel = DB.getValue(nodeWeapon.getParent().getParent(), 'level', 0)
		local nBAB = DB.getValue(nodeWeapon.getParent().getParent(), 'attackbonus.base', 0)
		local bLowBAB = (nBAB <= nCharLevel - 3)
		local nFocusBonus = 1

		if bLowBAB then nFocusBonus = 2 end

		sDesc = sDesc .. ' [WEAPON FOCUS +' .. nFocusBonus .. ']'
	end

	local nodeWeaponSource = AmmunitionManager.getShortcutNode(nodeWeapon)
	local sType = (DB.getValue(nodeWeaponSource, 'subtype', ''))
	local nLevel = (DB.getValue(nodeWeaponSource, 'level', ''))
	local bTooHeavy = CharManager.isWeaponTooHeavy(ActorManager.getCreatureNode(rActor), sType, nLevel)
	if bTooHeavy then sDesc = sDesc .. ' [TOOHEAVY -2]' end

	if not OptionsManager.isOption('RMMT', 'off') and nAttacksCount > 1 then sDesc = sDesc .. ' [FULL]' end

	local bAttack = true
	local rRolls = {}
	local messagedata = { text = '', sender = rActor.sName, font = 'emotefont' }
	for i = 1, nAttacksCount do
		if not useWeaponAmmo(i) then
			if i == 1 then
				messagedata.text = Interface.getString('char_message_atkwithnoammo')
				Comm.deliverChatMessage(messagedata)
				bAttack = false
			else
				messagedata.text = Interface.getString('char_message_atkwithpartammo')
				Comm.deliverChatMessage(messagedata)
			end
			break
		end
		rAttack.order = i
		local rRoll = ActionAttack.getRoll(rActor, rAttack)
		rRoll.sDesc = rRoll.sDesc .. sDesc
		rRoll.sAttackNode = DB.getPath(nodeWeapon)
		table.insert(rRolls, rRoll)
	end
	return rRolls, bAttack
end

--	luacheck: globals isThrownAttack
function isThrownAttack()
	local sSpecial = DB.getValue(getDatabaseNode(), 'special', ''):lower()
	local bRanged = (type.getValue() == 1)
	return (string.find(sSpecial, 'thrown') and bRanged)
end

--	luacheck: globals onInit
function onInit()
	if isThrownAttack() then
		local attackNode = getDatabaseNode()
		local itemNode = AmmunitionManager.getShortcutNode(attackNode, 'shortcut')
		if itemNode then
			DB.setValue(attackNode, "ammoshortcut", "windowreference", "item", "....inventorylist." .. itemNode.getName())
		end
	end
end
