--==================================================
-- SERVICES
--==================================================

local ReplicatedStorage =
	game:GetService("ReplicatedStorage")


local ServerScriptService =
	game:GetService("ServerScriptService")


local HttpService =
	game:GetService("HttpService")

local TutorialService =
	require(
		ServerScriptService
		:WaitForChild("TutorialService")
	)


--==================================================
-- CONFIG
--==================================================

local PumpkinConfig =
	require(
		ReplicatedStorage
		:WaitForChild("Config")
		:WaitForChild("PumpkinConfig")
	)


local RollConfig =
	require(
		ReplicatedStorage
		:WaitForChild("Config")
		:WaitForChild("RollConfig")
	)

local GameAnalyticsService =
	require(
		script.Parent
		:WaitForChild("GameAnalyticsService")
	)


--==================================================
-- SERVER MODULES
--==================================================

local PlayerDataService =
	require(
		ServerScriptService
		:WaitForChild("PlayerDataService")
	)


local CurrencyService =
	require(
		ServerScriptService
		:WaitForChild("CurrencyService")
	)


local PumpkinInventoryService =
	require(
		ServerScriptService
		:WaitForChild("PumpkinInventoryService")
	)


local PumpkinPurseAdapter =
	require(
		ServerScriptService
		:WaitForChild("PumpkinPurseAdapter")
	)


local PlotService =
	require(
		ServerScriptService
		:WaitForChild("PlotService")
	)


local PlayerFeedbackService =
	require(
		ServerScriptService
		:WaitForChild("PlayerFeedbackService")
	)


local PumpkinIndexService =
	require(
		ServerScriptService
		:WaitForChild("PumpkinIndexService")
	)


--==================================================
-- MODULE
--==================================================

local PumpkinRollService = {}


--==================================================
-- MOST ROLLS LEADERBOARD EVENT
--==================================================

local RecordPumpkinRoll =
	ServerScriptService:FindFirstChild(
		"RecordPumpkinRoll"
	)


if not RecordPumpkinRoll then

	RecordPumpkinRoll =
		Instance.new(
			"BindableEvent"
		)


	RecordPumpkinRoll.Name =
		"RecordPumpkinRoll"


	RecordPumpkinRoll.Parent =
		ServerScriptService

end


--==================================================
-- RANDOM
--==================================================

local RNG =
	Random.new()


--==================================================
-- SERVER STATE
--==================================================

-- Stores the player's currently rolled pumpkin offer.
--
-- Example:
--
-- ActiveOffers[player] = {
--     OfferId = "...",
--     PumpkinId = "CarvedPumpkin",
--     PurchasePrice = 300,
--     CreatedAt = 123.45,
--     ReadyAt = 125.75,
-- }

local ActiveOffers =
	{}


-- Prevents the same player from purchasing the
-- same offer multiple times simultaneously.

local PurchaseBusy =
	{}


--==================================================
-- GET FALLBACK PUMPKIN
--==================================================

local function GetFallbackPumpkin()

	local fallbackPumpkin =
		nil


	local fallbackCount =
		0


	for pumpkinId, pumpkinData in pairs(
		PumpkinConfig.Pumpkins
		) do

		if pumpkinData.IsFallback then

			fallbackCount +=
				1


			fallbackPumpkin =
				{
					PumpkinId =
					pumpkinId,

					Data =
					pumpkinData,
				}

		end

	end


	--==================================================
	-- VALIDATE FALLBACK
	--==================================================

	if fallbackCount == 0 then

		error(
			"[PumpkinRollService] No fallback pumpkin exists. Exactly one pumpkin must have IsFallback = true."
		)

	end


	if fallbackCount > 1 then

		error(
			"[PumpkinRollService] Multiple fallback pumpkins found. Exactly one pumpkin must have IsFallback = true."
		)

	end


	return fallbackPumpkin

end


--==================================================
-- GET BASE PROBABILITY
--==================================================

local function GetBaseProbability(
	pumpkinData
)

	local baseOneIn =
		pumpkinData.BaseOneIn


	if type(
		baseOneIn
		) ~= "number" then

		return 0

	end


	if baseOneIn <= 0 then

		return 0

	end


	-- Example:
	--
	-- BaseOneIn = 100
	--
	-- Base probability:
	--
	-- 1 / 100
	-- =
	-- 0.01
	-- =
	-- 1%

	return 1
		/ baseOneIn

end


--==================================================
-- GET LUCK-ADJUSTED PROBABILITY
--==================================================

local function GetLuckAdjustedProbability(
	pumpkinData,
	luckMultiplier
)

	local baseProbability =
		GetBaseProbability(
			pumpkinData
		)


	if baseProbability <= 0 then

		return 0

	end


	--==================================================
	-- NOT AFFECTED BY LUCK
	--==================================================

	if pumpkinData.AffectedByLuck == false then

		return baseProbability

	end


	--==================================================
	-- x1 LUCK
	--==================================================

	-- At exactly x1 Luck the pumpkin keeps its
	-- literal BaseOneIn probability.
	--
	-- Example:
	--
	-- BaseOneIn = 30000
	--
	-- x1 Luck:
	--
	-- exactly 1 / 30000
	--
	-- Luck only begins modifying the probability
	-- above x1.

	if luckMultiplier <= 1 then

		return baseProbability

	end


	--==================================================
	-- BASE ONE-IN
	--==================================================

	local baseOneIn =
		math.max(
			pumpkinData.BaseOneIn
			or 1,
			1
		)


	--==================================================
	-- LUCK SETTINGS
	--==================================================

	-- These values will eventually live inside
	-- RollConfig.
	--
	-- Defaults are provided here so the updated
	-- PumpkinRollService works even before you update
	-- RollConfig.
	--
	-- MinimumLuckPower:
	--
	-- Controls how strongly very common pumpkins
	-- respond to Luck.
	--
	-- MaximumLuckPower:
	--
	-- Controls the strongest possible effect Luck can
	-- have on the rarest pumpkins.
	--
	-- LuckRarityScale:
	--
	-- Controls how quickly pumpkins move from the
	-- minimum Luck effect toward the maximum.

	local minimumLuckPower =
		RollConfig.RNG.MinimumLuckPower
		or 0.35


	local maximumLuckPower =
		RollConfig.RNG.MaximumLuckPower
		or 1.00


	local luckRarityScale =
		RollConfig.RNG.LuckRarityScale
		or 4.5


	--==================================================
	-- VALIDATE SETTINGS
	--==================================================

	minimumLuckPower =
		math.max(
			0,
			minimumLuckPower
		)


	maximumLuckPower =
		math.max(
			minimumLuckPower,
			maximumLuckPower
		)


	luckRarityScale =
		math.max(
			0.001,
			luckRarityScale
		)


	--==================================================
	-- RARITY FACTOR
	--==================================================

	-- Convert BaseOneIn into a number from 0 to 1.
	--
	-- Common pumpkins sit closer to 0.
	--
	-- Rare pumpkins move closer to 1.
	--
	-- Because your current intended upper region is
	-- roughly 1/30K:
	--
	-- log10(30000)
	-- ≈ 4.477
	--
	-- A rarity scale of 4.5 therefore places your
	-- rarest current pumpkins very close to the
	-- maximum Luck benefit.

	local rarityFactor =
		math.log10(
			baseOneIn
		)
		/ luckRarityScale


	rarityFactor =
		math.clamp(
			rarityFactor,
			0,
			1
		)


	--==================================================
	-- LUCK POWER
	--==================================================

	-- Interpolate between the minimum and maximum.
	--
	-- This is the major change from the old system.
	--
	-- OLD:
	--
	-- luckPower =
	--     log10(BaseOneIn)
	--     * LuckRarityStrength
	--
	-- That exponent could continue increasing as
	-- BaseOneIn became larger.
	--
	-- NEW:
	--
	-- luckPower is intentionally bounded between:
	--
	-- 0.35 and 1.00
	--
	-- This means rare pumpkins still benefit more from
	-- Luck, but the effect cannot spiral out of control.

	local luckPower =
		minimumLuckPower
		+ (
			maximumLuckPower
			- minimumLuckPower
		)
		* rarityFactor


	--==================================================
	-- LUCK BONUS
	--==================================================

	local luckBonus =
		luckMultiplier
		^ luckPower


	--==================================================
	-- ADJUST PROBABILITY
	--==================================================

	local adjustedProbability =
		baseProbability
		* luckBonus


	return adjustedProbability

end


--==================================================
-- GET PROBABILITY TABLE
--==================================================

function PumpkinRollService.GetProbabilityTable(
	luckMultiplier
)

	luckMultiplier =
		math.max(
			1,
			luckMultiplier
			or 1
		)


	local fallbackPumpkin =
		GetFallbackPumpkin()


	local entries =
		{}


	local totalExplicitProbability =
		0


	--==================================================
	-- BUILD EXPLICIT NON-FALLBACK ODDS
	--==================================================

	for pumpkinId, pumpkinData in pairs(
		PumpkinConfig.Pumpkins
		) do

		if not pumpkinData.IsFallback then

			local probability =
				GetLuckAdjustedProbability(
					pumpkinData,
					luckMultiplier
				)


			if probability > 0 then

				table.insert(
					entries,
					{
						PumpkinId =
							pumpkinId,

						Data =
							pumpkinData,

						Probability =
							probability,

						IsFallback =
							false,
					}
				)


				totalExplicitProbability +=
					probability

			end

		end

	end


	--==================================================
	-- HIGH-LUCK SAFETY
	--==================================================

	local minimumFallbackChance =
		RollConfig.RNG.MinimumFallbackChance
		or 0.001


	minimumFallbackChance =
		math.clamp(
			minimumFallbackChance,
			0,
			1
		)


	local maximumExplicitChance =
		1
	- minimumFallbackChance


	-- If the combined non-fallback probability becomes
	-- larger than the available probability space,
	-- scale all non-fallback probabilities down
	-- proportionally.
	--
	-- This can happen at very high Luck.
	--
	-- IMPORTANT:
	--
	-- Your BaseOneIn configuration should still be
	-- designed so this does NOT happen at x1 Luck.
	--
	-- If this activates at x1 Luck, the configured
	-- BaseOneIn values are packed too closely together.

	if totalExplicitProbability
		> maximumExplicitChance then

		local scaleFactor =
			maximumExplicitChance
			/ totalExplicitProbability


		totalExplicitProbability =
			0


		for _, entry in ipairs(
			entries
			) do

			entry.Probability *=
				scaleFactor


			totalExplicitProbability +=
				entry.Probability

		end

	end


	--==================================================
	-- FALLBACK PROBABILITY
	--==================================================

	local fallbackProbability =
		1
	- totalExplicitProbability


	fallbackProbability =
		math.max(
			fallbackProbability,
			0
		)


	table.insert(
		entries,
		{
			PumpkinId =
				fallbackPumpkin.PumpkinId,

			Data =
				fallbackPumpkin.Data,

			Probability =
				fallbackProbability,

			IsFallback =
				true,
		}
	)


	--==================================================
	-- SORT TABLE
	--==================================================

	-- Explicit pumpkins are sorted from more common
	-- to rarer using BaseOneIn.
	--
	-- Fallback is placed last.

	table.sort(
		entries,

		function(a, b)

			if a.IsFallback
				and not b.IsFallback then

				return false

			end


			if b.IsFallback
				and not a.IsFallback then

				return true

			end


			local aOneIn =
				a.Data.BaseOneIn
				or math.huge


			local bOneIn =
				b.Data.BaseOneIn
				or math.huge


			return aOneIn
				< bOneIn

		end
	)


	return entries

end


--==================================================
-- GET PROBABILITY TOTAL
--==================================================

function PumpkinRollService.GetProbabilityTotal(
	luckMultiplier
)

	local entries =
		PumpkinRollService.GetProbabilityTable(
			luckMultiplier
		)


	local total =
		0


	for _, entry in ipairs(
		entries
		) do

		total +=
			entry.Probability

	end


	return total

end


--==================================================
-- DEBUG PRINT PROBABILITY TABLE
--==================================================

function PumpkinRollService.PrintProbabilityTable(
	luckMultiplier
)

	local entries =
		PumpkinRollService.GetProbabilityTable(
			luckMultiplier
		)


	print(
		"=================================================="
	)


	print(
		"PUMPKIN ROLL ODDS | Luck:",
		luckMultiplier
	)


	print(
		"=================================================="
	)


	for _, entry in ipairs(
		entries
		) do

		local probability =
			entry.Probability


		local percentage =
			probability
			* 100


		local actualOneIn


		if probability > 0 then

			actualOneIn =
				1
				/ probability

		else

			actualOneIn =
				math.huge

		end


		print(
			entry.PumpkinId,
			"|",
			string.format(
				"%.6f%%",
				percentage
			),
			"| Approx 1 in",
			string.format(
				"%.2f",
				actualOneIn
			),
			"| Display 1 in",
			tostring(
				entry.Data.BaseOneIn
					or 1
			),
			entry.IsFallback
				and "| FALLBACK"
				or ""
		)

	end


	print(
		"TOTAL:",
		PumpkinRollService.GetProbabilityTotal(
			luckMultiplier
		)
	)


	print(
		"=================================================="
	)

end


--==================================================
-- DRAW PUMPKIN
--==================================================

local function DrawPumpkin(
	luckMultiplier
)

	local entries =
		PumpkinRollService.GetProbabilityTable(
			luckMultiplier
		)


	local roll =
		RNG:NextNumber(
			0,
			1
		)


	local cumulative =
		0


	for _, entry in ipairs(
		entries
		) do

		cumulative +=
			entry.Probability


		if roll <= cumulative then

			return entry.PumpkinId,
				entry.Data

		end

	end


	--==================================================
	-- SAFETY FALLBACK
	--==================================================

	-- Floating-point precision should normally never
	-- reach this point, but return the configured
	-- fallback pumpkin just in case.

	local fallback =
		GetFallbackPumpkin()


	return fallback.PumpkinId,
		fallback.Data

end


--==================================================
-- REQUEST ROLL
--==================================================

function PumpkinRollService.RequestRoll(
	player
)

	--==================================================
	-- GET PLAYER DATA
	--==================================================

	local data =
		PlayerDataService.GetData(
			player
		)


	if not data then

		return false,
			"DataNotLoaded"

	end


	--==================================================
	-- TUTORIAL ROLL RULES
	--==================================================

	local tutorialActive =
		TutorialService.IsActive(
			player
		)


	local tutorialStep =
		TutorialService.GetStep(
			player
		)


	-- While the tutorial is active, the player may
	-- only roll during Step 1.
	--
	-- After they roll the tutorial pumpkin, they must
	-- buy it before they are allowed to roll again.

	if tutorialActive
		and tutorialStep
		~= TutorialService.STEP_ROLL then

		TutorialService.ShowCompleteTutorial(
			player
		)


		return false,
			"CompleteTutorial"

	end


	--==================================================
	-- VERIFY PLAYER HAS A PLOT
	--==================================================

	local plot =
		PlotService.GetPlayerPlot(
			player
		)


	if not plot then

		return false,
			"NoPlot"

	end


	--==================================================
	-- CHECK CURRENT OFFER
	--==================================================

	local currentOffer =
		ActiveOffers[player]


	-- If the current roll animation has not finished,
	-- do not allow another roll yet.

	if currentOffer then

		local now =
			os.clock()


		if now
			< currentOffer.ReadyAt then

			return false,
				"RollInProgress"

		end


		--==================================================
		-- REROLL OLD OFFER
		--==================================================

		-- Once the reveal is finished, using the
		-- RollButton again intentionally discards the
		-- previous offer.

		ActiveOffers[player] =
			nil

	end


	--==================================================
	-- GET PLAYER LUCK
	--==================================================

	local luckMultiplier =
		CurrencyService.GetLuckMultiplier(
			data
		)


	--==================================================
	-- SERVER-SIDE RNG / TUTORIAL FORCED PUMPKIN
	--==================================================

	local pumpkinId
	local pumpkinData


	if tutorialActive then

		-- The tutorial always gives the player the
		-- Normal pumpkin on their first roll.

		pumpkinId =
			"NormalPumpkin"


		pumpkinData =
			PumpkinConfig.GetPumpkin(
				"NormalPumpkin"
			)

	else

		pumpkinId,
			pumpkinData =
			DrawPumpkin(
				luckMultiplier
			)

	end


	if not pumpkinId
		or not pumpkinData then

		return false,
			"RollFailed"

	end


	--==================================================
	-- CREATE OFFER
	--==================================================

	local offerId =
		HttpService:GenerateGUID(
			false
		)


	local animationDuration =
		RollConfig.GetAnimationDuration()


	local now =
		os.clock()


	local purchasePrice =
		pumpkinData.PurchasePrice
		or 0


	ActiveOffers[player] =
		{
			OfferId =
			offerId,

			PumpkinId =
			pumpkinId,

			PurchasePrice =
			purchasePrice,

			CreatedAt =
			now,

			ReadyAt =
			now
			+ animationDuration,
		}


	--==================================================
	-- TUTORIAL: ROLL COMPLETE
	--==================================================

	if tutorialActive then

		--==================================================
		-- ANALYTICS - ROLLED FIRST PUMPKIN
		--==================================================

		GameAnalyticsService.LogOnboardingStep(
			player,
			GameAnalyticsService.OnboardingSteps.RolledFirstPumpkin
		)


		--==================================================
		-- ADVANCE TUTORIAL TO BUY
		--==================================================

		TutorialService.AdvanceToBuy(
			player
		)

	end


	--==================================================
	-- COUNT SUCCESSFUL ROLL
	--==================================================

	RecordPumpkinRoll:Fire(
		player
	)


	--==================================================
	-- RETURN DISPLAY DATA
	--==================================================

	return true,
		{
			OfferId =
			offerId,

			PumpkinId =
			pumpkinId,

			DisplayName =
			pumpkinData.DisplayName
			or pumpkinId,

			-- IMPORTANT:
			--
			-- This remains the permanent displayed
			-- BaseOneIn value.
			--
			-- Luck changes the ACTUAL probability,
			-- but does not change this UI number.
			--
			-- For example:
			--
			-- BaseOneIn = 30000
			--
			-- UI:
			-- 1/30K
			--
			-- even when higher Luck has improved the
			-- player's real chance.

			BaseOneIn =
			pumpkinData.BaseOneIn
			or 1,

			PurchasePrice =
			purchasePrice,

			ModelName =
			pumpkinData.ModelName
			or pumpkinId,

			Rarity =
			pumpkinData.Rarity
			or "Common",

			AnimationDuration =
			animationDuration,

			LuckMultiplier =
			luckMultiplier,
		}

end


--==================================================
-- BUY CURRENT OFFER
--==================================================

function PumpkinRollService.BuyOffer(
	player,
	offerId
)

	--==================================================
	-- DOUBLE-PURCHASE GUARD
	--==================================================

	if PurchaseBusy[
		player
		] then

		return false,
			"PurchaseBusy"

	end


	PurchaseBusy[player] =
		true


	--==================================================
	-- FINISH HELPER
	--==================================================

	local function Finish(
		success,
		result
	)

		PurchaseBusy[player] =
			nil


		return success,
			result

	end


	--==================================================
	-- GET ACTIVE OFFER
	--==================================================

	local offer =
		ActiveOffers[player]


	if not offer then

		return Finish(
			false,
			"NoActiveOffer"
		)

	end


	--==================================================
	-- VERIFY OFFER ID
	--==================================================

	if offer.OfferId
		~= offerId then

		return Finish(
			false,
			"InvalidOffer"
		)

	end


	--==================================================
	-- VERIFY REVEAL FINISHED
	--==================================================

	if os.clock()
		< offer.ReadyAt then

		return Finish(
			false,
			"OfferNotReady"
		)

	end


	--==================================================
	-- GET PLAYER DATA
	--==================================================

	local data =
		PlayerDataService.GetData(
			player
		)


	if not data then

		return Finish(
			false,
			"DataNotLoaded"
		)

	end


	--==================================================
	-- TUTORIAL BUY RULES
	--==================================================

	if TutorialService.IsActive(
		player
		) then

		-- The player must currently be on Step 2.

		if not TutorialService.IsStep(
			player,
			TutorialService.STEP_BUY
			) then

			TutorialService.ShowCompleteTutorial(
				player
			)


			return Finish(
				false,
				"CompleteTutorial"
			)

		end


		-- The tutorial offer must be the forced
		-- Normal pumpkin.

		if offer.PumpkinId
			~= "NormalPumpkin" then

			return Finish(
				false,
				"InvalidTutorialPumpkin"
			)

		end

	end


	--==================================================
	-- GET PUMPKIN DATA
	--==================================================

	local pumpkinData =
		PumpkinConfig.GetPumpkin(
			offer.PumpkinId
		)


	if not pumpkinData then

		return Finish(
			false,
			"InvalidPumpkin"
		)

	end


	--==================================================
	-- SERVER-AUTHORITATIVE PRICE
	--==================================================

	local price =
		offer.PurchasePrice
		or pumpkinData.PurchasePrice
		or 0


	--==================================================
	-- CHECK PLAYER MONEY
	--==================================================

	local currentDollars =
		data.Dollars
		or 0


	if currentDollars
		< price then

		--==================================================
		-- PURCHASE DECLINED FEEDBACK
		--==================================================

		PlayerFeedbackService.Send(
			player,
			"PurchaseDeclined"
		)


		return Finish(
			false,
			"NotEnoughDollars"
		)

	end


	--==================================================
	-- CHECK INVENTORY SPACE
	--==================================================

	local hasSpace,
		spaceReason =
		PumpkinInventoryService
		.HasInventorySpace(
			player
		)


	if not hasSpace then

		return Finish(
			false,
			spaceReason
				or "InventoryFull"
		)

	end


	--==================================================
	-- DEDUCT MONEY
	--==================================================

	local newDollars =
		currentDollars
	- price


	local moneySuccess =
		CurrencyService.SetDollars(
			player,
			newDollars
		)


	if not moneySuccess then

		return Finish(
			false,
			"CurrencyUpdateFailed"
		)

	end


	--==================================================
	-- ADD PUMPKIN
	--==================================================

	local addSuccess,
		addResult =
		PumpkinInventoryService
		.AddPumpkin(
			player,
			offer.PumpkinId
		)


	--==================================================
	-- REFUND IF ADD FAILED
	--==================================================

	if not addSuccess then

		CurrencyService.SetDollars(
			player,
			currentDollars
		)


		return Finish(
			false,
			addResult
				or "InventoryAddFailed"
		)

	end


	--==================================================
	-- UPDATE PUMPKIN INDEX
	--==================================================

	local indexSuccess,
		indexReason =
		PumpkinIndexService.Unlock(
			player,
			offer.PumpkinId
		)


	if not indexSuccess then

		warn(
			"[PumpkinRollService] Could not update Pumpkin Index:",
			player.Name,
			offer.PumpkinId,
			indexReason
		)

	end


	--==================================================
	-- REFRESH PURSE INVENTORY
	--==================================================

	PumpkinPurseAdapter.RefreshPlayer(
		player
	)


	--==================================================
	-- CLEAR OFFER
	--==================================================

	ActiveOffers[player] =
		nil


	--==================================================
	-- PURCHASE SUCCESS FEEDBACK
	--==================================================

	PlayerFeedbackService.Send(
		player,
		"PurchaseSuccess"
	)


	--==================================================
	-- TUTORIAL: BUY COMPLETE
	--==================================================

	if TutorialService.IsActive(
		player
		) then

		--==================================================
		-- ANALYTICS - BOUGHT FIRST PUMPKIN
		--==================================================

		GameAnalyticsService.LogOnboardingStep(
			player,
			GameAnalyticsService.OnboardingSteps.BoughtFirstPumpkin
		)


		--==================================================
		-- ADVANCE TUTORIAL TO PLACE
		--==================================================

		TutorialService.AdvanceToPlace(
			player
		)

	end


	--==================================================
	-- GET UNIQUE INSTANCE ID
	--==================================================

	local instanceId =
		nil


	-- AddPumpkin currently returns information about
	-- the newly-created unique pumpkin.
	--
	-- Depending on your InventoryService implementation,
	-- this may either be:
	--
	-- a table containing InstanceId
	--
	-- or the InstanceId itself.

	if type(
		addResult
		) == "table" then

		instanceId =
			addResult.InstanceId

	elseif type(
		addResult
		) == "string" then

		instanceId =
			addResult

	end


	--==================================================
	-- RETURN SUCCESS
	--==================================================

	return Finish(
		true,
		{
			OfferId =
				offer.OfferId,

			PumpkinId =
				offer.PumpkinId,

			DisplayName =
				pumpkinData.DisplayName
				or offer.PumpkinId,

			PurchasePrice =
				price,

			InstanceId =
				instanceId,

			Dollars =
				newDollars,
		}
	)

end


--==================================================
-- GET ACTIVE OFFER
--==================================================

function PumpkinRollService.GetActiveOffer(
	player
)

	return ActiveOffers[player]

end


--==================================================
-- CLEANUP PLAYER
--==================================================

function PumpkinRollService.CleanupPlayer(
	player
)

	ActiveOffers[player] =
		nil


	PurchaseBusy[player] =
		nil

end


return PumpkinRollService
