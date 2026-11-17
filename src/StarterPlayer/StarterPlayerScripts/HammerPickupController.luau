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
-- PLAYER
--==================================================

local player =
	Players.LocalPlayer


local playerGui =
	player:WaitForChild(
		"PlayerGui"
	)


--==================================================
-- WORLD
--==================================================

local Plots =
	workspace:WaitForChild(
		"Plots"
	)


--==================================================
-- REMOTES
--==================================================

local Remotes =
	ReplicatedStorage
	:WaitForChild(
		"Remotes"
	)


local PickupPumpkinRequest =
	Remotes
	:WaitForChild(
		"PickupPumpkinRequest"
	)


local PickupPumpkinResult =
	Remotes
	:WaitForChild(
		"PickupPumpkinResult"
	)


--==================================================
-- SETTINGS
--==================================================

local HAMMER_TOOL_NAME =
	"Hammer"


-- Yellow used for pickup highlighting.
local PICKUP_COLOR =
	Color3.fromRGB(
		255,
		220,
		35
	)


--==================================================
-- PICKUP BOX SETTINGS
--==================================================

-- X/Z come directly from the pumpkin's
-- GridWidth / GridDepth.
--
-- We only add a little extra height.

local BOX_EXTRA_HEIGHT =
	0.6


--==================================================
-- PICKUP STATE
--==================================================

local pickupModeActive =
	false


local activeHammer =
	nil


local currentPlot =
	nil


local currentPlotFloor =
	nil


local placedPumpkinsFolder =
	nil


local hoveredPumpkin =
	nil


local pickupPending =
	false


local lastTouchPosition =
	nil


--==================================================
-- YELLOW PREVIEW
--==================================================

local pickupBox =
	nil


local pickupSelectionBox =
	nil


--==================================================
-- FIND OWN PLOT
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
-- REFRESH PLOT
--==================================================

local function RefreshPlot()

	currentPlot =
		FindOwnPlot()


	if not currentPlot then

		currentPlotFloor =
			nil


		placedPumpkinsFolder =
			nil


		return false

	end


	currentPlotFloor =
		currentPlot:FindFirstChild(
			"PlotFloor"
		)


	placedPumpkinsFolder =
		currentPlot:FindFirstChild(
			"PlacedPumpkins"
		)


	return currentPlotFloor ~= nil
		and placedPumpkinsFolder ~= nil

end


--==================================================
-- DETECT PLAYSTATION
--==================================================

local function IsPlayStation()

	local success,
		buttonName =
		pcall(
			function()

				return UserInputService
				:GetStringForKeyCode(
					Enum.KeyCode.ButtonA
				)

			end
		)


	if success
		and buttonName
		== "ButtonCross" then

		return true

	end


	return false

end


--==================================================
-- CREATE PICKUP GUI
--==================================================

local pickupGui =
	Instance.new("ScreenGui")


pickupGui.Name =
	"HammerPickupGui"


pickupGui.ResetOnSpawn =
	false


pickupGui.IgnoreGuiInset =
	false


pickupGui.DisplayOrder =
	21


pickupGui.Parent =
	playerGui


--==================================================
-- INSTRUCTION TEXT
--==================================================

local instructionText =
	Instance.new("TextLabel")


instructionText.Name =
	"InstructionText"


instructionText.AnchorPoint =
	Vector2.new(
		0.5,
		1
	)


-- Lower than before.
--
-- Previous value was around -120.
instructionText.Position =
	UDim2.new(
		0.5,
		0,

		1,
		-95
	)


instructionText.Size =
	UDim2.fromOffset(
		760,
		58
	)


instructionText.BackgroundTransparency =
	1


instructionText.Text =
	"Click on pumpkins to pick up"


instructionText.TextColor3 =
	Color3.fromRGB(
		255,
		255,
		255
	)


-- Existing built-in text outline.
instructionText.TextStrokeColor3 =
	Color3.fromRGB(
		0,
		0,
		0
	)


instructionText.TextStrokeTransparency =
	0.1


instructionText.Font =
	Enum.Font.GothamBlack


instructionText.TextScaled =
	true


instructionText.Visible =
	false


instructionText.Parent =
	pickupGui


--==================================================
-- EXTRA +2 TEXT OUTLINE
--==================================================

-- Roblox TextStroke doesn't have a thickness
-- property.
--
-- This UIStroke adds another 2 pixels around
-- the existing outline.

local instructionStroke =
	Instance.new("UIStroke")


instructionStroke.Thickness =
	2


instructionStroke.Color =
	Color3.fromRGB(
		0,
		0,
		0
	)


instructionStroke.Transparency =
	0


instructionStroke.Parent =
	instructionText


--==================================================
-- TEXT SIZE CONSTRAINT
--==================================================

local textConstraint =
	Instance.new("UITextSizeConstraint")


textConstraint.MaxTextSize =
	38


textConstraint.MinTextSize =
	18


textConstraint.Parent =
	instructionText


--==================================================
-- CREATE PICKUP BOX
--==================================================

local function CreatePickupBox()

	if pickupBox then

		return

	end


	pickupBox =
		Instance.new("Part")


	pickupBox.Name =
		"PickupPreviewBox"


	pickupBox.Anchored =
		true


	pickupBox.CanCollide =
		false


	pickupBox.CanTouch =
		false


	pickupBox.CanQuery =
		false


	pickupBox.CastShadow =
		false


	pickupBox.Material =
		Enum.Material.ForceField


	pickupBox.Transparency =
		0.78


	pickupBox.Color =
		PICKUP_COLOR


	pickupBox.Parent =
		nil


	--==================================================
	-- YELLOW OUTLINE
	--==================================================

	pickupSelectionBox =
		Instance.new("SelectionBox")


	pickupSelectionBox.Name =
		"PickupSelectionBox"


	pickupSelectionBox.Adornee =
		pickupBox


	pickupSelectionBox.LineThickness =
		0.05


	pickupSelectionBox.SurfaceTransparency =
		1


	pickupSelectionBox.Color3 =
		PICKUP_COLOR


	pickupSelectionBox.Parent =
		pickupBox

end


--==================================================
-- HIDE PICKUP BOX
--==================================================

local function HidePickupBox()

	if pickupBox then

		pickupBox.Parent =
			nil

	end


	hoveredPumpkin =
		nil

end


--==================================================
-- SHOW PICKUP BOX
--==================================================

local function ShowPickupBox(
	pumpkinModel
)

	if not pickupBox then

		CreatePickupBox()

	end


	if not pickupBox then

		return

	end


	if not currentPlotFloor then

		RefreshPlot()


		if not currentPlotFloor then

			HidePickupBox()


			return

		end

	end


	--==================================================
	-- PUMPKIN ID
	--==================================================

	local pumpkinId =
		pumpkinModel:GetAttribute(
			"PumpkinId"
		)


	if type(pumpkinId)
		~= "string" then

		HidePickupBox()


		return

	end


	--==================================================
	-- PUMPKIN CONFIG
	--==================================================

	local pumpkinInfo =
		PumpkinConfig.GetPumpkin(
			pumpkinId
		)


	if not pumpkinInfo then

		HidePickupBox()


		return

	end


	--==================================================
	-- SAVED GRID INFORMATION
	--==================================================

	local gridX =
		pumpkinModel:GetAttribute(
			"GridX"
		)


	local gridZ =
		pumpkinModel:GetAttribute(
			"GridZ"
		)


	local rotation =
		pumpkinModel:GetAttribute(
			"Rotation"
		)
		or 0


	if type(gridX)
		~= "number"
		or type(gridZ)
		~= "number" then

		HidePickupBox()


		return

	end


	--==================================================
	-- ROTATED GRID FOOTPRINT
	--==================================================

	-- These values are used to locate the exact
	-- occupied footprint on the plot.

	local width,
		depth =
		PumpkinGridUtil
		.GetRotatedGridSize(
			pumpkinInfo.GridWidth,
			pumpkinInfo.GridDepth,
			rotation
		)


	--==================================================
	-- FOOTPRINT SURFACE CFRAME
	--==================================================

	-- This returns the same centered CFrame that
	-- PumpkinPlacementController uses.
	--
	-- That means even footprints such as 2x2
	-- are centered correctly between their cells.

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
	-- ACTUAL PUMPKIN HEIGHT
	--==================================================

	-- Only Y uses the physical pumpkin size.

	local _,
		boundingSize =
		pumpkinModel:GetBoundingBox()


	local boxHeight =
		boundingSize.Y
		+ BOX_EXTRA_HEIGHT


	--==================================================
	-- GRID FOOTPRINT SIZE
	--==================================================

	local cellSize =
		GameConfig.Grid.CellSize


	-- IMPORTANT:
	--
	-- Use the ORIGINAL GridWidth / GridDepth here.
	--
	-- surfaceCFrame already contains the rotation,
	-- so swapping the dimensions here as well would
	-- rotate them twice.

	local footprintWidth =
		pumpkinInfo.GridWidth
		* cellSize


	local footprintDepth =
		pumpkinInfo.GridDepth
		* cellSize


	--==================================================
	-- SIZE YELLOW BOX
	--==================================================

	pickupBox.Size =
		Vector3.new(
			footprintWidth,
			boxHeight,
			footprintDepth
		)


	--==================================================
	-- POSITION YELLOW BOX
	--==================================================

	-- surfaceCFrame sits on the plot surface at the
	-- center of the exact grid footprint.
	--
	-- Raise the box by half its height so its bottom
	-- sits on the plot.

	pickupBox.CFrame =
		surfaceCFrame
		* CFrame.new(
			0,
			boxHeight / 2,
			0
		)


	pickupBox.Parent =
		workspace

end


--==================================================
-- FIND PUMPKIN MODEL
--==================================================

local function FindPumpkinModel(
	hitObject
)

	if not hitObject
		or not placedPumpkinsFolder then

		return nil

	end


	local object =
		hitObject


	while object
		and object
		~= placedPumpkinsFolder do

		if object:IsA("Model")
			and object.Parent
			== placedPumpkinsFolder then

			local instanceId =
				object:GetAttribute(
					"InstanceId"
				)


			local ownerUserId =
				object:GetAttribute(
					"OwnerUserId"
				)


			-- Only allow the player's own pumpkins.
			if type(instanceId)
				== "string"
				and ownerUserId
				== player.UserId then

				return object

			end

		end


		object =
			object.Parent

	end


	return nil

end


--==================================================
-- RAYCAST FROM SCREEN POSITION
--==================================================

local function GetPumpkinAtScreenPoint(
	screenPoint
)

	if not placedPumpkinsFolder then

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


	local params =
		RaycastParams.new()


	-- Only this player's PlacedPumpkins
	-- folder can be targeted.
	params.FilterType =
		Enum.RaycastFilterType.Include


	params.FilterDescendantsInstances = {
		placedPumpkinsFolder,
	}


	local result =
		workspace:Raycast(
			ray.Origin,

			ray.Direction
			* 1000,

			params
		)


	if not result then

		return nil

	end


	return FindPumpkinModel(
		result.Instance
	)

end


--==================================================
-- GET TARGET SCREEN POSITION
--==================================================

local function GetTargetScreenPoint()

	local inputType =
		UserInputService:GetLastInputType()


	--==================================================
	-- CONTROLLER
	--==================================================

	-- Console targets the middle of the screen.
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
-- UPDATE TARGET
--==================================================

local function UpdateTarget()

	if not pickupModeActive then

		HidePickupBox()


		return

	end


	if not placedPumpkinsFolder then

		RefreshPlot()


		if not placedPumpkinsFolder then

			HidePickupBox()


			return

		end

	end


	local screenPoint =
		GetTargetScreenPoint()


	if not screenPoint then

		HidePickupBox()


		return

	end


	local pumpkin =
		GetPumpkinAtScreenPoint(
			screenPoint
		)


	if not pumpkin then

		HidePickupBox()


		return

	end


	hoveredPumpkin =
		pumpkin


	ShowPickupBox(
		pumpkin
	)

end


--==================================================
-- UPDATE INSTRUCTION TEXT
--==================================================

local function UpdateInstructionText()

	local inputType =
		UserInputService:GetLastInputType()


	--==================================================
	-- MOBILE
	--==================================================

	if inputType
		== Enum.UserInputType.Touch then

		instructionText.Text =
			"Tap pumpkins to pick up"


		-- Also kept lower.
		instructionText.Position =
			UDim2.new(
				0.5,
				0,

				1,
				-95
			)


		return

	end


	--==================================================
	-- CONTROLLER
	--==================================================

	if inputType.Name:find(
		"Gamepad"
		) then

		if IsPlayStation() then

			instructionText.Text =
				"Aim at a pumpkin and press X to pick up"

		else

			instructionText.Text =
				"Aim at a pumpkin and press A to pick up"

		end


		-- Console needs to stay above the hotbar.
		instructionText.Position =
			UDim2.new(
				0.5,
				0,

				1,
				-155
			)


		return

	end


	--==================================================
	-- PC
	--==================================================

	instructionText.Text =
		"Click on pumpkins to pick up"


	-- Lowered from -120 to -95.
	instructionText.Position =
		UDim2.new(
			0.5,
			0,

			1,
			-95
		)

end


--==================================================
-- BEGIN PICKUP MODE
--==================================================

local function BeginPickupMode(
	hammer
)

	activeHammer =
		hammer


	pickupModeActive =
		true


	pickupPending =
		false


	RefreshPlot()


	CreatePickupBox()


	UpdateInstructionText()


	instructionText.Visible =
		true


	UpdateTarget()

end


--==================================================
-- END PICKUP MODE
--==================================================

local function EndPickupMode()

	pickupModeActive =
		false


	activeHammer =
		nil


	pickupPending =
		false


	instructionText.Visible =
		false


	HidePickupBox()

end


--==================================================
-- IS HAMMER TOOL
--==================================================

local function IsHammerTool(
	instance
)

	return instance:IsA("Tool")

		and instance.Name
		== HAMMER_TOOL_NAME

end


--==================================================
-- ATTEMPT PICKUP MODEL
--==================================================

local function AttemptPickupModel(
	pumpkinModel
)

	if not pickupModeActive then

		return

	end


	if pickupPending then

		return

	end


	if not pumpkinModel then

		return

	end


	--==================================================
	-- OWNERSHIP CHECK
	--==================================================

	if pumpkinModel:GetAttribute(
		"OwnerUserId"
		) ~= player.UserId then

		return

	end


	local instanceId =
		pumpkinModel:GetAttribute(
			"InstanceId"
		)


	if type(instanceId)
		~= "string" then

		return

	end


	pickupPending =
		true


	PickupPumpkinRequest:FireServer(
		instanceId
	)

end


--==================================================
-- ATTEMPT CURRENT TARGET
--==================================================

local function AttemptCurrentTarget()

	AttemptPickupModel(
		hoveredPumpkin
	)

end


--==================================================
-- MOUSE + CONTROLLER INPUT
--==================================================

UserInputService.InputBegan:Connect(
	function(
		input,
		gameProcessed
	)

		if gameProcessed then

			return

		end


		if not pickupModeActive then

			return

		end


		--==================================================
		-- PC LEFT CLICK
		--==================================================

		if input.UserInputType
			== Enum.UserInputType.MouseButton1 then

			AttemptCurrentTarget()


			return

		end


		--==================================================
		-- CONTROLLER PICKUP
		--
		-- Xbox:
		-- A
		--
		-- PlayStation:
		-- Cross
		--==================================================

		if input.KeyCode
			== Enum.KeyCode.ButtonA then

			AttemptCurrentTarget()


			return

		end

	end
)


--==================================================
-- MOBILE TOUCH START
--==================================================

UserInputService.TouchStarted:Connect(
	function(
		touch,
		gameProcessed
	)

		if gameProcessed then

			return

		end


		if not pickupModeActive then

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
-- MOBILE TOUCH MOVE
--==================================================

UserInputService.TouchMoved:Connect(
	function(
		touch,
		gameProcessed
	)

		if gameProcessed then

			return

		end


		if not pickupModeActive then

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
-- MOBILE TAP PICKUP
--==================================================

UserInputService.TouchTapInWorld:Connect(
	function(
		position,
		processedByUI
	)

		if processedByUI then

			return

		end


		if not pickupModeActive then

			return

		end


		--==================================================
		-- USE EXACT TAP POSITION
		--==================================================

		lastTouchPosition =
			position


		local pumpkin =
			GetPumpkinAtScreenPoint(
				position
			)


		if not pumpkin then

			HidePickupBox()


			return

		end


		-- Show the yellow box on the
		-- pumpkin that was tapped.
		hoveredPumpkin =
			pumpkin


		ShowPickupBox(
			pumpkin
		)


		-- Then pick it up.
		AttemptPickupModel(
			pumpkin
		)

	end
)


--==================================================
-- INPUT DEVICE CHANGED
--==================================================

UserInputService.LastInputTypeChanged:Connect(
	function()

		if not pickupModeActive then

			return

		end


		UpdateInstructionText()


		UpdateTarget()

	end
)


--==================================================
-- GAMEPAD CONNECTED
--==================================================

UserInputService.GamepadConnected:Connect(
	function()

		if pickupModeActive then

			UpdateInstructionText()


			UpdateTarget()

		end

	end
)


--==================================================
-- SERVER PICKUP RESULT
--==================================================

PickupPumpkinResult.OnClientEvent:Connect(
	function(
		success,
		reason
	)

		pickupPending =
			false


		--==================================================
		-- FAILED
		--==================================================

		if not success then

			warn(
				"Pumpkin pickup failed:",
				reason
			)


			UpdateTarget()


			return

		end


		--==================================================
		-- SUCCESS
		--==================================================

		-- Server removed the physical pumpkin,
		-- so remove the stale highlight.
		HidePickupBox()


		UpdateTarget()

	end
)


--==================================================
-- CHARACTER CONNECTIONS
--==================================================

local characterConnections =
	{}


--==================================================
-- DISCONNECT OLD CONNECTIONS
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


	EndPickupMode()


	--==================================================
	-- HAMMER EQUIPPED
	--==================================================

	table.insert(
		characterConnections,

		character.ChildAdded:Connect(
			function(child)

				if IsHammerTool(
					child
					) then

					BeginPickupMode(
						child
					)

				end

			end
		)
	)


	--==================================================
	-- HAMMER UNEQUIPPED
	--==================================================

	table.insert(
		characterConnections,

		character.ChildRemoved:Connect(
			function(child)

				if child
					== activeHammer then

					EndPickupMode()

				end

			end
		)
	)


	--==================================================
	-- CHECK ALREADY EQUIPPED HAMMER
	--==================================================

	for _, child in ipairs(
		character:GetChildren()
		) do

		if IsHammerTool(
			child
			) then

			BeginPickupMode(
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
-- UPDATE TARGET EVERY FRAME
--==================================================

RunService.RenderStepped:Connect(
	function()

		if pickupModeActive then

			UpdateTarget()

		end

	end
)
