local GameConfig = {}

--==================================================
-- GRID / PLACEMENT
--==================================================

GameConfig.Grid = {

	-- Size of one placement grid cell in studs
	CellSize = 4,

	-- Rotation amount when rotating a pumpkin
	RotationStep = 90,
}


--==================================================
-- BASE LOCKS
--==================================================

GameConfig.BaseLock = {

	--==================================================
	-- DURATIONS
	--==================================================

	-- Free Normal Barrier duration.
	NormalDuration = 60,


	-- Premium Robux Barrier duration.
	--
	-- 10 minutes = 600 seconds.
	PremiumDuration = 10 * 60,


	-- If another player purchases Unlock Base
	-- against an active Normal Barrier,
	-- the base stays force-unlocked for 20 seconds.
	ForcedUnlockDuration = 20,


	--==================================================
	-- PAID OVERRIDE RULES
	--==================================================

	-- Other players may pay Robux to override
	-- an active Normal Barrier.
	AllowPaidOverrideOnFreeLock = true,


	-- Premium Barrier can NEVER be overridden
	-- through the Unlock Base Developer Product.
	AllowPaidOverrideOnPremiumLock = false,


	--==================================================
	-- ACCESS PERMISSIONS
	--==================================================

	-- The owner can always enter their own base,
	-- even while it is locked.
	OwnerCanAlwaysEnter = true,


	-- Owners may manually allow specific players
	-- in the server to enter while the base is locked.
	AllowPlayerPermissions = true,


	-- We may later add an option that automatically
	-- allows the owner's Roblox friends to enter.
	AllowFriendsOption = true,


	-- Explicitly allowed players can cross the
	-- locked base barrier.
	AllowedPlayersCanEnter = true,
}


--==================================================
-- INVENTORY
--==================================================

GameConfig.Inventory = {

	-- Maximum number of pumpkins a player may
	-- hold in their normal pumpkin inventory.
	MaxPumpkins = nil,
}


--==================================================
-- STORAGE / VAULT
--==================================================

GameConfig.Storage = {

	-- Starting number of rare-pumpkin storage slots.
	DefaultCapacity = 5,


	-- Maximum storage capacity after upgrades.
	MaximumCapacity = 10,


	-- Additional slots purchased through Robux.
	PaidExtraSlots = 5,
}


--==================================================
-- PUMPKIN INCOME
--==================================================

GameConfig.Income = {

	-- How often placed pumpkins accumulate money,
	-- measured in seconds.
	TickRate = 1,


	-- A pumpkin can hold up to 8 hours
	-- worth of uncollected income.
	MaxUncollectedSeconds = 8 * 60 * 60,


	-- Stops Touched from firing collection
	-- repeatedly within a fraction of a second.
	CollectDebounce = 0.5,
}


--==================================================
-- OFFLINE EARNINGS
--==================================================

GameConfig.OfflineEarnings = {

	-- Maximum amount of offline time that earns money.
	--
	-- 8 hours.
	MaxOfflineSeconds = 8 * 60 * 60,
}


--==================================================
-- STEALING
--==================================================

GameConfig.Stealing = {

	-- Master toggle for the stealing system.
	Enabled = true,


	-- How long another player must interact with
	-- a pumpkin before they successfully pick it up
	-- and begin carrying it away.
	InteractionDuration = 3,


	-- Maximum distance in studs from the target
	-- pumpkin when starting the stealing interaction.
	MaxStealDistance = 10,


	-- A player may only carry this many stolen
	-- pumpkins at once.
	MaxCarriedStolenPumpkins = 1,


	-- Locked bases normally block unauthorized players
	-- from physically entering.
	--
	-- Players who have been explicitly allowed into
	-- the base may still steal pumpkins normally.
	AllowStealingFromLockedBase = false,


	--==================================================
	-- FAILED THEFT CONDITIONS
	--==================================================

	-- If the thief/carrier is hit by ANY other player,
	-- the theft is cancelled.
	ReturnPumpkinWhenCarrierHit = true,


	-- The carrier is knocked down when hit while
	-- carrying a stolen pumpkin.
	KnockDownCarrierWhenHit = true,


	-- If the carrier dies before reaching their base,
	-- the pumpkin returns to its original owner.
	ReturnPumpkinOnCarrierDeath = true,


	-- If the carrier leaves, disconnects, or crashes,
	-- the pumpkin returns to its original owner.
	ReturnPumpkinIfCarrierLeaves = true,


	-- If the original owner leaves while their
	-- pumpkin is currently being carried by a thief,
	-- the theft is cancelled.
	--
	-- The pumpkin should be restored to the owner's
	-- saved placed-pumpkin data at its original
	-- coordinates.
	ReturnPumpkinIfOriginalOwnerLeaves = true,


	--==================================================
	-- SUCCESSFUL THEFT
	--==================================================

	-- Ownership does NOT change while the thief
	-- is running away with the pumpkin.
	--
	-- Ownership transfers only when the thief
	-- enters their own plot/base/pumpkin patch.
	TransferOwnershipOnEnteringOwnPlot = true,


	-- Once a theft succeeds, the pumpkin goes into
	-- the thief's pumpkin inventory rather than
	-- being automatically placed on their plot.
	AddStolenPumpkinToInventoryOnSuccess = true,


	--==================================================
	-- ORIGINAL PLACEMENT
	--==================================================

	-- Keep the stolen pumpkin's original grid cells
	-- reserved while the theft is still in progress.
	--
	-- This guarantees the pumpkin can be restored
	-- exactly where it came from if the theft fails.
	ReserveOriginalGridCellsDuringTheft = true,


	-- If the theft fails, restore the pumpkin using
	-- its original GridX, GridZ, and Rotation.
	RestoreOriginalPlacementOnFailedTheft = true,
}


--==================================================
-- RESPAWN
--==================================================

GameConfig.Respawn = {

	-- Character respawn delay in seconds.
	CharacterRespawnTime = 5,
}


return GameConfig
