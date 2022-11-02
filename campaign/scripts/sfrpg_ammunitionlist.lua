--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

--	luacheck: globals onFilter
local runOnce = false

function onFilter(w)
	if not runOnce then
		runOnce = true
		
	end
	if w.subtype.getValue() == 'Ammunition' then
		return true
	end
	return false
end
