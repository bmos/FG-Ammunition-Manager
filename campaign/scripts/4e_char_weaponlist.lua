--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
--	luacheck: globals hasLoadAction
function hasLoadAction()
	local bHasLoadAction = false;
	local nodeWeapon = getDatabaseNode();
	local sWeaponProperties = string.lower(DB.getValue(nodeWeapon, 'properties', ''));
	local sWeaponName = string.lower(DB.getValue(nodeWeapon, 'name', 'ranged weapon'));
	for _, v in pairs(AmmunitionManager.tLoadWeapons) do
		if string.find(sWeaponName, v) then
			bHasLoadAction = true;
			break
		end
	end

	return (bHasLoadAction and not sWeaponProperties:find('load free'))
end

--	luacheck: globals toggleDetail
function toggleDetail()
	if super and super.toggleDetail then super.toggleDetail(); end

	local nodeWeapon = getDatabaseNode();
	local bRanged = (DB.getValue(nodeWeapon, 'type', 0) == 1);
	isloaded.setVisible(bRanged and hasLoadAction());

	local rActor = ActorManager.resolveActor(nodeWeapon.getChild('...'));
	local nodeAmmoLink = AmmunitionManager.getAmmoNode(nodeWeapon);
	local _, bInfiniteAmmo = AmmunitionManager.getAmmoRemaining(rActor, nodeWeapon, nodeAmmoLink);

	ammo_label.setVisible(bRanged);
	if nodeAmmoLink then
		maxammo.setLink(nodeAmmoLink.getChild('count'))
		missedshots.setLink(nodeAmmoLink.getChild('missedshots'))
	else
		maxammo.setLink()
		missedshots.setLink()
	end
	ammocounter.setVisible(bRanged and not bInfiniteAmmo and not nodeAmmoLink);

	local bShow = bRanged and (activatedetail.getValue() == 1);
	ammunition_label.setVisible(bShow);
	recoverypercentage.setVisible(bShow);
	label_ammopercentof.setVisible(bShow);
	missedshots.setVisible(bShow);
	recoverammo.setVisible(bShow);
	ammopicker.setComboBoxVisible(bShow);

	-- re-build ammopicker list when opening details
	if bShow then
		ammopicker.clear();
		ammopicker.onInit();
	end
end

--	luacheck: globals onTypeChanged
function onTypeChanged()
	if super and super.onTypeChanged then super.onTypeChanged(); end
	toggleDetail();
end

function onInit()
	if super and super.onInit then super.onInit(); end
	DB.addHandler(getDatabaseNode().getNodeName(), 'onChildUpdate', toggleDetail);
	toggleDetail();
end

function onClose()
	if super and super.onClose then super.onClose(); end
	DB.removeHandler(getDatabaseNode().getNodeName(), 'onChildUpdate', toggleDetail);
end
