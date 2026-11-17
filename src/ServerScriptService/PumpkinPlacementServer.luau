--==================================================
-- SERVICES
--==================================================

local ReplicatedStorage =
	game:GetService(
		"ReplicatedStorage"
	)


--==================================================
-- MODULES
--==================================================

local PlayerDataService =
	require(
		script.Parent
		:WaitForChild("PlayerDataService")
	)


local PumpkinInventoryService =
	require(
		script.Parent
		:WaitForChild("PumpkinInventoryService")
	)


local PumpkinPlacementService =
	require(
		script.Parent
		:WaitForChild("PumpkinPlacementService")
	)


local PumpkinPurseAdapter =
	require(
		script.Parent
		:WaitForChild("PumpkinPurseAdapter")
	)


local PlayerFeedbackService =
	require(
		script.Parent
		:WaitForChild("PlayerFeedbackService")
	)


local PumpkinStealService =
	require(
		script.Parent
		:WaitForChild("PumpkinStealService")
	)


local TutorialService =
	require(
		script.Parent
		:WaitForChild("TutorialService")
	)


local GameAnalyticsService =
	require(
		script.Parent
		:WaitForChild("GameAnalyticsService")
	)


--==================================================
-- REMOTES
--==================================================

local Remotes =
	ReplicatedStorage
	:WaitForChild("Remotes")


-- Create the placement request RemoteEvent
-- automatically if it does not exist.

local PlacePumpkinRequest =
	Remotes:FindFirstChild(
		"PlacePumpkinRequest"
	)


if not PlacePumpkinRequest then

	PlacePumpkinRequest =
		Instance.new(
			"RemoteEvent"
		)


	PlacePumpkinRequest.Name =
		"PlacePumpkinRequest"


	PlacePumpkinRequest.Parent =
		Remotes

end


-- Server sends placement result back
-- to the requesting player.

local PlacementResult =
	Remotes:FindFirstChild(
		"PlacementResult"
	)


if not PlacementResult then

	PlacementResult =
		Instance.new(
			"RemoteEvent"
		)


	PlacementResult.Name =
		"PlacementResult"


	PlacementResult.Parent =
		Remotes

end


--==================================================
-- SIMPLE REQUEST RATE LIMIT
--==================================================

local lastPlacementRequest =
	{}


local MIN_REQUEST_TIME =
	0.08


--==================================================
-- FIND ONE OWNED PUMPKIN INSTANCE
--==================================================

local function FindOwnedPumpkin(
	player,
	pumpkinId
)

	local inventory =
		PumpkinInventoryService
		.GetInventory(
			player
		)


	if not inventory then

		return nil,
			nil

	end


	for index, pumpkin in ipairs(
		inventory
		) do

		if pumpkin.PumpkinId
			== pumpkinId then

			return pumpkin,
				index

		end

	end


	return nil,
		nil

end


--==================================================
-- PLACE REQUEST
--==================================================

PlacePumpkinRequest.OnServerEvent:Connect(
	function(
		player,
		pumpkinId,
		gridX,
		gridZ,
		rotation
	)

		--==================================================
		-- BASIC RATE LIMIT
		--==================================================

		local now =
			os.clock()


		local previous = lastPlacementRequest[player]


		if previous
			and now - previous
			< MIN_REQUEST_TIME then

			return

		end


		lastPlacementRequest[player] = now


		--==================================================
		-- BASIC TYPE VALIDATION
		--==================================================

		if type(
			pumpkinId
			) ~= "string" then

			return

		end


		if type(
			gridX
			) ~= "number"
				or type(
					gridZ
				) ~= "number"
				or type(
					rotation
				) ~= "number" then

			return

		end


		--==================================================
		-- PLAYER CURRENTLY IN STEAL MODE
		--==================================================

		if PumpkinStealService.IsStealing(
			player
			) then

			PlacementResult:FireClient(
				player,
				false,
				"CurrentlyStealing"
			)


			return

		end


		--==================================================
		-- DATA
		--==================================================

		local data =
			PlayerDataService.GetData(
				player
			)


		if not data then

			PlacementResult:FireClient(
				player,
				false,
				"DataNotLoaded"
			)


			return

		end


		--==================================================
		-- TUTORIAL PLACEMENT RULES
		--==================================================

		if TutorialService.IsActive(
			player
			) then

			-- Player is still in the tutorial.
			--
			-- They may only place a pumpkin during:
			--
			-- Step 3 = Place.

			if not TutorialService.IsStep(
				player,
				TutorialService.STEP_PLACE
				) then

				PlacementResult:FireClient(
					player,
					false,
					"CompleteTutorial"
				)


				return

			end


			-- The tutorial roll is always forced to
			-- NormalPumpkin.
			--
			-- Therefore only NormalPumpkin can be used
			-- to complete the tutorial.

			if pumpkinId
				~= "NormalPumpkin" then

				PlacementResult:FireClient(
					player,
					false,
					"TutorialRequiresNormalPumpkin"
				)


				return

			end

		end


		--==================================================
		-- VERIFY OWNERSHIP
		--==================================================

		local ownedPumpkin,
		inventoryIndex =
			FindOwnedPumpkin(
				player,
				pumpkinId
			)


		if not ownedPumpkin then

			PlacementResult:FireClient(
				player,
				false,
				"NotOwned"
			)


			return

		end


		--==================================================
		-- SERVER PLACEMENT VALIDATION
		--==================================================

		local valid,
		reason =
			PumpkinPlacementService
			.IsPlacementValid(
				player,
				pumpkinId,
				gridX,
				gridZ,
				rotation
			)


		if not valid then

			PlacementResult:FireClient(
				player,
				false,
				reason
			)


			return

		end


		--==================================================
		-- REMOVE EXACT OWNED INSTANCE FROM INVENTORY
		--==================================================

		table.remove(
			data.Inventory,
			inventoryIndex
		)


		--==================================================
		-- CREATE PERSISTENT PLACED RECORD
		--==================================================

		local placedRecord =
			{

				InstanceId =
				ownedPumpkin.InstanceId,

				PumpkinId =
				ownedPumpkin.PumpkinId,

				GridX =
				gridX,

				GridZ =
				gridZ,

				Rotation =
				rotation,

				StoredMoney =
				0,
			}


		table.insert(
			data.PlacedPumpkins,
			placedRecord
		)


		--==================================================
		-- SPAWN WORLD MODEL
		--==================================================

		local model,
		spawnReason =
			PumpkinPlacementService
			.RestorePumpkin(
				player,
				placedRecord
			)


		-- If spawning failed, rollback everything.

		if not model then

			--==================================================
			-- REMOVE PLACED RECORD
			--==================================================

			for index,
				record in ipairs(
					data.PlacedPumpkins
				) do

				if record.InstanceId
					== placedRecord.InstanceId then

					table.remove(
						data.PlacedPumpkins,
						index
					)


					break

				end

			end


			--==================================================
			-- RETURN PUMPKIN TO INVENTORY
			--==================================================

			table.insert(
				data.Inventory,
				ownedPumpkin
			)


			--==================================================
			-- REFRESH PURSE
			--==================================================

			PumpkinPurseAdapter
				.RefreshPlayer(
					player
				)


			--==================================================
			-- TELL CLIENT PLACEMENT FAILED
			--==================================================

			PlacementResult:FireClient(
				player,
				false,
				spawnReason
					or "SpawnFailed"
			)


			return

		end


		--==================================================
		-- REFRESH PURSE STACK
		--==================================================

		-- Example:
		--
		-- Normal x5
		-- becomes
		-- Normal x4
		--
		-- If it becomes zero, the proxy Tool
		-- is removed automatically.

		PumpkinPurseAdapter
			.RefreshPlayer(
				player
			)


		--==================================================
		-- PLACEMENT SOUND
		--==================================================

		-- The pumpkin has now:
		--
		-- been removed from inventory
		-- been added to PlacedPumpkins
		-- successfully spawned in the world
		-- had Purse refreshed
		--
		-- So this is a confirmed successful placement.

		PlayerFeedbackService.Send(
			player,
			"PumpkinPlacePickup"
		)


		--==================================================
		-- COMPLETE TUTORIAL
		--==================================================

		-- Important:
		--
		-- We only complete the tutorial AFTER the
		-- world model successfully spawned.
		--
		-- Failed placements therefore cannot complete
		-- the tutorial.

		if TutorialService.IsStep(
			player,
			TutorialService.STEP_PLACE
			) then

			--==================================================
			-- ANALYTICS - PLACED FIRST PUMPKIN
			--==================================================

			GameAnalyticsService.LogOnboardingStep(
				player,
				GameAnalyticsService.OnboardingSteps.PlacedFirstPumpkin
			)


			--==================================================
			-- COMPLETE TUTORIAL
			--==================================================

			TutorialService.Complete(
				player
			)

		end


		--==================================================
		-- SUCCESS
		--==================================================

		PlacementResult:FireClient(
			player,
			true,
			"Placed"
		)

	end
)
