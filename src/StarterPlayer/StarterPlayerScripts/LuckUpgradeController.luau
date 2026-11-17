--==================================================
-- SERVICES
--==================================================

local Players =
	game:GetService("Players")


local ReplicatedStorage =
	game:GetService("ReplicatedStorage")


local TweenService =
	game:GetService("TweenService")


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
-- REFERENCES
--==================================================

local Plots =
	workspace:WaitForChild(
		"Plots"
	)


local NumberFormatter =
	require(
		ReplicatedStorage
		:WaitForChild("Modules")
		:WaitForChild("NumberFormatter")
	)


--==================================================
-- SURFACE GUI TEMPLATE
--==================================================

-- StarterGui automatically copies this into
-- PlayerGui when the player joins.
--
-- We use this copy as the template and create
-- one SurfaceGui for every plot.

local SurfaceGuiTemplate =
	playerGui:WaitForChild(
		"LuckUpgradeSurfaceGui"
	)


-- The template itself should not be displayed.
SurfaceGuiTemplate.Enabled =
	false


SurfaceGuiTemplate.Adornee =
	nil


--==================================================
-- REMOTES
--==================================================

local LuckRemotes =
	ReplicatedStorage
	:WaitForChild("Remotes")
	:WaitForChild("Luck")


local GetLuckState =
	LuckRemotes:WaitForChild(
		"GetLuckState"
	)


local PurchaseLuck =
	LuckRemotes:WaitForChild(
		"PurchaseLuck"
	)


--==================================================
-- BUTTON SETTINGS
--==================================================

-- Normal button size.
local NORMAL_SCALE =
	1


-- Button becomes slightly larger
-- while the mouse is hovering over it.
local HOVER_SCALE =
	1.05


-- Button becomes smaller when clicked.
local CLICK_SCALE =
	0.92


-- Hover animation speed.
local HOVER_TIME =
	0.10


-- Click-down animation speed.
local CLICK_TIME =
	0.08


-- Click return animation speed.
local RETURN_TIME =
	0.10


--==================================================
-- DISABLED APPEARANCE
--==================================================

local DISABLED_COLOR =
	Color3.fromRGB(
		120,
		120,
		120
	)


--==================================================
-- STATE
--==================================================

local currentLuckState =
	nil


local purchaseBusy =
	false


-- Stores all of the locally-created boards.
--
-- Example:
--
-- boards[Plot1] = {
--     Plot = Plot1,
--     SurfaceGui = ...
-- }

local boards =
	{}


-- Saves each button's original ImageColor3 so
-- we can restore it after greying the button out.

local buttonOriginalColors =
	{}


--==================================================
-- GET BUTTON UISCALE
--==================================================

local function GetButtonScale(
	button
)

	local uiScale =
		button:FindFirstChild(
			"ButtonScale"
		)


	if not uiScale then

		uiScale =
			Instance.new(
				"UIScale"
			)


		uiScale.Name =
			"ButtonScale"


		uiScale.Scale =
			NORMAL_SCALE


		uiScale.Parent =
			button

	end


	return uiScale

end


--==================================================
-- TWEEN BUTTON SCALE
--==================================================

local function TweenButtonScale(
	button,
	targetScale,
	duration,
	easingStyle,
	easingDirection
)

	local uiScale =
		GetButtonScale(
			button
		)


	local tween =
		TweenService:Create(
			uiScale,

			TweenInfo.new(
				duration,
				easingStyle
				or Enum.EasingStyle.Quad,
				easingDirection
				or Enum.EasingDirection.Out
			),

			{
				Scale =
				targetScale
			}
		)


	tween:Play()


	return tween

end


--==================================================
-- PLAY BUTTON CLICK ANIMATION
--==================================================

local function PlayButtonClick(
	button
)

	--==================================================
	-- SHRINK
	--==================================================

	local downTween =
		TweenButtonScale(
			button,
			CLICK_SCALE,
			CLICK_TIME,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		)


	downTween.Completed:Wait()


	--==================================================
	-- RETURN
	--==================================================

	-- If the mouse is still over the button after
	-- clicking, return to the hover size.
	--
	-- Otherwise return to normal size.

	local isHovering =
		button:GetAttribute(
			"IsHovering"
		)


	local targetScale


	if isHovering
		and button.Interactable then

		targetScale =
			HOVER_SCALE

	else

		targetScale =
			NORMAL_SCALE

	end


	TweenButtonScale(
		button,
		targetScale,
		RETURN_TIME,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out
	)

end


--==================================================
-- CONNECT BUTTON HOVER
--==================================================

local function ConnectButtonHover(
	button
)

	-- Ensure the UIScale exists immediately.
	GetButtonScale(
		button
	)


	-- Start as not hovering.
	button:SetAttribute(
		"IsHovering",
		false
	)


	--==================================================
	-- MOUSE ENTER
	--==================================================

	button.MouseEnter:Connect(
		function()

			-- Don't animate disabled buttons.
			if not button.Interactable then

				return

			end


			button:SetAttribute(
				"IsHovering",
				true
			)


			TweenButtonScale(
				button,
				HOVER_SCALE,
				HOVER_TIME,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			)

		end
	)


	--==================================================
	-- MOUSE LEAVE
	--==================================================

	button.MouseLeave:Connect(
		function()

			button:SetAttribute(
				"IsHovering",
				false
			)


			TweenButtonScale(
				button,
				NORMAL_SCALE,
				HOVER_TIME,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			)

		end
	)

end


--==================================================
-- SET BUTTON ENABLED / DISABLED
--==================================================

local function SetButtonEnabledVisual(
	button,
	enabled
)

	-- Save original color once.
	if buttonOriginalColors[
		button
		] == nil then

		buttonOriginalColors[
		button
		] =
			button.ImageColor3

	end


	--==================================================
	-- ENABLED
	--==================================================

	if enabled then

		button.ImageColor3 =
			buttonOriginalColors[
		button
		]


		button.Active =
			true


		button.Interactable =
			true


		--==================================================
		-- DISABLED
		--==================================================

	else

		button.ImageColor3 =
			DISABLED_COLOR


		button.Active =
			false


		button.Interactable =
			false


		-- Disabled buttons should not remain enlarged
		-- if they became disabled while being hovered.

		button:SetAttribute(
			"IsHovering",
			false
		)


		TweenButtonScale(
			button,
			NORMAL_SCALE,
			HOVER_TIME,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		)

	end

end


--==================================================
-- FIND UPGRADE INFO PART
--==================================================

local function GetUpgradeInfoPart(
	plot
)

	--==================================================
	-- WAIT FOR ROLL AREA
	--==================================================

	local rollArea =
		plot:WaitForChild(
			"RollArea",
			10
		)


	if not rollArea then

		warn(
			"[LuckUpgradeController] RollArea did not appear for:",
			plot.Name
		)

		return nil

	end


	--==================================================
	-- WAIT FOR UPGRADE INFO PART
	--==================================================

	local startTime =
		os.clock()


	local upgradeInfoPart =
		nil


	while not upgradeInfoPart
		and os.clock() - startTime < 10 do

		upgradeInfoPart =
			rollArea:FindFirstChild(
				"UpgradeInfoPart",
				true
			)


		if not upgradeInfoPart then

			task.wait(
				0.1
			)

		end

	end


	if not upgradeInfoPart then

		warn(
			"[LuckUpgradeController] UpgradeInfoPart did not appear for:",
			plot.Name
		)

		return nil

	end


	if not upgradeInfoPart:IsA(
		"BasePart"
		) then

		warn(
			"[LuckUpgradeController] UpgradeInfoPart exists but is not a BasePart in:",
			plot.Name
		)

		return nil

	end


	return upgradeInfoPart

end


--==================================================
-- CREATE LOCAL BOARD FOR PLOT
--==================================================

local function CreateBoardForPlot(
	plot
)

	-- Don't create the same board twice.
	if boards[
		plot
		] then

		return boards[
		plot
		]

	end


	--==================================================
	-- FIND PHYSICAL BOARD PART
	--==================================================

	local upgradeInfoPart =
		GetUpgradeInfoPart(
			plot
		)


	if not upgradeInfoPart then

		-- Some plots may not have their upgrade
		-- board built yet, so simply ignore them.

		return nil

	end


	-- Required so the physical SurfaceGui can
	-- receive mouse interaction.
	upgradeInfoPart.CanQuery =
		true


	--==================================================
	-- CLONE SURFACE GUI
	--==================================================

	local surfaceGui =
		SurfaceGuiTemplate:Clone()


	surfaceGui.Name =
		"LuckUpgradeSurfaceGui_"
		.. plot.Name


	-- Display this local SurfaceGui on the
	-- physical UpgradeInfoPart.
	surfaceGui.Adornee =
		upgradeInfoPart


	surfaceGui.Enabled =
		true


	surfaceGui.Active =
		true


	-- IMPORTANT:
	--
	-- Keep the SurfaceGui inside PlayerGui.
	--
	-- Adornee makes it visually appear on the
	-- physical part in Workspace.

	surfaceGui.Parent =
		playerGui


	--==================================================
	-- FIND BUY 1 FRAME
	--==================================================

	local buy1Frame =
		surfaceGui:FindFirstChild(
			"BuyButton1Frame"
		)


	if not buy1Frame then

		warn(
			"[LuckUpgradeController] BuyButton1Frame missing in template."
		)


		surfaceGui:Destroy()


		return nil

	end


	--==================================================
	-- FIND BUY 3 FRAME
	--==================================================

	local buy3Frame =
		surfaceGui:FindFirstChild(
			"BuyButton3Frame"
		)


	if not buy3Frame then

		warn(
			"[LuckUpgradeController] BuyButton3Frame missing in template."
		)


		surfaceGui:Destroy()


		return nil

	end


	--==================================================
	-- BUY 1 REFERENCES
	--==================================================

	local buy1Button =
		buy1Frame:FindFirstChild(
			"BuyButton"
		)


	local buy1Text =
		buy1Frame:FindFirstChild(
			"BuyText"
		)


	local buy1Price =
		buy1Frame:FindFirstChild(
			"PriceText"
		)


	--==================================================
	-- BUY 3 REFERENCES
	--==================================================

	local buy3Button =
		buy3Frame:FindFirstChild(
			"BuyButton"
		)


	local buy3Text =
		buy3Frame:FindFirstChild(
			"BuyText"
		)


	local buy3Price =
		buy3Frame:FindFirstChild(
			"PriceText"
		)


	--==================================================
	-- VALIDATE EVERYTHING
	--==================================================

	if not buy1Button
		or not buy1Text
		or not buy1Price
		or not buy3Button
		or not buy3Text
		or not buy3Price then

		warn(
			"[LuckUpgradeController] One or more UI objects are missing in:",
			surfaceGui.Name
		)


		surfaceGui:Destroy()


		return nil

	end


	--==================================================
	-- CREATE BOARD TABLE
	--==================================================

	local board =
		{
			Plot =
			plot,

			UpgradeInfoPart =
			upgradeInfoPart,

			SurfaceGui =
			surfaceGui,

			Buy1Button =
			buy1Button,

			Buy1Text =
			buy1Text,

			Buy1Price =
			buy1Price,

			Buy3Button =
			buy3Button,

			Buy3Text =
			buy3Text,

			Buy3Price =
			buy3Price,
		}


	boards[
	plot
	] =
		board


	return board

end


--==================================================
-- UPDATE ONE BOARD
--==================================================

local function UpdateBoard(
	board
)

	local plot =
		board.Plot


	--==================================================
	-- DOES THIS PLAYER OWN THIS PLOT?
	--==================================================

	local isOwner =
		plot:GetAttribute(
			"OwnerUserId"
		) == player.UserId


	--==================================================
	-- BUTTON TEXT
	--==================================================

	board.Buy1Text.Text =
		"Buy 1"


	board.Buy3Text.Text =
		"Buy 3"


	--==================================================
	-- OTHER PLAYER'S PLOT / UNCLAIMED PLOT
	--==================================================

	if not isOwner then

		board.Buy1Price.Text =
			"$0"


		board.Buy3Price.Text =
			"$0"


		SetButtonEnabledVisual(
			board.Buy1Button,
			false
		)


		SetButtonEnabledVisual(
			board.Buy3Button,
			false
		)


		return

	end


	--==================================================
	-- PLAYER DATA NOT READY YET
	--==================================================

	if not currentLuckState then

		board.Buy1Price.Text =
			"$0"


		board.Buy3Price.Text =
			"$0"


		SetButtonEnabledVisual(
			board.Buy1Button,
			false
		)


		SetButtonEnabledVisual(
			board.Buy3Button,
			false
		)


		return

	end


	--==================================================
	-- DISPLAY PRICES
	--==================================================

	board.Buy1Price.Text =
		NumberFormatter
		.FormatMoneyWithDollar(
			currentLuckState.Buy1Price
		)


	board.Buy3Price.Text =
		NumberFormatter
		.FormatMoneyWithDollar(
			currentLuckState.Buy3Price
		)


	--==================================================
	-- CHECK AFFORDABILITY
	--==================================================

	local dollars =
		currentLuckState.Dollars
		or 0


	local canAfford1 =
		dollars
		>= currentLuckState.Buy1Price


	local canAfford3 =
		dollars
		>= currentLuckState.Buy3Price


	--==================================================
	-- ENABLE / DISABLE BUTTONS
	--==================================================

	SetButtonEnabledVisual(
		board.Buy1Button,

		canAfford1
			and not purchaseBusy
	)


	SetButtonEnabledVisual(
		board.Buy3Button,

		canAfford3
			and not purchaseBusy
	)

end


--==================================================
-- UPDATE ALL BOARDS
--==================================================

local function UpdateAllBoards()

	for _, board in pairs(
		boards
		) do

		UpdateBoard(
			board
		)

	end

end


--==================================================
-- REQUEST CURRENT LUCK STATE
--==================================================

local function RefreshLuckState()

	local callSucceeded,
		stateSucceeded,
		result =
		pcall(
			function()

				return GetLuckState
				:InvokeServer()

			end
		)


	--==================================================
	-- REMOTE ITSELF FAILED
	--==================================================

	if not callSucceeded then

		warn(
			"[LuckUpgradeController] GetLuckState remote failed:",
			stateSucceeded
		)


		return false

	end


	--==================================================
	-- SERVER SAID STATE ISN'T READY
	--==================================================

	if not stateSucceeded then

		-- DataNotLoaded is normal for a brief moment
		-- while the player's profile loads.

		if result
			~= "DataNotLoaded" then

			warn(
				"[LuckUpgradeController] Could not get Luck state:",
				result
			)

		end


		return false

	end


	--==================================================
	-- SUCCESS
	--==================================================

	currentLuckState =
		result


	UpdateAllBoards()


	return true

end


--==================================================
-- PURCHASE LUCK
--==================================================

local function Purchase(
	board,
	amount
)

	--==================================================
	-- ALREADY PURCHASING
	--==================================================

	if purchaseBusy then

		return

	end


	--==================================================
	-- VERIFY THIS IS OUR PLOT
	--==================================================

	if board.Plot:GetAttribute(
		"OwnerUserId"
		) ~= player.UserId then

		return

	end


	--==================================================
	-- DATA MUST BE READY
	--==================================================

	if not currentLuckState then

		return

	end


	--==================================================
	-- GET LOCAL DISPLAY PRICE
	--==================================================

	local price


	if amount == 1 then

		price =
			currentLuckState.Buy1Price


	elseif amount == 3 then

		price =
			currentLuckState.Buy3Price


	else

		return

	end


	--==================================================
	-- CLIENT-SIDE AFFORDABILITY CHECK
	--==================================================

	-- This is only for responsiveness.
	--
	-- The server performs the real authoritative
	-- affordability check.

	if currentLuckState.Dollars
		< price then

		return

	end


	--==================================================
	-- CHOOSE BUTTON
	--==================================================

	local button


	if amount == 1 then

		button =
			board.Buy1Button

	else

		button =
			board.Buy3Button

	end


	--==================================================
	-- CLICK ANIMATION
	--==================================================

	-- Play this BEFORE disabling the buttons so
	-- the button visibly reacts immediately.

	task.spawn(
		function()

			PlayButtonClick(
				button
			)

		end
	)


	--==================================================
	-- LOCK BUTTONS
	--==================================================

	purchaseBusy =
		true


	UpdateAllBoards()


	--==================================================
	-- ASK SERVER TO PURCHASE
	--==================================================

	local callSucceeded,
		purchaseSucceeded,
		result =
		pcall(
			function()

				return PurchaseLuck
				:InvokeServer(
					board.Plot,
					amount
				)

			end
		)


	--==================================================
	-- REMOTE FAILED
	--==================================================

	if not callSucceeded then

		warn(
			"[LuckUpgradeController] PurchaseLuck remote failed:",
			purchaseSucceeded
		)


		purchaseBusy =
			false


		RefreshLuckState()


		return

	end


	--==================================================
	-- SERVER REJECTED PURCHASE
	--==================================================

	if not purchaseSucceeded then

		warn(
			"[LuckUpgradeController] Luck purchase rejected:",
			result
		)


		purchaseBusy =
			false


		RefreshLuckState()


		return

	end


	--==================================================
	-- PURCHASE SUCCESS
	--==================================================

	currentLuckState =
		{
			LuckLevel =
			result.LuckLevel,

			LuckMultiplier =
			result.LuckMultiplier,

			Buy1Price =
			result.Buy1Price,

			Buy3Price =
			result.Buy3Price,

			Dollars =
			result.Dollars,
		}


	purchaseBusy =
		false


	-- Immediately update:
	--
	-- Buy 1 price
	-- Buy 3 price
	-- affordability
	-- button colours

	UpdateAllBoards()

end


--==================================================
-- CONNECT ONE BOARD
--==================================================

local function ConnectBoard(
	plot
)

	--==================================================
	-- CREATE BOARD
	--==================================================

	local board =
		CreateBoardForPlot(
			plot
		)


	if not board then

		return

	end


	--==================================================
	-- HOVER EFFECTS
	--==================================================

	ConnectButtonHover(
		board.Buy1Button
	)


	ConnectButtonHover(
		board.Buy3Button
	)


	--==================================================
	-- BUY 1
	--==================================================

	board.Buy1Button.Activated:Connect(
		function()

			Purchase(
				board,
				1
			)

		end
	)


	--==================================================
	-- BUY 3
	--==================================================

	board.Buy3Button.Activated:Connect(
		function()

			Purchase(
				board,
				3
			)

		end
	)


	--==================================================
	-- PLOT OWNER CHANGED
	--==================================================

	plot:GetAttributeChangedSignal(
		"OwnerUserId"
	):Connect(
		function()

			UpdateAllBoards()

		end
	)


	--==================================================
	-- INITIAL DISPLAY
	--==================================================

	UpdateBoard(
		board
	)

end


--==================================================
-- CONNECT ALL EXISTING PLOTS
--==================================================

local function ConnectAllBoards()

	for _, plot in ipairs(
		Plots:GetChildren()
		) do

		ConnectBoard(
			plot
		)

	end

end


--==================================================
-- NEW PLOT ADDED
--==================================================

Plots.ChildAdded:Connect(
	function(plot)

		-- Wait one frame so descendants have
		-- time to appear.

		task.wait()


		ConnectBoard(
			plot
		)


		UpdateAllBoards()

	end
)


--==================================================
-- PLOT REMOVED
--==================================================

Plots.ChildRemoved:Connect(
	function(plot)

		local board =
			boards[
		plot
		]


		if not board then

			return

		end


		if board.SurfaceGui then

			board.SurfaceGui:Destroy()

		end


		boards[
		plot
		] =
			nil

	end
)


--==================================================
-- START
--==================================================

ConnectAllBoards()


UpdateAllBoards()


--==================================================
-- RETRY MISSING BOARDS
--==================================================

task.spawn(
	function()

		for attempt = 1, 20 do

			for _, plot in ipairs(
				Plots:GetChildren()
				) do

				if not boards[
					plot
					] then

					ConnectBoard(
						plot
					)

				end

			end


			task.wait(
				0.5
			)

		end

	end
)

--==================================================
-- WAIT FOR PLAYER DATA
--==================================================

task.spawn(
	function()

		while not RefreshLuckState() do

			task.wait(
				0.5
			)

		end

	end
)

--==================================================
-- KEEP LUCK BOARD STATE UPDATED
--==================================================

-- Dollars can change from many different systems:
--
-- Pumpkin income
-- Test buttons
-- Purchases
-- Rewards
-- Selling
-- etc.
--
-- The Luck board needs to periodically ask the
-- server for the newest Dollars and Luck state so
-- affordability stays correct.

task.spawn(
	function()

		while true do

			task.wait(
				0.5
			)


			RefreshLuckState()

		end

	end
)
