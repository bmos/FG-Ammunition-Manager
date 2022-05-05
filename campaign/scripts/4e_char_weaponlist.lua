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
		if maxammo then maxammo.setLink(nodeAmmoLink.getChild('count')); end
		if missedshots then missedshots.setLink(nodeAmmoLink.getChild('missedshots')); end
	else
		if maxammo then maxammo.setLink(); end
		if missedshots then missedshots.setLink(); end
	end
	ammocounter.setVisible(bRanged and not bInfiniteAmmo and not nodeAmmoLink);

	local bShow = bRanged and activatedetail and (activatedetail.getValue() == 1);
	if ammunition_label then ammunition_label.setVisible(bShow); end
	if recoverypercentage then recoverypercentage.setVisible(bShow); end
	if label_ammopercentof then label_ammopercentof.setVisible(bShow); end
	if missedshots then missedshots.setVisible(bShow); end
	if recoverammo then recoverammo.setVisible(bShow); end
	if ammopicker then ammopicker.setComboBoxVisible(bShow); end

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
