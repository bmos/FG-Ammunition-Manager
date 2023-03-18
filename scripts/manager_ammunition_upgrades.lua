--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

local function upgradeDataV400()
	local upgradeVals = {
		ammopicker = { type = 'string', newname = 'ammopicker' },
		ammoshortcut = { type = 'windowreference', newname = 'ammopickershortcut' },
		recoverypercentage = { type = 'number', newname = 'missrecoverypercentage' },
		missedshots = { type = 'number', newname = 'missedshots' },
		isloaded = { type = 'number', newname = 'isloaded' },
	}

	for _, nodeChar in ipairs(DB.getChildList('charsheet')) do
		for _, nodeWeapon in ipairs(DB.getChildList(nodeChar, 'weaponlist')) do
			local nodeAmmoManager = DB.createChild(nodeWeapon, 'ammunitionmanager')
			for k, v in pairs(upgradeVals) do
				local upgradeNode = DB.getChild(nodeWeapon, k)
				if upgradeNode then
					if v.type == 'windowreference' then
						local upgradeType, upgradeValue = DB.getValue(upgradeNode)
						upgradeValue = string.gsub(upgradeValue, 'charsheet%.id%-%d+%.', '.....') -- keep path relative
						DB.setValue(nodeAmmoManager, v.newname, v.type, upgradeType, upgradeValue)
					else
						local upgradeValue = DB.getValue(upgradeNode)
						DB.setValue(nodeAmmoManager, v.newname, v.type, upgradeValue)
					end
					DB.deleteNode(upgradeNode)
				end
			end
		end
	end
end

local function extractSemanticVersion(sVersion)
	local sMajor, sMinor, sPatch = string.match(sVersion, 'v?(%d+)%.(%d*)%.(%d*).*')
	return { major = tonumber(sMajor or 0), minor = tonumber(sMinor or 0), patch = tonumber(sPatch or 0)}
end

local function atLeastNotOver(sVersion, sLowVer, sHighVer)
	local tVersion = extractSemanticVersion(sVersion)
	local tLow = extractSemanticVersion(sLowVer)
	local tHigh = extractSemanticVersion(sHighVer)

	local nVersion = tVersion.major * 10^6 + tVersion.minor * 10^3 + tVersion.patch
	local nLowVer = tLow.major * 10^6 + tLow.minor * 10^3 + tLow.patch
	local nHighVer = tHigh.major * 10^6 + tHigh.minor * 10^3 + tHigh.patch

	if (nVersion < nHighVer) and (nVersion >= nLowVer) then
		return true
	end
	return false
end

-- luacheck: globals upgradeData
function upgradeData()
	local sExtension = 'bmosammomanager'
	local aUpgrades = { -- should execute first, second, third, etc
		{ min = '0.0.0', max = '4.0.0', fn = upgradeDataV400 },
	}

	local nodeUpdateNotifier = DB.createChild(DB.getRoot(), 'extensionvcupgrades')
	local sDataVersion = DB.getValue(nodeUpdateNotifier, sExtension, '0.0.0')

	for _, tUpgrade in ipairs(aUpgrades) do
		if atLeastNotOver(sDataVersion, tUpgrade.min, tUpgrade.max) then
			tUpgrade.fn()
			DB.setValue(nodeUpdateNotifier, sExtension, 'string', tUpgrade.max)
		end
	end
end