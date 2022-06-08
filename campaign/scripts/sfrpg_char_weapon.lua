--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--

local function getWeaponUsage(nodeWeapon)
	local _,sShortcut = DB.getValue(nodeWeapon, 'shortcut', '');
	if sShortcut and sShortcut ~= '' then
		local nodeLinkedWeapon = DB.findNode(sShortcut)
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
	local nodeAmmoLink = AmmunitionManager.getAmmoNode(nodeWeapon);
	local rActor = ActorManager.resolveActor(nodeWeapon.getChild('...'));
	local _, bInfiniteAmmo = AmmunitionManager.getAmmoRemaining(rActor, nodeWeapon, nodeAmmoLink);

	--	luacheck: globals type
	local bRanged = (type.getValue() == 1);
	label_range.setVisible(bRanged);
	rangeincrement.setVisible(bRanged);
	-- isloaded.setVisible(bRanged and hasLoadAction(nodeWeapon));
	label_ammo.setVisible(bRanged);
	uses.setVisible(bRanged);
	ammocounter.setVisible(bRanged and not bInfiniteAmmo);

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

	

	if uses.setLink then
		if nodeAmmoLink then
			uses.setLink(nodeAmmoLink.getChild('count'))
		else
			uses.setLink()
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
