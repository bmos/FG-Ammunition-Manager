--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals onLocationChanged onInit onClose

local function onLocationChanged() self.updateContainers() end

function onInit()
	if super and super.onInit then super.onInit() end

	DB.addHandler(DB.getPath(getDatabaseNode(), '*.location'), 'onUpdate', onLocationChanged)
end

function onClose()
	if super and super.onClose then super.onClose() end

	DB.removeHandler(DB.getPath(getDatabaseNode(), '*.location'), 'onUpdate', onLocationChanged)
end
