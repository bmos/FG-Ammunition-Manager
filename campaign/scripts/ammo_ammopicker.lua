-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

local bParsed = false;
local aComponents = {};
local aAutoFill = {};

function getCompletion(s)
	for _,v in ipairs(aAutoFill) do
		if string.lower(s) == string.lower(string.sub(v, 1, #s)) then
			return v;
		end
	end
	return "";
end

function parseComponents()
	aComponents = {};
	
	-- Get the comma-separated strings
	local aClauses, aClauseStats = StringManager.split(getValue(), ",;\r", true);
	
	-- Check each comma-separated string for a potential skill roll or auto-complete opportunity
	for i = 1, #aClauses do
		table.insert(aComponents, {nStart = aClauseStats[i].startpos, nLabelEnd = aClauseStats[i].startpos + #aClauses[i], nEnd = aClauseStats[i].endpos, sLabel = aClauses[i] });
	end
	
	bParsed = true;
end

function onEnter()
	if not onChar(13) then
		local nCursor = getSelectionPosition();
		local sOldValue = getValue();
		local sNewValue = sOldValue:sub(1, nCursor-1) .. "\r" .. sOldValue:sub(nCursor);
		setValue(sNewValue);
		setCursorPosition(nCursor + 1);
		setSelectionPosition(0);
	end
	return true;
end

function onChar(nKeyCode)
	bParsed = false;
	
	local nCursor = getCursorPosition();
	local sValue = getValue();
	local sCompletion;
	
	-- If alpha character, then build a potential autocomplete
	if ((nKeyCode >= 65) and (nKeyCode <= 90)) or ((nKeyCode >= 97) and (nKeyCode <= 122)) then
		-- Parse the value string
		parseComponents();

		-- Build auto-complete for the current string
		for i = 1, #aComponents, 1 do
			if nCursor == aComponents[i].nLabelEnd then
				sCompletion = getCompletion(aComponents[i].sLabel);
				if sCompletion ~= "" then
					local sNewValue = sValue:sub(1, aComponents[i].nStart - 1) .. sCompletion .. sValue:sub(getCursorPosition());
					setValue(sNewValue);
					setSelectionPosition(nCursor + #sCompletion);
					return true;
				end

				return false;
			end
		end

	-- Or else if space character, then finish the autocomplete
	else
		if (((nKeyCode == 13) or (nKeyCode == 44) or (nKeyCode == 59)) and (nCursor >= 2)) then
			-- Parse the value string
			parseComponents();
			
			-- Find any string we may have just auto-completed
			local nLastCursor = nCursor - 1;
			for i = 1, #aComponents, 1 do
				if nCursor - 1 == aComponents[i].nLabelEnd then
					sCompletion = getCompletion(aComponents[i].sLabel);
					if sCompletion ~= "" then
						local sNewValue = string.sub(sValue, 1, aComponents[i].nStart - 1) .. sCompletion .. string.sub(sValue, nLastCursor);
						setValue(sNewValue);
						setCursorPosition(nCursor + #sCompletion);
						setSelectionPosition(nCursor + #sCompletion);
						return true;
					end

					return false;
				end
			end
		end
	end
end

function onGainFocus()
	aAutoFill = {};
	
	local nodeChar = window.getDatabaseNode().getChild('...')
	for _,v in pairs(nodeChar.getChild('inventorylist').getChildren()) do
		local sName = DB.getValue(v, "name", "");
		local bAmmo = DB.getValue(v, "subtype", ""):lower():match("ammunition") or DB.getValue(v, "subtype", ""):lower():match("ammo");
		if bAmmo then
			if sName ~= "" then
				table.insert(aAutoFill, sName);
			end
		end
	end
end
