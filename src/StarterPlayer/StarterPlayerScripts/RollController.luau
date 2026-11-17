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


--==================================================
-- REFERENCES
--==================================================

local Plots =
	workspace:WaitForChild("Plots")


local RollAssets =
	ReplicatedStorage
	:WaitForChild("RollAssets")


local PumpkinModels =
	ReplicatedStorage
	:WaitForChild("PumpkinModels")


local Config =
	ReplicatedStorage
	:WaitForChild("Config")


local Remotes =
	ReplicatedStorage
	:WaitForChild("Remotes")


local PumpkinRollRemotes =
	Remotes
	:WaitForChild("PumpkinRoll")


local RequestRoll =
	PumpkinRollRemotes
	:WaitForChild("RequestRoll")


local BuyOffer =
	PumpkinRollRemotes
	:WaitForChild("BuyOffer")


--==================================================
-- MODULES
--==================================================

local RollConfig =
	require(
		Config:WaitForChild(
			"RollConfig"
		)
	)


local NumberFormatter =
	require(
		ReplicatedStorage
		:WaitForChild("Modules")
		:WaitForChild("NumberFormatter")
	)


--==================================================
-- ASSET REFERENCES
--==================================================

local PlaceholderTemplate =
	RollAssets:WaitForChild(
		"DefaultPumpkinPlaceholder"
	)


--==================================================
-- BUTTON SETTINGS
--==================================================

local BUTTON_DISABLED_COLOR =
	Color3.fromRGB(
		110,
		110,
		110
	)


--==================================================
-- RESULT DISPLAY SETTINGS
--==================================================

local RESULT_DISPLAY_WIDTH =
	260


local RESULT_DISPLAY_HEIGHT =
	120


local RESULT_DISPLAY_OFFSET =
	Vector3.new(
		0,
		4,
		0
	)


--==================================================
-- STATE
--==================================================

local rolling =
	false


local buying =
	false


local currentOffer =
	nil


local currentDisplayModel =
	nil


local currentPlaceholder =
	nil


local currentResultBillboard =
	nil


local currentBuyPrompt =
	nil


local rollSystem =
	nil


local rollPumpkinPosition =
	nil


local rollButton =
	nil


local rollPrompt =
	nil


local redButton =
	nil


local originalRedButtonColor =
	nil


local rollSound =
	nil


local appearSound =
	nil


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
-- FIND ROLL SYSTEM
--==================================================

local function FindRollSystem()

	local plot =
		FindOwnPlot()


	if not plot then

		return nil

	end


	local rollArea =
		plot:FindFirstChild(
			"RollArea"
		)


	if not rollArea then

		return nil

	end


	return rollArea:FindFirstChild(
		"RollSystem"
	)

end


--==================================================
-- GET ROLL POSITION
--==================================================

local function GetRollPositionCFrame()

	if not rollPumpkinPosition then

		return nil

	end


	if rollPumpkinPosition:IsA(
		"BasePart"
		) then

		return rollPumpkinPosition.CFrame

	end


	if rollPumpkinPosition:IsA(
		"Model"
		) then

		return rollPumpkinPosition:GetPivot()

	end


	return nil

end


--==================================================
-- CONFIGURE DISPLAY MODEL
--==================================================

local function ConfigureDisplayModel(
	model
)

	for _, descendant in ipairs(
		model:GetDescendants()
		) do

		if descendant:IsA(
			"BasePart"
			) then

			descendant.Anchored =
				true


			descendant.CanCollide =
				false


			descendant.CanTouch =
				false


			descendant.CanQuery =
				false

		end

	end

end


--==================================================
-- GET A BASEPART FROM MODEL
--==================================================

local function GetModelBasePart(
	model
)

	if model.PrimaryPart then

		return model.PrimaryPart

	end


	return model:FindFirstChildWhichIsA(
		"BasePart",
		true
	)

end


--==================================================
-- CLEAR RESULT BILLBOARD
--==================================================

local function ClearResultBillboard()

	if currentResultBillboard then

		currentResultBillboard:Destroy()


		currentResultBillboard =
			nil

	end

end


--==================================================
-- CLEAR BUY PROMPT
--==================================================

local function ClearBuyPrompt()

	if currentBuyPrompt then

		currentBuyPrompt:Destroy()


		currentBuyPrompt =
			nil

	end

end


--==================================================
-- CLEAR DISPLAY MODEL
--==================================================

local function ClearDisplayModel()

	ClearResultBillboard()

	ClearBuyPrompt()


	if currentDisplayModel then

		currentDisplayModel:Destroy()


		currentDisplayModel =
			nil

	end

end


--==================================================
-- CLEAR PLACEHOLDER
--==================================================

local function ClearPlaceholder()

	if currentPlaceholder then

		currentPlaceholder:Destroy()


		currentPlaceholder =
			nil

	end

end


--==================================================
-- SHOW DEFAULT PLACEHOLDER
--==================================================

local function ShowPlaceholder()

	ClearDisplayModel()

	ClearPlaceholder()


	local rollCFrame =
		GetRollPositionCFrame()


	if not rollCFrame then

		return

	end


	local model =
		PlaceholderTemplate:Clone()


	model.Name =
		"CurrentRollPlaceholder"


	ConfigureDisplayModel(
		model
	)


	model.Parent =
		workspace


	model:PivotTo(
		rollCFrame
	)


	currentPlaceholder =
		model

end


--==================================================
-- GET SILHOUETTES
--==================================================

local function GetSilhouetteModels()

	local silhouettes =
		{}


	for _, object in ipairs(
		RollAssets:GetChildren()
		) do

		if object:IsA("Model")
			and string.match(
				object.Name,
				"^SilhouettePumpkin"
			) then

			table.insert(
				silhouettes,
				object
			)

		end

	end


	table.sort(
		silhouettes,

		function(a, b)

			local aNumber =
				tonumber(
					string.match(
						a.Name,
						"%d+"
					)
				)
				or 0


			local bNumber =
				tonumber(
					string.match(
						b.Name,
						"%d+"
					)
				)
				or 0


			return aNumber
				< bNumber

		end
	)


	return silhouettes

end


--==================================================
-- TWEEN MODEL SCALE
--==================================================

local function TweenModelScale(
	model,
	originalScale,
	startMultiplier,
	endMultiplier,
	duration
)

	local startScale =
		originalScale
		* startMultiplier


	local endScale =
		originalScale
		* endMultiplier


	model:ScaleTo(
		startScale
	)


	local scaleValue =
		Instance.new(
			"NumberValue"
		)


	scaleValue.Value =
		startScale


	local connection =
		scaleValue
		:GetPropertyChangedSignal(
			"Value"
		)
		:Connect(
			function()

				if model.Parent then

					model:ScaleTo(
						scaleValue.Value
					)

				end

			end
		)


	local tween =
		TweenService:Create(

			scaleValue,

			TweenInfo.new(
				duration,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			),

			{
				Value =
				endScale
			}
		)


	tween:Play()


	tween.Completed:Wait()


	connection:Disconnect()


	scaleValue:Destroy()

end


--==================================================
-- PLAY ROLL SOUND
--==================================================

local function PlayRollSound()

	if not rollSound then

		return

	end


	rollSound:Stop()


	rollSound.TimePosition =
		0


	rollSound:Play()

end


--==================================================
-- PLAY APPEAR SOUND
--==================================================

local function PlayAppearSound()

	if not appearSound then

		return

	end


	appearSound:Stop()


	appearSound.TimePosition =
		0


	appearSound:Play()

end


--==================================================
-- PLAY REVEAL PARTICLES
--==================================================

local function PlayRevealParticles()

	local revealAttachment =
		rollPumpkinPosition
		:FindFirstChild(
			"RevealAttachment",
			true
		)


	if not revealAttachment then

		warn(
			"[RollController] RevealAttachment not found."
		)


		return

	end


	for _, descendant in ipairs(
		revealAttachment:GetDescendants()
		) do

		if descendant:IsA(
			"ParticleEmitter"
			) then

			local emitCount =
				descendant:GetAttribute(
					"EmitCount"
				)
				or 20


			descendant:Emit(
				emitCount
			)

		end

	end

end


--==================================================
-- SET ROLL BUTTON ENABLED STATE
--==================================================

local function SetRollButtonEnabled(
	enabled
)

	if rollPrompt then

		rollPrompt.Enabled =
			enabled

	end


	if redButton
		and originalRedButtonColor then

		if enabled then

			redButton.Color =
				originalRedButtonColor

		else

			redButton.Color =
				BUTTON_DISABLED_COLOR

		end

	end

end


--==================================================
-- GET ROLL DELAY
--==================================================

local function GetRollDelay(
	step
)

	return RollConfig.GetStepDelay(
		step
	)

end


--==================================================
-- SHOW SILHOUETTE
--==================================================

local function ShowSilhouette(
	template
)

	ClearDisplayModel()


	local rollCFrame =
		GetRollPositionCFrame()


	if not rollCFrame then

		return

	end


	local model =
		template:Clone()


	model.Name =
		"CurrentRollSilhouette"


	local originalScale =
		model:GetScale()


	ConfigureDisplayModel(
		model
	)


	model.Parent =
		workspace


	model:PivotTo(
		rollCFrame
	)


	currentDisplayModel =
		model


	PlayRollSound()


	local animation =
		RollConfig.Animation


	TweenModelScale(
		model,
		originalScale,
		animation.SilhouetteStartScale,
		animation.SilhouettePopScale,
		animation.SilhouettePopTime
	)


	TweenModelScale(
		model,
		originalScale,
		animation.SilhouettePopScale,
		animation.SilhouetteNormalScale,
		animation.SilhouetteSettleTime
	)

end


--==================================================
-- CREATE RESULT BILLBOARD
--==================================================

local function CreateResultBillboard(
	model,
	offer
)

	ClearResultBillboard()


	--==================================================
	-- FIND PART TO ATTACH DISPLAY TO
	--==================================================

	local adornee =
		GetModelBasePart(
			model
		)


	if not adornee then

		warn(
			"[RollController] Could not find BasePart for result billboard."
		)


		return

	end


	--==================================================
	-- BILLBOARD GUI
	--==================================================

	local billboard =
		Instance.new(
			"BillboardGui"
		)


	billboard.Name =
		"RollResultInfo"


	billboard.Adornee =
		adornee


	-- SCALE ONLY.
	--
	-- This keeps the billboard behaving like
	-- world-space UI instead of staying huge
	-- when the player walks farther away.

	billboard.Size =
		UDim2.fromScale(
			7,
			3
		)


	billboard.StudsOffsetWorldSpace =
		Vector3.new(
			0,
			3.4,
			0
		)


	billboard.AlwaysOnTop =
		true


	billboard.MaxDistance =
		100


	billboard.Parent =
		player:WaitForChild(
			"PlayerGui"
		)


	--==================================================
	-- MAIN CONTAINER
	--==================================================

	local container =
		Instance.new(
			"Frame"
		)


	container.Name =
		"Container"


	container.Size =
		UDim2.fromScale(
			1,
			1
		)


	container.BackgroundTransparency =
		1


	container.Parent =
		billboard


	--==================================================
	-- PUMPKIN NAME
	--==================================================

	local nameLabel =
		Instance.new(
			"TextLabel"
		)


	nameLabel.Name =
		"PumpkinName"


	nameLabel.Position =
		UDim2.fromScale(
			0,
			0
		)


	nameLabel.Size =
		UDim2.fromScale(
			1,
			0.36
		)


	nameLabel.BackgroundTransparency =
		1


	nameLabel.Text =
		offer.DisplayName


	nameLabel.TextColor3 =
		Color3.fromRGB(
			255,
			255,
			255
		)


	nameLabel.TextStrokeColor3 =
		Color3.fromRGB(
			0,
			0,
			0
		)


	nameLabel.TextStrokeTransparency =
		0


	nameLabel.Font =
		Enum.Font.FredokaOne


	nameLabel.TextScaled =
		true


	nameLabel.TextXAlignment =
		Enum.TextXAlignment.Center


	nameLabel.TextYAlignment =
		Enum.TextYAlignment.Center


	nameLabel.Parent =
		container


	--==================================================
	-- NAME STROKE
	--==================================================

	local nameStroke =
		Instance.new(
			"UIStroke"
		)


	nameStroke.Color =
		Color3.fromRGB(
			0,
			0,
			0
		)


	nameStroke.Thickness =
		2


	nameStroke.Transparency =
		0


	nameStroke.Parent =
		nameLabel


	--==================================================
	-- NAME TEXT SIZE LIMIT
	--==================================================

	local nameConstraint =
		Instance.new(
			"UITextSizeConstraint"
		)


	nameConstraint.MinTextSize =
		10


	nameConstraint.MaxTextSize =
		42


	nameConstraint.Parent =
		nameLabel


	--==================================================
	-- ONE IN ??? TEXT
	--==================================================

	local rarityLabel =
		Instance.new(
			"TextLabel"
		)


	rarityLabel.Name =
		"RarityText"


	rarityLabel.Position =
		UDim2.fromScale(
			0,
			0.35
		)


	rarityLabel.Size =
		UDim2.fromScale(
			1,
			0.30
		)


	rarityLabel.BackgroundTransparency =
		1


	rarityLabel.Text =
		"1 in "
		.. tostring(
			offer.BaseOneIn
		)


	rarityLabel.TextColor3 =
		Color3.fromRGB(
			255,
			155,
			35
		)


	rarityLabel.TextStrokeColor3 =
		Color3.fromRGB(
			0,
			0,
			0
		)


	rarityLabel.TextStrokeTransparency =
		0


	rarityLabel.Font =
		Enum.Font.FredokaOne


	rarityLabel.TextScaled =
		true


	rarityLabel.TextXAlignment =
		Enum.TextXAlignment.Center


	rarityLabel.TextYAlignment =
		Enum.TextYAlignment.Center


	rarityLabel.Parent =
		container


	--==================================================
	-- RARITY STROKE
	--==================================================

	local rarityStroke =
		Instance.new(
			"UIStroke"
		)


	rarityStroke.Color =
		Color3.fromRGB(
			0,
			0,
			0
		)


	rarityStroke.Thickness =
		2


	rarityStroke.Transparency =
		0


	rarityStroke.Parent =
		rarityLabel


	--==================================================
	-- RARITY TEXT SIZE LIMIT
	--==================================================

	local rarityConstraint =
		Instance.new(
			"UITextSizeConstraint"
		)


	rarityConstraint.MinTextSize =
		10


	rarityConstraint.MaxTextSize =
		35


	rarityConstraint.Parent =
		rarityLabel


	--==================================================
	-- PRICE BACKGROUND
	--==================================================

	local priceBackground =
		Instance.new(
			"Frame"
		)


	priceBackground.Name =
		"PriceBackground"


	priceBackground.AnchorPoint =
		Vector2.new(
			0.5,
			0
		)


	priceBackground.Position =
		UDim2.fromScale(
			0.5,
			0.66
		)


	priceBackground.Size =
		UDim2.fromScale(
			0.35,
			0.30
		)


	priceBackground.BorderSizePixel =
		0


	priceBackground.BackgroundColor3 =
		Color3.fromRGB(
			0,
			0,
			0
		)


	priceBackground.BackgroundTransparency =
		0


	priceBackground.Parent =
		container


	--==================================================
	-- PRICE BACKGROUND GRADIENT
	--==================================================

	local priceGradient =
		Instance.new(
			"UIGradient"
		)


	priceGradient.Color =
		ColorSequence.new(
			Color3.fromRGB(
				0,
				0,
				0
			)
		)


	priceGradient.Transparency =
		NumberSequence.new(
			{
				NumberSequenceKeypoint.new(
					0,
					1
				),

				NumberSequenceKeypoint.new(
					0.20,
					0.5
				),

				NumberSequenceKeypoint.new(
					0.35,
					0
				),

				NumberSequenceKeypoint.new(
					0.65,
					0
				),

				NumberSequenceKeypoint.new(
					0.80,
					0.5
				),

				NumberSequenceKeypoint.new(
					1,
					1
				),
			}
		)


	priceGradient.Rotation =
		0


	priceGradient.Parent =
		priceBackground


	--==================================================
	-- PRICE TEXT
	--==================================================

	local priceLabel =
		Instance.new(
			"TextLabel"
		)


	priceLabel.Name =
		"PriceText"


	priceLabel.Position =
		UDim2.fromScale(
			0,
			0
		)


	priceLabel.Size =
		UDim2.fromScale(
			1,
			1
		)


	priceLabel.BackgroundTransparency =
		1


	priceLabel.Text =
		NumberFormatter
		.FormatMoneyWithDollar(
			offer.PurchasePrice
		)


	priceLabel.TextColor3 =
		Color3.fromRGB(
			100,
			255,
			60
		)


	priceLabel.TextStrokeColor3 =
		Color3.fromRGB(
			0,
			0,
			0
		)


	priceLabel.TextStrokeTransparency =
		0


	priceLabel.Font =
		Enum.Font.FredokaOne


	priceLabel.TextScaled =
		true


	priceLabel.TextXAlignment =
		Enum.TextXAlignment.Center


	priceLabel.TextYAlignment =
		Enum.TextYAlignment.Center


	priceLabel.Parent =
		priceBackground


	--==================================================
	-- PRICE STROKE
	--==================================================

	local priceStroke =
		Instance.new(
			"UIStroke"
		)


	priceStroke.Color =
		Color3.fromRGB(
			0,
			0,
			0
		)


	priceStroke.Thickness =
		2


	priceStroke.Transparency =
		0


	priceStroke.Parent =
		priceLabel


	--==================================================
	-- PRICE TEXT SIZE LIMIT
	--==================================================

	local priceConstraint =
		Instance.new(
			"UITextSizeConstraint"
		)


	priceConstraint.MinTextSize =
		10


	priceConstraint.MaxTextSize =
		35


	priceConstraint.Parent =
		priceLabel


	--==================================================
	-- MATCH PRICE BACKGROUND WIDTH TO TEXT
	--==================================================

	task.defer(
		function()

			task.wait()


			if not priceLabel.Parent then

				return

			end


			if not container.Parent then

				return

			end


			local containerWidth =
				container.AbsoluteSize.X


			local textWidth =
				priceLabel.TextBounds.X


			if containerWidth <= 0 then

				return

			end


			local widthScale =
				(textWidth / containerWidth)
				* 1.12


			widthScale =
				math.clamp(
					widthScale,
					0.18,
					0.70
				)


			priceBackground.Size =
				UDim2.fromScale(
					widthScale,
					0.30
				)

		end
	)


	currentResultBillboard =
		billboard

end


--==================================================
-- BUY CURRENT OFFER
--==================================================

local function PurchaseCurrentOffer()

	if buying then

		return

	end


	if rolling then

		return

	end


	if not currentOffer then

		return

	end


	buying =
		true


	if currentBuyPrompt then

		currentBuyPrompt.Enabled =
			false

	end


	--==================================================
	-- ASK SERVER TO BUY
	--==================================================

	local callSucceeded,
		purchaseSucceeded,
		result =
		pcall(
			function()

				return BuyOffer:InvokeServer(
					currentOffer.OfferId
				)

			end
		)


	--==================================================
	-- REMOTE ERROR
	--==================================================

	if not callSucceeded then

		warn(
			"[RollController] BuyOffer RemoteFunction failed:",
			purchaseSucceeded
		)


		if currentBuyPrompt then

			currentBuyPrompt.Enabled =
				true

		end


		buying =
			false


		return

	end


	--==================================================
	-- SERVER REJECTED PURCHASE
	--==================================================

	if not purchaseSucceeded then

		warn(
			"[RollController] Purchase failed:",
			result
		)


		if currentBuyPrompt then

			currentBuyPrompt.Enabled =
				true

		end


		buying =
			false


		return

	end


	--==================================================
	-- PURCHASE SUCCESSFUL
	--==================================================

	currentOffer =
		nil


	ClearDisplayModel()


	ShowPlaceholder()


	buying =
		false

end


--==================================================
-- CREATE BUY PROXIMITY PROMPT
--==================================================

local function CreateBuyPrompt(
	model,
	offer
)

	ClearBuyPrompt()


	local promptPart =
		GetModelBasePart(
			model
		)


	if not promptPart then

		warn(
			"[RollController] Result pumpkin has no BasePart for Buy prompt."
		)


		return

	end


	local prompt =
		Instance.new(
			"ProximityPrompt"
		)


	prompt.Name =
		"BuyPrompt"


	prompt.ActionText =
		"Buy"


	prompt.ObjectText =
		offer.DisplayName


	prompt.HoldDuration =
		0.3


	prompt.MaxActivationDistance =
		10


	prompt.RequiresLineOfSight =
		false


	prompt.KeyboardKeyCode =
		Enum.KeyCode.E


	prompt.GamepadKeyCode =
		Enum.KeyCode.ButtonX


	prompt.Parent =
		promptPart


	prompt.Triggered:Connect(
		function()

			PurchaseCurrentOffer()

		end
	)


	currentBuyPrompt =
		prompt

end


--==================================================
-- SHOW FINAL RESULT
--==================================================

local function ShowFinalResult(
	offer
)

	ClearDisplayModel()


	local modelTemplate =
		PumpkinModels:FindFirstChild(
			offer.ModelName
		)


	if not modelTemplate then

		warn(
			"[RollController] Could not find result model:",
			offer.ModelName
		)


		return false

	end


	if not modelTemplate:IsA(
		"Model"
		) then

		warn(
			"[RollController] Result asset is not a Model:",
			offer.ModelName
		)


		return false

	end


	local rollCFrame =
		GetRollPositionCFrame()


	if not rollCFrame then

		return false

	end


	local model =
		modelTemplate:Clone()


	model.Name =
		"CurrentRollResult"


	local originalScale =
		model:GetScale()


	ConfigureDisplayModel(
		model
	)


	model.Parent =
		workspace


	model:PivotTo(
		rollCFrame
	)


	currentDisplayModel =
		model


	--==================================================
	-- SOUND + VFX
	--==================================================

	PlayAppearSound()


	PlayRevealParticles()


	--==================================================
	-- RESULT POP
	--==================================================

	local animation =
		RollConfig.Animation


	TweenModelScale(
		model,
		originalScale,
		animation.ResultStartScale,
		animation.ResultPopScale,
		animation.ResultPopTime
	)


	TweenModelScale(
		model,
		originalScale,
		animation.ResultPopScale,
		animation.ResultNormalScale,
		animation.ResultSettleTime
	)


	--==================================================
	-- DISPLAY RESULT INFO
	--==================================================

	CreateResultBillboard(
		model,
		offer
	)


	--==================================================
	-- CREATE PHYSICAL BUY PROMPT
	--==================================================

	CreateBuyPrompt(
		model,
		offer
	)


	return true

end


--==================================================
-- PLAY ROLL ANIMATION
--==================================================

local function PlayRollAnimation(
	offer
)

	local silhouettes =
		GetSilhouetteModels()


	if #silhouettes == 0 then

		warn(
			"[RollController] No silhouette pumpkins found."
		)


		return false

	end


	local animation =
		RollConfig.Animation


	for step = 1,
		animation.Steps do

		local silhouetteIndex =
			((step - 1)
				% #silhouettes)
			+ 1


		local silhouette = silhouettes[silhouetteIndex]


		ShowSilhouette(
			silhouette
		)


		local delayTime =
			GetRollDelay(
				step
			)


		task.wait(
			delayTime
		)

	end


	return ShowFinalResult(
		offer
	)

end


--==================================================
-- REQUEST NEW ROLL
--==================================================

local function RequestNewRoll()

	if rolling then

		return

	end


	if buying then

		return

	end


	rolling =
		true


	--==================================================
	-- LOCK PHYSICAL BUTTON
	--==================================================

	SetRollButtonEnabled(
		false
	)


	--==================================================
	-- IMPORTANT:
	--
	-- DO NOT CLEAR THE CURRENT VISUAL YET.
	--
	-- Previously the placeholder/result was removed
	-- here before RequestRoll:InvokeServer().
	--
	-- That caused an empty/invisible gap on the first
	-- roll while the client waited for the server.
	--
	-- We now keep the existing visual visible until
	-- the server successfully returns the new offer.
	--==================================================


	--==================================================
	-- REQUEST RESULT FROM SERVER
	--==================================================

	local callSucceeded,
		rollSucceeded,
		result =
		pcall(
			function()

				return RequestRoll:InvokeServer()

			end
		)


	--==================================================
	-- REMOTE FAILED
	--==================================================

	if not callSucceeded then

		warn(
			"[RollController] RequestRoll RemoteFunction failed:",
			rollSucceeded
		)


		-- Keep/reset the placeholder if there is
		-- no existing offer.

		if not currentOffer then

			ShowPlaceholder()

		end


		SetRollButtonEnabled(
			true
		)


		rolling =
			false


		return

	end


	--==================================================
	-- SERVER REJECTED ROLL
	--==================================================

	if not rollSucceeded then

		--==================================================
		-- TUTORIAL: PLAYER MUST FINISH CURRENT STEP
		--==================================================

		-- PumpkinRollService returns "CompleteTutorial"
		-- when the player tries to roll again while they
		-- should be buying or placing.
		--
		-- TutorialService also tells TutorialController
		-- to show CompleteTutorialFrame.
		--
		-- IMPORTANT:
		-- We intentionally DO NOT rebuild the current
		-- pumpkin/placeholder here.
		--
		-- The old visual was never cleared before the
		-- server request, so leaving it alone avoids:
		--
		-- 1. replaying the result pop animation
		-- 2. replaying reveal sound/VFX
		-- 3. recreating the BuyPrompt unnecessarily

		if result
			== "CompleteTutorial" then

			SetRollButtonEnabled(
				true
			)


			rolling =
				false


			return

		end


		--==================================================
		-- OTHER SERVER REJECTIONS
		--==================================================

		warn(
			"[RollController] Roll rejected:",
			result
		)


		if currentOffer then

			-- Restore the previous offer if one
			-- already existed.

			ShowFinalResult(
				currentOffer
			)

		else

			ShowPlaceholder()

		end


		SetRollButtonEnabled(
			true
		)


		rolling =
			false


		return

	end


	--==================================================
	-- SAVE SERVER OFFER
	--==================================================

	currentOffer =
		result


	--==================================================
	-- CLEAR OLD VISUAL
	--==================================================

	-- The server has now successfully returned.
	--
	-- It is safe to remove the placeholder/previous
	-- result because the silhouette sequence is about
	-- to start immediately.

	ClearPlaceholder()

	ClearDisplayModel()


	--==================================================
	-- PLAY VISUAL SEQUENCE
	--==================================================

	local displayed =
		PlayRollAnimation(
			currentOffer
		)


	if not displayed then

		warn(
			"[RollController] Could not display rolled pumpkin."
		)

	end


	--==================================================
	-- ROLL COMPLETE
	--==================================================

	rolling =
		false


	SetRollButtonEnabled(
		true
	)

end


--==================================================
-- INITIALIZE ROLL SYSTEM
--==================================================

local function Initialize()

	-- Plot assignment may happen shortly after
	-- this LocalScript starts.

	while true do

		rollSystem =
			FindRollSystem()


		if rollSystem then

			break

		end


		task.wait(
			0.5
		)

	end


	--==================================================
	-- POSITION
	--==================================================

	rollPumpkinPosition =
		rollSystem:WaitForChild(
			"RollPumpkinPosition"
		)


	--==================================================
	-- ROLL BUTTON
	--==================================================

	rollButton =
		rollSystem:WaitForChild(
			"RollButton"
		)


	rollPrompt =
		rollButton
		:FindFirstChildWhichIsA(
			"ProximityPrompt",
			true
		)


	if not rollPrompt then

		warn(
			"[RollController] RollButton has no ProximityPrompt."
		)


		return

	end


	--==================================================
	-- RED BUTTON
	--==================================================

	redButton =
		rollButton:FindFirstChild(
			"RedButton",
			true
		)


	if redButton
		and redButton:IsA(
			"BasePart"
		) then

		originalRedButtonColor =
			redButton.Color

	else

		warn(
			"[RollController] Could not find BasePart named RedButton."
		)


		redButton =
			nil

	end


	--==================================================
	-- SOUNDS
	--==================================================

	rollSound =
		rollSystem:FindFirstChild(
			"RollSound"
		)


	appearSound =
		rollSystem:FindFirstChild(
			"AppearSound"
		)


	if not rollSound then

		warn(
			"[RollController] RollSound not found."
		)

	end


	if not appearSound then

		warn(
			"[RollController] AppearSound not found."
		)

	end


	--==================================================
	-- INITIAL PLACEHOLDER
	--==================================================

	ShowPlaceholder()


	SetRollButtonEnabled(
		true
	)


	--==================================================
	-- CONNECT ROLL BUTTON
	--==================================================

	rollPrompt.Triggered:Connect(
		function()

			RequestNewRoll()

		end
	)


	print(
		"[RollController] Initialized."
	)

end


--==================================================
-- START
--==================================================

task.spawn(
	Initialize
)
