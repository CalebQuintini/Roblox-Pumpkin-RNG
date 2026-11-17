local PlayerDataTemplate = {}


PlayerDataTemplate.DefaultData = {

	DataVersion = 1,

	Dollars = 10,

	LuckLevel = 0,

	Inventory = {},

	PlacedPumpkins = {},

	PumpkinIndex = {},

	Storage = {},

	StorageUpgraded = false,

	PermanentPurchases = {},

	-- Stores Roblox Developer Product PurchaseIds
	-- that have already been successfully granted.
	--
	-- This prevents duplicate receipt delivery
	-- from granting the same purchase twice.
	ProcessedReceipts = {},

	-- Stores information needed to recover an
	-- Unlock Base purchase if the player disconnects
	-- or the server shuts down before the receipt
	-- finishes processing.
	--
	-- Example:
	--
	-- PendingUnlockPurchase = {
	--     TargetOwnerUserId = 123456789
	-- }
	--
	-- When there is no pending purchase,
	-- this remains an empty table.
	PendingUnlockPurchase = {},

	TutorialCompleted = false,

	Hotbar = {},

	LastSeenUnixTime = 0,

	PendingOfflineEarnings = 0,

	PremiumBarrierRemaining = 0,

	AutoCollectOwned = false,

	StarterPackBought = false,

	TutorialStep = 1,
}


return PlayerDataTemplate
