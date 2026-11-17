--==================================================
-- SERVICES
--==================================================

local ReplicatedStorage =
	game:GetService("ReplicatedStorage")


--==================================================
-- MODULES
--==================================================

local PumpkinInventoryService =
	require(
		script.Parent
		:WaitForChild("PumpkinInventoryService")
	)


--==================================================
-- REMOTES
--==================================================

local Remotes =
	ReplicatedStorage
	:WaitForChild("Remotes")


local InventoryRequest =
	Remotes
	:WaitForChild("InventoryRequest")


local InventoryUpdated =
	Remotes
	:WaitForChild("InventoryUpdated")


--==================================================
-- SEND CURRENT STATE
--==================================================

local function SendInventory(player)

	local state =
		PumpkinInventoryService
		.BuildClientState(
			player
		)


	InventoryUpdated:FireClient(
		player,
		state
	)

end


--==================================================
-- HANDLE REQUEST
--==================================================

InventoryRequest.OnServerEvent:Connect(
	function(
		player,
		action,
		value1,
		value2
	)

		--==================================================
		-- REQUEST INVENTORY
		--==================================================

		if action == "RequestInventory" then

			SendInventory(player)

			return

		end


		--==================================================
		-- TEMPORARY TEST NORMAL PUMPKIN
		--==================================================

		if action == "TestAddNormalPumpkin" then

			local success,
			reason =
				PumpkinInventoryService
				.AddPumpkin(
					player,
					"NormalPumpkin"
				)


			if not success then

				warn(
					"Failed adding NormalPumpkin:",
					reason
				)

			end


			SendInventory(player)

			return

		end


		--==================================================
		-- TEMPORARY TEST CARVED PUMPKIN
		--==================================================

		if action == "TestAddCarvedPumpkin" then

			local success,
			reason =
				PumpkinInventoryService
				.AddPumpkin(
					player,
					"CarvedPumpkin"
				)


			if not success then

				warn(
					"Failed adding CarvedPumpkin:",
					reason
				)

			end


			SendInventory(player)

			return

		end


		--==================================================
		-- PUT BACKPACK ITEM INTO HOTBAR
		--==================================================

		if action == "SetHotbarSlot" then

			local slot =
				value1


			local pumpkinId =
				value2


			PumpkinInventoryService
				.SetHotbarSlot(
					player,
					slot,
					pumpkinId
				)


			SendInventory(player)

			return

		end


		--==================================================
		-- REMOVE FROM HOTBAR
		--==================================================

		if action == "RemoveHotbarSlot" then

			local slot =
				value1


			PumpkinInventoryService
				.RemoveHotbarSlot(
					player,
					slot
				)


			SendInventory(player)

			return

		end


		--==================================================
		-- MOVE / SWAP HOTBAR ITEMS
		--==================================================

		if action == "MoveHotbarSlot" then

			local fromSlot =
				value1


			local toSlot =
				value2


			PumpkinInventoryService
				.MoveHotbarSlot(
					player,
					fromSlot,
					toSlot
				)


			SendInventory(player)

			return

		end

	end
)
