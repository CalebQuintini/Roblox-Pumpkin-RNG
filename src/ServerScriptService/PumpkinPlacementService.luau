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

local PumpkinConfig =
	require(
		ReplicatedStorage
		:WaitForChild("Config")
		:WaitForChild("PumpkinConfig")
	)


local GameConfig =
	require(
		ReplicatedStorage
		:WaitForChild("Config")
		:WaitForChild("GameConfig")
	)


local PumpkinGridUtil =
	require(
		ReplicatedStorage
		:WaitForChild("Modules")
		:WaitForChild("PumpkinGridUtil")
	)


local PlotService =
	require(
		script.Parent
		:WaitForChild("PlotService")
	)


local PlayerDataService =
	require(
		script.Parent
		:WaitForChild("PlayerDataService")
	)

local PumpkinStealService =
	require(
		script.Parent
		:WaitForChild("PumpkinStealService")
	)


--==================================================
-- REFERENCES
--==================================================

local PumpkinModels =
	ReplicatedStorage
	:WaitForChild(
		"PumpkinModels"
	)


--==================================================
-- MODULE
--==================================================

local PumpkinPlacementService = {}


--==================================================
-- VALID ROTATIONS
--==================================================

local VALID_ROTATIONS = {

	[0] = true,

	[90] = true,

	[180] = true,

	[270] = true,
}


--==================================================
-- GET ROTATED GRID SIZE
--==================================================

function PumpkinPlacementService
	.GetRotatedGridSize(
		pumpkinId,
		rotation
	)

	local pumpkinInfo =
		PumpkinConfig.GetPumpkin(
			pumpkinId
		)


	if not pumpkinInfo then

		return nil

	end


	return PumpkinGridUtil
		.GetRotatedGridSize(
			pumpkinInfo.GridWidth,
			pumpkinInfo.GridDepth,
			rotation
		)

end


--==================================================
-- CHECK OCCUPANCY
--==================================================

function PumpkinPlacementService
	.IsAreaOccupied(
		player,
		pumpkinId,
		gridX,
		gridZ,
		rotation,
		ignoreInstanceId
	)

	local data =
		PlayerDataService.GetData(
			player
		)


	if not data then

		return true

	end


	local pumpkinInfo =
		PumpkinConfig.GetPumpkin(
			pumpkinId
		)


	if not pumpkinInfo then

		return true

	end


	local width,
		depth =
		PumpkinGridUtil
		.GetRotatedGridSize(
			pumpkinInfo.GridWidth,
			pumpkinInfo.GridDepth,
			rotation
		)


	-- Check every already-placed pumpkin.
	for _, placed in ipairs(
		data.PlacedPumpkins
		) do

		-- Used when restoring an existing
		-- pumpkin so it doesn't collide
		-- with itself.
		if placed.InstanceId
			~= ignoreInstanceId then

			local placedInfo =
				PumpkinConfig.GetPumpkin(
					placed.PumpkinId
				)


			if placedInfo then

				local placedWidth,
					placedDepth =
					PumpkinGridUtil
					.GetRotatedGridSize(
						placedInfo.GridWidth,
						placedInfo.GridDepth,
						placed.Rotation
						or 0
					)


				if PumpkinGridUtil
					.RectanglesOverlap(
						gridX,
						gridZ,
						width,
						depth,

						placed.GridX,
						placed.GridZ,
						placedWidth,
						placedDepth
					) then

					return true

				end

			end

		end

	end


	return false

end


--==================================================
-- VALIDATE PLACEMENT
--==================================================

function PumpkinPlacementService
	.IsPlacementValid(
		player,
		pumpkinId,
		gridX,
		gridZ,
		rotation,
		ignoreInstanceId
	)

	--==================================================
	-- PLAYER CURRENTLY IN STEAL MODE
	--==================================================

	-- A player carrying a stolen pumpkin cannot
	-- place pumpkins from their inventory.

	if PumpkinStealService.IsStealing(
		player
		) then

		return false,
			"CurrentlyStealing"

	end


	--==================================================
	-- PLOT
	--==================================================

	local plotFloor =
		PlotService.GetPlotFloor(
			player
		)


	if not plotFloor then

		return false,
			"NoPlot"

	end


	--==================================================
	-- PUMPKIN TYPE
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
	-- GRID VALUES
	--==================================================

	if type(gridX) ~= "number"
		or type(gridZ) ~= "number"
		or gridX % 1 ~= 0
		or gridZ % 1 ~= 0 then

		return false,
			"InvalidGridPosition"

	end


	--==================================================
	-- ROTATION
	--==================================================

	if type(rotation) ~= "number"
		or not VALID_ROTATIONS[
		rotation
		] then

		return false,
			"InvalidRotation"

	end


	--==================================================
	-- FOOTPRINT
	--==================================================

	local width,
		depth =
		PumpkinGridUtil
		.GetRotatedGridSize(
			pumpkinInfo.GridWidth,
			pumpkinInfo.GridDepth,
			rotation
		)


	--==================================================
	-- BOUNDS
	--==================================================

	local inside =
		PumpkinGridUtil
		.IsInsideGrid(
			plotFloor,
			gridX,
			gridZ,
			width,
			depth,
			GameConfig.Grid.CellSize
		)


	if not inside then

		return false,
			"OutOfBounds"

	end


	--==================================================
	-- OCCUPANCY
	--==================================================

	if PumpkinPlacementService
		.IsAreaOccupied(
			player,
			pumpkinId,
			gridX,
			gridZ,
			rotation,
			ignoreInstanceId
		) then

		return false,
			"Occupied"

	end


	return true,
		"Valid"

end


--==================================================
-- GET PLACEMENT CFRAME
--==================================================

function PumpkinPlacementService
	.GetPlacementCFrame(
		player,
		pumpkinId,
		gridX,
		gridZ,
		rotation
	)

	local plotFloor =
		PlotService.GetPlotFloor(
			player
		)


	if not plotFloor then

		return nil

	end


	local pumpkinInfo =
		PumpkinConfig.GetPumpkin(
			pumpkinId
		)


	if not pumpkinInfo then

		return nil

	end


	local width,
		depth =
		PumpkinGridUtil
		.GetRotatedGridSize(
			pumpkinInfo.GridWidth,
			pumpkinInfo.GridDepth,
			rotation
		)


	return PumpkinGridUtil
		.GetPlacementSurfaceCFrame(
			plotFloor,
			gridX,
			gridZ,
			width,
			depth,
			rotation,
			GameConfig.Grid.CellSize
		)

end


--==================================================
-- RESTORE / SPAWN ONE PLACED PUMPKIN
--==================================================

function PumpkinPlacementService
	.RestorePumpkin(
		player,
		savedPumpkin
	)

	if type(savedPumpkin)
		~= "table" then

		return nil,
			"InvalidSavedPumpkin"

	end


	local valid,
		reason =
		PumpkinPlacementService
		.IsPlacementValid(
			player,
			savedPumpkin.PumpkinId,
			savedPumpkin.GridX,
			savedPumpkin.GridZ,
			savedPumpkin.Rotation
			or 0,
			savedPumpkin.InstanceId
		)


	if not valid then

		warn(
			"Could not restore pumpkin:",
			reason
		)

		return nil,
			reason

	end


	local pumpkinInfo =
		PumpkinConfig.GetPumpkin(
			savedPumpkin.PumpkinId
		)


	if not pumpkinInfo then

		return nil,
			"InvalidPumpkin"

	end


	local template =
		PumpkinModels
		:FindFirstChild(
			pumpkinInfo.ModelName
		)


	if not template then

		warn(
			"Missing pumpkin model:",
			pumpkinInfo.ModelName
		)

		return nil,
			"MissingModel"

	end


	local placedFolder =
		PlotService
		.GetPlacedPumpkinsFolder(
			player
		)


	if not placedFolder then

		return nil,
			"NoPlacedPumpkinsFolder"

	end


	-- Clone actual world model.
	local model =
		template:Clone()


	model.Name =
		savedPumpkin.InstanceId


	-- Runtime attributes make debugging and
	-- future interactions much easier.
	model:SetAttribute(
		"InstanceId",
		savedPumpkin.InstanceId
	)


	model:SetAttribute(
		"PumpkinId",
		savedPumpkin.PumpkinId
	)


	model:SetAttribute(
		"OwnerUserId",
		player.UserId
	)


	model:SetAttribute(
		"GridX",
		savedPumpkin.GridX
	)


	model:SetAttribute(
		"GridZ",
		savedPumpkin.GridZ
	)


	model:SetAttribute(
		"Rotation",
		savedPumpkin.Rotation
			or 0
	)


	-- Make placed pumpkin physical/anchored.
	for _, descendant in ipairs(
		model:GetDescendants()
		) do

		if descendant:IsA(
			"BasePart"
			) then

			descendant.Anchored =
				true

		end

	end


	model.Parent =
		placedFolder


	local surfaceCFrame =
		PumpkinPlacementService
		.GetPlacementCFrame(
			player,
			savedPumpkin.PumpkinId,
			savedPumpkin.GridX,
			savedPumpkin.GridZ,
			savedPumpkin.Rotation
			or 0
		)


	if not surfaceCFrame then

		model:Destroy()

		return nil,
			"CouldNotCalculateCFrame"

	end


	PumpkinGridUtil
		.AlignModelToSurface(
			model,
			surfaceCFrame
		)


	return model

end


--==================================================
-- RESTORE ALL SAVED PUMPKINS
--==================================================

function PumpkinPlacementService
	.RestoreSavedPumpkins(
		player,
		playerData
	)

	if not playerData then

		return

	end


	if type(
		playerData.PlacedPumpkins
		) ~= "table" then

		playerData.PlacedPumpkins =
			{}

	end


	local placedFolder =
		PlotService
		.GetPlacedPumpkinsFolder(
			player
		)


	if placedFolder then

		-- Prevent duplicate runtime models if
		-- restoration is called twice.
		placedFolder:ClearAllChildren()

	end


	for _, savedPumpkin in ipairs(
		playerData.PlacedPumpkins
		) do

		PumpkinPlacementService
			.RestorePumpkin(
				player,
				savedPumpkin
			)

	end

end


--==================================================
-- RETURN MODULE
--==================================================

return PumpkinPlacementService
