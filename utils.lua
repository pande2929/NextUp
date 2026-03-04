-- utils.lua

local ns = NextUp

ns.UsingElvUI = false
ns.UsingBT4 = false

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

local actionBarSlotMatrix = {
	["ACTIONBUTTON"] = 1,
	["MULTIACTIONBAR1BUTTON"] = 61,
	["MULTIACTIONBAR2BUTTON"] = 49,
	["MULTIACTIONBAR3BUTTON"] = 25,
	["MULTIACTIONBAR4BUTTON"] = 37,
	["MULTIACTIONBAR5BUTTON"] = 145,
	["MULTIACTIONBAR6BUTTON"] = 157,
	["MULTIACTIONBAR7BUTTON"] = 169
}

--[[
local actionSlotKeybinds = {}

local druidActionBarSlotMatrix = {
	[0] = 73,		-- cat
	[1] = 85,		-- prowl
	[2] = 97,		-- bear
	[3] = 109		-- moonkin
}

local stealthActionBarSlotMatrix = {
	[0] = 73		-- rogue stealth
}

function ns:PrintActionBarInfo()
	for _, barPrefix in pairs(barPrefixes) do
		for i = 1, 12 do
			local name = barPrefix .. i
			local button = _G[name]

			if button then
				local actionSlot = button.action
				local actionBarButtonName = actionBarPrefixMatrix[barPrefix] .. i

				print(name, actionBarButtonName, actionSlot)
			end
		end
	end
end

------------------------------------------------------------
-- Function: Generates a mapping of action slots names to keybinds.
------------------------------------------------------------
function ns:GenerateKeybindMapping() 
	actionSlotKeybinds = {}

	-- Primary action bars (1-8)
	for _, barPrefix in pairs(barPrefixes) do
		for i = 1, 12 do
			local name = barPrefix .. i
			local button = _G[name]
			local actionSlot = button.action

			local actionBarButtonName = actionBarPrefixMatrix[barPrefix] .. i
			local keys = { GetBindingKey(actionBarButtonName) }

			if #keys > 0 then
				local binding = keys[1] -- default to first binding

				binding = binding:upper():gsub("SHIFT", "S"):gsub("BUTTON", "B")
				actionSlotKeybinds[actionSlot] = binding
				print(actionSlot, actionSlotKeybinds[actionSlot])
			end
		end
	end
end
]]

local function LookUpKeyBind(actionSlot)
	--return actionSlotKeybinds[actionSlot]
	for _, barPrefix in pairs(barPrefixes) do
		for i = 1, 12 do
			local name = barPrefix .. i
			local button = _G[name]

			if button then
				local slot = button.action

				-- Needs to be name of actionbutton
				local actionBarButtonName = actionBarPrefixMatrix[barPrefix] .. i
				local keys = { GetBindingKey(actionBarButtonName) }
				--print("actionBarButtonName: " .. actionBarButtonName, "Keys: " .. #keys, "Slot: ".. slot, "actionSlot: " .. actionSlot)

				-- Some additional considerations for converting BT4 action slots to "standard" ones.
				if ns.UsingBT4 == true then
					-- check for paging on ACTIONBUTTON bar or when specific pages are used. (Stealth, druid forms)
					if actionBarPrefixMatrix[barPrefix] == "ACTIONBUTTON" and  (actionSlot >= 73 and actionSlot < 122) and (actionSlot % 12 == slot) then
						slot = actionSlot
					else 
						local slotBase = actionBarSlotMatrix[actionBarPrefixMatrix[barPrefix]]
						slot = slotBase + slot - 1
					end
				end

				--print(actionBarButtonName, slot, actionSlot)

				if #keys > 0 and slot == actionSlot then
					local binding = keys[1] -- default to first binding

					binding = binding:upper():gsub("SHIFT", "S"):gsub("BUTTON", "B"):gsub("ALT", "A"):gsub("CTRL", "C"):gsub("SPACE", "SPC")
					return binding
				end
			end
		end
	end
end

------------------------------------------------------------
-- Function: Returns the keybinds for a given action button.
------------------------------------------------------------
function ns:GetABKeybind(spellID)
	if not spellID then
		return nil
	end

	local slots = C_ActionBar.FindSpellActionButtons(spellID)


	if slots and #slots > 0 then
		-- Iterate through slots and get the one that matches
		for _, slot in pairs(slots) do
			local binding = LookUpKeyBind(slot)

			if binding then 
				return binding 

			end
		end
		--return LookUpKeyBind(slots[1])
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