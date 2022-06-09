--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--

function onAmmoCountChanged()
	local nodeWeapon = getDatabaseNode()
	local nodeLinkedWeapon = AmmunitionManager.getShortcutNode(nodeWeapon, 'shortcut')
	local usage = DB.getValue(nodeLinkedWeapon, 'usage', 1)
	local uses = DB.getValue(nodeWeapon, 'uses', 1)
	local currentAmmo = current_ammo.getValue()
	local ammoUsed = math.max(0, uses - math.floor(currentAmmo / usage))
	
	DB.setValue(nodeWeapon, 'ammo', 'number', ammoUsed)
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
	local nodeWeaponSource = AmmunitionManager.getShortcutNode(nodeWeapon, "shortcut");
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
		if getClass() == "charmini_weapon" then
			attacks.setVisible(false);
			attackicons.setVisible(false);
			attack2.setVisible(false);
		end
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

super.onDataChanged = onDataChanged
