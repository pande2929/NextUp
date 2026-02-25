-- utils.lua

local ns = NextUp

-- TODO: Create barPrefixes for ElvUI naming.
-- "ElvUI_BarXButtonX" "ElvUI_BarX"
local barPrefixes = {
	"ActionButton",
	"MultiBarBottomLeftButton",
	"MultiBarBottomRightButton",
	"MultiBarRightButton",
	"MultiBarLeftButton",
	"MultiBar5Button",
	"MultiBar6Button",
	"MultiBar7Button"
}

-- TODO: Create actionBarPrefixMatrix for ElvUI naming.
local actionBarPrefixMatrix = {
	["ActionButton"] = "ACTIONBUTTON",
	["MultiBarBottomLeftButton"] = "MULTIACTIONBAR1BUTTON",
	["MultiBarBottomRightButton"] = "MULTIACTIONBAR2BUTTON",
	["MultiBarRightButton"] = "MULTIACTIONBAR3BUTTON",
	["MultiBarLeftButton"] = "MULTIACTIONBAR4BUTTON",
	["MultiBar5Button"] = "MULTIACTIONBAR5BUTTON",
	["MultiBar6Button"] = "MULTIACTIONBAR6BUTTON",
	["MultiBar7Button"] = "MULTIACTIONBAR7BUTTON"
}

------------------------------------------------------------
-- Function: Returns true if ElvUI is loaded.
------------------------------------------------------------
function ns:IsElvUILoaded()
	local loaded, loading = C_AddOns.IsAddOnLoaded("ElvUI")
	return loaded or loading
end

------------------------------------------------------------
-- Function: Builds a matrix of keybinds to lookup and returns it.
------------------------------------------------------------
local function GenerateKeybindMatrix()
	local slotToKeybindMatrix = {}

	for _, barPrefix in pairs(barPrefixes) do
		for i = 1, 12 do
			local name = barPrefix .. i
			local button = _G[name]

			if button then
				local actionSlot = button.action

				-- Needs to be name of actionbutton
				local actionBarButtonName = actionBarPrefixMatrix[barPrefix] .. i
				local keys = { GetBindingKey(actionBarButtonName) }

				if #keys > 0 and actionSlot then
					local binding = keys[1] -- default to first binding

					binding = binding:upper():gsub("SHIFT", "S")

					-- Save to keybind matrix
					slotToKeybindMatrix[actionSlot] = binding
				end
			end
		end
	end

	return slotToKeybindMatrix
end

------------------------------------------------------------
-- Function: Returns the keybinds for a given action button.
------------------------------------------------------------
function ns:GetKeybinds(spellID)
	if not spellID then
		return nil
	end

	-- Get action slots for spell.
	local slots = C_ActionBar.FindSpellActionButtons(spellID)
	local slotToKeybindMatrix = GenerateKeybindMatrix()

	if slots then
		for _, slot in ipairs(slots) do
			if slotToKeybindMatrix[slot] then
				return slotToKeybindMatrix[slot]
			end
		end
	end
end

------------------------------------------------------------
-- Function: Checks if spell is ready or not.
------------------------------------------------------------
function ns:IsSpellReady(spellID)
	if not spellID then return false end

    local isUsable, insufficientPower = C_Spell.IsSpellUsable(spellID)

    if not isUsable or insufficientPower then
        return false
    end

    return true
end

------------------------------------------------------------
-- Function: Checks if the spell is on the GCD.
------------------------------------------------------------
function ns:IsSpellOnGCD(spellID)
	local _, gcdMS = GetSpellBaseCooldown(spellID)
	return gcdMS ~= 0
end