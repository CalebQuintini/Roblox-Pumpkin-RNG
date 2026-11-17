--==================================================
-- SERVICES
--==================================================

local Players =
	game:GetService("Players")


local ReplicatedStorage =
	game:GetService("ReplicatedStorage")


--==================================================
-- MODULES
--==================================================

local PlayerDataService =
	require(
		script.Parent
		:WaitForChild("PlayerDataService")
	)


local CurrencyService =
	require(
		script.Parent
		:WaitForChild("CurrencyService")
	)


local PlayerFeedbackService =
	require(
		script.Parent
		:WaitForChild("PlayerFeedbackService")
	)


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


local NumberFormatter =
	require(
		ReplicatedStorage
		:WaitForChild("Modules")
		:WaitForChild("NumberFormatter")
	)

local PumpkinStealService =
	require(
		script.Parent
		:WaitForChild("PumpkinStealService")
	)

--==================================================
-- SERVICE
--==================================================

local PumpkinIncomeService = {}


--==================================================
-- SETTINGS
--==================================================

local TICK_RATE =
	GameConfig.Income.TickRate
	or 1


local MAX_UNCOLLECTED_SECONDS =
	GameConfig.Income.MaxUncollectedSeconds
	or (8 * 60 * 60)


local COLLECT_DEBOUNCE =
	GameConfig.Income.CollectDebounce
	or 0.5


--==================================================
-- REGISTERED PUMPKINS
--==================================================

-- [InstanceId] = {
--
--     Player = player,
--     Model = pumpkinModel,
--     Connections = {},
--     Label = TextLabel
--
-- }

local registeredPumpkins =
	{}


--==================================================
-- COLLECTION DEBOUNCE
--==================================================

local collectionDebounces =
	{}


--==================================================
-- FIND SAVED PUMPKIN RECORD
--==================================================

local function FindPlacedRecord(
	data,
	instanceId
)

	if type(data.PlacedPumpkins)
		~= "table" then

		return nil

	end


	for _, record in ipairs(
		data.PlacedPumpkins
		) do

		if record.InstanceId
			== instanceId then

			return record

		end

	end


	return nil

end


--==================================================
-- FIND A PART IN THE MODEL
--==================================================

local function FindAdorneePart(
	model
)

	if model.PrimaryPart then

		return model.PrimaryPart

	end


	for _, descendant in ipairs(
		model:GetDescendants()
		) do

		if descendant:IsA("BasePart") then

			return descendant

		end

	end


	return nil

end


--==================================================
-- MAKE PLACED PUMPKIN NON-COLLIDABLE
--==================================================

local function ConfigurePumpkinParts(
	model
)

	for _, descendant in ipairs(
		model:GetDescendants()
		) do

		if descendant:IsA("BasePart") then

			-- Player can walk through pumpkin.
			descendant.CanCollide =
				false


			-- Touched still needs to work.
			descendant.CanTouch =
				true


			-- Keep raycasting enabled.
			--
			-- Placement/pickup systems use raycasts.
			descendant.CanQuery =
				true

		end

	end

end


--==================================================
-- CREATE MONEY BILLBOARD
--==================================================

local function CreateMoneyDisplay(
	model
)

	local oldGui =
		model:FindFirstChild(
			"IncomeBillboard"
		)


	if oldGui then

		oldGui:Destroy()

	end


	local adornee =
		FindAdorneePart(
			model
		)


	if not adornee then

		return nil

	end


	--==================================================
	-- MODEL BOUNDS
	--==================================================

	local boundingCFrame,
		boundingSize =
		model:GetBoundingBox()


	local topPosition =
		boundingCFrame.Position
		+ (
			boundingCFrame.UpVector
			* (
				boundingSize.Y / 2
				+ 1.5
			)
		)


	local worldOffset =
		topPosition
	- adornee.Position


	--==================================================
	-- BILLBOARD GUI
	--==================================================

	local billboard =
		Instance.new("BillboardGui")


	billboard.Name =
		"IncomeBillboard"


	billboard.Adornee =
		adornee


	-- IMPORTANT:
	--
	-- Offset-only sizing means the billboard uses
	-- a consistent pixel size on the player's screen.
	billboard.Size =
		UDim2.fromOffset(
			150,
			38
		)


	billboard.StudsOffsetWorldSpace =
		worldOffset


	billboard.AlwaysOnTop =
		true


	-- Keep disappearing after this distance.
	billboard.MaxDistance =
		100


	billboard.Parent =
		model


	--==================================================
	-- MONEY TEXT
	--==================================================

	local label =
		Instance.new("TextLabel")


	label.Name =
		"MoneyText"


	label.Size =
		UDim2.fromScale(
			1,
			1
		)


	label.BackgroundTransparency =
		1


	label.Text =
		"$0"


	label.TextColor3 =
		Color3.fromRGB(
			100,
			255,
			60
		)


	label.TextStrokeColor3 =
		Color3.fromRGB(
			0,
			0,
			0
		)


	label.TextStrokeTransparency =
		0


	label.Font =
		Enum.Font.GothamBlack


	label.TextScaled =
		false


	label.TextSize =
		27


	label.TextXAlignment =
		Enum.TextXAlignment.Center


	label.TextYAlignment =
		Enum.TextYAlignment.Center


	label.Parent =
		billboard


	--==================================================
	-- EXTRA BLACK OUTLINE
	--==================================================

	local stroke =
		Instance.new("UIStroke")


	stroke.Thickness =
		2


	stroke.Color =
		Color3.fromRGB(
			0,
			0,
			0
		)


	stroke.Transparency =
		0


	stroke.Parent =
		label


	return label

end


--==================================================
-- UPDATE DISPLAY
--==================================================

local function UpdateDisplay(
	instanceId
)

	local registration = registeredPumpkins[instanceId]


	if not registration then

		return

	end


	local player =
		registration.Player


	local label =
		registration.Label


	if not label
		or not label.Parent then

		return

	end


	local data =
		PlayerDataService.GetData(
			player
		)


	if not data then

		return

	end


	local record =
		FindPlacedRecord(
			data,
			instanceId
		)


	if not record then

		return

	end


	local storedMoney =
		record.StoredMoney
		or 0


	label.Text =
		NumberFormatter.FormatMoneyWithDollar(
			storedMoney
		)

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
-- COLLECT STORED MONEY
--==================================================

function PumpkinIncomeService.Collect(
	player,
	instanceId
)
	
	--==================================================
	-- PUMPKIN CURRENTLY BEING STOLEN
	--==================================================

	if PumpkinStealService.IsPumpkinReserved(
		instanceId
		) then

		return false,
			"PumpkinBeingStolen"

	end

	local registration = registeredPumpkins[instanceId]


	if not registration then

		return false,
			"NotRegistered"

	end


	--==================================================
	-- OWNER ONLY
	--==================================================

	if registration.Player
		~= player then

		return false,
			"NotOwner"

	end


	--==================================================
	-- DEBOUNCE
	--==================================================

	local now =
		os.clock()


	local lastCollection = collectionDebounces[instanceId]
		or 0


	if now - lastCollection
		< COLLECT_DEBOUNCE then

		return false,
			"Debounced"

	end


	collectionDebounces[instanceId] = now


	--==================================================
	-- DATA
	--==================================================

	local data =
		PlayerDataService.GetData(
			player
		)


	if not data then

		return false,
			"DataNotLoaded"

	end


	local record =
		FindPlacedRecord(
			data,
			instanceId
		)


	if not record then

		return false,
			"PlacedRecordMissing"

	end


	local storedMoney =
		record.StoredMoney
		or 0


	if storedMoney <= 0 then

		return false,
			"NoMoney"

	end


	--==================================================
	-- RESET FIRST
	--==================================================

	-- Reset before paying.
	--
	-- This helps protect against duplicate touch
	-- events attempting to collect the same amount.
	record.StoredMoney =
		0


	--==================================================
	-- PAY PLAYER
	--==================================================

	local success =
		CurrencyService.AddDollars(
			player,
			storedMoney
		)


	if not success then

		-- Something failed.
		--
		-- Give the stored value back.
		record.StoredMoney =
			storedMoney


		UpdateDisplay(
			instanceId
		)


		return false,
			"CurrencyUpdateFailed"

	end


	UpdateDisplay(
		instanceId
	)


	--==================================================
	-- MONEY COLLECTION FEEDBACK
	--==================================================

	-- Money was successfully transferred.
	-- Play the collection sound exactly once.

	PlayerFeedbackService.Send(
		player,
		"PumpkinMoneyCollect"
	)


	return true,
		storedMoney

end

--==================================================
-- GET TOTAL STORED MONEY
--==================================================

function PumpkinIncomeService.GetTotalStoredMoney(
	player
)

	if not player then

		return 0

	end


	--==================================================
	-- DATA
	--==================================================

	local data =
		PlayerDataService.GetData(
			player
		)


	if not data then

		return 0

	end


	if type(data.PlacedPumpkins)
		~= "table" then

		return 0

	end


	--==================================================
	-- ADD ALL STORED MONEY
	--==================================================

	local totalStoredMoney =
		0


	for _, record in ipairs(
		data.PlacedPumpkins
		) do

		local storedMoney =
			record.StoredMoney
			or 0


		if type(storedMoney)
			== "number"
			and storedMoney > 0 then

			totalStoredMoney +=
				storedMoney

		end

	end


	return totalStoredMoney

end

--==================================================
-- COLLECT ALL STORED MONEY
--==================================================

function PumpkinIncomeService.CollectAll(
	player
)

	if not player then

		return false,
			0,
			"InvalidPlayer"

	end


	--==================================================
	-- DATA
	--==================================================

	local data =
		PlayerDataService.GetData(
			player
		)


	if not data then

		return false,
			0,
			"DataNotLoaded"

	end


	if type(data.PlacedPumpkins)
		~= "table" then

		return false,
			0,
			"NoPlacedPumpkins"

	end


	--==================================================
	-- CALCULATE TOTAL
	--==================================================

	local totalStoredMoney =
		0


	for _, record in ipairs(
		data.PlacedPumpkins
		) do

		local storedMoney =
			record.StoredMoney
			or 0


		if type(storedMoney)
			== "number"
			and storedMoney > 0 then

			totalStoredMoney +=
				storedMoney

		end

	end


	--==================================================
	-- NOTHING TO COLLECT
	--==================================================

	if totalStoredMoney <= 0 then

		return false,
			0,
			"NoMoney"

	end


	--==================================================
	-- RESET ALL PUMPKINS FIRST
	--==================================================

	-- Save the original values so we can restore
	-- them if CurrencyService fails.

	local originalValues =
		{}


	for _, record in ipairs(
		data.PlacedPumpkins
		) do

		local storedMoney =
			record.StoredMoney
			or 0


		if type(storedMoney)
			~= "number" then

			storedMoney =
				0

		end


		originalValues[record] =
			storedMoney


		record.StoredMoney =
			0

	end


	--==================================================
	-- PAY PLAYER ONCE
	--==================================================

	local success =
		CurrencyService.AddDollars(
			player,
			totalStoredMoney
		)


	--==================================================
	-- PAYMENT FAILED
	--==================================================

	if not success then

		for record, originalAmount in pairs(
			originalValues
			) do

			record.StoredMoney =
				originalAmount

		end


		-- Refresh every visible pumpkin display.

		for instanceId, registration in pairs(
			registeredPumpkins
			) do

			if registration.Player
				== player then

				UpdateDisplay(
					instanceId
				)

			end

		end


		return false,
			0,
			"CurrencyUpdateFailed"

	end


	--==================================================
	-- UPDATE ALL PUMPKIN DISPLAYS
	--==================================================

	for instanceId, registration in pairs(
		registeredPumpkins
		) do

		if registration.Player
			== player then

			UpdateDisplay(
				instanceId
			)

		end

	end


	--==================================================
	-- COLLECTION SOUND
	--==================================================

	-- Play only once even though multiple pumpkins
	-- may have been collected.

	PlayerFeedbackService.Send(
		player,
		"PumpkinMoneyCollect"
	)


	return true,
		totalStoredMoney,
		nil

end

--==================================================
-- COLLECT BEFORE HAMMER PICKUP
--==================================================

function PumpkinIncomeService.CollectBeforePickup(
	player,
	instanceId
)
	
	--==================================================
	-- PUMPKIN CURRENTLY BEING STOLEN
	--==================================================

	if PumpkinStealService.IsPumpkinReserved(
		instanceId
		) then

		return false

	end

	local registration = registeredPumpkins[instanceId]

	if not registration then

		return true

	end


	if registration.Player
		~= player then

		return false

	end


	local data =
		PlayerDataService.GetData(
			player
		)


	if not data then

		return false

	end


	local record =
		FindPlacedRecord(
			data,
			instanceId
		)


	if not record then

		return false

	end


	local storedMoney =
		record.StoredMoney
		or 0


	if storedMoney <= 0 then

		return true

	end


	record.StoredMoney =
		0


	local success =
		CurrencyService.AddDollars(
			player,
			storedMoney
		)


	if not success then

		record.StoredMoney =
			storedMoney


		return false

	end


	--==================================================
	-- MONEY COLLECTION FEEDBACK
	--==================================================

	-- Picking a pumpkin up can automatically collect
	-- money that was still stored inside it.
	--
	-- Play the money collection sound only if there
	-- really was money and the transfer succeeded.

	PlayerFeedbackService.Send(
		player,
		"PumpkinMoneyCollect"
	)


	return true

end


--==================================================
-- REGISTER PUMPKIN
--==================================================

function PumpkinIncomeService.RegisterPumpkin(
	player,
	pumpkinModel
)

	if not player
		or not pumpkinModel then

		return false

	end


	local instanceId =
		pumpkinModel:GetAttribute(
			"InstanceId"
		)


	if type(instanceId)
		~= "string" then

		return false

	end


	--==================================================
	-- ALREADY REGISTERED
	--==================================================

	if registeredPumpkins[
		instanceId
		] then

		return true

	end


	--==================================================
	-- VERIFY DATA
	--==================================================

	local data =
		PlayerDataService.GetData(
			player
		)


	if not data then

		return false

	end


	local record =
		FindPlacedRecord(
			data,
			instanceId
		)


	if not record then

		return false

	end


	-- Old save records won't have this yet.
	if type(record.StoredMoney)
		~= "number" then

		record.StoredMoney =
			0

	end


	--==================================================
	-- PHYSICS
	--==================================================

	ConfigurePumpkinParts(
		pumpkinModel
	)


	--==================================================
	-- BILLBOARD
	--==================================================

	local label =
		CreateMoneyDisplay(
			pumpkinModel
		)


	--==================================================
	-- REGISTRATION
	--==================================================

	local registration = {

		Player =
			player,

		Model =
			pumpkinModel,

		Label =
			label,

		Connections =
			{},
	}


	registeredPumpkins[instanceId] = registration


	--==================================================
	-- TOUCH CONNECTIONS
	--==================================================

	for _, descendant in ipairs(
		pumpkinModel:GetDescendants()
		) do

		if descendant:IsA("BasePart") then

			local connection =
				descendant.Touched:Connect(
					function(hit)

						local touchingPlayer = GetPlayerFromHit(hit)


						if not touchingPlayer then

							return

						end


						-- Only owner can normally collect.
						if touchingPlayer
							~= player then

							return

						end


						PumpkinIncomeService.Collect(
							touchingPlayer,
							instanceId
						)

					end
				)


			table.insert(
				registration.Connections,
				connection
			)

		end

	end


	--==================================================
	-- MODEL REMOVED
	--==================================================

	local ancestryConnection


	ancestryConnection =
		pumpkinModel.AncestryChanged:Connect(
			function(
				_,
				parent
			)

				if parent then

					return

				end


				PumpkinIncomeService
				.UnregisterPumpkin(
					instanceId
				)

			end
		)


	table.insert(
		registration.Connections,
		ancestryConnection
	)


	UpdateDisplay(
		instanceId
	)


	return true

end


--==================================================
-- UNREGISTER PUMPKIN
--==================================================

function PumpkinIncomeService.UnregisterPumpkin(
	instanceId
)

	local registration = registeredPumpkins[instanceId]


	if not registration then

		return

	end


	for _, connection in ipairs(
		registration.Connections
		) do

		connection:Disconnect()

	end


	registeredPumpkins[instanceId] = nil


	collectionDebounces[instanceId] = nil

end


--==================================================
-- INCOME TICK
--==================================================

function PumpkinIncomeService.ProcessIncome(
	elapsedTime
)

	for instanceId,
		registration in pairs(
			registeredPumpkins
		) do

		local player =
			registration.Player


		local model =
			registration.Model


		if not player.Parent
			or not model.Parent then

			PumpkinIncomeService
				.UnregisterPumpkin(
					instanceId
				)


			continue

		end


		local data =
			PlayerDataService.GetData(
				player
			)


		if not data then

			continue

		end


		local record =
			FindPlacedRecord(
				data,
				instanceId
			)


		if not record then

			continue

		end


		local pumpkinInfo =
			PumpkinConfig.GetPumpkin(
				record.PumpkinId
			)


		if not pumpkinInfo then

			continue

		end


		local moneyPerSecond =
			pumpkinInfo.MoneyPerSecond
			or 0


		if moneyPerSecond <= 0 then

			continue

		end


		if type(record.StoredMoney)
			~= "number" then

			record.StoredMoney =
				0

		end


		--==================================================
		-- MAX CAPACITY
		--==================================================

		local maximumStored =
			moneyPerSecond
			* MAX_UNCOLLECTED_SECONDS


		--==================================================
		-- ADD INCOME
		--==================================================

		record.StoredMoney =
			math.min(

				record.StoredMoney
				+ (
					moneyPerSecond
					* elapsedTime
				),

				maximumStored
			)


		UpdateDisplay(
			instanceId
		)

	end

end


return PumpkinIncomeService
