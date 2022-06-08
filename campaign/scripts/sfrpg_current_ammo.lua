function onInit()
    setHoverCursor("hand");
end			

function onDoubleClick(x,y)
    -- window.onReloadAction(draginfo)
    local nodeWeapon = window.getDatabaseNode()
    Interface.openWindow("char_weapon_reload", nodeWeapon);
    local rActor, _ = CharManager.getWeaponAttackRollStructures(nodeWeapon);
    ChatManager.Message(Interface.getString("char_message_reloadammo"), true, rActor)
end

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

local function getLinkedWeapon(nodeWeapon)
	local _,sShortcut = DB.getValue(nodeWeapon, 'shortcut', '');
	if sShortcut and sShortcut ~= '' then
		return DB.findNode(sShortcut)
	end
end

function onValueChanged()
    window.onAmmoCountChanged()
end