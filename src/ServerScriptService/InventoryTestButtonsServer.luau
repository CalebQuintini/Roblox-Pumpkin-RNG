--==================================================
-- SERVICES
--==================================================

local Workspace =
	game:GetService(
		"Workspace"
	)


local ReplicatedStorage =
	game:GetService(
		"ReplicatedStorage"
	)


local HttpService =
	game:GetService(
		"HttpService"
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


local PlayerDataTemplate =
	require(
		ReplicatedStorage
		:WaitForChild("Config")
		:WaitForChild("PlayerDataTemplate")
	)


--==================================================
-- MODULES
--==================================================

local PumpkinInventoryService =
	require(
		script.Parent
		:WaitForChild("PumpkinInventoryService")
	)


local PumpkinPurseAdapter =
	require(
		script.Parent
		:WaitForChild("PumpkinPurseAdapter")
	)


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


local PlotService =
	require(
		script.Parent
		:WaitForChild("PlotService")
	)


--==================================================
-- TEST BUTTON REFERENCES
--==================================================

local testButtonsFolder =
	Workspace
	:WaitForChild("InventoryTestButtons")


--==================================================
-- NORMAL PUMPKIN BUTTON
--==================================================

local addNormalButton =
	testButtonsFolder
	:WaitForChild("AddNormal")


local normalPrompt =
	addNormalButton
	:WaitForChild("ProximityPrompt")


--==================================================
-- CARVED PUMPKIN BUTTON
--==================================================

local addCarvedButton =
	testButtonsFolder
	:WaitForChild("AddCarved")


local carvedPrompt =
	addCarvedButton
	:WaitForChild("ProximityPrompt")


--==================================================
-- WIPE INVENTORY BUTTON
--==================================================

local wipeInventoryButton =
	testButtonsFolder
	:WaitForChild("WipeInventory")


local wipeInventoryPrompt =
	wipeInventoryButton
	:WaitForChild("ProximityPrompt")


--==================================================
-- ADD MONEY BUTTON
--==================================================

local giveMoneyButton =
	testButtonsFolder
	:WaitForChild("GiveMoney")


local giveMoneyPrompt =
	giveMoneyButton
	:WaitForChild("ProximityPrompt")


--==================================================
-- GIVE ALL PUMPKINS BUTTON
--==================================================

local giveAllPumpkinsButton =
	testButtonsFolder
	:WaitForChild("GiveAllPumpkins")


local giveAllPumpkinsPrompt =
	giveAllPumpkinsButton
	:WaitForChild("ProximityPrompt")


--==================================================
-- RESET EVERYTHING BUTTON
--==================================================

-- Keeping your exact Explorer name:
--
-- ResetEveything
--
-- Notice "Everything" is intentionally spelled
-- "Eveything" here because that is the name you said
-- you created in Studio.

local resetEverythingButton =
	testButtonsFolder
	:WaitForChild("ResetEveything")


local resetEverythingPrompt =
	resetEverythingButton
	:WaitForChild("ProximityPrompt")


--==================================================
-- TEST MONEY AMOUNT
--==================================================

local QUINTILLION =
	1e18


--==================================================
-- DEEP COPY
--==================================================

local function DeepCopy(
	value
)

	if type(value)
		~= "table" then

		return value

	end


	local copy =
		{}


	for key, childValue in pairs(
		value
		) do

		copy[
		DeepCopy(key)
		] =
			DeepCopy(
				childValue
			)

	end


	return copy

end


--==================================================
-- RESET TABLE TO DEFAULT DATA
--==================================================

local function ResetDataTable(
	data
)

	if not data then

		return false

	end


	--==================================================
	-- CLEAR EXISTING KEYS
	--==================================================

	-- We do NOT replace the data table itself.
	--
	-- Other services may already hold a reference
	-- to this exact table.
	--
	-- Instead we empty the table and copy the
	-- template values back into the SAME table.

	for key in pairs(
		data
		) do

		data[key] =
			nil

	end


	--==================================================
	-- COPY DEFAULT DATA
	--==================================================

	local freshData =
		DeepCopy(
			PlayerDataTemplate.DefaultData
		)


	for key, value in pairs(
		freshData
		) do

		data[key] =
			value

	end


	return true

end


--==================================================
-- REMOVE PHYSICAL PLACED PUMPKINS
--==================================================

local function DestroyPlacedPumpkins(
	player
)

	local plot =
		PlotService.GetPlayerPlot(
			player
		)


	if not plot then

		return

	end


	local placedFolder =
		plot:FindFirstChild(
			"PlacedPumpkins"
		)


	if not placedFolder then

		return

	end


	for _, child in ipairs(
		placedFolder:GetChildren()
		) do

		child:Destroy()

	end

end


--==================================================
-- ADD NORMAL PUMPKIN
--==================================================

normalPrompt.Triggered:Connect(
	function(player)

		local success,
		result =
			PumpkinInventoryService.AddPumpkin(
				player,
				"NormalPumpkin"
			)


		if not success then

			warn(
				"Failed to add NormalPumpkin for",
				player.Name,
				"Reason:",
				result
			)


			PumpkinPurseAdapter.RefreshPlayer(
				player
			)


			return

		end


		PumpkinPurseAdapter.RefreshPlayer(
			player
		)


		print(
			player.Name,
			"received a Normal Pumpkin."
		)

	end
)


--==================================================
-- ADD CARVED PUMPKIN
--==================================================

carvedPrompt.Triggered:Connect(
	function(player)

		local success,
		result =
			PumpkinInventoryService.AddPumpkin(
				player,
				"CarvedPumpkin"
			)


		if not success then

			warn(
				"Failed to add CarvedPumpkin for",
				player.Name,
				"Reason:",
				result
			)


			PumpkinPurseAdapter.RefreshPlayer(
				player
			)


			return

		end


		PumpkinPurseAdapter.RefreshPlayer(
			player
		)


		print(
			player.Name,
			"received a Carved Pumpkin."
		)

	end
)


--==================================================
-- ADD $1 QUINTILLION
--==================================================

giveMoneyPrompt.Triggered:Connect(
	function(player)

		local data =
			PlayerDataService.GetData(
				player
			)


		if not data then

			warn(
				"Could not give money to",
				player.Name,
				"Reason: DataNotLoaded"
			)


			return

		end


		local success =
			CurrencyService.AddDollars(
				player,
				QUINTILLION
			)


		if not success then

			warn(
				"Failed to give $1 Quintillion to",
				player.Name
			)


			return

		end


		print(
			player.Name,
			"received $1 Quintillion."
		)

	end
)


--==================================================
-- WIPE INVENTORY
--==================================================

wipeInventoryPrompt.Triggered:Connect(
	function(player)

		local data =
			PlayerDataService.GetData(
				player
			)


		if not data then

			warn(
				"Could not wipe inventory for",
				player.Name,
				"Reason: DataNotLoaded"
			)


			return

		end


		--==================================================
		-- CLEAR INVENTORY
		--==================================================

		data.Inventory =
			{}


		--==================================================
		-- CLEAR HOTBAR
		--==================================================

		data.Hotbar =
			{}


		--==================================================
		-- REFRESH PURSE
		--==================================================

		PumpkinPurseAdapter.RefreshPlayer(
			player
		)


		print(
			"Wiped all inventory pumpkins for",
			player.Name
		)

	end
)


--==================================================
-- GIVE EVERY PUMPKIN
--==================================================

giveAllPumpkinsPrompt.Triggered:Connect(
	function(player)

		local data =
			PlayerDataService.GetData(
				player
			)


		if not data then

			warn(
				"[InventoryTestButtons] Could not give all pumpkins to",
				player.Name,
				"Reason: DataNotLoaded"
			)


			return

		end


		--==================================================
		-- MAKE SURE INVENTORY EXISTS
		--==================================================

		if type(
			data.Inventory
			) ~= "table" then

			data.Inventory =
				{}

		end


		--==================================================
		-- MAKE SURE INDEX EXISTS
		--==================================================

		if type(
			data.PumpkinIndex
			) ~= "table" then

			data.PumpkinIndex =
				{}

		end


		--==================================================
		-- SORT PUMPKIN IDS
		--==================================================

		local pumpkinIds =
			{}


		for pumpkinId in pairs(
			PumpkinConfig.Pumpkins
			) do

			table.insert(
				pumpkinIds,
				pumpkinId
			)

		end


		table.sort(
			pumpkinIds
		)


		--==================================================
		-- ADD ONE OF EVERY TYPE
		--==================================================

		local addedCount =
			0


		for _, pumpkinId in ipairs(
			pumpkinIds
			) do

			--==================================================
			-- CREATE TEST INSTANCE DIRECTLY
			--==================================================

			-- We intentionally insert directly into the
			-- inventory for this TEST button.
			--
			-- PumpkinInventoryService.AddPumpkin normally
			-- respects the player's inventory capacity.
			--
			-- For a developer "Give All" button, we want
			-- every pumpkin to be added even if there are
			-- more pumpkin types than the normal inventory
			-- limit.

			table.insert(
				data.Inventory,
				{
					PumpkinId =
						pumpkinId,

					InstanceId =
						HttpService:GenerateGUID(
							false
						),
				}
			)


			--==================================================
			-- UNLOCK IN INDEX
			--==================================================

			data.PumpkinIndex[
			pumpkinId
			] =
				true


			addedCount +=
				1

		end


		--==================================================
		-- REFRESH PURSE
		--==================================================

		PumpkinPurseAdapter.RefreshPlayer(
			player
		)


		print(
			"[InventoryTestButtons]",
			player.Name,
			"received every pumpkin.",
			"Total:",
			addedCount
		)

	end
)


--==================================================
-- RESET EVERYTHING
--==================================================

resetEverythingPrompt.Triggered:Connect(
	function(player)

		--==================================================
		-- GET LOADED DATA
		--==================================================

		local data =
			PlayerDataService.GetData(
				player
			)


		if not data then

			warn(
				"[InventoryTestButtons] Could not reset",
				player.Name,
				"Reason: DataNotLoaded"
			)


			return

		end


		print(
			"[InventoryTestButtons] RESET EVERYTHING requested by",
			player.Name
		)


		--==================================================
		-- REMOVE PHYSICAL PUMPKINS FIRST
		--==================================================

		DestroyPlacedPumpkins(
			player
		)


		--==================================================
		-- RESET ENTIRE SAVE DATA
		--==================================================

		-- This is much safer than manually doing:
		--
		-- data.Dollars = ...
		-- data.LuckLevel = ...
		-- data.Inventory = {}
		-- data.PumpkinIndex = {}
		-- etc.
		--
		-- By restoring PlayerDataTemplate.DefaultData,
		-- EVERY persistent field goes back to its
		-- brand-new-player value.
		--
		-- That includes future fields you add later too.

		local resetSuccess =
			ResetDataTable(
				data
			)


		if not resetSuccess then

			warn(
				"[InventoryTestButtons] Reset failed for",
				player.Name
			)


			return

		end


		--==================================================
		-- REFRESH PURSE
		--==================================================

		PumpkinPurseAdapter.RefreshPlayer(
			player
		)


		--==================================================
		-- SAVE RESET IMMEDIATELY
		--==================================================

		local saveSuccess =
			PlayerDataService.SavePlayer(
				player,
				false
			)


		if not saveSuccess then

			warn(
				"[InventoryTestButtons] Reset happened in memory",
				"but failed to save for",
				player.Name
			)


			return

		end


		print(
			"[InventoryTestButtons]",
			player.Name,
			"was completely reset to PlayerDataTemplate defaults."
		)


		--==================================================
		-- REJOIN FOR CLEAN REINITIALIZATION
		--==================================================

		-- A lot of your game systems cache runtime state:
		--
		-- Luck boards
		-- barriers
		-- pumpkin income
		-- plot state
		-- index UI
		-- inventory UI
		-- purchases
		--
		-- Rather than trying to manually reset every
		-- system from this test script, we save the
		-- clean data and make the player rejoin.
		--
		-- On rejoin every system initializes from the
		-- brand-new default data.

		task.delay(
			0.5,

			function()

				if player.Parent then

					player:Kick(
						"Test data reset complete. Rejoin to continue."
					)

				end

			end
		)

	end
)
