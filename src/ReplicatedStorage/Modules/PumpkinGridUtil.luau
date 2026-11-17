--==================================================
-- MODULE
--==================================================

local PumpkinGridUtil = {}


--==================================================
-- GET ROTATED GRID SIZE
--==================================================

function PumpkinGridUtil.GetRotatedGridSize(
	gridWidth,
	gridDepth,
	rotation
)

	rotation =
		rotation % 360


	-- A 90° or 270° rotation swaps
	-- width and depth.
	if rotation == 90
		or rotation == 270 then

		return gridDepth,
			gridWidth

	end


	return gridWidth,
		gridDepth

end


--==================================================
-- GET FLOOR GRID SIZE
--==================================================

function PumpkinGridUtil.GetFloorGridSize(
	plotFloor,
	cellSize
)

	local columns =
		math.floor(
			plotFloor.Size.X
			/ cellSize
		)


	local rows =
		math.floor(
			plotFloor.Size.Z
			/ cellSize
		)


	return columns,
		rows

end


--==================================================
-- WORLD POSITION -> GRID POSITION
--==================================================

function PumpkinGridUtil.WorldPointToGrid(
	plotFloor,
	worldPosition,
	footprintWidth,
	footprintDepth,
	cellSize
)

	-- Convert the world point into the
	-- PlotFloor's local coordinate system.
	--
	-- This is important because plots can
	-- be rotated differently in the world.
	local localPosition =
		plotFloor.CFrame
		:PointToObjectSpace(
			worldPosition
		)


	-- Convert the desired footprint center
	-- into the bottom-left/start grid cell.
	local gridXFloat =
		(
			localPosition.X
			+ plotFloor.Size.X / 2
		)
		/ cellSize
	- footprintWidth / 2
		+ 1


	local gridZFloat =
		(
			localPosition.Z
			+ plotFloor.Size.Z / 2
		)
		/ cellSize
	- footprintDepth / 2
		+ 1


	-- Round to the nearest starting grid cell.
	local gridX =
		math.floor(
			gridXFloat + 0.5
		)


	local gridZ =
		math.floor(
			gridZFloat + 0.5
		)


	return gridX,
		gridZ

end


--==================================================
-- CHECK IF FOOTPRINT IS INSIDE FLOOR
--==================================================

function PumpkinGridUtil.IsInsideGrid(
	plotFloor,
	gridX,
	gridZ,
	footprintWidth,
	footprintDepth,
	cellSize
)

	local columns,
		rows =
		PumpkinGridUtil
		.GetFloorGridSize(
			plotFloor,
			cellSize
		)


	-- Start cell cannot be below 1.
	if gridX < 1
		or gridZ < 1 then

		return false

	end


	-- Calculate final occupied cells.
	local endX =
		gridX
		+ footprintWidth
	- 1


	local endZ =
		gridZ
		+ footprintDepth
	- 1


	if endX > columns
		or endZ > rows then

		return false

	end


	return true

end


--==================================================
-- GET PLACEMENT SURFACE CFRAME
--==================================================

function PumpkinGridUtil.GetPlacementSurfaceCFrame(
	plotFloor,
	gridX,
	gridZ,
	footprintWidth,
	footprintDepth,
	rotation,
	cellSize
)

	-- Calculate center of the occupied
	-- cells in PlotFloor local coordinates.
	local localX =
		-plotFloor.Size.X / 2
		+ (
			gridX - 1
			+ footprintWidth / 2
		)
		* cellSize


	local localZ =
		-plotFloor.Size.Z / 2
		+ (
			gridZ - 1
			+ footprintDepth / 2
		)
		* cellSize


	-- Put the point on the TOP surface
	-- of PlotFloor.
	local surfaceCFrame =
		plotFloor.CFrame
		* CFrame.new(
			localX,
			plotFloor.Size.Y / 2,
			localZ
		)


	-- Apply rotation relative to the plot.
	surfaceCFrame =
		surfaceCFrame
		* CFrame.Angles(
			0,
			math.rad(rotation),
			0
		)


	return surfaceCFrame

end


--==================================================
-- ALIGN MODEL BOTTOM TO FLOOR
--==================================================

function PumpkinGridUtil.AlignModelToSurface(
	model,
	surfaceCFrame
)

	-- Start by putting the model pivot on
	-- the placement position.
	model:PivotTo(
		surfaceCFrame
	)


	-- Find its actual rendered bounds.
	local boundingCFrame,
		boundingSize =
		model:GetBoundingBox()


	local up =
		surfaceCFrame.UpVector


	-- Approximate the bottom of the model.
	--
	-- Our pumpkins only rotate around Y,
	-- so this lines up with the plot's UpVector.
	local bottomPosition =
		boundingCFrame.Position
	- up
		* (
			boundingSize.Y / 2
		)


	-- Measure how far the bottom currently is
	-- from the PlotFloor surface.
	local distance =
		(
			surfaceCFrame.Position
			- bottomPosition
		):Dot(up)


	-- Move the entire model upward/downward
	-- until its bottom rests on PlotFloor.
	local translation =
		up * distance


	model:PivotTo(
		CFrame.new(translation)
			* model:GetPivot()
	)

end


--==================================================
-- RECTANGLE OVERLAP
--==================================================

function PumpkinGridUtil.RectanglesOverlap(
	ax,
	az,
	aw,
	ad,
	bx,
	bz,
	bw,
	bd
)

	local aEndX =
		ax + aw - 1

	local aEndZ =
		az + ad - 1


	local bEndX =
		bx + bw - 1

	local bEndZ =
		bz + bd - 1


	return not (
		aEndX < bx
			or bEndX < ax
			or aEndZ < bz
			or bEndZ < az
	)

end


--==================================================
-- RETURN MODULE
--==================================================

return PumpkinGridUtil
