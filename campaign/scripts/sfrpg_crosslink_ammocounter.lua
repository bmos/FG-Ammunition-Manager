--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--
--	luacheck: globals onLinkUpdated isReadOnly onDrop onValueChanged setValue getValue setReadOnly
local bLocked = false
local sLink = nil

function onInit()
	if super and super.onInit then super.onInit() end

	if self.update then self.update() end

	onLinkUpdated()
end

function onClose() if sLink then DB.removeHandler(sLink, 'onUpdate', onLinkUpdated) end end

-- function onDrop(_, _, draginfo)
-- 	if Session.IsHost then
-- 		if draginfo.getType() ~= 'number' then return false end

-- 		if self.handleDrop then
-- 			self.handleDrop(draginfo)
-- 			return true
-- 		end
-- 	end
-- end

function onValueChanged()
	Debug.chat("onValueChanged")
	if sLink then
		if not bLocked then
			bLocked = true
			
			if sLink and not isReadOnly() then DB.setValue(sLink, 'number', (getMaxValue() - getCurrentValue()) * window.getWeaponUsage()) end

			-- if self.update then self.update() end

			bLocked = false
		end
	else
		-- if self.update then self.update() end
	end
end

function onLinkUpdated()
	Debug.chat("onLinkUpdated")
	if sLink and not bLocked then
		bLocked = true

		setCurrentValue(getMaxValue() - math.floor(DB.getValue(sLink, 0) / window.getWeaponUsage()))

		if self.update then self.update() end

		bLocked = false
	end
end

--	luacheck: globals setLink
function setLink(dbnode, bLock)
	if sLink then
		DB.removeHandler(sLink, 'onUpdate', onLinkUpdated)
		sLink = nil
	end

	if dbnode then
		sLink = dbnode.getPath()

		if bLock == true then setReadOnly(true) end

		DB.addHandler(sLink, 'onUpdate', onLinkUpdated)
		onLinkUpdated()
	else
		setCurrentValue(getMaxValue())
	end
end
