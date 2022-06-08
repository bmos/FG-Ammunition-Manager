--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--

local function getShortcutNode(node, shortcutName)
	local _,sRecord = DB.getValue(node, shortcutName, '', '');
	if sRecord and sShortcut ~= '' then
		return CharManager.resolveRefNode(sRecord)
	end
end

local function getWeaponUsage(nodeWeapon)
	local _,sShortcut = DB.getValue(nodeWeapon, 'shortcut', '');
	if sShortcut and sShortcut ~= '' then
		local nodeLinkedWeapon = CharManager.resolveRefNode(sShortcut)
		if nodeLinkedWeapon then
			return DB.getValue(nodeLinkedWeapon, 'usage', 1)
		end
	end
	return 1
end

local function reduceItemCount(nodeWeapon, nAmmo)
	local nodeAmmo = AmmunitionManager.getAmmoNode(nodeWeapon)
	if nodeAmmo then
		local nCount = DB.getValue(nodeAmmo, "count", 0)
		if (nAmmo > 0) and (nCount > 0) then
			local nUsage = getWeaponUsage(nodeWeapon)
			local nReload = nCount - nAmmo * nUsage
			if nReload > 0 then
				DB.setValue(nodeWeapon, 'ammo', 'number', 0)
				DB.setValue(nodeAmmo, 'count', 'number', nReload)
			else
				local nAvailableUses = math.floor(nCount / nUsage)
				DB.setValue(nodeWeapon, 'ammo', 'number', nAmmo - nAvailableUses)
				DB.setValue(nodeAmmo, 'count', 'number', nCount - nAvailableUses * nUsage)
			end
		end
	end
end

function onAmmoCountChanged()
	local nodeWeapon = getDatabaseNode();
	local usage = getWeaponUsage(nodeWeapon)
	local uses = DB.getValue(nodeWeapon, 'uses', 1)
	local currentAmmo = current_ammo.getValue()
	local ammoUsed = math.max(0, uses - math.floor(currentAmmo / usage))
	
	DB.setValue(nodeWeapon, 'ammo', 'number', ammoUsed)
end

--	luacheck: globals onReloadAction
function onReloadAction()
	-- local nodeWeapon = getDatabaseNode();
	-- local rActor, _ = CharManager.getWeaponAttackRollStructures(nodeWeapon);

	-- local nAmmo = DB.getValue(nodeWeapon, "ammo",0);
	-- local nUses = DB.getValue(nodeWeapon, "uses",0);
	-- if nAmmo > 0 then
	-- 	if nUses == 1 then
	-- 		ChatManager.Message(Interface.getString("char_message_ammodrawn"), true, rActor);
	-- 		reduceItemCount(nodeWeapon, nAmmo);
	-- 	else
	-- 		ChatManager.Message(Interface.getString("char_message_reloadammo"), true, rActor);
	-- 		reduceItemCount(nodeWeapon, nAmmo);
	-- 	end
	-- else
	-- 	ChatManager.Message(Interface.getString("char_message_ammofull"), true, rActor);
	-- end

	Interface.openWindow("char_weapon_editor", getDatabaseNode());

	return true;
end

--	luacheck: globals hasLoadAction
function hasLoadAction(nodeWeapon)
	local bHasLoadAction
	--	luacheck: globals type
	local bRanged = (type.getValue() == 1);
	local sWeaponName = string.lower(DB.getValue(nodeWeapon, 'name', 'ranged weapon'));
	for _,v in pairs(AmmunitionManager.tLoadWeapons) do
		if string.find(sWeaponName, v) then bHasLoadAction = true; break; end
	end

	return (bRanged and bHasLoadAction)
end

--	luacheck: globals automateAmmo
function automateAmmo(nodeWeapon)
	local bNotLoaded = (DB.getValue(nodeWeapon, 'isloaded') == 0);
	DB.setValue(nodeWeapon, 'isloaded', 'number', 0);
	if hasLoadAction(nodeWeapon) and bNotLoaded then
		local rActor = ActorManager.resolveActor(nodeWeapon.getChild('...'));
		local sWeaponName = string.lower(DB.getValue(nodeWeapon, 'name', 'ranged weapon'));

		ChatManager.Message(string.format(Interface.getString('char_actions_notloaded'), sWeaponName), true, rActor);
		return true;
	end
end

function onDataChanged()
	super.onLinkChanged();
	super.onDamageChanged();

	local nodeWeapon = getDatabaseNode();
	local nodeWeaponSource = getShortcutNode(nodeWeapon, "shortcut");
	local nodeAmmoLink = AmmunitionManager.getAmmoNode(nodeWeapon);
	local rActor = ActorManager.resolveActor(nodeWeapon.getChild('...'));

	--	luacheck: globals type
	local bRanged = (type.getValue() == 1);
	local _, bInfiniteAmmo = AmmunitionManager.getAmmoRemaining(rActor, nodeWeapon, nodeAmmoLink);
	local bDrawnCapacity = (DB.getValue(nodeWeaponSource, "capacity", ""):lower() == "drawn")
	
	label_range.setVisible(bRanged);
	rangeincrement.setVisible(bRanged);
	-- isloaded.setVisible(bRanged and hasLoadAction(nodeWeapon));
	label_ammo.setVisible(bRanged);
	-- uses.setVisible(bRanged and not nodeAmmoLink);
	current_ammo.setVisible(bRanged);
	ammocounter.setVisible(bRanged and not bInfiniteAmmo and not bDrawnCapacity);

	local sSpecial = DB.getValue(nodeWeapon, "special",""):lower();
	if string.find(sSpecial, "unwieldy") then
		bNoFull = true
	elseif string.find(sSpecial, "explode") then
		bNoFull = true
	elseif string.find(sSpecial, "thrown") and bRanged then
		bNoFull = true
	else
		bNoFull = false
	end

	if bNoFull then
		attack1.setVisible(false);
	end

	local sSpecial = DB.getValue(nodeWeapon, "special",""):lower();	
	if string.find(sSpecial, "powered") then
		label_ammo.setVisible(true);
		-- uses.setVisible(not nodeAmmoLink);
		current_ammo.setVisible(true);
		ammocounter.setVisible(true);
	end

	if current_ammo.setLink then
		if nodeAmmoLink then
			current_ammo.setLink(nodeAmmoLink.getChild('count'))
		else
			current_ammo.setLink()
		end
	else
		Debug.chat("WARNING: NO AMMUNITION SET ON ITEM", DB.getValue(nodeWeapon, 'name'))
	end
end

function onInit()
	super.registerMenuItem(Interface.getString("menu_deleteweapon"), "delete", 4);
	super.registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 4, 3);

	local sNode = getDatabaseNode().getPath();
	DB.addHandler(sNode, "onChildUpdate", onDataChanged);
	onDataChanged();
end

function onClose()
	local sNode = getDatabaseNode().getPath();
	DB.removeHandler(sNode, "onChildUpdate", onDataChanged);
end
