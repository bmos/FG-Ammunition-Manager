--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

--	luacheck: globals onFilter
function onFilter(w)
	if w.subtype.getValue() == 'Ammunition' and w.location.getValue() == '' then
		return true
	end
	return false
end
