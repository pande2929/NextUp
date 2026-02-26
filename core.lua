-- core.lua

local addonName, ns = ...
NextUp = ns
NextUp.name = "NextUp"

------------------------------------------------------------
-- Function: Initialize the addon
------------------------------------------------------------
function NextUp:OnInitialize()
	-- Initialize the UI
	NextUp:InitializeUI()

	-- Event handlers and hooks
	NextUp:RegisterEvents()

	-- Keybinds
	--NextUp:GenerateKeybindMapping()

	-- Let timer know that we're ready.
	NextUp.initialized = true
end