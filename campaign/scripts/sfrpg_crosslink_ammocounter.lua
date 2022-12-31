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
	if not sLink or bLocked or isReadOnly() then return end

	bLocked = true

	local currentAmmo = DB.getValue(sLink, 'number', 0)
	local usage = AmmunitionManager.getWeaponUsage(window.getDatabaseNode())
	local excess = math.fmod(currentAmmo, usage)
	DB.setValue(sLink, 'number', math.min(excess + (getMaxValue() - getCurrentValue()) * usage, getMaxValue() * usage))

	bLocked = false
end

function onLinkUpdated()
	if not sLink or bLocked then return end

	bLocked = true

	setCurrentValue(getMaxValue() - math.floor(DB.getValue(sLink, 0) / AmmunitionManager.getWeaponUsage(window.getDatabaseNode())))

	if self.update then self.update() end

	bLocked = false
end

--	luacheck: globals setLink
function setLink(dbnode)
	if sLink then
		DB.removeHandler(sLink, 'onUpdate', onLinkUpdated)
		sLink = nil
	end

	if not dbnode then
		setCurrentValue(getMaxValue())
		return
	end

	sLink = dbnode.getPath()

	DB.addHandler(sLink, 'onUpdate', onLinkUpdated)

	onLinkUpdated()
end
