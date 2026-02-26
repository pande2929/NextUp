-- events.lua

local ns = NextUp
local lastCastSpell = 0
local lastButton = nil
ns.recSpellID = nil

------------------------------------------------------------
-- Function: When assisted highlight spell changes.
------------------------------------------------------------
local function OnSpellChange()
    -- Get suggested spell.
	local spellID = C_AssistedCombat.GetNextCastSpell()

	if spellID then
		ns.recSpellID = spellID

		ns:ApplyDimEffect(not ns:IsSpellReady(spellID))
		ns:UpdateHighlightFrame(spellID)
	end
end

------------------------------------------------------------
-- Function: When player leaves combat.
------------------------------------------------------------
local function OnLeaveCombat()
	if ns.dirtyUI then
		ns:RefreshUI()
	end
end

------------------------------------------------------------
-- Function: Calls the ElvUI AssistedOnUpdate function and then
-- triggers AssistedCombatManager.OnAssistedHighlightSpellChange
------------------------------------------------------------
function ns:AssistedOnUpdate(elapsed)
	local E = unpack(ElvUI)
	local AB = E:GetModule('ActionBars')
	
	AB.AssistedOnUpdate(self, elapsed)

	EventRegistry:TriggerEvent("AssistedCombatManager.OnAssistedHighlightSpellChange");
end

------------------------------------------------------------
-- Function: Registers events.
------------------------------------------------------------
function ns:RegisterEvents()
    -- Track combat state.
    local c = CreateFrame("Frame")
    c:RegisterEvent("PLAYER_REGEN_ENABLED")
    c:SetScript("OnEvent", OnLeaveCombat)

	-- Track specialization changed
	-- Necessary since I'm currently seeing an issue where assisted highlight needs to be disabled and re-enabled.
	local n = CreateFrame("Frame")
	n:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	n:SetScript("OnEvent", function(self, event, unit)
		if unit == "player" then
			SetCVar("assistedCombatHighlight", false)
			C_Timer.After(2, function()
				SetCVar("assistedCombatHighlight", true)
			end)
		end
	end)

	-- Print all action slots
	--ns:PrintActionBarInfo()

	-- Track when assisted highlight button changes.
	EventRegistry:RegisterCallback("AssistedCombatManager.OnAssistedHighlightSpellChange", OnSpellChange)

	if (ns.UsingElvUI == true) then
		-- ElvUI overrides the built in AssistedCombatManager.OnUpdate function with its own. 
		-- We need to use ours instead and then call theirs.
		_G.AssistedCombatManager.OnUpdate = ns.AssistedOnUpdate
	end

    -- Track whenever player uses an ability.
    hooksecurefunc("UseAction", function(slot, checkCursor, onSelf)
        local _, spellID = GetActionInfo(slot)
        if spellID then
            lastCastSpell = spellID
        end
    end)

	-- Listen for spell readiness updates
	local g = CreateFrame("Frame")
	g:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
	g:SetScript("OnEvent", function(self, event)
		-- If no suggested spell, ensure no dim effect is applied.
		if ns.recSpellID == nil then
			ns:ApplyDimEffect(false)
			return
		end

		local spellID = ns.recSpellID

		local spInfo = C_Spell.GetSpellInfo(spellID)
		ns:ApplyDimEffect(not ns:IsSpellReady(spellID))
	end)

	-- Create listeners for casting events.
	local f = CreateFrame("Frame")
	f:RegisterEvent("UNIT_SPELLCAST_START")
	f:RegisterEvent("UNIT_SPELLCAST_STOP")
	f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	f:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	f:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	f:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    f:RegisterEvent("UNIT_SPELLCAST_EMPOWER_START")
    f:RegisterEvent("UNIT_SPELLCAST_EMPOWER_STOP")

    -- When should the cooldown animation display?
    -- Ability or macro used. Automatic casts or abilities should not show the animation.

	f:SetScript("OnEvent", function(_, event, unit, _, spellID)
		if unit ~= "player" then
			return
		end
		
		-- Show the cooldown animation with duration of spell, otherwise use GCD for instant casts.
		if event == "UNIT_SPELLCAST_START" then
			local _, _, _, startTimeMS, endTimeMS = UnitCastingInfo("player")
			
			if startTimeMS and endTimeMS then
				ns:ShowCooldownAnimation(startTimeMS / 1000.0, (endTimeMS - startTimeMS) / 1000.0)
			end
		elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
			local _, _, _, startTimeMS, endTimeMS = UnitChannelInfo("player")

			-- Check for empowered and channeled casts. Otherwise proceed.
			if startTimeMS == nil and endTimeMS == nil and lastCastSpell == spellID then
				-- Nope, just a regular instant cast
				-- check if spell is on GCD
				--[[
				local scInfo = C_Spell.GetSpellCharges(spellID)
				if scInfo and scInfo.cooldownStartTime then
					print(not scInfo.currentCharges, not not scInfo.currentCharges, scInfo.currentCharges)
					--ns:ShowCooldownAnimation(scInfo.cooldownStartTime, scInfo.cooldownDuration)
				end
				]]

				if ns:IsSpellOnGCD(spellID) then
					--local scInfo = C_Spell.GetSpellCharges(spellID)

					local cdInfo = C_Spell.GetSpellCooldown(61304)
					ns:ShowCooldownAnimation(cdInfo.startTime, cdInfo.duration)
					
					--[[
					local cdSpellInfo = C_Spell.GetSpellCooldown(spellID)
					local spellCharges = C_Spell.GetSpellCharges(spellID)
					local spInfo = C_Spell.GetSpellInfo(spellID)
					print(spInfo.name, spellCharges.cooldownDuration)
					if spellCharges.cooldownDuration == 0 then
						print("TEST")
					end
					]]
				end
			end
        elseif event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_EMPOWER_START" then
			local _, _, _, startTimeMS, endTimeMS = UnitChannelInfo("player")

            if startTimeMS and endTimeMS then
			    ns:ShowCooldownAnimation(startTimeMS / 1000.0, (endTimeMS - startTimeMS) / 1000.0)
				--print(startTimeMS / 1000.0, (endTimeMS - startTimeMS) / 1000.0)
		    end
		elseif
			event == "UNIT_SPELLCAST_INTERRUPTED" or 
            event == "UNIT_SPELLCAST_CHANNEL_STOP" or 
            event == "UNIT_SPELLCAST_STOP" or
            event == "UNIT_SPELLCAST_EMPOWER_STOP" then
			ns:ShowCooldownAnimation(0, 0)
        end
	end)
end

------------------------------------------------------------
-- Function: Fires when a setting is changed.
------------------------------------------------------------
function ns:OnSettingChanged(setting, value)
    -- flag the UI as dirty
    ns.dirtyUI = true

    -- Don't make changes in combat to avoid taint        
    if not InCombatLockdown() then
	    -- Update the UI
        ns:RefreshUI()
    else
        print("Setting change will be deferred until out of combat.")
    end
end

------------------------------------------------------------
-- Event handler for addon initialization.
------------------------------------------------------------
local login = CreateFrame("Frame")
login:RegisterEvent("PLAYER_LOGIN")

login:SetScript("OnEvent", function(_, event, arg1)
	if event == "PLAYER_LOGIN" then
		-- Load or initialize databases
		NextUp_SavedVariables = NextUp_SavedVariables or {}

		if not NextUp_SavedVariables.settings then
			NextUp_SavedVariables.settings = {
				fontSize = 40,
				offsetX = 0,
				offsetY = -180,
				sizeX = 62,
				sizeY = 62,
				buttonScale = 1.0,
				point = "CENTER",
				textPoint = "CENTER",
				textOffsetX = 0,
				textOffsetY = 0,
				showOverlayGlow = false,
                hideActionBar1 = false,
                hideActionBar2 = false,
                hideActionBar3 = false,
				hideCastbar = false,
				enabled = true
			}
		end

		--print(ns.name .. " settings initialized.")

		--[[
		SLASH_NEXTUP1 = "/nextup"
		SLASH_NEXTUP2 = "/nu"

		SlashCmdList["NEXTUP"] = function(msg)
			msg = msg:lower()
			if msg == "showbars" then
				--NextUpFrame:Show()
			elseif msg == "hidebars" then
				--NextUpFrame:Hide()
			else
				print("NextUp commands:")
				print("/nextup showbars - Show all action bars.")
				print("/nextup hidebars - Hide the NextUp frame")
			end
		end
		]]

		-- Check for other addons that we need to account for.
		local elvUILoaded, elvUILoading = C_AddOns.IsAddOnLoaded("ElvUI")
		ns.UsingElvUI = elvUILoaded or elvUILoading

		local bt4Loaded, bt4Loading = C_AddOns.IsAddOnLoaded("Bartender4")
		ns.UsingBT4 = bt4Loaded or bt4Loading

		-- Check if Assisted Hightlight is active. If it isn't, then ask the user if they want to enable it.
		if GetCVarBool("assistedCombatHighlight") then
			ns:OnInitialize()
		else
			--print("Blizzard's Assisted Highlight feature is not enabled. Please enable and reload.")
			StaticPopupDialogs["NEXTUP_ADDON_CONFIRM"] = {
				text = "Blizzard's Assisted Highlight feature is not enabled, which the NextUp addon requires. Do you wish to enable it?",
				button1 = "Yes",
				button2 = "No",
				OnAccept = function(self)
					SetCVar("assistedCombatHighlight", true)
					ns:OnInitialize()
				end,
				OnCancel = function(self) end,
				timeout = 0, -- stay open until user clicks
				whileDead = true, -- show even if the player is dead
				hideOnEscape = true, -- pressing ESC closes it
				preferredIndex = 3, -- avoid frame conflicts
			}

			-- Show the popup:
			StaticPopup_Show("NEXTUP_ADDON_CONFIRM")
		end
	end
end)
