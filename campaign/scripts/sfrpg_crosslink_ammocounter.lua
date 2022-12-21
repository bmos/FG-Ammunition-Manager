--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--
--	luacheck: globals onLinkUpdated isReadOnly onValueChanged setValue getValue setReadOnly setCurrentValue
--	luacheck: globals getCurrentValue getMaxValue
local sLink, bLocked

function onInit()
	if super and super.onInit then super.onInit() end

	if self.update then self.update() end

	onLinkUpdated()
end

function onClose()
	if sLink then DB.removeHandler(sLink, 'onUpdate', onLinkUpdated) end
end

function onValueChanged()
	if sLink then
		if not bLocked then
			bLocked = true

			if sLink and not isReadOnly() then DB.setValue(sLink, 'number', (getMaxValue() - getCurrentValue()) * AmmunitionManager.getWeaponUsage(window.getDatabaseNode())) end

			bLocked = false
		end
	end
end

function onLinkUpdated()
	if sLink and not bLocked then
		bLocked = true

		setCurrentValue(getMaxValue() - math.floor(DB.getValue(sLink, 0) / AmmunitionManager.getWeaponUsage(window.getDatabaseNode())))

		if self.update then self.update() end

		bLocked = false
	end
end

--	luacheck: globals setLink
function setLink(dbnode)
	if sLink then
		DB.removeHandler(sLink, 'onUpdate', onLinkUpdated)
		sLink = nil
	end

	if dbnode then
		sLink = dbnode.getPath()

		DB.addHandler(sLink, 'onUpdate', onLinkUpdated)

		onLinkUpdated()
	else
		setCurrentValue(getMaxValue())
	end
end
