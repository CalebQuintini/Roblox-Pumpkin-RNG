--==================================================
-- SERVICES
--==================================================

local Players =
	game:GetService("Players")


local MarketplaceService =
	game:GetService("MarketplaceService")


local ReplicatedStorage =
	game:GetService("ReplicatedStorage")


--==================================================
-- MODULES
--==================================================

local AutoCollectService =
	require(
		script.Parent
		:WaitForChild("AutoCollectService")
	)


local NumberFormatter =
	require(
		ReplicatedStorage
		:WaitForChild("Modules")
		:WaitForChild("NumberFormatter")
	)


--==================================================
-- WORLD
--==================================================

local Plots =
	workspace:WaitForChild(
		"Plots"
	)


--==================================================
-- SETTINGS
--==================================================

local DISPLAY_UPDATE_RATE =
	0.25


local TOUCH_DEBOUNCE =
	1


--==================================================
-- RUNTIME
--==================================================

-- [plot] = {
--     GreenCollectPart = BasePart,
--     MoneyDisplayText = TextLabel,
--     DefaultLabels = {TextLabel, TextLabel},
--     Connection = RBXScriptConnection,
-- }

local plotStates =
	{}


-- [player] = os.clock()

local touchDebounces =
	{}


--==================================================
-- FIND PLAYER BY USER ID
--==================================================

-- Manual search also works with Studio test players
-- that may have UserIds such as -1 and -2.

local function FindPlayerByUserId(
	userId
)

	for _, player in ipairs(
		Players:GetPlayers()
		) do

		if player.UserId
			== userId then

			return player

		end

	end


	return nil

end


--==================================================
-- GET PLAYER FROM TOUCHED PART
--==================================================

local function GetPlayerFromHit(
	hit
)

	if not hit then

		return nil

	end


	local character =
		hit:FindFirstAncestorOfClass(
			"Model"
		)


	if not character then

		return nil

	end


	return Players:GetPlayerFromCharacter(
		character
	)

end


--==================================================
-- GET PLOT OWNER
--==================================================

local function GetPlotOwner(
	plot
)

	local ownerUserId =
		plot:GetAttribute(
			"OwnerUserId"
		)


	-- 0 means the plot has no owner.

	if type(ownerUserId)
		~= "number"
		or ownerUserId == 0 then

		return nil

	end


	return FindPlayerByUserId(
		ownerUserId
	)

end


--==================================================
-- SET DEFAULT UI
--==================================================

local function SetDefaultDisplay(
	state
)

	if not state then

		return

	end


	--==================================================
	-- SHOW THE TWO EXISTING TEXTLABELS
	--==================================================

	for _, label in ipairs(
		state.DefaultLabels
		) do

		if label
			and label.Parent then

			label.Visible =
				true

		end

	end


	--==================================================
	-- HIDE MONEY DISPLAY
	--==================================================

	if state.MoneyDisplayText
		and state.MoneyDisplayText.Parent then

		state.MoneyDisplayText.Visible =
			false

	end

end


--==================================================
-- SET OWNED UI
--==================================================

local function SetOwnedDisplay(
	state,
	amount
)

	if not state then

		return

	end


	--==================================================
	-- HIDE THE TWO DEFAULT TEXTLABELS
	--==================================================

	for _, label in ipairs(
		state.DefaultLabels
		) do

		if label
			and label.Parent then

			label.Visible =
				false

		end

	end


	--==================================================
	-- SHOW MONEY DISPLAY
	--==================================================

	if state.MoneyDisplayText
		and state.MoneyDisplayText.Parent then

		state.MoneyDisplayText.Visible =
			true


		state.MoneyDisplayText.Text =
			NumberFormatter
			.FormatMoneyWithDollar(
				amount
			)

	end

end


--==================================================
-- UPDATE ONE PLOT DISPLAY
--==================================================

local function UpdatePlotDisplay(
	plot
)

	local state =
		plotStates[
	plot
	]


	if not state then

		return

	end


	--==================================================
	-- GET OWNER
	--==================================================

	local owner =
		GetPlotOwner(
			plot
		)


	--==================================================
	-- NO OWNER
	--==================================================

	if not owner then

		SetDefaultDisplay(
			state
		)


		return

	end


	--==================================================
	-- DOES OWNER HAVE AUTO COLLECT?
	--==================================================

	local ownsAutoCollect =
		AutoCollectService
		.OwnsAutoCollect(
			owner
		)


	--==================================================
	-- NOT PURCHASED
	--==================================================

	if not ownsAutoCollect then

		SetDefaultDisplay(
			state
		)


		return

	end


	--==================================================
	-- PURCHASED
	--==================================================

	local storedMoney =
		AutoCollectService
		.GetStoredMoney(
			owner
		)


	SetOwnedDisplay(
		state,
		storedMoney
	)

end


--==================================================
-- CAN PROCESS TOUCH?
--==================================================

local function CanProcessTouch(
	player
)

	local now =
		os.clock()


	local lastTouch =
		touchDebounces[
	player
	]
		or 0


	if now - lastTouch
		< TOUCH_DEBOUNCE then

		return false

	end


	touchDebounces[
	player
	] =
		now


	return true

end


--==================================================
-- HANDLE GREEN COLLECT PART TOUCH
--==================================================

local function OnGreenCollectPartTouched(
	plot,
	hit
)

	local player =
		GetPlayerFromHit(
			hit
		)


	if not player then

		return

	end


	--==================================================
	-- OWNER ONLY
	--==================================================

	local owner =
		GetPlotOwner(
			plot
		)


	if not owner then

		return

	end


	if owner ~= player then

		return

	end


	--==================================================
	-- TOUCH DEBOUNCE
	--==================================================

	if not CanProcessTouch(
		player
		) then

		return

	end


	--==================================================
	-- ALREADY OWNS AUTO COLLECT
	--==================================================

	if AutoCollectService
		.OwnsAutoCollect(
			player
		) then

		local success,
			amount,
			reason =
			AutoCollectService.Collect(
				player
			)


		-- No warning is necessary if there simply
		-- wasn't any money waiting.

		if not success
			and reason ~= "NoMoney" then

			warn(
				"[AutoCollectServer] Auto Collect failed:",
				player.Name,
				reason
			)

		end


		-- Update immediately instead of waiting
		-- for the normal display refresh loop.

		UpdatePlotDisplay(
			plot
		)


		return

	end


	--==================================================
	-- DOES NOT OWN AUTO COLLECT
	--==================================================

	-- Walking over the button opens the Developer
	-- Product purchase window.

	MarketplaceService:PromptProductPurchase(
		player,
		AutoCollectService.PRODUCT_ID
	)

end


--==================================================
-- SETUP ONE PLOT
--==================================================

local function SetupPlot(
	plot
)

	if plotStates[
		plot
		] then

		return

	end


	--==================================================
	-- AUTO COLLECT FOLDER
	--==================================================

	local autoCollectFolder =
		plot:FindFirstChild(
			"AutoCollect"
		)


	if not autoCollectFolder then

		warn(
			"[AutoCollectServer] Missing AutoCollect in",
			plot.Name
		)


		return

	end


	--==================================================
	-- AUTO COLLECT BUTTON MODEL
	--==================================================

	local autoCollectButton =
		autoCollectFolder:FindFirstChild(
			"AutoCollectButton"
		)


	if not autoCollectButton then

		warn(
			"[AutoCollectServer] Missing AutoCollectButton in",
			plot.Name
		)


		return

	end


	--==================================================
	-- GREEN COLLECT PART
	--==================================================

	local greenCollectPart =
		autoCollectButton:FindFirstChild(
			"GreenCollectPart",
			true
		)


	if not greenCollectPart
		or not greenCollectPart:IsA(
			"BasePart"
		) then

		warn(
			"[AutoCollectServer] Missing GreenCollectPart in",
			plot.Name
		)


		return

	end


	greenCollectPart.CanTouch =
		true


	--==================================================
	-- BILLBOARD GUI
	--==================================================

	local billboardGui =
		greenCollectPart:FindFirstChild(
			"BillboardGui"
		)


	if not billboardGui then

		warn(
			"[AutoCollectServer] Missing BillboardGui in",
			plot.Name
		)


		return

	end


	--==================================================
	-- FRAME
	--==================================================

	local frame =
		billboardGui:FindFirstChild(
			"Frame"
		)


	if not frame then

		warn(
			"[AutoCollectServer] Missing Frame in BillboardGui for",
			plot.Name
		)


		return

	end


	--==================================================
	-- MONEY DISPLAY TEXT
	--==================================================

	local moneyDisplayText =
		frame:FindFirstChild(
			"MoneyDisplayText"
		)


	if not moneyDisplayText
		or not moneyDisplayText:IsA(
			"TextLabel"
		) then

		warn(
			"[AutoCollectServer] Missing MoneyDisplayText in",
			plot.Name
		)


		return

	end


	--==================================================
	-- FIND THE TWO DEFAULT TEXTLABELS
	--==================================================

	local defaultLabels =
		{}


	for _, child in ipairs(
		frame:GetChildren()
		) do

		if child:IsA(
			"TextLabel"
			)
				and child.Name
				== "TextLabel" then

			table.insert(
				defaultLabels,
				child
			)

		end

	end


	if #defaultLabels < 2 then

		warn(
			"[AutoCollectServer] Expected 2 TextLabels in",
			plot.Name,
			"but found",
			#defaultLabels
		)

	end


	--==================================================
	-- SAVE STATE
	--==================================================

	local state =
		{
			GreenCollectPart =
			greenCollectPart,

			MoneyDisplayText =
			moneyDisplayText,

			DefaultLabels =
			defaultLabels,

			Connection =
			nil,
		}


	plotStates[
	plot
	] =
		state


	--==================================================
	-- TOUCH CONNECTION
	--==================================================

	state.Connection =
		greenCollectPart.Touched:Connect(
			function(hit)

				OnGreenCollectPartTouched(
					plot,
					hit
				)

			end
		)


	--==================================================
	-- OWNER CHANGE
	--==================================================

	plot:GetAttributeChangedSignal(
		"OwnerUserId"
	):Connect(
		function()

			UpdatePlotDisplay(
				plot
			)

		end
	)


	--==================================================
	-- INITIAL DISPLAY
	--==================================================

	UpdatePlotDisplay(
		plot
	)


	print(
		"[AutoCollectServer] Setup",
		plot.Name
	)

end


--==================================================
-- SETUP EXISTING PLOTS
--==================================================

for _, plot in ipairs(
	Plots:GetChildren()
	) do

	SetupPlot(
		plot
	)

end


--==================================================
-- FUTURE PLOTS
--==================================================

Plots.ChildAdded:Connect(
	function(plot)

		task.defer(
			function()

				SetupPlot(
					plot
				)

			end
		)

	end
)


--==================================================
-- UPDATE MONEY DISPLAY
--==================================================

-- StoredMoney is continuously changing while
-- pumpkins produce income.
--
-- This loop updates MoneyDisplayText so the total
-- visibly increases in real time.

task.spawn(
	function()

		while true do

			for plot in pairs(
				plotStates
				) do

				if plot.Parent then

					UpdatePlotDisplay(
						plot
					)

				end

			end


			task.wait(
				DISPLAY_UPDATE_RATE
			)

		end

	end
)


--==================================================
-- PLAYER LEAVE
--==================================================

Players.PlayerRemoving:Connect(
	function(player)

		touchDebounces[
		player
		] = nil

	end
)


print(
	"[AutoCollectServer] Started"
)
