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


local PlotService =
	require(
		script.Parent
		:WaitForChild("PlotService")
	)


local PumpkinPurseAdapter =
	require(
		script.Parent
		:WaitForChild("PumpkinPurseAdapter")
	)


local PumpkinIncomeService =
	require(
		script.Parent
		:WaitForChild("PumpkinIncomeService")
	)


local PlayerFeedbackService =
	require(
		script.Parent
		:WaitForChild("PlayerFeedbackService")
	)


local GameConfig =
	require(
		ReplicatedStorage
		:WaitForChild("Config")
		:WaitForChild("GameConfig")
	)

local PumpkinStealService =
	require(
		script.Parent
		:WaitForChild("PumpkinStealService")
	)

--==================================================
-- REMOTES
--==================================================

local Remotes =
	ReplicatedStorage
	:WaitForChild("Remotes")


--==================================================
-- PICKUP REQUEST REMOTE
--==================================================

local PickupPumpkinRequest =
	Remotes:FindFirstChild(
		"PickupPumpkinRequest"
	)


if not PickupPumpkinRequest then

	PickupPumpkinRequest =
		Instance.new(
			"RemoteEvent"
		)


	PickupPumpkinRequest.Name =
		"PickupPumpkinRequest"


	PickupPumpkinRequest.Parent =
		Remotes

end


--==================================================
-- PICKUP RESULT REMOTE
--==================================================

local PickupPumpkinResult =
	Remotes:FindFirstChild(
		"PickupPumpkinResult"
	)


if not PickupPumpkinResult then

	PickupPumpkinResult =
		Instance.new(
			"RemoteEvent"
		)


	PickupPumpkinResult.Name =
		"PickupPumpkinResult"


	PickupPumpkinResult.Parent =
		Remotes

end


--==================================================
-- SETTINGS
--==================================================

local REQUEST_COOLDOWN =
	0.12


--==================================================
-- RATE LIMIT STATE
--==================================================

local lastPickupTime =
	{}


--==================================================
-- FIND SAVED PLACED PUMPKIN RECORD
--==================================================

local function FindPlacedRecord(
	data,
	instanceId
)

	if type(
		data.PlacedPumpkins
		) ~= "table" then

		return nil,
			nil

	end


	for index,
		record in ipairs(
			data.PlacedPumpkins
		) do

		if record.InstanceId
			== instanceId then

			return record,
				index

		end

	end


	return nil,
		nil

end


--==================================================
-- FIND PHYSICAL PUMPKIN MODEL
--==================================================

local function FindPhysicalPumpkin(
	placedFolder,
	instanceId
)

	for _, object in ipairs(
		placedFolder:GetChildren()
		) do

		if object:GetAttribute(
			"InstanceId"
			) == instanceId then

			return object

		end

	end


	return nil

end


--==================================================
-- CHECK INVENTORY CAPACITY
--==================================================

local function HasInventorySpace(
	data
)

	if type(
		data.Inventory
		) ~= "table" then

		data.Inventory =
			{}

	end


	local inventoryConfig =
		GameConfig.Inventory


	if not inventoryConfig then

		-- If Inventory config somehow doesn't
		-- exist, don't block pickup.
		return true

	end


	local maxPumpkins =
		inventoryConfig.MaxPumpkins


	if type(
		maxPumpkins
		) ~= "number" then

		return true

	end


	return #data.Inventory
		< maxPumpkins

end


--==================================================
-- SEND FAILURE RESULT
--==================================================

local function SendFailure(
	player,
	reason
)

	PickupPumpkinResult:FireClient(
		player,
		false,
		reason
	)

end


--==================================================
-- HANDLE PICKUP REQUEST
--==================================================

PickupPumpkinRequest.OnServerEvent:Connect(
	function(
		player,
		instanceId
	)

		--==================================================
		-- BASIC TYPE VALIDATION
		--==================================================

		if type(
			instanceId
			) ~= "string" then

			return

		end


		--==================================================
		-- PUMPKIN CURRENTLY BEING STOLEN
		--==================================================

		-- If this specific pumpkin is reserved because
		-- another player is currently stealing it,
		-- the owner cannot pick it up.

		if PumpkinStealService.IsPumpkinReserved(
			instanceId
			) then

			SendFailure(
				player,
				"PumpkinBeingStolen"
			)


			return

		end


		--==================================================
		-- PLAYER CURRENTLY IN STEAL MODE
		--==================================================

		-- A player carrying a stolen pumpkin cannot
		-- enter the normal pickup flow at all.

		if PumpkinStealService.IsStealing(
			player
			) then

			SendFailure(
				player,
				"CurrentlyStealing"
			)


			return

		end


		--==================================================
		-- RATE LIMIT
		--==================================================

		local now =
			os.clock()


		local previousTime =
			lastPickupTime[player]
			or 0


		if now - previousTime
			< REQUEST_COOLDOWN then

			return

		end


		lastPickupTime[player] =
			now


		--==================================================
		-- GET PLAYER DATA
		--==================================================

		local data =
			PlayerDataService.GetData(
				player
			)


		if not data then

			SendFailure(
				player,
				"DataNotLoaded"
			)


			return

		end


		--==================================================
		-- GET PLAYER'S OWN PLOT
		--==================================================

		local plot =
			PlotService.GetPlayerPlot(
				player
			)


		if not plot then

			SendFailure(
				player,
				"NoPlot"
			)


			return

		end


		local placedFolder =
			plot:FindFirstChild(
				"PlacedPumpkins"
			)


		if not placedFolder then

			SendFailure(
				player,
				"NoPlacedPumpkinsFolder"
			)


			return

		end


		--==================================================
		-- FIND SAVED PLACED RECORD
		--==================================================

		local record,
		recordIndex =
			FindPlacedRecord(
				data,
				instanceId
			)


		if not record
			or not recordIndex then

			SendFailure(
				player,
				"PumpkinNotPlaced"
			)


			return

		end


		--==================================================
		-- FIND PHYSICAL MODEL
		--==================================================

		local physicalPumpkin =
			FindPhysicalPumpkin(
				placedFolder,
				instanceId
			)


		if not physicalPumpkin then

			SendFailure(
				player,
				"PhysicalPumpkinMissing"
			)


			return

		end


		--==================================================
		-- VERIFY OWNERSHIP
		--==================================================

		-- Never trust the client.
		--
		-- Even though the client only highlights
		-- the player's own pumpkins, the server
		-- validates ownership again.

		if physicalPumpkin:GetAttribute(
			"OwnerUserId"
			) ~= player.UserId then

			SendFailure(
				player,
				"NotOwner"
			)


			return

		end


		--==================================================
		-- VERIFY INSTANCE ID
		--==================================================

		if record.InstanceId
			~= instanceId then

			SendFailure(
				player,
				"InstanceIdMismatch"
			)


			return

		end


		--==================================================
		-- VERIFY PUMPKIN ID
		--==================================================

		local pumpkinId =
			record.PumpkinId


		if type(
			pumpkinId
			) ~= "string" then

			SendFailure(
				player,
				"InvalidPumpkinId"
			)


			return

		end


		--==================================================
		-- INVENTORY CAPACITY
		--==================================================

		if not HasInventorySpace(
			data
			) then

			SendFailure(
				player,
				"InventoryFull"
			)


			return

		end


		--==================================================
		-- COLLECT STORED MONEY BEFORE PICKUP
		--==================================================

		-- If this pumpkin has accumulated money,
		-- pay that money to the player before
		-- moving the pumpkin back into inventory.
		--
		-- This prevents the player from losing
		-- stored earnings when using the Hammer.

		local collectedSuccessfully =
			PumpkinIncomeService
			.CollectBeforePickup(
				player,
				instanceId
			)


		if not collectedSuccessfully then

			SendFailure(
				player,
				"CouldNotCollectStoredMoney"
			)


			return

		end


		--==================================================
		-- SAVE ORIGINAL INSTANCE INFORMATION
		--==================================================

		local originalInstanceId =
			record.InstanceId


		local originalPumpkinId =
			record.PumpkinId


		--==================================================
		-- REMOVE FROM PLACED PUMPKINS
		--==================================================

		-- Once this record is removed:
		--
		-- 1. it is no longer considered placed
		-- 2. it no longer generates pumpkin income
		-- 3. its grid cells become free

		table.remove(
			data.PlacedPumpkins,
			recordIndex
		)


		--==================================================
		-- RETURN SAME PUMPKIN INSTANCE TO INVENTORY
		--==================================================

		-- IMPORTANT:
		--
		-- We DO NOT GenerateGUID here.
		--
		-- The exact same pumpkin instance goes
		-- back into the player's inventory.

		table.insert(
			data.Inventory,
			{
				InstanceId =
					originalInstanceId,

				PumpkinId =
					originalPumpkinId,
			}
		)


		--==================================================
		-- REMOVE PHYSICAL MODEL
		--==================================================

		-- Destroying this model causes the
		-- PumpkinIncomeService registration to
		-- clean itself up through AncestryChanged.
		--
		-- It also immediately removes the pumpkin
		-- from the plot visually.

		physicalPumpkin:Destroy()


		--==================================================
		-- REFRESH PURSE
		--==================================================

		-- The player's pumpkin stack count may
		-- increase here, so refresh Purse.

		PumpkinPurseAdapter.RefreshPlayer(
			player
		)


		--==================================================
		-- PICKUP SOUND
		--==================================================

		PlayerFeedbackService.Send(
			player,
			"PumpkinPlacePickup"
		)


		--==================================================
		-- SUCCESS RESULT
		--==================================================

		PickupPumpkinResult:FireClient(
			player,
			true,
			originalInstanceId
		)


		--==================================================
		-- DEBUG
		--==================================================

		print(
			player.Name,
			"picked up pumpkin",
			originalPumpkinId,
			"InstanceId:",
			originalInstanceId
		)

	end
)


--==================================================
-- CLEAN PLAYER RATE LIMIT DATA
--==================================================

Players.PlayerRemoving:Connect(
	function(player)

		lastPickupTime[player] = nil

	end
)
