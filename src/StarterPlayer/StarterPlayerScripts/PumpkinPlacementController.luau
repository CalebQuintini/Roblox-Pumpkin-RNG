--==================================================
-- SERVICES
--==================================================

local Players =
	game:GetService("Players")


local ReplicatedStorage =
	game:GetService("ReplicatedStorage")


local UserInputService =
	game:GetService("UserInputService")


local RunService =
	game:GetService("RunService")


--==================================================
-- PLAYER
--==================================================

local player =
	Players.LocalPlayer


local playerGui =
	player:WaitForChild("PlayerGui")


--==================================================
-- MODULES
--==================================================

local PumpkinConfig =
	require(
		ReplicatedStorage
		:WaitForChild("Config")
		:WaitForChild("PumpkinConfig")
	)


local GameConfig =
	require(
		ReplicatedStorage
		:WaitForChild("Config")
		:WaitForChild("GameConfig")
	)


local PumpkinGridUtil =
	require(
		ReplicatedStorage
		:WaitForChild("Modules")
		:WaitForChild("PumpkinGridUtil")
	)


--==================================================
-- REFERENCES
--==================================================

local PumpkinModels =
	ReplicatedStorage
	:WaitForChild("PumpkinModels")


local Plots =
	workspace
	:WaitForChild("Plots")


--==================================================
-- REMOTES
--==================================================

local Remotes =
	ReplicatedStorage
	:WaitForChild("Remotes")


local PlacePumpkinRequest =
	Remotes
	:WaitForChild("PlacePumpkinRequest")


local PlacementResult =
	Remotes
	:WaitForChild("PlacementResult")


--==================================================
-- CUSTOM UI ASSETS
--==================================================

-- Replace this with your uploaded mouse PNG.
--
-- Example:
--
-- "rbxassetid://123456789012345"

local MOUSE_ICON_IMAGE =
	"rbxassetid://90172194100956"


--==================================================
-- PLACEMENT STATE
--==================================================

local activeTool =
	nil


local activePumpkinId =
	nil


local activePumpkinInfo =
	nil


local ghostModel =
	nil


local previewBox =
	nil


local previewSelectionBox =
	nil


local rotation =
	0


local currentGridX =
	nil


local currentGridZ =
	nil


local currentPlacementValid =
	false


local placementPending =
	false


local currentPlot =
	nil


local currentPlotFloor =
	nil


local lastTouchPosition =
	nil


--==================================================
-- PREVIEW BOX SETTINGS
--==================================================

-- X and Z now come directly from the pumpkin's
-- GridWidth / GridDepth footprint.
--
-- We only add a little extra height so the box
-- extends slightly above the pumpkin.

local EXTRA_BOX_HEIGHT =
	0.6


--==================================================
-- UI SETTINGS
--==================================================

-- Size used for:
--
-- R
-- Mouse square
-- Xbox buttons
-- PlayStation buttons
-- TAP icon

local CONTROL_ICON_SIZE =
	40


--==================================================
-- PLACEMENT UI POSITIONS
--==================================================

-- PC placement bar position.
local DESKTOP_UI_Y =
	-92


-- Mobile placement bar position.
local MOBILE_UI_Y =
	-92


-- Console bar is raised higher so it
-- doesn't cover the Purse hotbar.
local CONSOLE_UI_Y =
	-135


--==================================================
-- UI COLORS
--==================================================

local BAR_COLOR =
	Color3.fromRGB(
		35,
		35,
		35
	)


local TEXT_COLOR =
	Color3.fromRGB(
		255,
		255,
		255
	)


local BUTTON_BACKGROUND =
	Color3.fromRGB(
		245,
		245,
		245
	)


local KEY_BORDER_COLOR =
	Color3.fromRGB(
		90,
		90,
		90
	)


local CONTROLLER_BORDER_COLOR =
	Color3.fromRGB(
		20,
		20,
		20
	)


local KEY_TEXT_COLOR =
	Color3.fromRGB(
		25,
		25,
		25
	)


local XBOX_X_COLOR =
	Color3.fromRGB(
		35,
		130,
		255
	)


local XBOX_A_COLOR =
	Color3.fromRGB(
		45,
		190,
		75
	)


local PLAYSTATION_SQUARE_COLOR =
	Color3.fromRGB(
		255,
		80,
		170
	)


local PLAYSTATION_CROSS_COLOR =
	Color3.fromRGB(
		55,
		140,
		255
	)


--==================================================
-- FIND PLAYER'S OWN PLOT
--==================================================

local function FindOwnPlot()

	for _, plot in ipairs(
		Plots:GetChildren()
		) do

		if plot:GetAttribute(
			"OwnerUserId"
			) == player.UserId then

			return plot

		end

	end


	return nil

end


--==================================================
-- REFRESH PLAYER'S PLOT REFERENCES
--==================================================

local function RefreshOwnPlot()

	currentPlot =
		FindOwnPlot()


	if not currentPlot then

		currentPlotFloor =
			nil


		return false

	end


	currentPlotFloor =
		currentPlot
		:FindFirstChild(
			"PlotFloor"
		)


	return currentPlotFloor
		~= nil

end


--==================================================
-- DETECT PLAYSTATION CONTROLLER
--==================================================

local function IsPlayStation()

	-- Xbox ButtonX:
	--
	-- "ButtonX"
	--
	-- PlayStation Square:
	--
	-- "ButtonSquare"

	local successX,
		buttonXName =
		pcall(
			function()

				return UserInputService
				:GetStringForKeyCode(
					Enum.KeyCode.ButtonX
				)

			end
		)


	if successX then

		if buttonXName
			== "ButtonSquare" then

			return true

		end

	end


	-- Additional check:
	--
	-- Xbox ButtonA:
	-- "ButtonA"
	--
	-- PlayStation Cross:
	-- "ButtonCross"

	local successA,
		buttonAName =
		pcall(
			function()

				return UserInputService
				:GetStringForKeyCode(
					Enum.KeyCode.ButtonA
				)

			end
		)


	if successA then

		if buttonAName
			== "ButtonCross" then

			return true

		end

	end


	return false

end


--==================================================
-- CREATE PLACEMENT GUI
--==================================================

local placementGui =
	Instance.new("ScreenGui")


placementGui.Name =
	"PumpkinPlacementGui"


placementGui.ResetOnSpawn =
	false


placementGui.IgnoreGuiInset =
	false


placementGui.DisplayOrder =
	20


placementGui.Parent =
	playerGui


--==================================================
-- CONTROLS BAR
--==================================================

local controlsBar =
	Instance.new("Frame")


controlsBar.Name =
	"ControlsBar"


controlsBar.AnchorPoint =
	Vector2.new(
		0.5,
		1
	)


controlsBar.Position =
	UDim2.new(
		0.5,
		0,

		1,
		DESKTOP_UI_Y
	)


-- Narrower than before.
controlsBar.Size =
	UDim2.fromOffset(
		390,
		56
	)


controlsBar.BackgroundColor3 =
	BAR_COLOR


controlsBar.BackgroundTransparency =
	0.22


controlsBar.BorderSizePixel =
	0


controlsBar.Visible =
	false


controlsBar.Parent =
	placementGui


--==================================================
-- CONTROLS BAR CORNERS
--==================================================

local controlsCorner =
	Instance.new("UICorner")


controlsCorner.CornerRadius =
	UDim.new(
		0,
		8
	)


controlsCorner.Parent =
	controlsBar


--==================================================
-- CONTROLS BAR OUTLINE
--==================================================

local controlsStroke =
	Instance.new("UIStroke")


controlsStroke.Thickness =
	2


controlsStroke.Transparency =
	0.4


controlsStroke.Color =
	Color3.fromRGB(
		10,
		10,
		10
	)


controlsStroke.Parent =
	controlsBar


--==================================================
-- DESKTOP / CONTROLLER CONTENT
--==================================================

local controlsContent =
	Instance.new("Frame")


controlsContent.Name =
	"ControlsContent"


controlsContent.AnchorPoint =
	Vector2.new(
		0.5,
		0.5
	)


controlsContent.Position =
	UDim2.fromScale(
		0.5,
		0.5
	)


controlsContent.Size =
	UDim2.new(
		1,
		-16,

		1,
		-8
	)


controlsContent.BackgroundTransparency =
	1


controlsContent.Parent =
	controlsBar


--==================================================
-- CONTENT LAYOUT
--==================================================

local contentLayout =
	Instance.new("UIListLayout")


contentLayout.FillDirection =
	Enum.FillDirection.Horizontal


contentLayout.HorizontalAlignment =
	Enum.HorizontalAlignment.Center


contentLayout.VerticalAlignment =
	Enum.VerticalAlignment.Center


contentLayout.Padding =
	UDim.new(
		0,
		7
	)


contentLayout.Parent =
	controlsContent


--==================================================
-- HELPER: CREATE CONTROL TEXT
--==================================================

local function CreateControlText(
	name,
	text,
	width
)

	local label =
		Instance.new("TextLabel")


	label.Name =
		name


	label.Size =
		UDim2.fromOffset(
			width,
			38
		)


	label.BackgroundTransparency =
		1


	label.Text =
		text


	label.TextColor3 =
		TEXT_COLOR


	label.TextStrokeTransparency =
		0.35


	label.TextStrokeColor3 =
		Color3.new(
			0,
			0,
			0
		)


	label.Font =
		Enum.Font.GothamBlack


	label.TextScaled =
		true


	return label

end


--==================================================
-- HELPER: CREATE KEYBOARD KEY
--==================================================

local function CreateKeyboardKey(
	name,
	text
)

	local key =
		Instance.new("Frame")


	key.Name =
		name


	key.Size =
		UDim2.fromOffset(
			CONTROL_ICON_SIZE,
			CONTROL_ICON_SIZE
		)


	key.BackgroundColor3 =
		BUTTON_BACKGROUND


	key.BorderSizePixel =
		0


	local corner =
		Instance.new("UICorner")


	corner.CornerRadius =
		UDim.new(
			0,
			6
		)


	corner.Parent =
		key


	local stroke =
		Instance.new("UIStroke")


	stroke.Thickness =
		3


	stroke.Color =
		KEY_BORDER_COLOR


	stroke.Parent =
		key


	local label =
		Instance.new("TextLabel")


	label.Name =
		"Symbol"


	label.AnchorPoint =
		Vector2.new(
			0.5,
			0.5
		)


	label.Position =
		UDim2.fromScale(
			0.5,
			0.5
		)


	label.Size =
		UDim2.fromScale(
			0.7,
			0.7
		)


	label.BackgroundTransparency =
		1


	label.Text =
		text


	label.TextColor3 =
		KEY_TEXT_COLOR


	label.Font =
		Enum.Font.GothamBlack


	label.TextScaled =
		true


	label.Parent =
		key


	return key

end


--==================================================
-- HELPER: CONTROLLER CIRCLE
--==================================================

local function CreateControllerCircle(
	name
)

	local circle =
		Instance.new("Frame")


	circle.Name =
		name


	circle.Size =
		UDim2.fromOffset(
			CONTROL_ICON_SIZE,
			CONTROL_ICON_SIZE
		)


	circle.BackgroundColor3 =
		BUTTON_BACKGROUND


	circle.BorderSizePixel =
		0


	local corner =
		Instance.new("UICorner")


	corner.CornerRadius =
		UDim.new(
			1,
			0
		)


	corner.Parent =
		circle


	local stroke =
		Instance.new("UIStroke")


	stroke.Thickness =
		3


	stroke.Color =
		CONTROLLER_BORDER_COLOR


	stroke.Parent =
		circle


	return circle

end


--==================================================
-- HELPER: XBOX BUTTON
--==================================================

local function CreateXboxButton(
	name,
	letter,
	letterColor
)

	local circle =
		CreateControllerCircle(
			name
		)


	local label =
		Instance.new("TextLabel")


	label.Name =
		"Symbol"


	label.AnchorPoint =
		Vector2.new(
			0.5,
			0.5
		)


	label.Position =
		UDim2.fromScale(
			0.5,
			0.5
		)


	label.Size =
		UDim2.fromScale(
			0.68,
			0.68
		)


	label.BackgroundTransparency =
		1


	label.Text =
		letter


	label.TextColor3 =
		letterColor


	label.Font =
		Enum.Font.GothamBlack


	label.TextScaled =
		true


	label.Parent =
		circle


	return circle

end


--==================================================
-- HELPER: PLAYSTATION CROSS
--==================================================

local function CreatePlayStationCross()

	local circle =
		CreateControllerCircle(
			"PlayStationCross"
		)


	local line1 =
		Instance.new("Frame")


	line1.Name =
		"CrossLine1"


	line1.AnchorPoint =
		Vector2.new(
			0.5,
			0.5
		)


	line1.Position =
		UDim2.fromScale(
			0.5,
			0.5
		)


	line1.Size =
		UDim2.fromOffset(
			22,
			3
		)


	line1.Rotation =
		45


	line1.BackgroundColor3 =
		PLAYSTATION_CROSS_COLOR


	line1.BorderSizePixel =
		0


	line1.Parent =
		circle


	local lineCorner =
		Instance.new("UICorner")


	lineCorner.CornerRadius =
		UDim.new(
			1,
			0
		)


	lineCorner.Parent =
		line1


	local line2 =
		line1:Clone()


	line2.Name =
		"CrossLine2"


	line2.Rotation =
		-45


	line2.Parent =
		circle


	return circle

end


--==================================================
-- HELPER: PLAYSTATION SQUARE
--==================================================

local function CreatePlayStationSquare()

	local circle =
		CreateControllerCircle(
			"PlayStationSquare"
		)


	local square =
		Instance.new("Frame")


	square.Name =
		"SquareSymbol"


	square.AnchorPoint =
		Vector2.new(
			0.5,
			0.5
		)


	square.Position =
		UDim2.fromScale(
			0.5,
			0.5
		)


	square.Size =
		UDim2.fromOffset(
			17,
			17
		)


	square.BackgroundTransparency =
		1


	square.BorderSizePixel =
		0


	square.Parent =
		circle


	local squareStroke =
		Instance.new("UIStroke")


	squareStroke.Thickness =
		3


	squareStroke.Color =
		PLAYSTATION_SQUARE_COLOR


	squareStroke.Parent =
		square


	return circle

end


--==================================================
-- ROTATE ICON CONTAINER
--==================================================

local rotateIconContainer =
	Instance.new("Frame")


rotateIconContainer.Name =
	"RotateIconContainer"


rotateIconContainer.Size =
	UDim2.fromOffset(
		CONTROL_ICON_SIZE,
		CONTROL_ICON_SIZE
	)


rotateIconContainer.BackgroundTransparency =
	1


rotateIconContainer.Parent =
	controlsContent


--==================================================
-- KEYBOARD R
--==================================================

local keyboardR =
	CreateKeyboardKey(
		"KeyboardR",
		"R"
	)


keyboardR.Parent =
	rotateIconContainer


--==================================================
-- XBOX X
--==================================================

local xboxX =
	CreateXboxButton(
		"XboxX",
		"X",
		XBOX_X_COLOR
	)


xboxX.Visible =
	false


xboxX.Parent =
	rotateIconContainer


--==================================================
-- PLAYSTATION SQUARE
--==================================================

local playStationSquare =
	CreatePlayStationSquare()


playStationSquare.Visible =
	false


playStationSquare.Parent =
	rotateIconContainer


--==================================================
-- ROTATE TEXT
--==================================================

local rotateText =
	CreateControlText(
		"RotateText",
		"- Rotate",
		100
	)


rotateText.Parent =
	controlsContent


--==================================================
-- SPACER
--==================================================

local spacer =
	Instance.new("Frame")


spacer.Name =
	"Spacer"


spacer.Size =
	UDim2.fromOffset(
		7,
		1
	)


spacer.BackgroundTransparency =
	1


spacer.Parent =
	controlsContent


--==================================================
-- PLACE ICON CONTAINER
--==================================================

local placeIconContainer =
	Instance.new("Frame")


placeIconContainer.Name =
	"PlaceIconContainer"


placeIconContainer.Size =
	UDim2.fromOffset(
		CONTROL_ICON_SIZE,
		CONTROL_ICON_SIZE
	)


placeIconContainer.BackgroundTransparency =
	1


placeIconContainer.Parent =
	controlsContent


--==================================================
-- MOUSE KEY
--==================================================

local mouseKey =
	Instance.new("Frame")


mouseKey.Name =
	"MouseKey"


mouseKey.Size =
	UDim2.fromOffset(
		CONTROL_ICON_SIZE,
		CONTROL_ICON_SIZE
	)


mouseKey.BackgroundColor3 =
	BUTTON_BACKGROUND


mouseKey.BorderSizePixel =
	0


mouseKey.Parent =
	placeIconContainer


local mouseKeyCorner =
	Instance.new("UICorner")


mouseKeyCorner.CornerRadius =
	UDim.new(
		0,
		6
	)


mouseKeyCorner.Parent =
	mouseKey


local mouseKeyStroke =
	Instance.new("UIStroke")


mouseKeyStroke.Thickness =
	3


mouseKeyStroke.Color =
	KEY_BORDER_COLOR


mouseKeyStroke.Parent =
	mouseKey


--==================================================
-- CUSTOM MOUSE PNG
--==================================================

local mouseIcon =
	Instance.new("ImageLabel")


mouseIcon.Name =
	"MouseIcon"


mouseIcon.AnchorPoint =
	Vector2.new(
		0.5,
		0.5
	)


mouseIcon.Position =
	UDim2.fromScale(
		0.5,
		0.5
	)


-- Square stays exactly the same size.
--
-- Only the actual mouse artwork is larger.
mouseIcon.Size =
	UDim2.fromScale(
		1.1,
		1.1
	)


mouseIcon.BackgroundTransparency =
	1


mouseIcon.Image =
	MOUSE_ICON_IMAGE


mouseIcon.ScaleType =
	Enum.ScaleType.Fit


mouseIcon.Parent =
	mouseKey


--==================================================
-- XBOX A
--==================================================

local xboxA =
	CreateXboxButton(
		"XboxA",
		"A",
		XBOX_A_COLOR
	)


xboxA.Visible =
	false


xboxA.Parent =
	placeIconContainer


--==================================================
-- PLAYSTATION CROSS
--==================================================

local playStationCross =
	CreatePlayStationCross()


playStationCross.Visible =
	false


playStationCross.Parent =
	placeIconContainer


--==================================================
-- PLACE TEXT
--==================================================

local placeText =
	CreateControlText(
		"PlaceText",
		"- Place",
		88
	)


placeText.Parent =
	controlsContent


--==================================================
-- MOBILE CONTENT
--==================================================

local mobileContent =
	Instance.new("Frame")


mobileContent.Name =
	"MobileContent"


mobileContent.Size =
	UDim2.fromScale(
		1,
		1
	)


mobileContent.BackgroundTransparency =
	1


mobileContent.Visible =
	false


mobileContent.Parent =
	controlsBar


--==================================================
-- MOBILE ROTATE BUTTON
--==================================================

local rotateButton =
	Instance.new("TextButton")


rotateButton.Name =
	"RotateButton"


rotateButton.AnchorPoint =
	Vector2.new(
		0.5,
		0.5
	)


rotateButton.Position =
	UDim2.fromScale(
		0.28,
		0.5
	)


rotateButton.Size =
	UDim2.fromOffset(
		105,
		36
	)


rotateButton.BackgroundColor3 =
	BUTTON_BACKGROUND


rotateButton.Text =
	"Rotate"


rotateButton.TextColor3 =
	KEY_TEXT_COLOR


rotateButton.Font =
	Enum.Font.GothamBlack


-- Important:
--
-- Don't use TextScaled here.
-- It made the mobile Rotate text too large.
rotateButton.TextScaled =
	false


rotateButton.TextSize =
	20


-- Reduce the heavy black outline.
rotateButton.TextStrokeTransparency =
	0.65


rotateButton.TextStrokeColor3 =
	Color3.new(
		0,
		0,
		0
	)


rotateButton.BorderSizePixel =
	0


rotateButton.Parent =
	mobileContent


local rotateButtonCorner =
	Instance.new("UICorner")


rotateButtonCorner.CornerRadius =
	UDim.new(
		0,
		6
	)


rotateButtonCorner.Parent =
	rotateButton


-- Slightly thinner border.
local rotateButtonStroke =
	Instance.new("UIStroke")


rotateButtonStroke.Thickness =
	2


rotateButtonStroke.Color =
	KEY_BORDER_COLOR


rotateButtonStroke.Parent =
	rotateButton


--==================================================
-- MOBILE TAP ICON
--==================================================

local mobileTapKey =
	CreateKeyboardKey(
		"MobileTapKey",
		"TAP"
	)


mobileTapKey.AnchorPoint =
	Vector2.new(
		0.5,
		0.5
	)


mobileTapKey.Position =
	UDim2.fromScale(
		0.60,
		0.5
	)


mobileTapKey.Parent =
	mobileContent


local tapSymbol =
	mobileTapKey
	:FindFirstChild(
		"Symbol"
	)


if tapSymbol then

	tapSymbol.TextScaled =
		false


	tapSymbol.TextSize =
		13

end


--==================================================
-- MOBILE PLACE TEXT
--==================================================

local mobilePlaceText =
	Instance.new("TextLabel")


mobilePlaceText.Name =
	"MobilePlaceText"


mobilePlaceText.AnchorPoint =
	Vector2.new(
		0.5,
		0.5
	)


mobilePlaceText.Position =
	UDim2.fromScale(
		0.76,
		0.5
	)


mobilePlaceText.Size =
	UDim2.fromOffset(
		90,
		36
	)


mobilePlaceText.BackgroundTransparency =
	1


mobilePlaceText.Text =
	"- Place"


mobilePlaceText.TextColor3 =
	TEXT_COLOR


mobilePlaceText.TextStrokeTransparency =
	0.35


mobilePlaceText.TextStrokeColor3 =
	Color3.new(
		0,
		0,
		0
	)


mobilePlaceText.Font =
	Enum.Font.GothamBlack


mobilePlaceText.TextScaled =
	true


mobilePlaceText.Parent =
	mobileContent


--==================================================
-- SHOW KEYBOARD CONTROLS
--==================================================

local function ShowKeyboardControls()

	controlsBar.Position =
		UDim2.new(
			0.5,
			0,

			1,
			DESKTOP_UI_Y
		)


	controlsContent.Visible =
		true


	mobileContent.Visible =
		false


	keyboardR.Visible =
		true


	xboxX.Visible =
		false


	playStationSquare.Visible =
		false


	mouseKey.Visible =
		true


	xboxA.Visible =
		false


	playStationCross.Visible =
		false

end


--==================================================
-- SHOW XBOX CONTROLS
--==================================================

local function ShowXboxControls()

	-- Console version sits higher.
	controlsBar.Position =
		UDim2.new(
			0.5,
			0,

			1,
			CONSOLE_UI_Y
		)


	controlsContent.Visible =
		true


	mobileContent.Visible =
		false


	keyboardR.Visible =
		false


	xboxX.Visible =
		true


	playStationSquare.Visible =
		false


	mouseKey.Visible =
		false


	xboxA.Visible =
		true


	playStationCross.Visible =
		false

end


--==================================================
-- SHOW PLAYSTATION CONTROLS
--==================================================

local function ShowPlayStationControls()

	-- Console version sits higher.
	controlsBar.Position =
		UDim2.new(
			0.5,
			0,

			1,
			CONSOLE_UI_Y
		)


	controlsContent.Visible =
		true


	mobileContent.Visible =
		false


	keyboardR.Visible =
		false


	xboxX.Visible =
		false


	playStationSquare.Visible =
		true


	mouseKey.Visible =
		false


	xboxA.Visible =
		false


	playStationCross.Visible =
		true

end


--==================================================
-- SHOW MOBILE CONTROLS
--==================================================

local function ShowMobileControls()

	controlsBar.Position =
		UDim2.new(
			0.5,
			0,

			1,
			MOBILE_UI_Y
		)


	controlsContent.Visible =
		false


	mobileContent.Visible =
		true

end


--==================================================
-- UPDATE CONTROLS FOR INPUT DEVICE
--==================================================

local function UpdateControlsForInput(
	inputType
)

	--==================================================
	-- MOBILE
	--==================================================

	if inputType
		== Enum.UserInputType.Touch then

		ShowMobileControls()


		return

	end


	--==================================================
	-- CONTROLLER
	--==================================================

	if inputType.Name:find(
		"Gamepad"
		) then

		if IsPlayStation() then

			ShowPlayStationControls()

		else

			ShowXboxControls()

		end


		return

	end


	--==================================================
	-- KEYBOARD + MOUSE
	--==================================================

	ShowKeyboardControls()

end


--==================================================
-- DESTROY PREVIEW
--==================================================

local function DestroyPreview()

	if ghostModel then

		ghostModel:Destroy()


		ghostModel =
			nil

	end


	if previewSelectionBox then

		previewSelectionBox:Destroy()


		previewSelectionBox =
			nil

	end


	if previewBox then

		previewBox:Destroy()


		previewBox =
			nil

	end

end


--==================================================
-- CREATE GHOST
--==================================================

local function CreateGhost()

	if not activePumpkinInfo then

		return

	end


	local template =
		PumpkinModels
		:FindFirstChild(
			activePumpkinInfo.ModelName
		)


	if not template then

		warn(
			"Missing pumpkin model:",
			activePumpkinInfo.ModelName
		)


		return

	end


	--==================================================
	-- GHOST MODEL
	--==================================================

	ghostModel =
		template:Clone()


	ghostModel.Name =
		"PlacementGhost"


	for _, descendant in ipairs(
		ghostModel:GetDescendants()
		) do

		if descendant:IsA("BasePart") then

			descendant.Anchored =
				true


			descendant.CanCollide =
				false


			descendant.CanTouch =
				false


			descendant.CanQuery =
				false


			-- Keep pumpkin completely opaque.
			descendant.LocalTransparencyModifier =
				0

		end

	end


	ghostModel.Parent =
		workspace


	--==================================================
	-- 3D PREVIEW BOX
	--==================================================

	previewBox =
		Instance.new("Part")


	previewBox.Name =
		"PlacementPreviewBox"


	previewBox.Anchored =
		true


	previewBox.CanCollide =
		false


	previewBox.CanTouch =
		false


	previewBox.CanQuery =
		false


	previewBox.CastShadow =
		false


	previewBox.Material =
		Enum.Material.ForceField


	previewBox.Transparency =
		0.78


	previewBox.Parent =
		workspace


	--==================================================
	-- PREVIEW BOX OUTLINE
	--==================================================

	previewSelectionBox =
		Instance.new("SelectionBox")


	previewSelectionBox.Name =
		"PlacementSelectionBox"


	previewSelectionBox.Adornee =
		previewBox


	previewSelectionBox.LineThickness =
		0.05


	previewSelectionBox.SurfaceTransparency =
		1


	previewSelectionBox.Parent =
		previewBox

end


--==================================================
-- END PLACEMENT MODE
--==================================================

local function EndPlacement()

	activeTool =
		nil


	activePumpkinId =
		nil


	activePumpkinInfo =
		nil


	currentGridX =
		nil


	currentGridZ =
		nil


	currentPlacementValid =
		false


	placementPending =
		false


	controlsBar.Visible =
		false


	DestroyPreview()

end


--==================================================
-- START PLACEMENT MODE
--==================================================

local function BeginPlacement(
	tool
)

	local pumpkinId =
		tool:GetAttribute(
			"PumpkinId"
		)


	if type(pumpkinId)
		~= "string" then

		return

	end


	local pumpkinInfo =
		PumpkinConfig.GetPumpkin(
			pumpkinId
		)


	if not pumpkinInfo then

		return

	end


	DestroyPreview()


	activeTool =
		tool


	activePumpkinId =
		pumpkinId


	activePumpkinInfo =
		pumpkinInfo


	rotation =
		0


	currentGridX =
		nil


	currentGridZ =
		nil


	currentPlacementValid =
		false


	placementPending =
		false


	RefreshOwnPlot()


	CreateGhost()


	controlsBar.Visible =
		true


	UpdateControlsForInput(
		UserInputService:GetLastInputType()
	)

end


--==================================================
-- CHECK IF TOOL IS PUMPKIN PROXY
--==================================================

local function IsPumpkinTool(
	instance
)

	return instance:IsA("Tool")

		and instance:GetAttribute(
			"PumpkinProxy"
		) == true

		and type(
			instance:GetAttribute(
				"PumpkinId"
			)
		) == "string"

end


--==================================================
-- LOCAL OCCUPANCY CHECK
--==================================================

local function IsLocallyOccupied(
	gridX,
	gridZ,
	width,
	depth
)

	if not currentPlot then

		return true

	end


	local placedFolder =
		currentPlot
		:FindFirstChild(
			"PlacedPumpkins"
		)


	if not placedFolder then

		return false

	end


	for _, model in ipairs(
		placedFolder:GetChildren()
		) do

		local otherPumpkinId =
			model:GetAttribute(
				"PumpkinId"
			)


		local otherGridX =
			model:GetAttribute(
				"GridX"
			)


		local otherGridZ =
			model:GetAttribute(
				"GridZ"
			)


		local otherRotation =
			model:GetAttribute(
				"Rotation"
			)
			or 0


		if otherPumpkinId
			and otherGridX
			and otherGridZ then

			local otherInfo =
				PumpkinConfig.GetPumpkin(
					otherPumpkinId
				)


			if otherInfo then

				local otherWidth,
					otherDepth =
					PumpkinGridUtil
					.GetRotatedGridSize(
						otherInfo.GridWidth,
						otherInfo.GridDepth,
						otherRotation
					)


				local overlaps =
					PumpkinGridUtil
					.RectanglesOverlap(
						gridX,
						gridZ,
						width,
						depth,

						otherGridX,
						otherGridZ,
						otherWidth,
						otherDepth
					)


				if overlaps then

					return true

				end

			end

		end

	end


	return false

end


--==================================================
-- GET CURRENT SCREEN POINT
--==================================================

local function GetScreenPoint()

	local inputType =
		UserInputService
		:GetLastInputType()


	--==================================================
	-- CONTROLLER
	--==================================================

	if inputType.Name:find(
		"Gamepad"
		) then

		local camera =
			workspace.CurrentCamera


		if not camera then

			return nil

		end


		return Vector2.new(
			camera.ViewportSize.X / 2,
			camera.ViewportSize.Y / 2
		)

	end


	--==================================================
	-- TOUCH
	--==================================================

	if inputType
		== Enum.UserInputType.Touch
		and lastTouchPosition then

		return lastTouchPosition

	end


	--==================================================
	-- MOUSE
	--==================================================

	return UserInputService
		:GetMouseLocation()

end


--==================================================
-- RAYCAST AGAINST PLAYER'S OWN PLOT FLOOR
--==================================================

local function GetPlotHitPosition(
	screenPoint
)

	if not currentPlotFloor then

		return nil

	end


	local camera =
		workspace.CurrentCamera


	if not camera then

		return nil

	end


	local ray =
		camera:ViewportPointToRay(
			screenPoint.X,
			screenPoint.Y
		)


	local raycastParams =
		RaycastParams.new()


	raycastParams.FilterType =
		Enum.RaycastFilterType.Include


	raycastParams.FilterDescendantsInstances = {
		currentPlotFloor,
	}


	local result =
		workspace:Raycast(
			ray.Origin,

			ray.Direction
			* 1000,

			raycastParams
		)


	if not result then

		return nil

	end


	return result.Position

end


--==================================================
-- UPDATE PREVIEW
--==================================================

local function UpdatePreview()

	if not activePumpkinId
		or not activePumpkinInfo
		or not ghostModel
		or not previewBox then

		return

	end


	if not currentPlotFloor then

		RefreshOwnPlot()


		if not currentPlotFloor then

			return

		end

	end


	local screenPoint =
		GetScreenPoint()


	if not screenPoint then

		return

	end


	local hitPosition =
		GetPlotHitPosition(
			screenPoint
		)


	--==================================================
	-- NOT POINTING AT PLOT
	--==================================================

	if not hitPosition then

		ghostModel.Parent =
			nil


		previewBox.Parent =
			nil


		currentPlacementValid =
			false


		return

	end


	--==================================================
	-- RESTORE PREVIEW
	--==================================================

	if not ghostModel.Parent then

		ghostModel.Parent =
			workspace

	end


	if not previewBox.Parent then

		previewBox.Parent =
			workspace

	end


	--==================================================
	-- ROTATED GRID SIZE
	--==================================================

	local width,
		depth =
		PumpkinGridUtil
		.GetRotatedGridSize(
			activePumpkinInfo.GridWidth,
			activePumpkinInfo.GridDepth,
			rotation
		)


	--==================================================
	-- WORLD -> GRID
	--==================================================

	local gridX,
		gridZ =
		PumpkinGridUtil
		.WorldPointToGrid(
			currentPlotFloor,
			hitPosition,
			width,
			depth,
			GameConfig.Grid.CellSize
		)


	currentGridX =
		gridX


	currentGridZ =
		gridZ


	--==================================================
	-- CHECK BOUNDS
	--==================================================

	local inside =
		PumpkinGridUtil
		.IsInsideGrid(
			currentPlotFloor,
			gridX,
			gridZ,
			width,
			depth,
			GameConfig.Grid.CellSize
		)


	--==================================================
	-- CHECK OCCUPANCY
	--==================================================

	local occupied =
		false


	if inside then

		occupied =
			IsLocallyOccupied(
				gridX,
				gridZ,
				width,
				depth
			)

	end


	currentPlacementValid =
		inside
		and not occupied


	--==================================================
	-- PLACEMENT CFRAME
	--==================================================

	local surfaceCFrame =
		PumpkinGridUtil
		.GetPlacementSurfaceCFrame(
			currentPlotFloor,
			gridX,
			gridZ,
			width,
			depth,
			rotation,
			GameConfig.Grid.CellSize
		)


	--==================================================
	-- POSITION GHOST
	--==================================================

	PumpkinGridUtil
		.AlignModelToSurface(
			ghostModel,
			surfaceCFrame
		)


	--==================================================
	-- GHOST HEIGHT
	--==================================================

	-- We still use the actual pumpkin model to determine
	-- how tall the transparent box should be.
	--
	-- X and Z are NOT taken from the model anymore.
	-- They come from GridWidth / GridDepth.

	local _,
		boundingSize =
		ghostModel:GetBoundingBox()


	--==================================================
	-- GRID FOOTPRINT SIZE
	--==================================================

	local cellSize =
		GameConfig.Grid.CellSize


	-- IMPORTANT:
	--
	-- surfaceCFrame already contains the pumpkin's
	-- rotation.
	--
	-- Therefore the Part's LOCAL X/Z size should use
	-- the pumpkin's original GridWidth / GridDepth.
	--
	-- Example:
	--
	-- GridWidth = 3
	-- GridDepth = 1
	--
	-- Rotation 0:
	--     12 x 4 studs
	--
	-- Rotation 90:
	--     the CFrame rotates that same 12 x 4 box
	--     so it occupies 4 x 12 studs in world space.

	local footprintWidth =
		activePumpkinInfo.GridWidth
		* cellSize


	local footprintDepth =
		activePumpkinInfo.GridDepth
		* cellSize


	local previewHeight =
		boundingSize.Y
		+ EXTRA_BOX_HEIGHT


	--==================================================
	-- SIZE PREVIEW BOX
	--==================================================

	previewBox.Size =
		Vector3.new(
			footprintWidth,
			previewHeight,
			footprintDepth
		)


	--==================================================
	-- POSITION PREVIEW BOX
	--==================================================

	-- GetPlacementSurfaceCFrame already places us at
	-- the CENTER of the exact occupied grid footprint.
	--
	-- Move upward by half the box height so the bottom
	-- of the box sits on the plot surface.

	previewBox.CFrame =
		surfaceCFrame
		* CFrame.new(
			0,
			previewHeight / 2,
			0
		)

	--==================================================
	-- PREVIEW COLOR
	--==================================================

	if currentPlacementValid then

		local validColor =
			Color3.fromRGB(
				60,
				255,
				80
			)


		previewBox.Color =
			validColor


		previewSelectionBox.Color3 =
			validColor


	else

		local invalidColor =
			Color3.fromRGB(
				255,
				60,
				60
			)


		previewBox.Color =
			invalidColor


		previewSelectionBox.Color3 =
			invalidColor

	end

end


--==================================================
-- ROTATE PLACEMENT
--==================================================

local function RotatePlacement()

	if not activePumpkinId then

		return

	end


	rotation =
		(rotation + 90)
		% 360


	UpdatePreview()

end


--==================================================
-- ATTEMPT PLACEMENT
--==================================================

local function AttemptPlacement()

	if not activePumpkinId then

		return

	end


	if placementPending then

		return

	end


	if not currentPlacementValid then

		return

	end


	if currentGridX == nil
		or currentGridZ == nil then

		return

	end


	placementPending =
		true


	PlacePumpkinRequest:FireServer(
		activePumpkinId,
		currentGridX,
		currentGridZ,
		rotation
	)

end


--==================================================
-- MOBILE ROTATE BUTTON
--==================================================

rotateButton.MouseButton1Click:Connect(
	function()

		RotatePlacement()

	end
)


--==================================================
-- KEYBOARD / MOUSE / CONTROLLER INPUT
--==================================================

UserInputService.InputBegan:Connect(
	function(
		input,
		gameProcessed
	)

		if gameProcessed then

			return

		end


		if not activePumpkinId then

			return

		end


		--==================================================
		-- KEYBOARD ROTATE
		--==================================================

		if input.KeyCode
			== Enum.KeyCode.R then

			RotatePlacement()


			return

		end


		--==================================================
		-- CONTROLLER ROTATE
		--
		-- Xbox X
		-- PlayStation Square
		--==================================================

		if input.KeyCode
			== Enum.KeyCode.ButtonX then

			RotatePlacement()


			return

		end


		--==================================================
		-- MOUSE PLACE
		--==================================================

		if input.UserInputType
			== Enum.UserInputType.MouseButton1 then

			AttemptPlacement()


			return

		end


		--==================================================
		-- CONTROLLER PLACE
		--
		-- Xbox A
		-- PlayStation Cross
		--==================================================

		if input.KeyCode
			== Enum.KeyCode.ButtonA then

			AttemptPlacement()


			return

		end

	end
)


--==================================================
-- MOBILE TOUCH POSITION
--==================================================

UserInputService.TouchStarted:Connect(
	function(
		touch,
		gameProcessed
	)

		if gameProcessed then

			return

		end


		lastTouchPosition =
			Vector2.new(
				touch.Position.X,
				touch.Position.Y
			)

	end
)


UserInputService.TouchMoved:Connect(
	function(
		touch,
		gameProcessed
	)

		if gameProcessed then

			return

		end


		lastTouchPosition =
			Vector2.new(
				touch.Position.X,
				touch.Position.Y
			)

	end
)


--==================================================
-- MOBILE TAP TO PLACE
--==================================================

UserInputService.TouchTapInWorld:Connect(
	function(
		position,
		processedByUI
	)

		-- Ignore taps on UI.
		if processedByUI then

			return

		end


		if not activePumpkinId then

			return

		end


		-- TouchTapInWorld gives us one
		-- Vector2 screen position.
		lastTouchPosition =
			position


		-- Snap preview to the exact place
		-- the player tapped.
		UpdatePreview()


		-- Then attempt placement.
		AttemptPlacement()

	end
)


--==================================================
-- INPUT DEVICE CHANGED
--==================================================

UserInputService.LastInputTypeChanged:Connect(
	function(inputType)

		UpdateControlsForInput(
			inputType
		)

	end
)


--==================================================
-- GAMEPAD CONNECTED
--==================================================

UserInputService.GamepadConnected:Connect(
	function()

		if activePumpkinId then

			UpdateControlsForInput(
				UserInputService:GetLastInputType()
			)

		end

	end
)


--==================================================
-- SERVER PLACEMENT RESULT
--==================================================

PlacementResult.OnClientEvent:Connect(
	function(
		success,
		reason
	)

		placementPending =
			false


		if not success then

			warn(
				"Pumpkin placement failed:",
				reason
			)


			UpdatePreview()


			return

		end


		-- Keep placement mode active if more
		-- pumpkins of this type remain.
		UpdatePreview()

	end
)


--==================================================
-- CHARACTER CONNECTIONS
--==================================================

local characterConnections =
	{}


--==================================================
-- DISCONNECT OLD CHARACTER CONNECTIONS
--==================================================

local function DisconnectCharacterConnections()

	for _, connection in ipairs(
		characterConnections
		) do

		connection:Disconnect()

	end


	characterConnections =
		{}

end


--==================================================
-- SETUP CHARACTER
--==================================================

local function SetupCharacter(
	character
)

	DisconnectCharacterConnections()


	EndPlacement()


	--==================================================
	-- PUMPKIN TOOL EQUIPPED
	--==================================================

	table.insert(
		characterConnections,

		character.ChildAdded:Connect(
			function(child)

				if IsPumpkinTool(
					child
					) then

					BeginPlacement(
						child
					)

				end

			end
		)
	)


	--==================================================
	-- PUMPKIN TOOL UNEQUIPPED / REMOVED
	--==================================================

	table.insert(
		characterConnections,

		character.ChildRemoved:Connect(
			function(child)

				if child
					== activeTool then

					EndPlacement()

				end

			end
		)
	)


	--==================================================
	-- CHECK ALREADY EQUIPPED TOOL
	--==================================================

	for _, child in ipairs(
		character:GetChildren()
		) do

		if IsPumpkinTool(
			child
			) then

			BeginPlacement(
				child
			)


			break

		end

	end

end


--==================================================
-- CHARACTER RESPAWN
--==================================================

player.CharacterAdded:Connect(
	function(character)

		SetupCharacter(
			character
		)

	end
)


if player.Character then

	SetupCharacter(
		player.Character
	)

end


--==================================================
-- UPDATE PREVIEW EVERY FRAME
--==================================================

RunService.RenderStepped:Connect(
	function()

		if activePumpkinId then

			UpdatePreview()

		end

	end
)
