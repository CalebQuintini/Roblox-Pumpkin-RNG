--==================================================
-- SERVICES
--==================================================

-- HttpService lets us generate unique IDs
-- for newly-created pumpkin instances.

local HttpService =
	game:GetService(
		"HttpService"
	)


-- ReplicatedStorage contains shared configs.

local ReplicatedStorage =
	game:GetService(
		"ReplicatedStorage"
	)


--==================================================
-- MODULES
--==================================================

-- Contains information about every pumpkin type.

local PumpkinConfig =
	require(
		ReplicatedStorage
		:WaitForChild("Config")
		:WaitForChild("PumpkinConfig")
	)


-- Contains general inventory settings.

local GameConfig =
	require(
		ReplicatedStorage
		:WaitForChild("Config")
		:WaitForChild("GameConfig")
	)


-- Lets us access the player's loaded save data.

local PlayerDataService =
	require(
		script.Parent:WaitForChild(
			"PlayerDataService"
		)
	)


--==================================================
-- MODULE
--==================================================

local PumpkinInventoryService =
	{}


--==================================================
-- HOTBAR SETTINGS
--==================================================

-- IMPORTANT:
--
-- Baseball Bat R15 and Hammer are REAL Roblox Tools.
--
-- They are handled directly by the Purse / Backpack
-- system.
--
-- They are NOT stored inside data.Hotbar.
--
-- data.Hotbar only stores pumpkin-type assignments.
--
-- Because we no longer reserve:
--
-- Slot 1 = Bat
-- Slot 2 = Hammer
--
-- pumpkin assignment data can use slots 1 through 10.

local FIRST_PUMPKIN_SLOT =
	1


local LAST_HOTBAR_SLOT =
	10


--==================================================
-- GET PLAYER DATA
--==================================================

local function GetPlayerData(
	player
)

	local data =
		PlayerDataService.GetData(
			player
		)


	-- Player's profile has not loaded yet.

	if not data then

		return nil

	end


	--==================================================
	-- INVENTORY SAFETY
	--==================================================

	if type(
		data.Inventory
		) ~= "table" then

		data.Inventory =
			{}

	end


	--==================================================
	-- HOTBAR SAFETY
	--==================================================

	if type(
		data.Hotbar
		) ~= "table" then

		data.Hotbar =
			{}

	end


	return data

end


--==================================================
-- GET INVENTORY
--==================================================

function PumpkinInventoryService.GetInventory(
	player
)

	local data =
		GetPlayerData(
			player
		)


	if not data then

		return nil

	end


	return data.Inventory

end


--==================================================
-- GET INVENTORY COUNT
--==================================================

function PumpkinInventoryService.GetInventoryCount(
	player
)

	local inventory =
		PumpkinInventoryService.GetInventory(
			player
		)


	if not inventory then

		return 0

	end


	-- Every entry represents one unique
	-- pumpkin instance.

	return #inventory

end


--==================================================
-- CHECK INVENTORY CAPACITY
--==================================================

function PumpkinInventoryService.HasInventorySpace(
	player
)

	local currentAmount =
		PumpkinInventoryService.GetInventoryCount(
			player
		)


	local maximumAmount =
		GameConfig.Inventory.MaxPumpkins


	-- nil means unlimited inventory.

	if maximumAmount == nil then

		return true

	end


	return currentAmount
		< maximumAmount

end


--==================================================
-- CHECK WHETHER PLAYER OWNS PUMPKIN TYPE
--==================================================

function PumpkinInventoryService.OwnsPumpkinType(
	player,
	pumpkinId
)

	local inventory =
		PumpkinInventoryService.GetInventory(
			player
		)


	if not inventory then

		return false

	end


	for _, pumpkin in ipairs(
		inventory
		) do

		if pumpkin.PumpkinId
			== pumpkinId then

			return true

		end

	end


	return false

end


--==================================================
-- COUNT PUMPKIN TYPE
--==================================================

function PumpkinInventoryService.GetPumpkinTypeCount(
	player,
	pumpkinId
)

	local inventory =
		PumpkinInventoryService.GetInventory(
			player
		)


	if not inventory then

		return 0

	end


	local amount =
		0


	for _, pumpkin in ipairs(
		inventory
		) do

		if pumpkin.PumpkinId
			== pumpkinId then

			amount +=
				1

		end

	end


	return amount

end


--==================================================
-- FIND HOTBAR SLOT CONTAINING PUMPKIN
--==================================================

function PumpkinInventoryService.GetHotbarSlotForPumpkin(
	player,
	pumpkinId
)

	local data =
		GetPlayerData(
			player
		)


	if not data then

		return nil

	end


	for slot =
		FIRST_PUMPKIN_SLOT,
		LAST_HOTBAR_SLOT do

		if data.Hotbar[slot]
			== pumpkinId then

			return slot

		end

	end


	return nil

end


--==================================================
-- FIND FIRST FREE PUMPKIN HOTBAR SLOT
--==================================================

function PumpkinInventoryService.GetFirstFreeHotbarSlot(
	player
)

	local data =
		GetPlayerData(
			player
		)


	if not data then

		return nil

	end


	for slot =
		FIRST_PUMPKIN_SLOT,
		LAST_HOTBAR_SLOT do

		if data.Hotbar[slot]
			== nil then

			return slot

		end

	end


	return nil

end


--==================================================
-- AUTO-ASSIGN PUMPKIN TYPE
--==================================================

local function AutoAssignPumpkinType(
	player,
	pumpkinId
)

	--==================================================
	-- ALREADY ASSIGNED
	--==================================================

	-- Duplicates of the same pumpkin type should
	-- use the same stack rather than occupying
	-- another pumpkin assignment.

	local existingSlot =
		PumpkinInventoryService
		.GetHotbarSlotForPumpkin(
			player,
			pumpkinId
		)


	if existingSlot then

		return

	end


	--==================================================
	-- FIND FREE SLOT
	--==================================================

	local freeSlot =
		PumpkinInventoryService
		.GetFirstFreeHotbarSlot(
			player
		)


	-- No assignment slot is available.
	--
	-- The pumpkin remains safely inside Inventory.

	if not freeSlot then

		return

	end


	local data =
		GetPlayerData(
			player
		)


	if not data then

		return

	end


	-- Store the pumpkin TYPE.
	--
	-- Individual unique InstanceIds remain
	-- inside data.Inventory.

	data.Hotbar[freeSlot] =
		pumpkinId

end


--==================================================
-- ADD NEW PUMPKIN
--==================================================

function PumpkinInventoryService.AddPumpkin(
	player,
	pumpkinId
)

	local inventory =
		PumpkinInventoryService.GetInventory(
			player
		)


	if not inventory then

		return false,
			"DataNotLoaded"

	end


	--==================================================
	-- VALIDATE PUMPKIN TYPE
	--==================================================

	local pumpkinInfo =
		PumpkinConfig.GetPumpkin(
			pumpkinId
		)


	if not pumpkinInfo then

		return false,
			"InvalidPumpkin"

	end


	--==================================================
	-- CHECK INVENTORY CAPACITY
	--==================================================

	if not PumpkinInventoryService.HasInventorySpace(
		player
		) then

		return false,
			"InventoryFull"

	end


	--==================================================
	-- CREATE NEW UNIQUE INSTANCE ID
	--==================================================

	local instanceId =
		HttpService:GenerateGUID(
			false
		)


	local pumpkinInstance =
		{

			InstanceId =
			instanceId,

			PumpkinId =
			pumpkinId,
		}


	--==================================================
	-- ADD TO INVENTORY
	--==================================================

	table.insert(
		inventory,
		pumpkinInstance
	)


	--==================================================
	-- AUTO-ASSIGN TYPE
	--==================================================

	AutoAssignPumpkinType(
		player,
		pumpkinId
	)


	--==================================================
	-- DEBUG
	--==================================================

	print(
		player.Name,
		"received",
		pumpkinId,
		"InstanceId:",
		instanceId
	)


	return true,
		pumpkinInstance

end


--==================================================
-- ADD EXISTING PUMPKIN
--==================================================

-- Used when something transfers an EXISTING pumpkin
-- to another player.
--
-- The stealing system uses this.
--
-- IMPORTANT:
--
-- AddPumpkin()
-- creates a NEW InstanceId.
--
-- AddExistingPumpkin()
-- preserves an EXISTING InstanceId.
--
-- Example:
--
-- Player A owns:
--
-- InstanceId = ABC123
--
-- Player B steals it successfully.
--
-- Player B receives:
--
-- InstanceId = ABC123
--
-- NOT a newly-generated ID.

function PumpkinInventoryService.AddExistingPumpkin(
	player,
	pumpkinId,
	instanceId
)

	local inventory =
		PumpkinInventoryService.GetInventory(
			player
		)


	if not inventory then

		return false,
			"DataNotLoaded"

	end


	--==================================================
	-- VALIDATE PUMPKIN TYPE
	--==================================================

	local pumpkinInfo =
		PumpkinConfig.GetPumpkin(
			pumpkinId
		)


	if not pumpkinInfo then

		return false,
			"InvalidPumpkin"

	end


	--==================================================
	-- VALIDATE INSTANCE ID
	--==================================================

	if type(instanceId)
		~= "string"
		or instanceId == "" then

		return false,
			"InvalidInstanceId"

	end


	--==================================================
	-- CHECK INVENTORY CAPACITY
	--==================================================

	if not PumpkinInventoryService.HasInventorySpace(
		player
		) then

		return false,
			"InventoryFull"

	end


	--==================================================
	-- PREVENT DUPLICATE INSTANCE ID
	--==================================================

	for _, existingPumpkin in ipairs(
		inventory
		) do

		if existingPumpkin.InstanceId
			== instanceId then

			return false,
				"InstanceAlreadyOwned"

		end

	end


	--==================================================
	-- CREATE INVENTORY RECORD
	--==================================================

	-- Notice that we DO NOT call:
	--
	-- HttpService:GenerateGUID()
	--
	-- We preserve the supplied InstanceId.

	local pumpkinInstance =
		{

			InstanceId =
			instanceId,

			PumpkinId =
			pumpkinId,
		}


	--==================================================
	-- ADD TO INVENTORY
	--==================================================

	table.insert(
		inventory,
		pumpkinInstance
	)


	--==================================================
	-- AUTO-ASSIGN TYPE
	--==================================================

	AutoAssignPumpkinType(
		player,
		pumpkinId
	)


	--==================================================
	-- DEBUG
	--==================================================

	print(
		player.Name,
		"received existing pumpkin",
		pumpkinId,
		"InstanceId:",
		instanceId
	)


	return true,
		pumpkinInstance

end


--==================================================
-- FIND PUMPKIN INSTANCE
--==================================================

function PumpkinInventoryService.GetPumpkinByInstanceId(
	player,
	instanceId
)

	local inventory =
		PumpkinInventoryService.GetInventory(
			player
		)


	if not inventory then

		return nil

	end


	for index, pumpkin in ipairs(
		inventory
		) do

		if pumpkin.InstanceId
			== instanceId then

			return pumpkin,
				index

		end

	end


	return nil

end


--==================================================
-- REMOVE ONE PUMPKIN INSTANCE
--==================================================

function PumpkinInventoryService.RemovePumpkin(
	player,
	instanceId
)

	local inventory =
		PumpkinInventoryService.GetInventory(
			player
		)


	if not inventory then

		return false,
			"DataNotLoaded"

	end


	--==================================================
	-- FIND INSTANCE
	--==================================================

	local pumpkin,
		index =
		PumpkinInventoryService
		.GetPumpkinByInstanceId(
			player,
			instanceId
		)


	if not pumpkin then

		return false,
			"PumpkinNotFound"

	end


	local pumpkinId =
		pumpkin.PumpkinId


	--==================================================
	-- REMOVE UNIQUE INSTANCE
	--==================================================

	table.remove(
		inventory,
		index
	)


	--==================================================
	-- CLEAN PUMPKIN TYPE ASSIGNMENT
	--==================================================

	-- If the player still owns another pumpkin
	-- of this same type, keep the stack assignment.
	--
	-- Only remove the assignment after the LAST
	-- pumpkin of this type leaves their inventory.

	if not PumpkinInventoryService
		.OwnsPumpkinType(
			player,
			pumpkinId
		) then

		local slot =
			PumpkinInventoryService
			.GetHotbarSlotForPumpkin(
				player,
				pumpkinId
			)


		if slot then

			local data =
				GetPlayerData(
					player
				)


			if data then

				data.Hotbar[slot] =
					nil

			end

		end

	end


	return true,
		pumpkin

end


--==================================================
-- SET PUMPKIN HOTBAR ASSIGNMENT
--==================================================

function PumpkinInventoryService.SetHotbarSlot(
	player,
	slot,
	pumpkinId
)

	local data =
		GetPlayerData(
			player
		)


	if not data then

		return false,
			"DataNotLoaded"

	end


	--==================================================
	-- VALIDATE SLOT
	--==================================================

	-- data.Hotbar is now pumpkin-only.
	--
	-- Bat/Hammer physical Tools are managed
	-- separately by Purse.

	if type(slot)
		~= "number"
		or slot < FIRST_PUMPKIN_SLOT
		or slot > LAST_HOTBAR_SLOT then

		return false,
			"InvalidSlot"

	end


	--==================================================
	-- VALIDATE PUMPKIN
	--==================================================

	if not PumpkinConfig.GetPumpkin(
		pumpkinId
		) then

		return false,
			"InvalidPumpkin"

	end


	--==================================================
	-- MUST OWN TYPE
	--==================================================

	if not PumpkinInventoryService
		.OwnsPumpkinType(
			player,
			pumpkinId
		) then

		return false,
			"NotOwned"

	end


	--==================================================
	-- REMOVE OLD ASSIGNMENT
	--==================================================

	local oldSlot =
		PumpkinInventoryService
		.GetHotbarSlotForPumpkin(
			player,
			pumpkinId
		)


	if oldSlot then

		data.Hotbar[oldSlot] =
			nil

	end


	--==================================================
	-- ASSIGN TARGET SLOT
	--==================================================

	data.Hotbar[slot] =
		pumpkinId


	return true

end


--==================================================
-- REMOVE PUMPKIN HOTBAR ASSIGNMENT
--==================================================

function PumpkinInventoryService.RemoveHotbarSlot(
	player,
	slot
)

	local data =
		GetPlayerData(
			player
		)


	if not data then

		return false,
			"DataNotLoaded"

	end


	if type(slot)
		~= "number"
		or slot < FIRST_PUMPKIN_SLOT
		or slot > LAST_HOTBAR_SLOT then

		return false,
			"InvalidSlot"

	end


	-- Does NOT delete any actual pumpkin.
	--
	-- It only removes the saved pumpkin-type
	-- quick-access assignment.

	data.Hotbar[slot] =
		nil


	return true

end


--==================================================
-- MOVE / SWAP PUMPKIN HOTBAR ASSIGNMENTS
--==================================================

function PumpkinInventoryService.MoveHotbarSlot(
	player,
	fromSlot,
	toSlot
)

	local data =
		GetPlayerData(
			player
		)


	if not data then

		return false,
			"DataNotLoaded"

	end


	--==================================================
	-- VALIDATE SLOTS
	--==================================================

	if type(fromSlot)
		~= "number"
		or type(toSlot)
		~= "number"
		or fromSlot < FIRST_PUMPKIN_SLOT
		or fromSlot > LAST_HOTBAR_SLOT
		or toSlot < FIRST_PUMPKIN_SLOT
		or toSlot > LAST_HOTBAR_SLOT then

		return false,
			"InvalidSlot"

	end


	--==================================================
	-- SOURCE
	--==================================================

	local sourcePumpkin =
		data.Hotbar[fromSlot]


	if not sourcePumpkin then

		return false,
			"EmptySource"

	end


	--==================================================
	-- DESTINATION
	--==================================================

	local destinationPumpkin =
		data.Hotbar[toSlot]


	--==================================================
	-- SWAP
	--==================================================

	data.Hotbar[toSlot] =
		sourcePumpkin


	data.Hotbar[fromSlot] =
		destinationPumpkin


	return true

end


--==================================================
-- CREATE CLIENT STACK
--==================================================

local function CreateClientStack(
	pumpkinId,
	quantity
)

	local pumpkinInfo =
		PumpkinConfig.GetPumpkin(
			pumpkinId
		)


	if not pumpkinInfo then

		return nil

	end


	return {

		PumpkinId =
			pumpkinId,

		DisplayName =
			pumpkinInfo.DisplayName,

		Icon =
			pumpkinInfo.Icon,

		MoneyPerSecond =
			pumpkinInfo.MoneyPerSecond,

		Quantity =
			quantity,
	}

end


--==================================================
-- BUILD CLIENT INVENTORY STATE
--==================================================

function PumpkinInventoryService.BuildClientState(
	player
)

	local data =
		GetPlayerData(
			player
		)


	if not data then

		return {

			Hotbar =
				{},

			Backpack =
				{},

			InventoryCount =
				0,

			MaxInventory =
				GameConfig.Inventory.MaxPumpkins,
		}

	end


	--==================================================
	-- COUNT EACH PUMPKIN TYPE
	--==================================================

	local counts =
		{}


	for _, pumpkin in ipairs(
		data.Inventory
		) do

		local pumpkinId =
			pumpkin.PumpkinId


		if type(pumpkinId)
			== "string" then

			counts[pumpkinId] =
				(
					counts[pumpkinId]
					or 0
				)
				+ 1

		end

	end


	--==================================================
	-- BUILD PUMPKIN HOTBAR STATE
	--==================================================

	-- IMPORTANT:
	--
	-- This is only pumpkin assignment data.
	--
	-- It does NOT contain:
	--
	-- Baseball Bat R15
	-- Hammer
	--
	-- Those are real Roblox Tools and Purse
	-- discovers them directly in Backpack/Character.

	local clientHotbar =
		{}


	local assignedPumpkins =
		{}


	for slot =
		FIRST_PUMPKIN_SLOT,
		LAST_HOTBAR_SLOT do

		local pumpkinId =
			data.Hotbar[slot]


		--==================================================
		-- VALID ASSIGNMENT
		--==================================================

		if pumpkinId
			and counts[pumpkinId]
			and counts[pumpkinId] > 0 then

			local stack =
				CreateClientStack(
					pumpkinId,
					counts[pumpkinId]
				)


			if stack then

				stack.Slot =
					slot


				-- Use an ordinary array.
				--
				-- Do not use:
				--
				-- clientHotbar[slot] = stack
				--
				-- because that can create sparse
				-- numeric tables.

				table.insert(
					clientHotbar,
					stack
				)


				assignedPumpkins[pumpkinId] =
					true

			end


		else

			--==================================================
			-- REMOVE STALE ASSIGNMENT
			--==================================================

			data.Hotbar[slot] =
				nil

		end

	end


	--==================================================
	-- BUILD FULL INVENTORY / BACKPACK STATE
	--==================================================

	local backpack =
		{}


	for pumpkinId, quantity in pairs(
		counts
		) do

		-- Don't duplicate types already represented
		-- by the pumpkin hotbar state.

		if not assignedPumpkins[
			pumpkinId
			] then

			local stack =
				CreateClientStack(
					pumpkinId,
					quantity
				)


			if stack then

				table.insert(
					backpack,
					stack
				)

			end

		end

	end


	--==================================================
	-- STABLE SORTING
	--==================================================

	table.sort(
		backpack,

		function(
			a,
			b
		)

			return a.DisplayName
				< b.DisplayName

		end
	)


	--==================================================
	-- RETURN CLIENT STATE
	--==================================================

	return {

		Hotbar =
			clientHotbar,

		Backpack =
			backpack,

		InventoryCount =
			#data.Inventory,

		MaxInventory =
			GameConfig.Inventory.MaxPumpkins,
	}

end


--==================================================
-- RETURN MODULE
--==================================================

return PumpkinInventoryService
