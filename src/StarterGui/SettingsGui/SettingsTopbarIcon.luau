--!strict

--==================================================
-- SERVICES
--==================================================

local ReplicatedStorage =
	game:GetService(
		"ReplicatedStorage"
	)


local Players =
	game:GetService(
		"Players"
	)


--==================================================
-- TOPBARPLUS
--==================================================

local TopbarPlus =
	require(
		ReplicatedStorage
		:WaitForChild("Purse")
		:WaitForChild("Packages")
		:WaitForChild("_Index")
		:WaitForChild("ryanlua_topbarplus@1.0.1")
		:WaitForChild("topbarplus")
	)


--==================================================
-- PLAYER
--==================================================

local player =
	Players.LocalPlayer


local playerGui = player:WaitForChild("PlayerGui")


--==================================================
-- SETTINGS GUI
--==================================================

local SettingsGui =
	playerGui:WaitForChild(
		"SettingsGui"
	)


local SettingsFrame =
	SettingsGui:WaitForChild(
		"SettingsFrame"
	)


SettingsFrame.Visible = false


--==================================================
-- CREATE SETTINGS ICON
--==================================================

local settingsIcon =
	TopbarPlus.new()


--==================================================
-- NAME
--==================================================

-- This gives the icon a known name.
--
-- GameSettingsClient can now find the same
-- TopbarPlus icon when ExitImageButton is clicked.

settingsIcon:setName(
	"Settings"
)


--==================================================
-- IMAGE
--==================================================

settingsIcon:setImage(
	"rbxassetid://140652204449214"
)


--==================================================
-- IMAGE SIZE
--==================================================

settingsIcon:setImageScale(
	0.75
)


--==================================================
-- ALIGNMENT
--==================================================

settingsIcon:setLeft()


--==================================================
-- ORDER
--==================================================

-- Backpack uses -1.
--
-- Settings uses 0 so it appears directly
-- to the RIGHT of Backpack.

settingsIcon:setOrder(
	0
)


--==================================================
-- CAPTION
--==================================================

settingsIcon:setCaption(
	"Settings"
)


--==================================================
-- TOGGLE SETTINGS FRAME
--==================================================

-- TopbarPlus automatically handles:
--
-- Selected   -> Visible = true
-- Deselected -> Visible = false

settingsIcon:bindToggleItem(SettingsFrame)


--==================================================
-- AUTO DESELECT
--==================================================

settingsIcon:autoDeselect(
	true
)
