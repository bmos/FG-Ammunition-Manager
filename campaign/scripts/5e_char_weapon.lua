--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--

--	luacheck: globals setAmmoVis maxammo.setLink
local function setAmmoVis(nodeWeapon, ...)
	if super and super.setAmmoVis then super.setAmmoVis(nodeWeapon, ...) end

	local bLoading = AmmunitionManager.hasLoadAction(nodeWeapon)
	isloaded.setVisible(bLoading)

	local nodeAmmoLink = AmmunitionManager.getAmmoNode(nodeWeapon)
	local bRanged = AmmunitionManager.isWeaponRanged(nodeWeapon)
	ammocounter.setVisible(bRanged and not nodeAmmoLink)
	ammopicker.setComboBoxVisible(bRanged and nodeAmmoLink)
	ammopicker.setComboBoxReadOnly(true)

	local nodeCount
	if nodeAmmoLink then nodeCount = DB.getChild(nodeAmmoLink, 'count') end
	maxammo.setLink(nodeCount, nodeCount ~= nil)
end

--	luacheck: globals onDataChanged
function onInit()
	local nodeWeapon = getDatabaseNode();
	local nodeChar = DB.getChild(nodeWeapon, "...");
	DB.addHandler(nodeWeapon, "onChildUpdate", onDataChanged);
	DB.addHandler(DB.getPath(nodeChar, "abilities.*.score"), "onUpdate", onDataChanged);
	DB.addHandler(DB.getPath(nodeChar, "weapon.twoweaponfighting"), "onUpdate", onDataChanged);

	onDataChanged(nodeWeapon);
end

function onClose()
	local nodeWeapon = getDatabaseNode();
	local nodeChar = DB.getChild(nodeWeapon, "...");
	DB.removeHandler(nodeWeapon, "onChildUpdate", onDataChanged);
	DB.removeHandler(DB.getPath(nodeChar, "abilities.*.score"), "onUpdate", onDataChanged);
	DB.removeHandler(DB.getPath(nodeChar, "weapon.twoweaponfighting"), "onUpdate", onDataChanged);
end

--	luacheck: globals onLinkChanged
local m_sClass = "";
local m_sRecord = "";
function onLinkChanged()
	local node = getDatabaseNode();
	local sClass, sRecord = DB.getValue(node, "shortcut", "", "");
	if sClass ~= m_sClass or sRecord ~= m_sRecord then
		m_sClass = sClass;
		m_sRecord = sRecord;

		local sInvList = DB.getPath(DB.getChild(node, "..."), "inventorylist") .. ".";
		if sRecord:sub(1, #sInvList) == sInvList then
			carried.setLink(DB.findNode(DB.getPath(sRecord, "carried")));
		end
	end
end

--	luacheck: globals onAttackChanged onDamageChanged
function onDataChanged(nodeWeapon)
	onLinkChanged();
	onAttackChanged();
	onDamageChanged();

	setAmmoVis(nodeWeapon)
end

--	luacheck: globals highlightAttack
function highlightAttack(bOnControl)
	if bOnControl then
		attackshade.setFrame("rowshade");
	else
		attackshade.setFrame(nil);
	end
end

function onAttackChanged()
	local nodeWeapon = getDatabaseNode();
	local nodeChar = DB.getChild(nodeWeapon, "...")

	local nMod = CharWeaponManager.getAttackBonus(nodeChar, nodeWeapon);

	attackview.setValue(nMod);
end

--	luacheck: globals onAttackAction
function onAttackAction(draginfo)
	local nodeWeapon = getDatabaseNode();
	local nodeChar = DB.getChild(nodeWeapon, "...")

	-- Build basic attack action record
	local rAction = CharWeaponManager.buildAttackAction(nodeChar, nodeWeapon);

	-- Decrement ammo
	if rAction.range == "R" then
		CharWeaponManager.decrementAmmo(nodeChar, nodeWeapon);
	end

	-- Perform action
	local rActor = ActorManager.resolveActor(nodeChar);

	-- AMMUNITION MANAGER CHANGES
	local nAmmo, bInfiniteAmmo = AmmunitionManager.getAmmoRemaining(rActor, nodeWeapon, AmmunitionManager.getAmmoNode(nodeWeapon))
	local messagedata = { text = '', sender = rActor.sName, font = 'emotefont' }

	local bLoading = AmmunitionManager.hasLoadAction(nodeWeapon)

	local nodeAmmoManager = DB.getChild(nodeWeapon, 'ammunitionmanager')
	local bIsLoaded = DB.getValue(nodeAmmoManager, 'isloaded') == 1
	if not bLoading or bIsLoaded then
		if bInfiniteAmmo or nAmmo > 0 then
			if bLoading then DB.setValue(nodeAmmoManager, 'isloaded', 'number', 0) end
		end
		messagedata.text = Interface.getString('char_message_atkwithnoammo')
		Comm.deliverChatMessage(messagedata)

		if bLoading then DB.setValue(nodeAmmoManager, 'isloaded', 'number', 0) end
	else
		local sWeaponName = DB.getValue(nodeWeapon, 'name', 'weapon')
		messagedata.text = string.format(Interface.getString('char_actions_notloaded'), sWeaponName, true, rActor)
		Comm.deliverChatMessage(messagedata)
		return false
	end
	-- END AMMUNITION MANAGER CHANGES

	ActionAttack.performRoll(draginfo, rActor, rAction);
	return true;
end

function onDamageChanged()
	local nodeWeapon = getDatabaseNode();
	local nodeChar = DB.getChild(nodeWeapon, "...")

	local sDamage = CharWeaponManager.buildDamageString(nodeChar, nodeWeapon);

	damageview.setValue(sDamage);
end

--	luacheck: globals onDamageAction
function onDamageAction(draginfo)
	local nodeWeapon = getDatabaseNode()
	local nodeChar = DB.getChild(nodeWeapon, '...')

	-- Build basic damage action record
	local rAction = CharWeaponManager.buildDamageAction(nodeChar, nodeWeapon)

	-- Perform damage action
	local rActor = ActorManager.resolveActor(nodeChar)

	-- Celestian adding itemPath to rActor so that when effects
	-- are checked we can compare against action only effects
	local _, sRecord = DB.getValue(nodeWeapon, 'shortcut', '', '')
	rActor.itemPath = sRecord
	-- end Adanced Effects piece ---

	-- bmos adding ammoPath for AmmunitionManager + Advanced Effects integration
	-- add this in the onDamageAction function of other effects to maintain compatibility
	if AmmunitionManager then
		local nodeAmmo = AmmunitionManager.getAmmoNode(nodeWeapon, rActor)
		if nodeAmmo then rActor.ammoPath = DB.getPath(nodeAmmo) end
	end
	-- end bmos adding ammoPath

	ActionDamage.performRoll(draginfo, rActor, rAction)
	return true
end
