--==================================================
-- SERVICES
--==================================================

local ReplicatedStorage =
	game:GetService(
		"ReplicatedStorage"
	)


--==================================================
-- SERVER MODULES
--==================================================

local PlayerDataService =
	require(
		script.Parent
		:WaitForChild(
			"PlayerDataService"
		)
	)


local CurrencyService =
	require(
		script.Parent
		:WaitForChild(
			"CurrencyService"
		)
	)


local PumpkinInventoryService =
	require(
		script.Parent
		:WaitForChild(
			"PumpkinInventoryService"
		)
	)


local PumpkinPurseAdapter =
	require(
		script.Parent
		:WaitForChild(
			"PumpkinPurseAdapter"
		)
	)


local PlayerFeedbackService =
	require(
		script.Parent
		:WaitForChild(
			"PlayerFeedbackService"
		)
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


--==================================================
-- MODULE
--==================================================

local ShopPurchaseService = {}


--==================================================
-- PRODUCT IDS
--==================================================

ShopPurchaseService.STARTER_PACK_PRODUCT_ID =
	3718958066


ShopPurchaseService.BIG_PACK_PRODUCT_ID =
	3718958031


ShopPurchaseService.MEDIUM_PACK_PRODUCT_ID =
	3718958012


ShopPurchaseService.SMALL_PACK_PRODUCT_ID =
	3718957990


--==================================================
-- CASH REWARDS
--==================================================

local STARTER_PACK_MONEY =
	5000


local BIG_PACK_MONEY =
	180000


local MEDIUM_PACK_MONEY =
	50000


local SMALL_PACK_MONEY =
	5000


--==================================================
-- STARTER PACK PUMPKIN
--==================================================

-- IMPORTANT:
--
-- This must exactly match the PumpkinId key
-- inside PumpkinConfig.

local LEMON_PUMPKIN_ID =
	"LemonPumpkin"


--==================================================
-- REMOTES
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
-- SHOP REMOTE FOLDER
--==================================================

local ShopRemotes =
	Remotes:FindFirstChild(
		"Shop"
	)


if not ShopRemotes then

	ShopRemotes =
		Instance.new(
			"Folder"
		)


	ShopRemotes.Name =
		"Shop"


	ShopRemotes.Parent =
		Remotes

end


--==================================================
-- GET SHOP STATE
--==================================================

local GetShopState =
	ShopRemotes:FindFirstChild(
		"GetShopState"
	)


if not GetShopState then

	GetShopState =
		Instance.new(
			"RemoteFunction"
		)


	GetShopState.Name =
		"GetShopState"


	GetShopState.Parent =
		ShopRemotes

end


--==================================================
-- SHOP STATE UPDATED
--==================================================

local ShopStateUpdated =
	ShopRemotes:FindFirstChild(
		"ShopStateUpdated"
	)


if not ShopStateUpdated then

	ShopStateUpdated =
		Instance.new(
			"RemoteEvent"
		)


	ShopStateUpdated.Name =
		"ShopStateUpdated"


	ShopStateUpdated.Parent =
		ShopRemotes

end


--==================================================
-- GET SHOP STATE
--==================================================

function ShopPurchaseService.GetShopState(
	player
)

	local data =
		PlayerDataService.GetData(
			player
		)


	if not data then

		return {
			StarterPackBought =
				false,
		}

	end


	return {

		StarterPackBought =
			data.StarterPackBought
			== true,
	}

end


GetShopState.OnServerInvoke =
	function(player)

		return ShopPurchaseService
		.GetShopState(
			player
		)

	end


--==================================================
-- SEND SHOP STATE
--==================================================

local function SendShopState(
	player
)

	ShopStateUpdated:FireClient(
		player,
		ShopPurchaseService
			.GetShopState(
				player
			)
	)

end


--==================================================
-- ADD MONEY
--==================================================

local function AddMoney(
	player,
	amount
)

	local data =
		PlayerDataService.GetData(
			player
		)


	if not data then

		return false,
			"DataNotLoaded"

	end


	local currentMoney =
		data.Dollars
		or 0


	local newMoney =
		currentMoney
		+ amount


	local success =
		CurrencyService.SetDollars(
			player,
			newMoney
		)


	if not success then

		return false,
			"CurrencyUpdateFailed"

	end


	return true,
		newMoney

end


--==================================================
-- PURCHASE SUCCESS
--==================================================

local function PlayPurchaseSuccess(
	player
)

	PlayerFeedbackService.Send(
		player,
		"PurchaseSuccess"
	)

end


--==================================================
-- GRANT CASH PACK
--==================================================

local function GrantCashPack(
	player,
	amount
)

	local success,
		result =
		AddMoney(
			player,
			amount
		)


	if not success then

		warn(
			"[ShopPurchaseService] Could not grant cash:",
			player.Name,
			result
		)


		return Enum.ProductPurchaseDecision
			.NotProcessedYet

	end


	PlayPurchaseSuccess(
		player
	)


	print(
		"[ShopPurchaseService]",
		player.Name,
		"received $"
			.. tostring(amount)
	)


	return Enum.ProductPurchaseDecision
		.PurchaseGranted

end


--==================================================
-- GRANT STARTER PACK
--==================================================

local function GrantStarterPack(
	player
)

	local data =
		PlayerDataService.GetData(
			player
		)


	if not data then

		return Enum.ProductPurchaseDecision
			.NotProcessedYet

	end


	--==================================================
	-- ALREADY BOUGHT
	--==================================================

	-- Starter Pack is intentionally one-time.
	--
	-- If Roblox ever retries an already-granted
	-- receipt, do NOT grant everything again.

	if data.StarterPackBought
		== true then

		SendShopState(
			player
		)


		return Enum.ProductPurchaseDecision
			.PurchaseGranted

	end


	--==================================================
	-- VERIFY LEMON PUMPKIN
	--==================================================

	if not PumpkinConfig.GetPumpkin(
		LEMON_PUMPKIN_ID
		) then

		warn(
			"[ShopPurchaseService] Invalid Lemon Pumpkin Id:",
			LEMON_PUMPKIN_ID
		)


		return Enum.ProductPurchaseDecision
			.NotProcessedYet

	end


	--==================================================
	-- CHECK INVENTORY SPACE
	--==================================================

	if not PumpkinInventoryService
		.HasInventorySpace(
			player
		) then

		warn(
			"[ShopPurchaseService]",
			player.Name,
			"bought Starter Pack but inventory is full."
		)


		return Enum.ProductPurchaseDecision
			.NotProcessedYet

	end


	--==================================================
	-- ADD LEMON PUMPKIN
	--==================================================

	local pumpkinSuccess,
		pumpkinResult =
		PumpkinInventoryService
		.AddPumpkin(
			player,
			LEMON_PUMPKIN_ID
		)


	if not pumpkinSuccess then

		warn(
			"[ShopPurchaseService] Could not add Lemon Pumpkin:",
			player.Name,
			pumpkinResult
		)


		return Enum.ProductPurchaseDecision
			.NotProcessedYet

	end


	--==================================================
	-- ADD $5,000
	--==================================================

	local moneySuccess,
		moneyResult =
		AddMoney(
			player,
			STARTER_PACK_MONEY
		)


	if not moneySuccess then

		warn(
			"[ShopPurchaseService] Could not grant Starter Pack money:",
			player.Name,
			moneyResult
		)


		return Enum.ProductPurchaseDecision
			.NotProcessedYet

	end


	--==================================================
	-- UNLOCK LEMON PUMPKIN IN INDEX
	--==================================================

	data.PumpkinIndex =
		data.PumpkinIndex
		or {}


	data.PumpkinIndex[LEMON_PUMPKIN_ID] = true


	--==================================================
	-- MARK STARTER PACK BOUGHT
	--==================================================

	data.StarterPackBought =
		true


	--==================================================
	-- REFRESH INVENTORY UI / PURSE
	--==================================================

	PumpkinPurseAdapter.RefreshPlayer(
		player
	)


	--==================================================
	-- SUCCESS SOUND
	--==================================================

	PlayPurchaseSuccess(
		player
	)


	--==================================================
	-- UPDATE SHOP UI
	--==================================================

	SendShopState(
		player
	)


	print(
		"[ShopPurchaseService]",
		player.Name,
		"received Starter Pack"
	)


	return Enum.ProductPurchaseDecision
		.PurchaseGranted

end


--==================================================
-- PROCESS RECEIPT
--==================================================

function ShopPurchaseService.ProcessReceipt(
	player,
	receiptInfo
)

	local productId =
		receiptInfo.ProductId


	--==================================================
	-- STARTER PACK
	--==================================================

	if productId
		== ShopPurchaseService
		.STARTER_PACK_PRODUCT_ID then

		return GrantStarterPack(
			player
		)

	end


	--==================================================
	-- BIG CASH PACK
	--==================================================

	if productId
		== ShopPurchaseService
		.BIG_PACK_PRODUCT_ID then

		return GrantCashPack(
			player,
			BIG_PACK_MONEY
		)

	end


	--==================================================
	-- MEDIUM CASH PACK
	--==================================================

	if productId
		== ShopPurchaseService
		.MEDIUM_PACK_PRODUCT_ID then

		return GrantCashPack(
			player,
			MEDIUM_PACK_MONEY
		)

	end


	--==================================================
	-- SMALL CASH PACK
	--==================================================

	if productId
		== ShopPurchaseService
		.SMALL_PACK_PRODUCT_ID then

		return GrantCashPack(
			player,
			SMALL_PACK_MONEY
		)

	end


	-- Not one of our Shop products.

	return nil

end


return ShopPurchaseService
