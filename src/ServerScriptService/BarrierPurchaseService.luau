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

local BarrierService =
	require(
		script.Parent
		:WaitForChild("BarrierService")
	)

local PlayerFeedbackService =
	require(
		script.Parent
		:WaitForChild("PlayerFeedbackService")
	)


local PlayerDataService =
	require(
		script.Parent
		:WaitForChild("PlayerDataService")
	)


--==================================================
-- WORLD
--==================================================

local Plots =
	workspace:WaitForChild(
		"Plots"
	)


--==================================================
-- MODULE
--==================================================

local BarrierPurchaseService = {}


--==================================================
-- PRODUCT IDS
--==================================================

-- 10 MIN BASE LOCK

BarrierPurchaseService.PREMIUM_BARRIER_PRODUCT_ID =
	3718428383


-- UNLOCK BASE

BarrierPurchaseService.UNLOCK_BASE_PRODUCT_ID =
	3718428646


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
-- BARRIER REMOTE FOLDER
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
			"[BarrierPurchaseService]",
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
-- REMOTES USED HERE
--==================================================

local ShowPlayerBarrierUnlocked =
	GetOrCreateRemoteEvent(
		"ShowPlayerBarrierUnlocked"
	)


--==================================================
-- PENDING PREMIUM PURCHASES
--==================================================

-- [userId] = true

local pendingPremiumPurchases =
	{}


--==================================================
-- PENDING UNLOCK PURCHASES
--==================================================

-- [buyerUserId] = {
--     Plot = plot,
--     TargetOwnerUserId = number,
-- }

local pendingUnlockPurchases =
	{}


--==================================================
-- FIND PLAYER BY USER ID
--==================================================

-- We manually search Players:GetPlayers()
-- instead of relying on GetPlayerByUserId().
--
-- This also works with Roblox Studio test players,
-- which may have negative UserIds such as:
--
-- Player1 = -1
-- Player2 = -2

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
-- BEGIN PREMIUM PURCHASE
--==================================================

function BarrierPurchaseService.BeginPremiumPurchase(
	player
)

	if not player then

		return false,
			"InvalidPlayer"

	end


	--==================================================
	-- ALREADY PENDING
	--==================================================

	if pendingPremiumPurchases[
		player.UserId
		] then

		return false,
			"PurchaseAlreadyPending"

	end


	--==================================================
	-- GET BARRIER STATE
	--==================================================

	local state =
		BarrierService.GetPlayerState(
			player
		)


	if not state then

		return false,
			"NoPlot"

	end


	--==================================================
	-- FORCED UNLOCK
	--==================================================

	if state.Mode
		== BarrierService.States.ForcedUnlocked then

		return false,
			"ForcedUnlockActive"

	end


	--==================================================
	-- PREMIUM ALREADY ACTIVE
	--==================================================

	if state.Mode
		== BarrierService.States.Premium then

		return false,
			"PremiumAlreadyActive"

	end


	--==================================================
	-- REGISTER
	--==================================================

	pendingPremiumPurchases[player.UserId] =
		true


	return true,
		"PurchaseStarted"

end


--==================================================
-- CANCEL PREMIUM PURCHASE
--==================================================

function BarrierPurchaseService.CancelPremiumPurchase(
	player
)

	if not player then

		return

	end


	pendingPremiumPurchases[player.UserId] =
		nil

end


--==================================================
-- PERSISTENT UNLOCK TARGET HELPERS
--==================================================

-- The runtime pendingUnlockPurchases table is useful
-- while the current server is alive, but it disappears
-- if the player disconnects or the server shuts down.
--
-- To make an Unlock Base receipt recoverable, we also
-- store the target owner's UserId inside PlayerData.
--
-- IMPORTANT:
-- We never save an Instance (such as the Plot itself)
-- into PlayerData. DataStores cannot store Instances.
-- We save only plain values and rebuild the Plot
-- reference from OwnerUserId when needed.

local function GetPlayerData(
	player
)

	if not player then

		return nil

	end


	return PlayerDataService.GetData(
		player
	)

end


local function GetSavedPendingUnlock(
	player
)

	local data =
		GetPlayerData(
			player
		)


	if not data then

		return nil

	end


	local saved =
		data.PendingUnlockPurchase


	if type(saved)
		~= "table" then

		return nil

	end


	local targetOwnerUserId =
		saved.TargetOwnerUserId


	if type(targetOwnerUserId)
		~= "number"
		or targetOwnerUserId == 0 then

		return nil

	end


	return saved

end



local function FindPlotOwnedByUserId(
	userId
)

	if type(userId)
		~= "number"
		or userId == 0 then

		return nil

	end


	for _, plot in ipairs(
		Plots:GetChildren()
		) do

		if plot:GetAttribute(
			"OwnerUserId"
			) == userId then

			return plot

		end

	end


	return nil

end


local function SavePendingUnlock(
	buyer,
	targetPlot,
	targetOwnerUserId
)

	local data =
		GetPlayerData(
			buyer
		)


	if not data then

		return false,
			"DataNotLoaded"

	end


	local previousValue =
		data.PendingUnlockPurchase


	data.PendingUnlockPurchase =
		{
			TargetOwnerUserId =
			targetOwnerUserId,

			-- PlotId is stored only as extra context /
			-- debugging information. Recovery primarily
			-- uses TargetOwnerUserId because plot assignment
			-- can differ in a later server.
			TargetPlotId =
			targetPlot:GetAttribute(
				"PlotId"
			),

			TargetPlotName =
			targetPlot.Name,
		}


	local saveSuccess =
		PlayerDataService.SavePlayer(
			buyer,
			false
		)


	if not saveSuccess then

		data.PendingUnlockPurchase =
			previousValue


		return false,
			"CouldNotSavePendingUnlock"

	end


	return true

end


local function ClearSavedPendingUnlock(
	player,
	saveImmediately
)

	local data =
		GetPlayerData(
			player
		)


	if not data then

		return false

	end


	-- Use an empty table rather than nil so this field
	-- has a stable save format when added to the
	-- PlayerDataTemplate.
	data.PendingUnlockPurchase =
		{}


	if saveImmediately then

		return PlayerDataService.SavePlayer(
			player,
			false
		)

	end


	return true

end


--==================================================
-- BEGIN UNLOCK BASE PURCHASE
--==================================================

function BarrierPurchaseService.BeginUnlockPurchase(
	buyer,
	targetPlot
)

	if not buyer
		or not targetPlot then

		return false,
			"InvalidRequest"

	end


	--==================================================
	-- CANNOT TARGET OWN BASE
	--==================================================

	if targetPlot:GetAttribute(
		"OwnerUserId"
		) == buyer.UserId then

		return false,
			"OwnBase"

	end


	--==================================================
	-- TARGET MUST CURRENTLY HAVE NORMAL BARRIER
	--==================================================

	if not BarrierService.IsNormalLocked(
		targetPlot
		) then

		return false,
			"BaseNotNormalLocked"

	end


	--==================================================
	-- BUYER ALREADY HAS PENDING UNLOCK
	--==================================================

	if pendingUnlockPurchases[
		buyer.UserId
		]
			or GetSavedPendingUnlock(
				buyer
			) then

		return false,
			"PurchaseAlreadyPending"

	end


	--==================================================
	-- TARGET OWNER
	--==================================================

	local targetOwnerUserId =
		targetPlot:GetAttribute(
			"OwnerUserId"
		)


	-- 0 means this plot has no owner.
	--
	-- Negative UserIds are allowed because
	-- Roblox Studio multiplayer test players
	-- can use values such as -1 and -2.

	if type(targetOwnerUserId)
		~= "number"
		or targetOwnerUserId == 0 then

		return false,
			"NoTargetOwner"

	end


	--==================================================
	-- STORE RUNTIME TARGET
	--==================================================

	pendingUnlockPurchases[buyer.UserId] =
		{
			Plot =
			targetPlot,

			TargetOwnerUserId =
			targetOwnerUserId,
		}


	--==================================================
	-- PERSIST TARGET BEFORE ROBUX PROMPT
	--==================================================

	-- This save happens BEFORE BarrierPurchaseServer
	-- opens the Developer Product prompt.
	--
	-- If the server dies after the player buys, the
	-- target owner's UserId is therefore still present
	-- in PlayerData when Roblox retries the receipt.

	local saveSuccess,
		saveReason =
		SavePendingUnlock(
			buyer,
			targetPlot,
			targetOwnerUserId
		)


	if not saveSuccess then

		pendingUnlockPurchases[buyer.UserId] =
			nil


		return false,
			saveReason
			or "CouldNotSavePendingUnlock"

	end


	return true,
		"PurchaseStarted"

end


--==================================================
-- CANCEL UNLOCK PURCHASE
--==================================================

function BarrierPurchaseService.CancelUnlockPurchase(
	player
)

	if not player then

		return false

	end


	pendingUnlockPurchases[player.UserId] =
		nil


	-- The player cancelled / declined before a receipt
	-- needs to be fulfilled, so remove the saved target
	-- immediately as well.

	return ClearSavedPendingUnlock(
		player,
		true
	)

end


--==================================================
-- GET PENDING UNLOCK TARGET
--==================================================

function BarrierPurchaseService.GetPendingUnlockTarget(
	player
)

	if not player then

		return nil

	end


	--==================================================
	-- CURRENT SERVER RUNTIME TARGET
	--==================================================

	local runtimePending =
		pendingUnlockPurchases[player.UserId]


	if runtimePending
		and runtimePending.Plot
		and runtimePending.Plot.Parent then

		return runtimePending

	end


	--==================================================
	-- RECOVER FROM PLAYER DATA
	--==================================================

	local saved =
		GetSavedPendingUnlock(
			player
		)


	if not saved then

		return nil

	end


	local targetOwnerUserId =
		saved.TargetOwnerUserId


	local recoveredPlot =
		FindPlotOwnedByUserId(
			targetOwnerUserId
		)


	local recovered =
		{
			Plot =
			recoveredPlot,

			TargetOwnerUserId =
			targetOwnerUserId,

			RecoveredFromPlayerData =
			true,
		}


	-- Cache it for the rest of this server session.
	-- Plot may be nil if the target owner is not
	-- currently in this server. In that case the
	-- receipt remains NotProcessedYet and can retry.

	pendingUnlockPurchases[player.UserId] =
		recovered


	return recovered

end


--==================================================
-- GRANT PREMIUM BARRIER
--==================================================

function BarrierPurchaseService.GrantPremiumBarrier(
	player
)

	if not player then

		return false,
			"InvalidPlayer"

	end


	--==================================================
	-- CLEAR PENDING FLAG
	--==================================================

	pendingPremiumPurchases[player.UserId] =
		nil


	--==================================================
	-- ACTIVATE PREMIUM
	--==================================================

	local success,
		reason =
		BarrierService.ActivatePremium(
			player
		)


	if not success then

		return false,
			reason

	end


	--==================================================
	-- SUCCESS SOUND
	--==================================================

	PlayerFeedbackService.Send(
		player,
		"BarrierSuccessfullyActivated"
	)


	return true,
		"PremiumGranted"

end


--==================================================
-- GRANT UNLOCK BASE
--==================================================

function BarrierPurchaseService.GrantUnlockBase(
	buyer
)

	if not buyer then

		return false,
			"InvalidBuyer"

	end


	--==================================================
	-- GET / RECOVER PENDING TARGET
	--==================================================

	local pending =
		BarrierPurchaseService
		.GetPendingUnlockTarget(
			buyer
		)


	if not pending then

		return false,
			"NoPendingTarget"

	end


	local targetPlot =
		pending.Plot


	local targetOwnerUserId =
		pending.TargetOwnerUserId


	--==================================================
	-- TARGET OWNER MUST CURRENTLY BE IN THIS SERVER
	--==================================================

	-- If this receipt was recovered after a reconnect
	-- or server restart, the saved target may be valid
	-- but the target owner may not currently be here.
	--
	-- Do NOT acknowledge the receipt in that case.
	-- BarrierPurchaseServer will return NotProcessedYet.

	if not targetPlot
		or not targetPlot.Parent then

		-- Try once more in case the target owner joined
		-- after GetPendingUnlockTarget first recovered it.

		targetPlot =
			FindPlotOwnedByUserId(
				targetOwnerUserId
			)


		if targetPlot then

			pending.Plot =
				targetPlot

		end

	end


	if not targetPlot
		or not targetPlot.Parent then

		return false,
			"TargetOwnerNotInServer"

	end


	--==================================================
	-- SAME OWNER STILL OWNS THE PLOT
	--==================================================

	if targetPlot:GetAttribute(
		"OwnerUserId"
		) ~= targetOwnerUserId then

		return false,
			"TargetOwnerChanged"

	end


	--==================================================
	-- TARGET MUST STILL BE NORMAL LOCKED
	--==================================================

	-- This prevents Premium barriers from
	-- ever being force-unlocked.

	if not BarrierService.IsNormalLocked(
		targetPlot
		) then

		return false,
			"TargetNotNormalLocked"

	end


	--==================================================
	-- FORCE UNLOCK
	--==================================================

	local success,
		reason =
		BarrierService.ForceUnlockNormal(
			targetPlot
		)


	if not success then

		return false,
			reason

	end


	--==================================================
	-- CLEAR PENDING TARGET IN MEMORY
	--==================================================

	pendingUnlockPurchases[buyer.UserId] =
		nil


	-- Clear the saved target in the loaded PlayerData,
	-- but DO NOT perform a separate save here.
	--
	-- The updated BarrierPurchaseServer records the
	-- Roblox PurchaseId and immediately saves the reward
	-- + receipt state together after this function
	-- returns success.

	ClearSavedPendingUnlock(
		buyer,
		false
	)


	--==================================================
	-- FIND BASE OWNER
	--==================================================

	local targetOwner =
		FindPlayerByUserId(
			targetOwnerUserId
		)


	--==================================================
	-- NOTIFY BASE OWNER
	--==================================================

	if targetOwner then

		if ShowPlayerBarrierUnlocked then

			ShowPlayerBarrierUnlocked:FireClient(
				targetOwner,
				20
			)

		end


		PlayerFeedbackService.Send(
			targetOwner,
			"PlayerBaseUnlocked"
		)

	else

		warn(
			"[BarrierPurchaseService] Could not find target owner:",
			targetOwnerUserId
		)

	end


	return true,
		"BaseUnlocked"

end


--==================================================
-- IS PREMIUM PURCHASE PENDING
--==================================================

function BarrierPurchaseService.IsPremiumPurchasePending(
	player
)

	if not player then

		return false

	end


	return pendingPremiumPurchases[player.UserId] == true

end


--==================================================
-- IS UNLOCK PURCHASE PENDING
--==================================================

function BarrierPurchaseService.IsUnlockPurchasePending(
	player
)

	if not player then

		return false

	end


	if pendingUnlockPurchases[
		player.UserId
		] ~= nil then

		return true

	end


	return GetSavedPendingUnlock(
		player
	) ~= nil

end


--==================================================
-- CLEANUP PLAYER
--==================================================

function BarrierPurchaseService.CleanupPlayer(
	player
)

	if not player then

		return

	end


	pendingPremiumPurchases[player.UserId] =
		nil


	-- Only clear the runtime Instance reference.
	--
	-- DO NOT clear PlayerData.PendingUnlockPurchase here.
	-- If the player disconnects after paying but before
	-- Roblox's receipt finishes, that persistent value
	-- is exactly what lets a later server recover the
	-- intended target.

	pendingUnlockPurchases[player.UserId] =
		nil

end


return BarrierPurchaseService
