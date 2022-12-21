--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--
--	This table exists so people can add search terms for weapons that should have a load button.
--	luacheck: globals tLoadWeapons tLoadWeaponProps
tLoadWeapons = { 'loadaction' }
tLoadWeaponProps = { 'loadaction' }

--	luacheck: globals calculateMargin
function calculateMargin(nDC, nTotal)
	Debug.console('AmmunitionManager.calculateMargin - DEPRECATED - 2022-07-13 - Use AttackMargins.calculateMargin')
	if AttackMargins and AttackMargins.calculateMargin then AttackMargins.calculateMargin(nDC, nTotal) end
end

--	luacheck: globals getShortcutNode
function getShortcutNode(node, shortcutName)
	shortcutName = shortcutName or 'shortcut'
	local _, sRecord = DB.getValue(node, shortcutName, '')
	if sRecord and sRecord ~= '' then return DB.findNode(sRecord) end
end

---	This function finds the correct node for a weapon's ammunition.
--	It first checks for a path saved in ammoshortcut. If found, databasenode record is returned.
--	If no path is found, it checks to see if the ammo name is known.
--	If ammo name is available, it searches through the inventory for a match.
--	If found, databasenode record is returned.
--	If no match is found, nothing is returned.
--	luacheck: globals getAmmoNode
function getAmmoNode(nodeWeapon)
	-- check for saved ammoshortcut windowreference and return if found
	local ammoNode = getShortcutNode(nodeWeapon, 'ammoshortcut')
	if ammoNode then return ammoNode end

	-- if ammoshortcut does not provide a good node and weapon is ranged, try searching the inventory.
	local bRanged = DB.getValue(nodeWeapon, 'type', 0) == 1
	if User.getRulesetName() == '5E' then bRanged = bRanged or DB.getValue(nodeWeapon, 'type', 0) == 2 end

	if bRanged then
		local sAmmo = DB.getValue(nodeWeapon, 'ammopicker', '')
		if sAmmo ~= '' then
			Debug.console(Interface.getString('debug_ammo_noammoshortcutfound'))
			local nodeInventory = nodeWeapon.getChild('...inventorylist')
			if nodeInventory.getName() == 'inventorylist' then
				for _, nodeItem in pairs(nodeInventory.getChildren()) do
					if ItemManager.getIDState(nodeItem) then
						if DB.getValue(nodeItem, 'name', '') == sAmmo then return nodeItem end
					else
						if DB.getValue(nodeItem, 'nonid_name', '') == sAmmo then return nodeItem end
					end
				end
				Debug.console(Interface.getString('debug_ammo_itemnotfound'))
			else
				Debug.console(Interface.getString('debug_ammo_noinventoryfound'))
			end
		end
	end
end

--	luacheck: globals getWeaponName
function getWeaponName(s)
	local sWeaponName = s:gsub('%[ATTACK %(%u%)%]', '')
	sWeaponName = sWeaponName:gsub('%[ATTACK #%d+ %(%u%)%]', '')
	sWeaponName = sWeaponName:gsub('%[%u+%]', '')
	if sWeaponName:match('%[USING ') then sWeaponName = sWeaponName:match('%[USING (.-)%]') end
	sWeaponName = sWeaponName:gsub('%[.+%]', '')
	sWeaponName = sWeaponName:gsub(' %(vs%. .+%)', '')
	sWeaponName = StringManager.trim(sWeaponName)

	return sWeaponName or ''
end

local sRuleset
--	luacheck: globals getAmmoRemaining
function getAmmoRemaining(rSource, nodeWeapon, nodeAmmoLink)
	local function isInfiniteAmmo()
		local bInfiniteAmmo = DB.getValue(nodeWeapon, 'type', 0) ~= 1
		if sRuleset == '5E' then
			local bThrown = DB.getValue(nodeWeapon, 'type', 0) == 2
			bInfiniteAmmo = (bInfiniteAmmo and not bThrown)
		end
		return bInfiniteAmmo or EffectManager.hasCondition(rSource, 'INFAMMO')
	end

	local bInfiniteAmmo = isInfiniteAmmo()

	local nAmmo = 0
	if not bInfiniteAmmo then
		if nodeAmmoLink then
			nAmmo = DB.getValue(nodeAmmoLink, 'count', 0)
		else
			local nMaxAmmo = DB.getValue(nodeWeapon, 'maxammo', 0)
			local nAmmoUsed = DB.getValue(nodeWeapon, 'ammo', 0)
			nAmmo = nMaxAmmo - nAmmoUsed
			if nMaxAmmo == 0 then bInfiniteAmmo = true end
		end
	end
	return nAmmo, bInfiniteAmmo
end

--	tick off used ammunition, count misses, post 'out of ammo' chat message
--	luacheck: globals ammoTracker
function ammoTracker(rSource, sDesc, sResult, bCountAll)
	if not ActorManager.isPC(rSource) then return; end

	local function writeAmmoRemaining(nodeWeapon, nodeAmmoLink, nAmmoRemaining, sWeaponName)
		local messagedata = { text = '', sender = ActorManager.resolveActor(nodeWeapon.getChild('...')).sName, font = 'emotefont' }
		if nodeAmmoLink then
			if nAmmoRemaining == 0 then
				messagedata.text = string.format(Interface.getString('char_actions_usedallammo'), sWeaponName)
				Comm.deliverChatMessage(messagedata)

				DB.setValue(nodeAmmoLink, 'count', 'number', nAmmoRemaining)
			else
				DB.setValue(nodeAmmoLink, 'count', 'number', nAmmoRemaining)
			end
		else
			if nAmmoRemaining <= 0 then
				messagedata.text = string.format(Interface.getString('char_actions_usedallammo'), sWeaponName)
				Comm.deliverChatMessage(messagedata)
			end
			local nMaxAmmo = DB.getValue(nodeWeapon, 'maxammo', 0)
			DB.setValue(nodeWeapon, 'ammo', 'number', nMaxAmmo - nAmmoRemaining)
		end
	end

	local function countMissedShots(nodeAmmoLink)
		if bCountAll or (sResult == 'miss' or sResult == 'fumble') then -- counting misses
			DB.setValue(nodeAmmoLink, 'missedshots', 'number', DB.getValue(nodeAmmoLink, 'missedshots', 0) + 1)
		end
	end

	--	if weapon is fragile, set as broken or destroyed and post a chat message.
	local function breakWeapon(nodeWeapon, sWeaponName)
		-- examine weapon properties to check if fragile
		local function isFragile()
			local sWeaponProperties = DB.getValue(nodeWeapon, 'properties', ''):lower()
			local bIsFragile = (sWeaponProperties:find('fragile') or 0) > 0
			local bIsMasterwork = sWeaponProperties:find('masterwork') or false
			local bIsBone = sWeaponProperties:find('bone') or false
			local bIsMagic = DB.getValue(nodeWeapon, 'bonus', 0) > 0
			return (bIsFragile and not bIsMagic and (not bIsMasterwork or bIsBone))
		end

		if nodeWeapon and isFragile() then
			local nBroken = DB.getValue(nodeWeapon, 'broken', 0)
			local nItemHitpoints = DB.getValue(nodeWeapon, 'hitpoints', 0)
			local nItemDamage = DB.getValue(nodeWeapon, 'itemdamage', 0)
			local messagedata = { text = '', sender = rSource.sName, font = 'emotefont' }
			if nBroken == 0 then
				DB.setValue(nodeWeapon, 'broken', 'number', 1)
				DB.setValue(nodeWeapon, 'itemdamage', 'number', math.floor(nItemHitpoints / 2) + math.max(nItemDamage, 1))
				messagedata.text = string.format(Interface.getString('char_actions_fragile_broken'), sWeaponName)
				Comm.deliverChatMessage(messagedata)
			elseif nBroken == 1 then
				DB.setValue(nodeWeapon, 'broken', 'number', 2)
				DB.setValue(nodeWeapon, 'itemdamage', 'number', nItemHitpoints + math.max(nItemDamage, 1))
				messagedata.text = string.format(Interface.getString('char_actions_fragile_destroyed'), sWeaponName)
				Comm.deliverChatMessage(messagedata)
			end
		end
	end

	local sWeaponName = getWeaponName(sDesc)
	if not sDesc:match('%[CONFIRM%]') and sWeaponName ~= '' then
		local nodeWeaponList = ActorManager.getCreatureNode(rSource).getChild('.weaponlist')
		for _, nodeWeapon in pairs(nodeWeaponList.getChildren()) do
			local sWeaponNameFromNode = getWeaponName(DB.getValue(nodeWeapon, 'name', ''))
			if sWeaponNameFromNode == sWeaponName then
				if sResult == 'fumble' then -- break fragile weapon on natural 1
					local _, sWeaponNode = DB.getValue(nodeWeapon, 'shortcut', '')
					local nodeWeaponLink = DB.findNode(sWeaponNode)
					breakWeapon(nodeWeaponLink, sWeaponName)
				end
				local bMelee = DB.getValue(nodeWeapon, 'type', 0) == 0
				if (sDesc:match('%[ATTACK %(R%)%]') or sDesc:match('%[ATTACK #%d+ %(R%)%]')) and not bMelee then
					local nodeAmmoLink = getAmmoNode(nodeWeapon)
					local nAmmoRemaining, bInfiniteAmmo = getAmmoRemaining(rSource, nodeWeapon, nodeAmmoLink)
					if not bInfiniteAmmo then
						writeAmmoRemaining(nodeWeapon, nodeAmmoLink, nAmmoRemaining - 1, sWeaponName)
						countMissedShots(nodeAmmoLink or nodeWeapon)
					end
				end
			end
		end
	end
end

--	luacheck: globals getWeaponUsage
function getWeaponUsage(attackNode)
	local nodeLinkedWeapon = AmmunitionManager.getShortcutNode(attackNode, 'shortcut')
	if nodeLinkedWeapon then return tonumber(DB.getValue(nodeLinkedWeapon, 'usage', 1)) or 1 end
	return 1
end

function useAmmoStarfinder(rSource, rRoll)
	
	local attackNode = DB.findNode(rRoll.sAttackNode)
	if DB.getValue(nodeLinkedWeapon, 'type', 0) == 1 then -- ranged attack
		local ammoNode = AmmunitionManager.getAmmoNode(attackNode)
		local nAmmoCount, bInfiniteAmmo = AmmunitionManager.getAmmoRemaining(rSource, attackNode, ammoNode)
		if bInfiniteAmmo then return end
		local weaponUsage = AmmunitionManager.getWeaponUsage(attackNode)
		local remainingAmmo = nAmmoCount - weaponUsage
		DB.setValue(ammoNode, 'count', 'number', remainingAmmo)
		if remainingAmmo <= 0 then
			local attackName = DB.getValue(attackNode, 'name', '')
			local messageText = string.format(Interface.getString('char_actions_usedallammo'), attackName)
			local messagedata = { text = messageText, sender = ActorManager.resolveActor(attackNode.getChild('...')).sName, font = 'emotefont' }
			Comm.deliverChatMessage(messagedata)
		end
	end
end

local function noDecrementAmmo() end

-- Function Overrides

local onPostAttackResolve_old
local function onPostAttackResolve_new(rSource, rTarget, rRoll, rMessage, ...)
	onPostAttackResolve_old(rSource, rTarget, rRoll, rMessage, ...)
	AmmunitionManager.ammoTracker(rSource, rRoll.sDesc, rRoll.sResult, true)
end

local function onPostAttackResolve_starfinder(rSource, rTarget, rRoll, rMessage, ...)
	onPostAttackResolve_old(rSource, rTarget, rRoll, rMessage, ...)
	AmmunitionManager.useAmmoStarfinder(rSource, rRoll)
end

function onInit()
	-- replace result handlers
	if sRuleset == 'PFRPG' or sRuleset == '3.5E' then
		tLoadWeapons = { 'loadaction', 'firearm', 'crossbow', 'javelin', 'ballista', 'windlass', 'pistol', 'rifle', 'sling' }
	elseif sRuleset == '4E' then
		tLoadWeapons = { 'loadaction', 'ballista' }
	elseif sRuleset == '5E' then
		CharWeaponManager.decrementAmmo = noDecrementAmmo
	end

	onPostAttackResolve_old = ActionAttack.onPostAttackResolve
	if sRuleset == 'SFRPG' then -- SFRPG handled differently
		ActionAttack.onPostAttackResolve = onPostAttackResolve_starfinder
	else
		ActionAttack.onPostAttackResolve = onPostAttackResolve_new
	end
end
