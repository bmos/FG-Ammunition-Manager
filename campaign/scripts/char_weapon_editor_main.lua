-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if super and super.onInit then
		super.onInit();
	end
	local sNode = getDatabaseNode().getPath();
	DB.addHandler(sNode, "onChildUpdate", onDataChanged);
	onDataChanged();
end

function onClose()
	if super and super.onClose then
		super.onClose();
	end
	local sNode = getDatabaseNode().getPath();
	DB.removeHandler(sNode, "onChildUpdate", onDataChanged);
end

function onDataChanged()	
	if super and super.onDataChanged then
		super.onDataChanged();
	end
	local nodeWeapon = getDatabaseNode();
	local bRanged = DB.getValue(nodeWeapon, 'type', 0) == 1;
	header_ammo.setVisible(bRanged);
	ammopicker.setVisible(bRanged);
	label_ammopicker.setVisible(bRanged);
	recoverypercentage.setVisible(bRanged);
	label_recoverypercentage.setVisible(bRanged);
	label_ammopercentof.setVisible(bRanged);
	missedshots.setVisible(bRanged);
	label_missedshots.setVisible(bRanged);
	recoverammo.setVisible(bRanged);
end
