--==================================================
-- SERVICES
--==================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--==================================================
-- MODULES
--==================================================
local PumpkinInventoryService = require(script.Parent:WaitForChild("PumpkinInventoryService"))
local PumpkinConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("PumpkinConfig"))

--==================================================
-- MODULE
--==================================================
local PumpkinPurseAdapter = {}

--==================================================
-- CONSTANTS
--==================================================
-- Attribute used so we can identify which Tools
-- were created by our pumpkin inventory system.
local PUMPKIN_PROXY_ATTRIBUTE = "PumpkinProxy"

--==================================================
-- FIND EXISTING PROXY TOOL
--==================================================
local function FindPumpkinTool(player,pumpkinId)
	-- A Tool may currently be inside:
	--
	-- player.Backpack
	-- OR
	-- player.Character
	--
	-- because equipping a Tool moves it
	-- between those containers.
	local backpack = player:FindFirstChild("Backpack")

	if backpack then
		for _, child in ipairs(
			backpack:GetChildren()
			) do

			if child:IsA("Tool")
				and child:GetAttribute(
					PUMPKIN_PROXY_ATTRIBUTE
				) == true
					and child:GetAttribute(
						"PumpkinId"
					) == pumpkinId then

				return child

			end

		end

	end


	local character = player.Character

	if character then
		for _, child in ipairs(
			character:GetChildren()
			) do

			if child:IsA("Tool")
				and child:GetAttribute(
					PUMPKIN_PROXY_ATTRIBUTE
				) == true
					and child:GetAttribute(
						"PumpkinId"
					) == pumpkinId then
				return child
			end
		end
	end
	return nil
end

--==================================================
-- CREATE PROXY TOOL
--==================================================
local function CreatePumpkinTool(player,pumpkinId,quantity)
	local pumpkinInfo = PumpkinConfig.GetPumpkin(pumpkinId)

	if not pumpkinInfo then
		warn(
			"Cannot create Purse proxy Tool.",
			"Invalid PumpkinId:",
			pumpkinId
		)
		return nil
	end

	-- Create a lightweight Roblox Tool.
	--
	-- Purse already understands Tools,
	-- so this Tool will automatically appear
	-- in the Purse backpack/hotbar.
	local tool = Instance.new("Tool")

	-- Display name Purse will show.
	tool.Name = pumpkinInfo.DisplayName

	-- Pumpkins do not need a physical Handle
	-- just to appear in Purse.
	tool.RequiresHandle = false

	-- Prevent Roblox from dropping the proxy
	-- into the world with Backspace.
	tool.CanBeDropped = false

	-- Purse reads Tool.TextureId for the icon.
	tool.TextureId = pumpkinInfo.Icon or ""

	-- Mark this as one of our pumpkin proxy Tools.
	tool:SetAttribute(PUMPKIN_PROXY_ATTRIBUTE,true)

	-- Store which pumpkin TYPE this represents.
	tool:SetAttribute("PumpkinId",pumpkinId)

	-- Store current stack quantity.
	tool:SetAttribute("Quantity",quantity)

	-- Useful later when we customize Purse.
	tool:SetAttribute("MoneyPerSecond",pumpkinInfo.MoneyPerSecond or 0)

	-- Put it into Roblox's Backpack.
	--
	-- Purse is already listening for Tools added
	-- here and should create a slot automatically.
	local backpack = player:WaitForChild("Backpack")

	tool.Parent = backpack

	return tool

end

--==================================================
-- UPDATE ALL PUMPKIN PROXY TOOLS
--==================================================
function PumpkinPurseAdapter.RefreshPlayer(player)
	--==================================================
	-- COUNT OWNED PUMPKIN TYPES
	--==================================================
	local inventory = PumpkinInventoryService.GetInventory(player)

	if not inventory then
		return false,
			"DataNotLoaded"
	end

	local counts = {}

	for _, pumpkin in ipairs(inventory) do
		local pumpkinId = pumpkin.PumpkinId
		counts[pumpkinId] = (counts[pumpkinId] or 0) + 1
	end

	--==================================================
	-- CREATE OR UPDATE PROXY TOOLS
	--==================================================

	for pumpkinId, quantity in pairs(
		counts
		) do

		local tool =
			FindPumpkinTool(
				player,
				pumpkinId
			)


		-- No Tool yet for this pumpkin type.
		if not tool then

			tool =
				CreatePumpkinTool(
					player,
					pumpkinId,
					quantity
				)


			-- Tool already exists.
		else

			local pumpkinInfo =
				PumpkinConfig.GetPumpkin(
					pumpkinId
				)

			if pumpkinInfo then
				tool.Name = pumpkinInfo.DisplayName
				tool.TextureId = pumpkinInfo.Icon or ""
				tool:SetAttribute("Quantity",quantity)
				tool:SetAttribute("MoneyPerSecond",pumpkinInfo.MoneyPerSecond or 0)
			end
		end
	end

	--==================================================
	-- REMOVE TOOLS FOR TYPES NO LONGER OWNED
	--==================================================
	local function CheckContainer(container)
		if not container then
			return
		end

		for _, child in ipairs(
			container:GetChildren()
			) do

			if child:IsA("Tool")
				and child:GetAttribute(
					PUMPKIN_PROXY_ATTRIBUTE
				) == true then

				local pumpkinId =
					child:GetAttribute(
						"PumpkinId"
					)

				-- Player owns zero of this type now.
				if not counts[pumpkinId] then
					child:Destroy()
				end
			end
		end
	end

	CheckContainer(player:FindFirstChild("Backpack"))

	CheckContainer(player.Character)
	return true
end

--==================================================
-- RETURN MODULE
--==================================================
return PumpkinPurseAdapter
