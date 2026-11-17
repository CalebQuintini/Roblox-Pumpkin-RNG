--==================================================
-- SERVICES
--==================================================

local Players =
	game:GetService("Players")


local ReplicatedStorage =
	game:GetService("ReplicatedStorage")


local TweenService =
	game:GetService("TweenService")


local MarketplaceService =
	game:GetService("MarketplaceService")


--==================================================
-- PLAYER
--==================================================

local player =
	Players.LocalPlayer


--==================================================
-- GUI REFERENCES
--==================================================

local gui =
	script.Parent


local offlineFrame =
	gui:WaitForChild(
		"OfflineEarningsFrame"
	)


--==================================================
-- NORMAL CLAIM BUTTON
--==================================================

local claimButton =
	offlineFrame:WaitForChild(
		"ClaimButton"
	)


local normalClaimAmountText =
	claimButton:WaitForChild(
		"ClaimAmountText"
	)


--==================================================
-- X2 CLAIM BUTTON
--==================================================

local claimButtonX2 =
	offlineFrame:WaitForChild(
		"ClaimButtonX2"
	)


local x2ClaimAmountText =
	claimButtonX2:WaitForChild(
		"ClaimAmountText"
	)


--==================================================
-- MODULES
--==================================================

local NumberFormatter =
	require(
		ReplicatedStorage
		:WaitForChild("Modules")
		:WaitForChild("NumberFormatter")
	)


--==================================================
-- REMOTES
--==================================================

local Remotes =
	ReplicatedStorage
	:WaitForChild("Remotes")


local GetOfflineEarnings =
	Remotes:WaitForChild(
		"GetOfflineEarnings"
	)


local ClaimOfflineEarnings =
	Remotes:WaitForChild(
		"ClaimOfflineEarnings"
	)


local OfflineEarningsX2Claimed =
	Remotes:WaitForChild(
		"OfflineEarningsX2Claimed"
	)


--==================================================
-- PRODUCT ID
--==================================================

local X2_OFFLINE_EARNINGS_PRODUCT_ID =
	3718536228


--==================================================
-- SETTINGS
--==================================================

local HOVER_SCALE =
	1.07


local CLICK_SCALE =
	0.93


local HOVER_TIME =
	0.12


local CLICK_TIME =
	0.08


local RETURN_TIME =
	0.11


--==================================================
-- STATE
--==================================================

local claiming =
	false


local waitingForX2Purchase =
	false


local normalAmount =
	0


local x2Amount =
	0


--==================================================
-- BUTTON STATE TABLE
--==================================================

local buttonStates =
	{}


--==================================================
-- CREATE BUTTON STATE
--==================================================

local function CreateButtonState(
	button
)

	local scale =
		button:FindFirstChild(
			"ButtonScale"
		)


	if not scale then

		scale =
			Instance.new(
				"UIScale"
			)


		scale.Name =
			"ButtonScale"


		scale.Scale =
			1


		scale.Parent =
			button

	end


	-- ImageLabels need Active enabled
	-- so they can receive input.

	button.Active =
		true


	local state =
		{
			Button =
			button,

			Scale =
			scale,

			Hovering =
			false,
		}


	buttonStates[button] =
		state


	return state

end


--==================================================
-- CREATE BUTTON STATES
--==================================================

local normalButtonState =
	CreateButtonState(
		claimButton
	)


local x2ButtonState =
	CreateButtonState(
		claimButtonX2
	)


--==================================================
-- TWEEN BUTTON
--==================================================

local function TweenButton(
	state,
	scale,
	duration
)

	local tween =
		TweenService:Create(

			state.Scale,

			TweenInfo.new(
				duration,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			),

			{
				Scale =
				scale,
			}
		)


	tween:Play()


	return tween

end


--==================================================
-- PLAY CLICK ANIMATION
--==================================================

local function PlayClickAnimation(
	state
)

	local shrinkTween =
		TweenButton(
			state,
			CLICK_SCALE,
			CLICK_TIME
		)


	shrinkTween.Completed:Wait()


	local targetScale


	if state.Hovering then

		targetScale =
			HOVER_SCALE

	else

		targetScale =
			1

	end


	TweenButton(
		state,
		targetScale,
		RETURN_TIME
	)

end


--==================================================
-- SETUP BUTTON HOVER
--==================================================

local function SetupButtonHover(
	state
)

	local button =
		state.Button


	button.MouseEnter:Connect(
		function()

			state.Hovering =
				true


			if not claiming
				and not waitingForX2Purchase then

				TweenButton(
					state,
					HOVER_SCALE,
					HOVER_TIME
				)

			end

		end
	)


	button.MouseLeave:Connect(
		function()

			state.Hovering =
				false


			if not claiming
				and not waitingForX2Purchase then

				TweenButton(
					state,
					1,
					HOVER_TIME
				)

			end

		end
	)

end


--==================================================
-- FORMAT MONEY
--==================================================

local function FormatMoney(
	amount
)

	return NumberFormatter
		.FormatMoneyWithDollar(
			amount
		)

end


--==================================================
-- UPDATE CLAIM AMOUNTS
--==================================================

local function UpdateClaimAmounts(
	amount
)

	normalAmount =
		amount


	x2Amount =
		amount * 2


	--==================================================
	-- NORMAL BUTTON
	--==================================================

	normalClaimAmountText.Text =
		FormatMoney(
			normalAmount
		)


	--==================================================
	-- X2 BUTTON
	--==================================================

	x2ClaimAmountText.Text =
		FormatMoney(
			x2Amount
		)


	-- IMPORTANT:
	--
	-- We do NOT change ClaimText on either button.

end


--==================================================
-- SHOW OFFLINE EARNINGS UI
--==================================================

local function ShowOfflineEarnings(
	amount
)

	if type(amount)
		~= "number"
		or amount <= 0 then

		offlineFrame.Visible =
			false


		return

	end


	UpdateClaimAmounts(
		amount
	)


	offlineFrame.Visible =
		true

end


--==================================================
-- HIDE OFFLINE EARNINGS UI
--==================================================

local function HideOfflineEarnings()

	offlineFrame.Visible =
		false

end


--==================================================
-- CLAIM NORMAL OFFLINE EARNINGS
--==================================================

local function ClaimNormal()

	if claiming
		or waitingForX2Purchase then

		return

	end


	if not offlineFrame.Visible then

		return

	end


	claiming =
		true


	--==================================================
	-- CLICK ANIMATION
	--==================================================

	PlayClickAnimation(
		normalButtonState
	)


	--==================================================
	-- ASK SERVER TO CLAIM
	--==================================================

	local invokeSuccess,
		success,
		amount,
		reason =
		pcall(
			function()

				return ClaimOfflineEarnings
				:InvokeServer()

			end
		)


	--==================================================
	-- REMOTE FAILED
	--==================================================

	if not invokeSuccess then

		warn(
			"Could not claim offline earnings."
		)


		claiming =
			false


		return

	end


	--==================================================
	-- CLAIM FAILED
	--==================================================

	if not success then

		warn(
			"Offline earnings claim failed:",
			reason
		)


		claiming =
			false


		return

	end


	--==================================================
	-- SUCCESS
	--==================================================

	-- Server has already:
	--
	-- 1. Added the money
	-- 2. Updated the currency HUD
	-- 3. Played PurchaseSuccess
	--
	-- Now we can close the UI.

	HideOfflineEarnings()


	claiming =
		false

end


--==================================================
-- CLAIM X2 OFFLINE EARNINGS
--==================================================

local function ClaimX2()

	if claiming
		or waitingForX2Purchase then

		return

	end


	if not offlineFrame.Visible then

		return

	end


	waitingForX2Purchase =
		true


	--==================================================
	-- CLICK ANIMATION
	--==================================================

	PlayClickAnimation(
		x2ButtonState
	)


	--==================================================
	-- OPEN ROBUX PURCHASE
	--==================================================

	MarketplaceService:PromptProductPurchase(
		player,
		X2_OFFLINE_EARNINGS_PRODUCT_ID
	)

end


--==================================================
-- X2 EARNINGS SUCCESSFULLY GRANTED
--==================================================

OfflineEarningsX2Claimed.OnClientEvent:Connect(
	function()

		waitingForX2Purchase =
			false


		-- Only close after the SERVER confirms
		-- that x2 earnings were actually granted.

		HideOfflineEarnings()

	end
)


--==================================================
-- ROBUX PURCHASE WINDOW FINISHED
--==================================================

MarketplaceService
	.PromptProductPurchaseFinished
	:Connect(
		function(
			userId,
			productId,
			wasPurchased
		)

			--==================================================
			-- LOCAL PLAYER ONLY
			--==================================================

			if userId
				~= player.UserId then

				return

			end


			--==================================================
			-- X2 OFFLINE PRODUCT ONLY
			--==================================================

			if productId
				~= X2_OFFLINE_EARNINGS_PRODUCT_ID then

				return

			end


			--==================================================
			-- CANCELLED
			--==================================================

			if not wasPurchased then

				waitingForX2Purchase =
				false


				-- Do NOT close the UI.
				--
				-- Player may still choose the
				-- normal claim or try x2 again.

				return

			end


			--==================================================
			-- PURCHASED
			--==================================================

			-- Do nothing here.
			--
			-- The server's ProcessReceipt is responsible
			-- for granting the x2 earnings.
			--
			-- Once successful, the server fires:
			--
			-- OfflineEarningsX2Claimed
			--
			-- which closes this UI.

		end
	)


--==================================================
-- NORMAL BUTTON INPUT
--==================================================

claimButton.InputBegan:Connect(
	function(input)

		if input.UserInputType
			== Enum.UserInputType.MouseButton1
			or input.UserInputType
			== Enum.UserInputType.Touch then

			ClaimNormal()

		end

	end
)


--==================================================
-- X2 BUTTON INPUT
--==================================================

claimButtonX2.InputBegan:Connect(
	function(input)

		if input.UserInputType
			== Enum.UserInputType.MouseButton1
			or input.UserInputType
			== Enum.UserInputType.Touch then

			ClaimX2()

		end

	end
)


--==================================================
-- HOVER SETUP
--==================================================

SetupButtonHover(
	normalButtonState
)


SetupButtonHover(
	x2ButtonState
)


--==================================================
-- INITIAL STATE
--==================================================

offlineFrame.Visible =
	false


--==================================================
-- ASK SERVER FOR OFFLINE EARNINGS
--==================================================

task.spawn(
	function()

		local success,
		amount =
			pcall(
				function()

					return GetOfflineEarnings
					:InvokeServer()

				end
			)


		if not success then

			warn(
				"Could not retrieve offline earnings."
			)


			return

		end


		ShowOfflineEarnings(
			amount
		)

	end
)
