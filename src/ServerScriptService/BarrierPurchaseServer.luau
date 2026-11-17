--==================================================
-- SERVICES
--==================================================

local Players =
	game:GetService(
		"Players"
	)


local MarketplaceService =
	game:GetService(
		"MarketplaceService"
	)


local ReplicatedStorage =
	game:GetService(
		"ReplicatedStorage"
	)


--==================================================
-- MODULES
--==================================================

local BarrierService =
	require(
		script.Parent
		:WaitForChild(
			"BarrierService"
		)
	)


local BarrierPurchaseService =
	require(
		script.Parent
		:WaitForChild(
			"BarrierPurchaseService"
		)
	)


local AutoCollectService =
	require(
		script.Parent
		:WaitForChild(
			"AutoCollectService"
		)
	)


local OfflineEarningsService =
	require(
		script.Parent
		:WaitForChild(
			"OfflineEarningsService"
		)
	)


local PlayerFeedbackService =
	require(
		script.Parent
		:WaitForChild(
			"PlayerFeedbackService"
		)
	)


local ShopPurchaseService =
	require(
		script.Parent
		:WaitForChild(
			"ShopPurchaseService"
		)
	)


local PlayerDataService =
	require(
		script.Parent
		:WaitForChild(
			"PlayerDataService"
		)
	)


--==================================================
-- PRODUCT IDS
--==================================================

-- x2 Offline Earnings

local X2_OFFLINE_EARNINGS_PRODUCT_ID =
	3718536228


--==================================================
-- WORLD
--==================================================

local Plots =
	workspace:WaitForChild(
		"Plots"
	)


--==================================================
-- REMOTES ROOT
--==================================================

local Remotes =
	ReplicatedStorage:FindFirstChild(
		"Remotes"
	)


if not Remotes then

	Remotes =
		Instance.new(
			"Folder"
		)


	Remotes.Name =
		"Remotes"


	Remotes.Parent =
		ReplicatedStorage

end


--==================================================
-- BARRIER REMOTES
--==================================================

local BarrierRemotes =
	Remotes:FindFirstChild(
		"Barrier"
	)


if not BarrierRemotes then

	BarrierRemotes =
		Instance.new(
			"Folder"
		)


	BarrierRemotes.Name =
		"Barrier"


	BarrierRemotes.Parent =
		Remotes

end


--==================================================
-- GET / CREATE REMOTE EVENT
--==================================================

local function GetOrCreateRemoteEvent(
	name
)

	local existing =
		BarrierRemotes:FindFirstChild(
			name
		)


	if existing then

		if existing:IsA(
			"RemoteEvent"
			) then

			return existing

		end


		warn(
			"[BarrierPurchaseServer]",
			name,
			"exists but is not a RemoteEvent."
		)


		return nil

	end


	local remote =
		Instance.new(
			"RemoteEvent"
		)


	remote.Name =
		name


	remote.Parent =
		BarrierRemotes


	return remote

end


--==================================================
-- REMOTE USED HERE
--==================================================

local PromptUnlockBasePurchase =
	GetOrCreateRemoteEvent(
		"PromptUnlockBasePurchase"
	)


--==================================================
-- SETTINGS
--==================================================

local UNLOCK_PROMPT_DISTANCE =
	10


--==================================================
-- PROMPT STORAGE
--==================================================

-- [plot] = {
--     ProximityPrompt,
--     ProximityPrompt,
-- }

local plotUnlockPrompts =
	{}


--==================================================
-- DEBUG
--==================================================

print(
	"[BarrierPurchaseServer] Started"
)


--==================================================
-- UPDATE UNLOCK PROMPTS
--==================================================

local function UpdateUnlockPrompts(
	plot
)

	local prompts = plotUnlockPrompts[plot]


	if not prompts then

		return

	end


	--==================================================
	-- ONLY SHOW WHILE NORMAL LOCKED
	--==================================================

	-- IMPORTANT:
	-- ProximityPrompt.Enabled is replicated globally.
	-- The server decides whether this locked plot's
	-- prompt is enabled at all. A LocalScript named
	-- BarrierPromptController hides the prompt only
	-- from the owner of that plot.
	--
	-- SECURITY:
	-- OnUnlockPromptTriggered below still rejects the
	-- owner server-side. The LocalScript is only for UX.

	local shouldEnable =
		BarrierService.IsNormalLocked(
			plot
		)


	for _, prompt in ipairs(
		prompts
		) do

		if prompt
			and prompt.Parent then

			prompt.Enabled =
				shouldEnable

		end

	end

end


--==================================================
-- HANDLE UNLOCK PROMPT
--==================================================

local function OnUnlockPromptTriggered(
	player,
	plot
)

	if not player
		or not plot then

		return

	end


	--==================================================
	-- BLOCK BASE UNLOCK DURING TUTORIAL
	--==================================================

	-- TutorialServer / TutorialService sets this
	-- Attribute while the player is still completing
	-- the Roll -> Buy -> Place tutorial.
	--
	-- The check is server-side so the player cannot
	-- bypass the restriction and open an Unlock Base
	-- developer-product purchase during the tutorial.

	if player:GetAttribute(
		"TutorialActive"
		) then

		return

	end


	print(
		"[BarrierPurchaseServer]",
		player.Name,
		"triggered Unlock Base on",
		plot.Name
	)


	--==================================================
	-- CANNOT UNLOCK OWN BASE
	--==================================================

	if plot:GetAttribute(
		"OwnerUserId"
		) == player.UserId then

		return

	end


	--==================================================
	-- MUST STILL BE NORMAL LOCKED
	--==================================================

	if not BarrierService.IsNormalLocked(
		plot
		) then

		UpdateUnlockPrompts(
			plot
		)


		return

	end


	--==================================================
	-- REGISTER TARGET
	--==================================================

	local success,
		reason =
		BarrierPurchaseService
		.BeginUnlockPurchase(
			player,
			plot
		)


	print(
		"[BarrierPurchaseServer] BeginUnlockPurchase:",
		success,
		reason
	)


	if not success then

		return

	end


	--==================================================
	-- OPEN PURCHASE PROMPT ON CLIENT
	--==================================================

	if PromptUnlockBasePurchase then

		PromptUnlockBasePurchase
			:FireClient(
				player
			)

	end

end


--==================================================
-- CREATE UNLOCK PROMPT
--==================================================

local function CreateUnlockPrompt(
	plot,
	fencePart
)

	if not fencePart
		or not fencePart:IsA(
			"BasePart"
		) then

		return nil

	end


	--==================================================
	-- REUSE IF ALREADY EXISTS
	--==================================================

	local prompt =
		fencePart:FindFirstChild(
			"UnlockBasePrompt"
		)


	if prompt
		and not prompt:IsA(
			"ProximityPrompt"
		) then

		warn(
			"[BarrierPurchaseServer] UnlockBasePrompt exists but is not a ProximityPrompt:",
			fencePart:GetFullName()
		)


		return nil

	end


	--==================================================
	-- CREATE
	--==================================================

	if not prompt then

		prompt =
			Instance.new(
				"ProximityPrompt"
			)


		prompt.Name =
			"UnlockBasePrompt"


		prompt.Parent =
			fencePart

	end


	--==================================================
	-- SETTINGS
	--==================================================

	prompt.ActionText =
		"Unlock Base"


	prompt.ObjectText =
		"Locked Base"


	prompt.HoldDuration =
		0.5


	prompt.RequiresLineOfSight =
		false


	prompt.MaxActivationDistance =
		UNLOCK_PROMPT_DISTANCE


	prompt.Enabled =
		false


	--==================================================
	-- TRIGGER
	--==================================================

	prompt.Triggered:Connect(
		function(player)

			OnUnlockPromptTriggered(
				player,
				plot
			)

		end
	)


	return prompt

end


--==================================================
-- GET NORMAL BARRIER MODEL
--==================================================

local function GetNormalBarrierModel(
	plot
)

	local normalBarrier =
		plot:FindFirstChild(
			"NormalBarrier"
		)


	if not normalBarrier then

		return nil

	end


	return normalBarrier
		:FindFirstChild(
			"BarrierModel"
		)

end


--==================================================
-- SETUP ONE PLOT
--==================================================

local function SetupPlotUnlockPrompts(
	plot
)

	--==================================================
	-- DON'T SET UP TWICE
	--==================================================

	if plotUnlockPrompts[
		plot
		] then

		return

	end


	print(
		"[BarrierPurchaseServer] Setting up prompts for",
		plot.Name
	)


	--==================================================
	-- MAKE SURE BARRIER STATE EXISTS
	--==================================================

	BarrierService.InitializePlot(
		plot
	)


	--==================================================
	-- NORMAL BARRIER MODEL
	--==================================================

	local barrierModel =
		GetNormalBarrierModel(
			plot
		)


	if not barrierModel then

		warn(
			"[BarrierPurchaseServer] Missing NormalBarrier/BarrierModel in",
			plot.Name
		)


		return

	end


	--==================================================
	-- FIND FRONT/BACK FENCE
	--==================================================

	local frontFence =
		barrierModel:FindFirstChild(
			"FrontFencePart",
			true
		)


	local backFence =
		barrierModel:FindFirstChild(
			"BackFencePart",
			true
		)


	local prompts =
		{}


	--==================================================
	-- FRONT PROMPT
	--==================================================

	if frontFence
		and frontFence:IsA(
			"BasePart"
		) then

		local prompt =
			CreateUnlockPrompt(
				plot,
				frontFence
			)


		if prompt then

			table.insert(
				prompts,
				prompt
			)

		end

	else

		warn(
			"[BarrierPurchaseServer] Missing FrontFencePart in",
			plot.Name
		)

	end


	--==================================================
	-- BACK PROMPT
	--==================================================

	if backFence
		and backFence:IsA(
			"BasePart"
		) then

		local prompt =
			CreateUnlockPrompt(
				plot,
				backFence
			)


		if prompt then

			table.insert(
				prompts,
				prompt
			)

		end

	else

		warn(
			"[BarrierPurchaseServer] Missing BackFencePart in",
			plot.Name
		)

	end


	--==================================================
	-- STORE
	--==================================================

	plotUnlockPrompts[plot] = prompts


	--==================================================
	-- WATCH BARRIER STATE
	--==================================================

	plot:GetAttributeChangedSignal(
		"BarrierState"
	):Connect(
		function()

			UpdateUnlockPrompts(
				plot
			)

		end
	)


	--==================================================
	-- INITIAL UPDATE
	--==================================================

	UpdateUnlockPrompts(
		plot
	)

end


--==================================================
-- RECEIPT PROTECTION
--==================================================

-- Roblox may deliver the same Developer Product
-- receipt more than once.
--
-- ProcessedReceipts is stored inside PlayerData so
-- completed PurchaseIds survive reconnects.
--
-- receiptsBeingProcessed prevents two copies of the
-- same receipt from running at the same time.
--
-- receiptsPendingPersistence handles the case where
-- granting succeeded but the immediate save failed.
-- On the retry we save again WITHOUT granting again.

local receiptsBeingProcessed =
	{}

local receiptsPendingPersistence =
	{}

local function GetProcessedReceipts(player)
	local data = PlayerDataService.GetData(player)
	if not data then
		return nil, nil
	end
	if type(data.ProcessedReceipts) ~= "table" then
		data.ProcessedReceipts = {}
	end
	return data.ProcessedReceipts, data
end

local function IsReceiptProcessed(player, purchaseId)
	local processedReceipts = GetProcessedReceipts(player)
	if not processedReceipts then
		return false
	end
	return processedReceipts[purchaseId] == true
end

--==================================================
-- PROCESS PREMIUM RECEIPT
--==================================================

local function ProcessPremiumReceipt(
	player
)

	local success,
		reason =
		BarrierPurchaseService
		.GrantPremiumBarrier(
			player
		)


	if not success then

		warn(
			"[BarrierPurchaseServer] Failed to grant Premium Barrier:",
			player.Name,
			reason
		)


		return Enum.ProductPurchaseDecision
			.NotProcessedYet

	end


	print(
		"[BarrierPurchaseServer]",
		player.Name,
		"received Premium Barrier"
	)


	return Enum.ProductPurchaseDecision
		.PurchaseGranted

end


--==================================================
-- PROCESS UNLOCK BASE RECEIPT
--==================================================

local function ProcessUnlockReceipt(
	player
)

	--==================================================
	-- GET PENDING TARGET
	--==================================================

	local pending =
		BarrierPurchaseService
		.GetPendingUnlockTarget(
			player
		)


	if not pending then

		warn(
			"[BarrierPurchaseServer] No pending Unlock Base target for",
			player.Name
		)


		return Enum.ProductPurchaseDecision
			.NotProcessedYet

	end


	local targetPlot =
		pending.Plot


	--==================================================
	-- TARGET STILL EXISTS
	--==================================================

	if not targetPlot
		or not targetPlot.Parent then

		warn(
			"[BarrierPurchaseServer] Target plot disappeared for",
			player.Name
		)


		return Enum.ProductPurchaseDecision
			.NotProcessedYet

	end


	--==================================================
	-- NEVER FORCE-UNLOCK PREMIUM
	--==================================================

	if BarrierService.IsPremiumLocked(
		targetPlot
		) then

		warn(
			"[BarrierPurchaseServer] Tried to Unlock Base against Premium Barrier:",
			targetPlot.Name
		)


		return Enum.ProductPurchaseDecision
			.NotProcessedYet

	end


	--==================================================
	-- MUST STILL BE NORMAL LOCKED
	--==================================================

	if not BarrierService.IsNormalLocked(
		targetPlot
		) then

		warn(
			"[BarrierPurchaseServer] Target is no longer Normal locked:",
			targetPlot.Name
		)


		return Enum.ProductPurchaseDecision
			.NotProcessedYet

	end


	--==================================================
	-- GRANT
	--==================================================

	local success,
		reason =
		BarrierPurchaseService
		.GrantUnlockBase(
			player
		)


	if not success then

		warn(
			"[BarrierPurchaseServer] Failed to grant Unlock Base:",
			player.Name,
			reason
		)


		return Enum.ProductPurchaseDecision
			.NotProcessedYet

	end


	print(
		"[BarrierPurchaseServer]",
		player.Name,
		"successfully unlocked",
		targetPlot.Name
	)


	UpdateUnlockPrompts(
		targetPlot
	)


	return Enum.ProductPurchaseDecision
		.PurchaseGranted

end


--==================================================
-- PROCESS AUTO COLLECT RECEIPT
--==================================================

local function ProcessAutoCollectReceipt(
	player
)

	local success,
		reason =
		AutoCollectService
		.GrantAutoCollect(
			player
		)


	if not success then

		warn(
			"[BarrierPurchaseServer] Failed to grant Auto Collect:",
			player.Name,
			reason
		)


		return Enum.ProductPurchaseDecision
			.NotProcessedYet

	end


	--==================================================
	-- PURCHASE SUCCESS SOUND
	--==================================================

	PlayerFeedbackService.Send(
		player,
		"PurchaseSuccess"
	)


	print(
		"[BarrierPurchaseServer]",
		player.Name,
		"received Auto Collect"
	)


	return Enum.ProductPurchaseDecision
		.PurchaseGranted

end


--==================================================
-- PROCESS X2 OFFLINE EARNINGS
--==================================================

local function ProcessX2OfflineEarningsReceipt(
	player
)

	local success,
		amount,
		reason =
		OfflineEarningsService
		.ClaimX2(
			player
		)


	if not success then

		warn(
			"[BarrierPurchaseServer] Failed to grant x2 Offline Earnings:",
			player.Name,
			reason
		)


		return Enum.ProductPurchaseDecision
			.NotProcessedYet

	end


	PlayerFeedbackService.Send(
		player,
		"PurchaseSuccess"
	)


	print(
		"[BarrierPurchaseServer]",
		player.Name,
		"received x2 Offline Earnings:",
		amount
	)


	return Enum.ProductPurchaseDecision
		.PurchaseGranted

end


--==================================================
-- PROCESS RECEIPT
--==================================================

-- IMPORTANT:
--
-- This should be the ONLY place in the entire game
-- that assigns MarketplaceService.ProcessReceipt.
--
-- Every developer product is routed from here.

MarketplaceService.ProcessReceipt =
	function(receiptInfo)

		local player = Players:GetPlayerByUserId(
			receiptInfo.PlayerId
		)

		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		-- ProcessReceipt can arrive before PlayerData has
		-- finished loading. Wait for a future retry rather
		-- than trying to grant against missing data.
		if not PlayerDataService.GetData(player) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local productId = receiptInfo.ProductId
		local purchaseId = tostring(receiptInfo.PurchaseId or "")

		if purchaseId == "" then
			warn(
				"[BarrierPurchaseServer] Receipt missing PurchaseId:",
				player.Name,
				productId
			)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		print(
			"[BarrierPurchaseServer] Receipt:",
			player.Name,
			productId,
			purchaseId
		)

		-- Reward already succeeded in this server but the
		-- save failed. Retry only the save, never the grant.
		if receiptsPendingPersistence[purchaseId] then
			local saveSuccess = PlayerDataService.SavePlayer(player, false)
			if not saveSuccess then
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end
			receiptsPendingPersistence[purchaseId] = nil
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		-- Already persisted on an earlier delivery.
		if IsReceiptProcessed(player, purchaseId) then
			print(
				"[BarrierPurchaseServer] Receipt already processed:",
				player.Name,
				purchaseId
			)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		if receiptsBeingProcessed[purchaseId] then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		receiptsBeingProcessed[purchaseId] = true

		local callSucceeded, decision = pcall(function()
			local shopDecision = ShopPurchaseService.ProcessReceipt(
				player,
				receiptInfo
			)

			if shopDecision ~= nil then
				return shopDecision
			end

			if productId == AutoCollectService.PRODUCT_ID then
				return ProcessAutoCollectReceipt(player)
			end

			if productId == X2_OFFLINE_EARNINGS_PRODUCT_ID then
				return ProcessX2OfflineEarningsReceipt(player)
			end

			if productId == BarrierPurchaseService.PREMIUM_BARRIER_PRODUCT_ID then
				return ProcessPremiumReceipt(player)
			end

			if productId == BarrierPurchaseService.UNLOCK_BASE_PRODUCT_ID then
				return ProcessUnlockReceipt(player)
			end

			warn(
				"[BarrierPurchaseServer] Unhandled ProductId:",
				productId
			)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end)

		receiptsBeingProcessed[purchaseId] = nil

		if not callSucceeded then
			warn(
				"[BarrierPurchaseServer] Receipt handler error:",
				player.Name,
				productId,
				decision
			)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		if decision ~= Enum.ProductPurchaseDecision.PurchaseGranted then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		-- Grant succeeded. Mark this PurchaseId in the same
		-- PlayerData that now contains the granted reward.
		local processedReceipts = GetProcessedReceipts(player)
		if not processedReceipts then
			receiptsPendingPersistence[purchaseId] = true
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		processedReceipts[purchaseId] = true
		receiptsPendingPersistence[purchaseId] = true

		-- Save reward + PurchaseId before acknowledging the
		-- receipt. If this save fails, the next delivery will
		-- retry this save without granting the reward again.
		local saveSuccess = PlayerDataService.SavePlayer(player, false)
		if not saveSuccess then
			warn(
				"[BarrierPurchaseServer] Reward granted but save failed; waiting for receipt retry:",
				player.Name,
				purchaseId
			)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		receiptsPendingPersistence[purchaseId] = nil
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end


--==================================================
-- SETUP EXISTING PLOTS
--==================================================

for _, plot in ipairs(
	Plots:GetChildren()
	) do

	SetupPlotUnlockPrompts(
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

				SetupPlotUnlockPrompts(
					plot
				)

			end
		)

	end
)


--==================================================
-- PLAYER LEAVE
--==================================================

Players.PlayerRemoving:Connect(
	function(player)

		BarrierPurchaseService
			.CleanupPlayer(
				player
			)

	end
)
