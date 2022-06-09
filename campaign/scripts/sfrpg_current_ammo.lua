function onInit()
    setHoverCursor("hand");
end			

function onDoubleClick(x,y)
    -- Reloading
    local nodeWeapon = window.getDatabaseNode()
    Interface.openWindow("char_weapon_reload", nodeWeapon);
    local rActor, _ = CharManager.getWeaponAttackRollStructures(nodeWeapon);
    ChatManager.Message(Interface.getString("char_message_reloadammo"), true, rActor)
end

function onValueChanged()
    if super and super.onValueChanged then
        super.onValueChanged()
    end
    local nodeWeapon = window.getDatabaseNode()
	local nodeLinkedWeapon = AmmunitionManager.getShortcutNode(nodeWeapon, 'shortcut')
	local usage = DB.getValue(nodeLinkedWeapon, 'usage', 1)
	local uses = DB.getValue(nodeWeapon, 'uses', 1)
	local currentAmmo = getValue()
	local ammoUsed = math.max(0, uses - math.floor(currentAmmo / usage))

	DB.setValue(nodeWeapon, 'ammo', 'number', ammoUsed)
end