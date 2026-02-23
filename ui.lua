-- ui.lua

local ns = NextUp
local highlightFrame = nil

------------------------------------------------------------
-- Function: Updates the main frame.
------------------------------------------------------------
local function RedrawHighlightFrame()
    -- Reset positioning.
	highlightFrame:ClearAllPoints()
    highlightFrame.tex:ClearAllPoints()
	highlightFrame.highlightText:ClearAllPoints()

	highlightFrame:SetSize(NextUp_SavedVariables.settings.sizeX, NextUp_SavedVariables.settings.sizeY)
	highlightFrame:SetPoint(
		NextUp_SavedVariables.settings.point,
		UIParent,
		NextUp_SavedVariables.settings.point,
		NextUp_SavedVariables.settings.offsetX,
		NextUp_SavedVariables.settings.offsetY
	)

    highlightFrame.tex:SetPoint("TOPLEFT", highlightFrame, "TOPLEFT", 2, -2)
    highlightFrame.tex:SetPoint("BOTTOMRIGHT", highlightFrame, "BOTTOMRIGHT", -2, 2)
    highlightFrame.tex:SetTexCoord(0.06, 0.94, 0.06, 0.94)

	-- Set Text
	highlightFrame.highlightText:SetFont(highlightFrame.highlightText:GetFont(), NextUp_SavedVariables.settings.fontSize, "OUTLINE")
	highlightFrame.highlightText:SetPoint(
		NextUp_SavedVariables.settings.textPoint,
		highlightFrame,
		NextUp_SavedVariables.settings.textPoint,
		NextUp_SavedVariables.settings.textOffsetX,
		NextUp_SavedVariables.settings.textOffsetY
	)
	highlightFrame.highlightText:SetTextColor(1, 1, 1, 1)
end

------------------------------------------------------------
-- Function: Creates the main frame.
------------------------------------------------------------
local function CreateHighlightFrame()
    local backdropInfo =
    {
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileEdge = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    }

    -- Create the frame
    highlightFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	highlightFrame:SetBackdrop(backdropInfo)
	highlightFrame:SetBackdropColor(0.2, 0.2, 0.2, 0)
	highlightFrame:SetBackdropBorderColor(0.2, 0.2, 0.2, 0)

    -- Text
	highlightFrame.highlightText = highlightFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")

    -- Texture
    highlightFrame.tex = highlightFrame:CreateTexture()

    -- Cooldown overlay
    highlightFrame.cooldown = CreateFrame("Cooldown", "$parentCooldown", highlightFrame, "CooldownFrameTemplate")
    highlightFrame.cooldown:SetPoint("TOPLEFT", highlightFrame, "TOPLEFT", 2, -2)
    highlightFrame.cooldown:SetPoint("BOTTOMRIGHT", highlightFrame, "BOTTOMRIGHT", -2, 2)
	highlightFrame.cooldown:SetDrawEdge(false)


	--GameTooltip:SetOwner(highlightFrame, "ANCHOR_RIGHT")

	-- Tooltip handlers
	--[[
	highlightFrame:SetScript("OnEnter", function(self)
		--GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

		if ns.recSpellID then
    		GameTooltip:SetSpellByID(ns.recSpellID)
			--GameTooltip:SetText("TEST", 1, 1, 1, 1)
    		GameTooltip:Show()
		end
	end)
	highlightFrame:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	]]

    RedrawHighlightFrame()
end

------------------------------------------------------------
-- Function: Show/hide action bars
------------------------------------------------------------
local function UpdateActionBars()
    if NextUp_SavedVariables.settings.hideActionBar1 then
        local bar = MainActionBar
        bar:SetAlpha(0)
    else
        local bar = MainActionBar
        bar:SetAlpha(1)
    end

    if NextUp_SavedVariables.settings.hideActionBar2 then
        local bar = MultiBarBottomLeft
        bar:SetAlpha(0)
    else
        local bar = MultiBarBottomLeft
        bar:SetAlpha(1)
    end

    if NextUp_SavedVariables.settings.hideActionBar3 then
        local bar = MultiBarBottomRight
        bar:SetAlpha(0)
    else
        local bar = MultiBarBottomRight
        bar:SetAlpha(1)
    end

	--[[
	if NextUp_SavedVariables.settings.hideCastbar then
		local castBar = PlayerCastingBarFrame
		--castBar:SetAlpha(0)
		castBar:UnregisterAllEvents()
	else
		local castBar = PlayerCastingBarFrame
		--castBar:SetAlpha(1)
	end
	]]

    ns.dirtyUI = false
end

------------------------------------------------------------
-- Function: Create the settings frame.
------------------------------------------------------------
local function CreateSettingsFrame()
	local category = Settings.RegisterVerticalLayoutCategory(ns.name)

	-- Enable / disable addon for this character
	--[[
    do 
        local name = "Enabled - " .. UnitName("player")
        local variable = "Enabled"
        local variableKey = "enabled"
        local variableTbl = NextUp_SavedVariables.settings
        local defaultValue = true

        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)
        setting:SetValueChangedCallback(ns.OnSettingChanged)

        local tooltip = "Enable or disable the highlight frame for current character."
        Settings.CreateCheckbox(category, setting, tooltip)
    end
	]]

	-- Anchor Point
	do
		local variable = "Anchor Point"
		local defaultValue = "CENTER"
		local name = "Anchor Point"
		local tooltip = "Anchor point for the main UI."

		local function GetOptions()
			local container = Settings.CreateControlTextContainer()
			container:Add("CENTER", "CENTER")
			container:Add("TOPLEFT", "TOPLEFT")
			container:Add("TOPRIGHT", "TOPRIGHT")
			container:Add("BOTTOMLEFT", "BOTTOMLEFT")
			container:Add("BOTTOMRIGHT", "BOTTOMRIGHT")
			container:Add("TOP", "TOP")
			container:Add("BOTTOM", "BOTTOM")
			container:Add("LEFT", "LEFT")
			container:Add("RIGHT", "RIGHT")
			return container:GetData()
		end

		local function GetValue()
			return NextUp_SavedVariables.settings.point
		end

		local function SetValue(value)
			NextUp_SavedVariables.settings.point = value
		end

		local setting = Settings.RegisterProxySetting(
			category,
			variable,
			type(defaultValue),
			name,
			defaultValue,
			GetValue,
			SetValue
		)
		setting:SetValueChangedCallback(ns.OnSettingChanged)
		Settings.CreateDropdown(category, setting, GetOptions, tooltip)
	end

	-- X Offset Slider
	do
		local name = "Offset X"
		local variable = "Offset X"
		local defaultValue = 0
		local minValue = -300
		local maxValue = 300
		local step = 5
		local tooltip = "Move the main UI left or right."

		local function GetValue()
			return NextUp_SavedVariables.settings.offsetX
		end

		local function SetValue(value)
			NextUp_SavedVariables.settings.offsetX = value
		end

		local setting = Settings.RegisterProxySetting(
			category,
			variable,
			type(defaultValue),
			name,
			defaultValue,
			GetValue,
			SetValue
		)
		setting:SetValueChangedCallback(ns.OnSettingChanged)

		local options = Settings.CreateSliderOptions(minValue, maxValue, step)
		options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
		Settings.CreateSlider(category, setting, options, tooltip)
	end

	-- Y Offset Slider
	do
		local name = "Offset Y"
		local variable = "Offset Y"
		local defaultValue = -140
		local minValue = -300
		local maxValue = 300
		local step = 5
		local tooltip = "Move the main UI up or down."

		local function GetValue()
			return NextUp_SavedVariables.settings.offsetY
		end

		local function SetValue(value)
			NextUp_SavedVariables.settings.offsetY = value
		end

		local setting = Settings.RegisterProxySetting(
			category,
			variable,
			type(defaultValue),
			name,
			defaultValue,
			GetValue,
			SetValue
		)
		setting:SetValueChangedCallback(ns.OnSettingChanged)

		local options = Settings.CreateSliderOptions(minValue, maxValue, step)
		options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
		Settings.CreateSlider(category, setting, options, tooltip)
	end

	-- Size X Slider
	do
		local name = "Width"
		local variable = "Width"
		local defaultValue = 62
		local minValue = 30
		local maxValue = 100
		local step = 1
		local tooltip = "Change the width of the main UI."

		local function GetValue()
			return NextUp_SavedVariables.settings.sizeX
		end

		local function SetValue(value)
			NextUp_SavedVariables.settings.sizeX = value
		end

		local setting = Settings.RegisterProxySetting(
			category,
			variable,
			type(defaultValue),
			name,
			defaultValue,
			GetValue,
			SetValue
		)
		setting:SetValueChangedCallback(ns.OnSettingChanged)

		local options = Settings.CreateSliderOptions(minValue, maxValue, step)
		options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
		Settings.CreateSlider(category, setting, options, tooltip)
	end

	-- Size Y Slider
	do
		local name = "Height"
		local variable = "Height"
		local defaultValue = 62
		local minValue = 30
		local maxValue = 100
		local step = 1
		local tooltip = "Change the width of the main UI."

		local function GetValue()
			return NextUp_SavedVariables.settings.sizeY
		end

		local function SetValue(value)
			NextUp_SavedVariables.settings.sizeY = value
		end

		local setting = Settings.RegisterProxySetting(
			category,
			variable,
			type(defaultValue),
			name,
			defaultValue,
			GetValue,
			SetValue
		)
		setting:SetValueChangedCallback(ns.OnSettingChanged)

		local options = Settings.CreateSliderOptions(minValue, maxValue, step)
		options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
		Settings.CreateSlider(category, setting, options, tooltip)
	end

	do
		local variable = "Keybind Anchor Point"
		local defaultValue = "CENTER"
		local name = "Font Anchor Point"
		local tooltip = "Anchor point for the keybind."

		local function GetOptions()
			local container = Settings.CreateControlTextContainer()
			container:Add("CENTER", "CENTER")
			container:Add("TOPLEFT", "TOPLEFT")
			container:Add("TOPRIGHT", "TOPRIGHT")
			container:Add("BOTTOMLEFT", "BOTTOMLEFT")
			container:Add("BOTTOMRIGHT", "BOTTOMRIGHT")
			container:Add("TOP", "TOP")
			container:Add("BOTTOM", "BOTTOM")
			container:Add("LEFT", "LEFT")
			container:Add("RIGHT", "RIGHT")
			return container:GetData()
		end

		local function GetValue()
			return NextUp_SavedVariables.settings.textPoint
		end

		local function SetValue(value)
			NextUp_SavedVariables.settings.textPoint = value
		end

		local setting = Settings.RegisterProxySetting(
			category,
			variable,
			type(defaultValue),
			name,
			defaultValue,
			GetValue,
			SetValue
		)
		setting:SetValueChangedCallback(ns.OnSettingChanged)
		Settings.CreateDropdown(category, setting, GetOptions, tooltip)
	end

	-- Text Offset X
	do
		local name = "Text Offset X"
		local variable = "Text Offset X"
		local defaultValue = 0
		local minValue = -100
		local maxValue = 100
		local step = 1
		local tooltip = "Change the position of the text left or right."

		local function GetValue()
			return NextUp_SavedVariables.settings.textOffsetX
		end

		local function SetValue(value)
			NextUp_SavedVariables.settings.textOffsetX = value
		end

		local setting = Settings.RegisterProxySetting(
			category,
			variable,
			type(defaultValue),
			name,
			defaultValue,
			GetValue,
			SetValue
		)
		setting:SetValueChangedCallback(ns.OnSettingChanged)

		local options = Settings.CreateSliderOptions(minValue, maxValue, step)
		options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
		Settings.CreateSlider(category, setting, options, tooltip)
	end

	-- Text Offset Y
	do
		local name = "Text Offset Y"
		local variable = "Text Offset Y"
		local defaultValue = 0
		local minValue = -100
		local maxValue = 100
		local step = 1
		local tooltip = "Change the position of the text up or down."

		local function GetValue()
			return NextUp_SavedVariables.settings.textOffsetY
		end

		local function SetValue(value)
			NextUp_SavedVariables.settings.textOffsetY = value
		end

		local setting = Settings.RegisterProxySetting(
			category,
			variable,
			type(defaultValue),
			name,
			defaultValue,
			GetValue,
			SetValue
		)
		setting:SetValueChangedCallback(ns.OnSettingChanged)

		local options = Settings.CreateSliderOptions(minValue, maxValue, step)
		options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
		Settings.CreateSlider(category, setting, options, tooltip)
	end

	-- Font Size
	do
		local name = "Font Size"
		local variable = "Font Size"
		local defaultValue = 40
		local minValue = 10
		local maxValue = 80
		local step = 1
		local tooltip = "Change the font size."

		local function GetValue()
			return NextUp_SavedVariables.settings.fontSize
		end

		local function SetValue(value)
			NextUp_SavedVariables.settings.fontSize = value
		end

		local setting = Settings.RegisterProxySetting(
			category,
			variable,
			type(defaultValue),
			name,
			defaultValue,
			GetValue,
			SetValue
		)
		setting:SetValueChangedCallback(ns.OnSettingChanged)

		local options = Settings.CreateSliderOptions(minValue, maxValue, step)
		options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
		Settings.CreateSlider(category, setting, options, tooltip)
	end

	-- Show/hide Overlay Glow
	--[[
    do 
        local name = "Show Ability Procs"
        local variable = "Show_OverlayGlow"
        local variableKey = "showOverlayGlow"
        local variableTbl = NextUp_SavedVariables.settings
        local defaultValue = false

        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)
        setting:SetValueChangedCallback(ns.OnSettingChanged)

        local tooltip = "Show or hide ability procs."
        Settings.CreateCheckbox(category, setting, tooltip)
    end
	]]

    -- Hide action bar 1
    do
        local name = "Hide Actionbar 1"
        local variable = "Hide_Actionbar1"
        local variableKey = "hideActionBar1"
        local variableTbl = NextUp_SavedVariables.settings
        local defaultValue = false

        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)
        setting:SetValueChangedCallback(ns.OnSettingChanged)

        local tooltip = "Show or hide the primary action bar. Useful since Blizzard's assisted highlight doesn't use actions on disabled bars."
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    -- Hide action bar 2
    do
        local name = "Hide Actionbar 2"
        local variable = "Hide_Actionbar2"
        local variableKey = "hideActionBar2"
        local variableTbl = NextUp_SavedVariables.settings
        local defaultValue = false

        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)
        setting:SetValueChangedCallback(ns.OnSettingChanged)

        local tooltip = "Show or hide Action Bar 2. Useful since Blizzard's assisted highlight doesn't use actions on disabled bars."
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    -- Hide action bar 3
    do
        local name = "Hide Actionbar 3"
        local variable = "Hide_Actionbar3"
        local variableKey = "hideActionBar3"
        local variableTbl = NextUp_SavedVariables.settings
        local defaultValue = false

        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)
        setting:SetValueChangedCallback(ns.OnSettingChanged)

        local tooltip = "Show or hide the Action Bar 3. Useful since Blizzard's assisted highlight doesn't use actions on disabled bars."
        Settings.CreateCheckbox(category, setting, tooltip)
    end

	-- Hide cast bar
	--[[
	do
		local name = "Hide Default Castbar"
		local variable = "Hide_Castbar"
		local variableKey = "hideCastbar"
		local variableTbl = NextUp_SavedVariables.settings
		local defaultValue = false

        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)
        setting:SetValueChangedCallback(ns.OnSettingChanged)

        local tooltip = "Show or hide the default castbar."
        Settings.CreateCheckbox(category, setting, tooltip)
	end
	]]

	Settings.RegisterAddOnCategory(category)
end

------------------------------------------------------------
-- Function: Show a cooldown animation.
------------------------------------------------------------
function ns:ShowCooldownAnimation(startTime, duration)
	-- Clear existing animation
	highlightFrame.cooldown:SetCooldown(0, 0)

	-- test for nil
	-- we don't want this to fire when duration is 0
	-- Display a cooldown animation.
	if startTime and duration and ns.recSpellID and ns.recSpellID > 0 then
		highlightFrame.cooldown:SetCooldown(startTime, duration)
	end
end

------------------------------------------------------------
-- Function: Update the main frame.
------------------------------------------------------------
function ns:UpdateHighlightFrame(spellID)
	if not highlightFrame then 
		return 
	end

	if not ns.recSpellID or not spellID then
		-- Clear everything if this got called with nil values
		highlightFrame.tex:SetTexture(nil)
		highlightFrame.highlightText:SetText(nil)
		highlightFrame:SetBackdropColor(0.2, 0.2, 0.2, 0)
		highlightFrame:SetBackdropBorderColor(0.2, 0.2, 0.2, 0)
		return
	end

	local tex = C_Spell.GetSpellTexture(spellID)

	--Apply Dim effect
	ns:ApplyDimEffect(not ns:IsSpellReady(spellID))

	-- Get Keybind
	local keybind = ns:GetKeybinds(spellID)

	highlightFrame.tex:SetTexture(tex)
    highlightFrame.highlightText:SetText(keybind)
	highlightFrame:SetBackdropColor(0.2, 0.2, 0.2, 1)
	highlightFrame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
end

------------------------------------------------------------
-- Function: Refreshes the UI.
------------------------------------------------------------
function ns:RefreshUI()
    RedrawHighlightFrame()
    UpdateActionBars()
end

------------------------------------------------------------
-- Function: Initializes the UI.
------------------------------------------------------------
function ns:InitializeUI()
    CreateHighlightFrame()
    UpdateActionBars()
    CreateSettingsFrame()
end

------------------------------------------------------------
-- Function: Show/hide the dimming overlay
------------------------------------------------------------
function ns:ApplyDimEffect(show)
    if show == nil or not highlightFrame then
        return
    end

    local frame = highlightFrame

    if not frame.dimOverlay then
        local tex = frame:CreateTexture(nil, "OVERLAY")
        tex:SetAllPoints()
        tex:SetColorTexture(0, 0, 0, 0.5)
        frame.dimOverlay = tex
    end

	if show then
        frame.dimOverlay:Show()
    else
        frame.dimOverlay:Hide()
    end
end

------------------------------------------------------------
-- Function: Show/hide the out of range overlay.
------------------------------------------------------------
function ns:ApplyRedShift(show)
    if show == nil or not highlightFrame then
        return
    end

    local frame = highlightFrame

    if not frame.redOverlay then
        local tex = frame:CreateTexture(nil, "OVERLAY")
        tex:SetAllPoints()
        tex:SetColorTexture(0.5, 0, 0, 0.7)
        frame.redOverlay = tex
    end

    if show then
        frame.redOverlay:Show()
		--frame.highlightText:SetTextColor(1, 0, 0)
    else
        frame.redOverlay:Hide()
		--frame.highlightText:SetTextColor(1, 1, 1)
    end
end

------------------------------------------------------------
-- Function: Show/hide the overlay glow.
------------------------------------------------------------
function ns:ShowOverlayGlow(show)
	if show then
		LBG.ShowOverlayGlow(highlightFrame)
	else
		LBG.HideOverlayGlow(highlightFrame)
	end
end