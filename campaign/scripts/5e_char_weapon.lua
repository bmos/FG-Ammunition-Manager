--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
--	luacheck: globals onDamageAction
function onDamageAction(draginfo)
	local nodeWeapon = getDatabaseNode();
	local nodeChar = nodeWeapon.getChild('...')

	-- Build basic damage action record
	local rAction = CharWeaponManager.buildDamageAction(nodeChar, nodeWeapon);

	-- Perform damage action
	local rActor = ActorManager.resolveActor(nodeChar);

	-- Celestian adding itemPath to rActor so that when effects
	-- are checked we can compare against action only effects
	local _, sRecord = DB.getValue(nodeWeapon, 'shortcut', '', '');
	rActor.itemPath = sRecord;
	-- end Adanced Effects piece ---

	-- bmos adding ammoPath for AmmunitionManager + Advanced Effects integration
	-- add this in the onDamageAction function of other effects to maintain compatibility
	if AmmunitionManager then
		local nodeAmmo = AmmunitionManager.getAmmoNode(nodeWeapon, rActor)
		if nodeAmmo then rActor.ammoPath = nodeAmmo.getPath() end
	end
	-- end bmos adding ammoPath

	ActionDamage.performRoll(draginfo, rActor, rAction);
	return true;
end

--	luacheck: globals onDataChanged
function onDataChanged(nodeWeapon)
	if super and super.onDataChanged then super.onDataChanged(); end

	nodeWeapon = nodeWeapon or getDatabaseNode();
	local nodeChar = nodeWeapon.getChild('...')
	local rActor = ActorManager.resolveActor(nodeChar);
	local bLoading = DB.getValue(nodeWeapon, 'properties', ''):lower():find('loading') ~= nil and
					                 not (CharManager.hasFeature(nodeChar, 'crossbow expert') and
									                 DB.getValue(nodeWeapon, 'name', ''):lower():find('crossbow'));
	isloaded.setVisible(bLoading);
	local nodeAmmoLink = AmmunitionManager.getAmmoNode(nodeWeapon);
	local _, bInfiniteAmmo = AmmunitionManager.getAmmoRemaining(rActor, nodeWeapon, nodeAmmoLink);
	ammocounter.setVisible(not bInfiniteAmmo and not nodeAmmoLink);
	if nodeAmmoLink then
		maxammo.setLink(nodeAmmoLink.getChild('count'));
	else
		maxammo.setLink();
	end
end

function onInit()
	if super then
		if super.onAttackAction then

			local onAttackAction_old
			local function onAttackAction_new(draginfo, ...)
				local nodeWeapon = getDatabaseNode();
				local nodeChar = nodeWeapon.getChild('...')
				local rActor = ActorManager.resolveActor(nodeChar)
				local nAmmo, bInfiniteAmmo = AmmunitionManager.getAmmoRemaining(rActor, nodeWeapon, AmmunitionManager.getAmmoNode(nodeWeapon))

				-- only allow attacks when 'loading' weapons have been loaded
				local bLoading = DB.getValue(nodeWeapon, 'properties', ''):lower():find('loading') ~= nil and
								                 not (CharManager.hasFeature(nodeChar, 'crossbow expert') and
												                 DB.getValue(nodeWeapon, 'name', ''):lower():find('crossbow'));
				local bIsLoaded = DB.getValue(nodeWeapon, 'isloaded', 0) == 1
				if not bLoading or (bLoading and bIsLoaded) then
					if (bInfiniteAmmo or nAmmo > 0) then
						if bLoading then DB.setValue(nodeWeapon, 'isloaded', 'number', 0); end
						return onAttackAction_old(draginfo, ...);
					else
						ChatManager.Message(Interface.getString('char_message_atkwithnoammo'), true, rActor);
						if bLoading then DB.setValue(nodeWeapon, 'isloaded', 'number', 0); end
					end
				else
					local sWeaponName = DB.getValue(nodeWeapon, 'name', 'weapon')
					ChatManager.Message(string.format(Interface.getString('char_actions_notloaded'), sWeaponName, true, rActor));
				end
				-- end bmos only allowing attacks when ammo is sufficient
			end

			onAttackAction_old = super.onAttackAction;
			super.onAttackAction = onAttackAction_new;
		end
		if super.onInit then super.onInit(); end
	end

	local nodeWeapon = getDatabaseNode();
	DB.addHandler(nodeWeapon.getPath(), 'onChildUpdate', onDataChanged);

	local nodeCT = ActorManager.getCTNode(ActorManager.resolveActor(nodeWeapon.getChild('...')))
	DB.addHandler(DB.getPath(nodeCT, 'effects.*.label'), 'onUpdate', onDataChanged)
	DB.addHandler(DB.getPath(nodeCT, 'effects.*.isactive'), 'onUpdate', onDataChanged)
	DB.addHandler(DB.getPath(nodeCT, 'effects'), 'onChildDeleted', onDataChanged)

	onDataChanged();
end

function onClose()
	if super and super.onClose then super.onClose(); end

	local nodeWeapon = getDatabaseNode();
	DB.removeHandler(nodeWeapon.getPath(), 'onChildUpdate', onDataChanged);

	local nodeCT = ActorManager.getCTNode(ActorManager.resolveActor(nodeWeapon.getChild('...')))
	DB.removeHandler(DB.getPath(nodeCT, 'effects.*.label'), 'onUpdate', onDataChanged)
	DB.removeHandler(DB.getPath(nodeCT, 'effects.*.isactive'), 'onUpdate', onDataChanged)
	DB.removeHandler(DB.getPath(nodeCT, 'effects'), 'onChildDeleted', onDataChanged)
end
