--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals onFilter

function onFilter(w)
	return w.subtype.getValue() == 'Ammunition' and w.location.getValue() == ''
end
