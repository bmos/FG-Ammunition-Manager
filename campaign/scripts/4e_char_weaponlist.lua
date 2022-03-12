--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--

-- luacheck: globals hasLoadAction
function hasLoadAction()
	local bHasLoadAction = false;
	local nodeWeapon = getDatabaseNode();
	local sWeaponProperties = string.lower(DB.getValue(nodeWeapon), 'properties', ''));
	local sWeaponName = string.lower(DB.getValue(nodeWeapon), 'name', 'ranged weapon'));
	for _,v in pairs(AmmunitionManager.tLoadWeapons) do
		if string.find(sWeaponName, v) then bHasLoadAction = true; break; end
	end

	return (bHasLoadAction and not sWeaponProperties:find('load free'))
end

local function toggleDetail()
	if super and super.toggleDetail then
		super.toggleDetail();
	end

	local bRanged = (type.getValue() == 1);
	isloaded.setVisible(bRanged and hasLoadAction());
	if button_reload then button_reload.setVisible(bRanged) end

	local nodeWeapon = getDatabaseNode();
	local rActor = ActorManager.resolveActor(nodeWeapon.getChild('...'));
	local nodeAmmoLink = AmmunitionManager.getAmmoNode(nodeWeapon);
	local _, bInfiniteAmmo = AmmunitionManager.getAmmoRemaining(rActor, nodeWeapon, nodeAmmoLink);

	ammo_label.setVisible(bRanged);
	if nodeAmmoLink then
		maxammo.setLink(nodeAmmoLink.getChild('count'))
		if missedshots then missedshots.setLink(nodeAmmoLink.getChild('missedshots')) end
	else
		maxammo.setLink()
		if missedshots then missedshots.setLink() end
	end
	ammocounter.setVisible(bRanged and not bInfiniteAmmo and not nodeAmmoLink);

	if activatedetail then
		local bShow = (activatedetail.getValue() == 1);
		ammunition_label.setVisible(bRanged and bShow);
		recoverypercentage.setVisible(bRanged and bShow);
		label_ammopercentof.setVisible(bRanged and bShow);
		missedshots.setVisible(bRanged and bShow);
		recoverammo.setVisible(bRanged and bShow);
		ammopicker.setComboBoxVisible(bRanged and bShow);

		-- re-build ammopicker list when opening details
		if bShow then ammopicker.clear(); ammopicker.onInit(); end
	end
end

-- luacheck: globals onTypeChanged
function onTypeChanged()
	if super and super.onTypeChanged then
		super.onTypeChanged();
	end
	toggleDetail();
end

function onInit()
	if super and super.onInit then
		super.onInit();
	end
	DB.addHandler(getDatabaseNode().getNodeName(), "onChildUpdate", toggleDetail);
	toggleDetail();
end

function onClose()
	if super and super.onClose then
		super.onClose();
	end
	DB.removeHandler(getDatabaseNode().getNodeName(), "onChildUpdate", toggleDetail);
end