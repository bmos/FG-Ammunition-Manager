--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--
--	luacheck: globals onLinkUpdated isReadOnly nolinkwidget addBitmapWidget onDrop onValueChanged setValue getValue setReadOnly
local bLocked = false;
local sLink = nil;
local widget = nil;

function onInit()
	if super and super.onInit then super.onInit(); end

	if self.update then self.update(); end

	onLinkUpdated()
end

function onClose() if sLink then DB.removeHandler(sLink, 'onUpdate', onLinkUpdated); end end

function onDrop(_, _, draginfo)
	if Session.IsHost then
		if draginfo.getType() ~= 'number' then return false; end

		if self.handleDrop then
			self.handleDrop(draginfo);
			return true;
		end
	end
end

function onValueChanged()

	if sLink then
		if not bLocked then
			bLocked = true;

			if sLink and not isReadOnly() then DB.setValue(sLink, 'number', getValue()); end

			if self.update then self.update(); end

			bLocked = false;
		end
	else
		if self.update then self.update(); end
	end
end

function onLinkUpdated()
	if sLink and not bLocked then
		bLocked = true;

		setValue(DB.getValue(sLink, 0));

		if self.update then self.update(); end

		bLocked = false;
	end
end

--	luacheck: globals setLink
function setLink(dbnode, bLock)
	if sLink then
		DB.removeHandler(sLink, 'onUpdate', onLinkUpdated);
		sLink = nil;
		widget.destroy()
	end

	if dbnode then
		sLink = dbnode.getPath();

		if not nolinkwidget then
			widget = addBitmapWidget('field_linked');
			widget.setPosition('bottomright', 0, -2);
		end

		if bLock then setReadOnly(true); end

		DB.addHandler(sLink, 'onUpdate', onLinkUpdated);

		onLinkUpdated();
	elseif User.getRulesetName() == 'SFRPG' then
		DB.removeHandler(sLink, 'onUpdate', onLinkUpdated);

		setValue(0)
	end
end
