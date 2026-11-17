--==================================================
-- SERVICES
--==================================================

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


local CurrencyService =
	require(
		script.Parent
		:WaitForChild("CurrencyService")
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


local PumpkinConfig =
	require(
		ReplicatedStorage
		:WaitForChild("Config")
		:WaitForChild("PumpkinConfig")
	)


--==================================================
-- SERVICE
--==================================================

local PumpkinSellService = {}


--==================================================
-- FIND HELD PUMPKIN TOOL
--==================================================

local function GetHeldPumpkinTool(
	player
)

	local character =
		player.Character


	if not character then

		return nil

	end


	for _, child in ipairs(
		character:GetChildren()
		) do

		if child:IsA("Tool")
			and child:GetAttribute(
				"PumpkinProxy"
			) == true then

			local pumpkinId =
				child:GetAttribute(
					"PumpkinId"
				)


			if type(pumpkinId)
				== "string" then

				return child,
					pumpkinId

			end

		end

	end


	return nil,
		nil

end


--==================================================
-- FIND ONE INVENTORY INSTANCE
--==================================================

local function FindInventoryPumpkin(
	data,
	pumpkinId
)

	if type(data.Inventory)
		~= "table" then

		return nil,
			nil

	end


	for index,
		pumpkin in ipairs(
			data.Inventory
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
-- SELL HELD PUMPKIN
--==================================================

function PumpkinSellService.SellHeldPumpkin(
	player
)

	--==================================================
	-- PLAYER DATA
	--==================================================

	local data =
		PlayerDataService.GetData(
			player
		)


	if not data then

		return false,
			"DataNotLoaded"

	end


	--==================================================
	-- MUST BE HOLDING A PUMPKIN
	--==================================================

	local heldTool,
		pumpkinId =
		GetHeldPumpkinTool(
			player
		)


	if not heldTool
		or not pumpkinId then

		-- Player interacted with trash can while
		-- holding nothing or holding a non-pumpkin.
		--
		-- Nothing happens.

		return false,
			"NoHeldPumpkin"

	end


	--==================================================
	-- PUMPKIN CONFIG
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
	-- SELL VALUE
	--==================================================

	local sellValue =
		pumpkinInfo.SellValue
		or 0


	if type(sellValue)
		~= "number"
		or sellValue < 0 then

		return false,
			"InvalidSellValue"

	end


	--==================================================
	-- FIND REAL UNIQUE INVENTORY INSTANCE
	--==================================================

	local pumpkinInstance,
		inventoryIndex =
		FindInventoryPumpkin(
			data,
			pumpkinId
		)


	if not pumpkinInstance
		or not inventoryIndex then

		return false,
			"PumpkinNotOwned"

	end


	--==================================================
	-- SAVE INSTANCE INFORMATION
	--==================================================

	-- The Purse Tool represents a pumpkin TYPE.
	--
	-- We now select one actual unique pumpkin instance
	-- of that type from the player's inventory.

	local soldInstanceId =
		pumpkinInstance.InstanceId


	--==================================================
	-- REMOVE FROM INVENTORY FIRST
	--==================================================

	table.remove(
		data.Inventory,
		inventoryIndex
	)


	--==================================================
	-- PAY PLAYER
	--==================================================

	local currencySuccess =
		CurrencyService.AddDollars(
			player,
			sellValue
		)


	if not currencySuccess then

		--==================================================
		-- ROLLBACK
		--==================================================

		-- Money failed to update, so put the exact
		-- pumpkin instance back into inventory.

		table.insert(
			data.Inventory,
			inventoryIndex,
			pumpkinInstance
		)


		return false,
			"CurrencyUpdateFailed"

	end


	--==================================================
	-- REFRESH PURSE
	--==================================================

	PumpkinPurseAdapter.RefreshPlayer(
		player
	)


	--==================================================
	-- SUCCESS SOUND
	--==================================================

	-- Selling uses the same PurchaseSuccess sound
	-- we planned earlier.

	PlayerFeedbackService.Send(
		player,
		"PurchaseSuccess"
	)


	--==================================================
	-- SUCCESS
	--==================================================

	return true,
		{
			PumpkinId =
			pumpkinId,

			InstanceId =
			soldInstanceId,

			SellValue =
			sellValue,
		}

end


return PumpkinSellService
