--==================================================
-- SERVICES
--==================================================

-- Workspace contains the physical game world.
local Workspace =
	game:GetService("Workspace")


--==================================================
-- REFERENCES
--==================================================

-- This is the folder containing Plot1 through Plot8.
local PlotsFolder =
	Workspace:WaitForChild("Plots")


--==================================================
-- MODULE
--==================================================

-- This table becomes our PlotService.
local PlotService = {}


--==================================================
-- RUNTIME TABLES
--==================================================

-- Stores:
--
-- Player -> Plot
--
-- Example:
--
-- PlayerPlots[player] = Plot3
local PlayerPlots = {}


-- Stores:
--
-- Plot -> Player
--
-- Example:
--
-- PlotOwners[Plot3] = player
local PlotOwners = {}


-- Contains all valid plots found under Workspace.Plots.
local AllPlots = {}


--==================================================
-- GET PLOT ID
--==================================================

local function GetPlotId(plot)

	-- Read the PlotId Attribute from the Folder.
	local plotId =
		plot:GetAttribute("PlotId")


	-- Return it.
	return plotId

end


--==================================================
-- GET / CREATE PLACED PUMPKINS FOLDER
--==================================================

local function GetOrCreatePlacedPumpkinsFolder(plot)

	-- Try to find an existing folder.
	local folder =
		plot:FindFirstChild("PlacedPumpkins")


	-- If it already exists...
	if folder then

		-- Return it.
		return folder

	end


	-- Otherwise create a new Folder.
	folder =
		Instance.new("Folder")


	-- Give it the expected name.
	folder.Name =
		"PlacedPumpkins"


	-- Put it inside this plot.
	folder.Parent =
		plot


	-- Return the new Folder.
	return folder

end


--==================================================
-- CREATE OWNER DISPLAY
--==================================================

local function GetOrCreateOwnerDisplay(
	plot
)

	--==================================================
	-- OWNER SIGN
	--==================================================

	local ownerSign =
		plot:FindFirstChild(
			"OwnerSign"
		)


	if not ownerSign then

		warn(
			plot.Name,
			"is missing an OwnerSign Part."
		)


		return nil

	end


	--==================================================
	-- BILLBOARD GUI
	--==================================================

	local billboard =
		ownerSign:FindFirstChild(
			"OwnerBillboard"
		)


	if not billboard then

		billboard =
			Instance.new(
				"BillboardGui"
			)


		billboard.Name =
			"OwnerBillboard"


		billboard.Parent =
			ownerSign

	end


	--==================================================
	-- BILLBOARD SIZE
	--==================================================

	-- SCALE ONLY.
	--
	-- Increased slightly from the previous size
	-- so the player's plot name appears larger.

	billboard.Size =
		UDim2.fromScale(
			7.5,
			3.5
		)


	-- Position above OwnerSign.
	--
	-- StudsOffset is world positioning and is
	-- separate from the GUI's Scale/Offset sizing.

	billboard.StudsOffset =
		Vector3.new(
			0,
			2.25,
			0
		)


	billboard.AlwaysOnTop =
		true


	billboard.MaxDistance =
		150


	--==================================================
	-- OWNER NAME LABEL
	--==================================================

	local label =
		billboard:FindFirstChild(
			"OwnerNameLabel"
		)


	if not label then

		label =
			Instance.new(
				"TextLabel"
			)


		label.Name =
			"OwnerNameLabel"


		label.Parent =
			billboard

	end


	--==================================================
	-- LABEL SIZE
	--==================================================

	-- SCALE ONLY.

	label.Size =
		UDim2.fromScale(
			1,
			1
		)


	label.Position =
		UDim2.fromScale(
			0,
			0
		)


	label.BackgroundTransparency =
		1


	--==================================================
	-- TEXT
	--==================================================

	label.TextScaled =
		true


	label.Font =
		Enum.Font.FredokaOne


	-- White text.

	label.TextColor3 =
		Color3.fromRGB(
			255,
			255,
			255
		)


	-- Black text stroke.

	label.TextStrokeColor3 =
		Color3.fromRGB(
			0,
			0,
			0
		)


	label.TextStrokeTransparency =
		0


	label.TextXAlignment =
		Enum.TextXAlignment.Center


	label.TextYAlignment =
		Enum.TextYAlignment.Center


	-- Empty plots show nothing.

	label.Text =
		""


	--==================================================
	-- EXTRA BLACK OUTLINE
	--==================================================

	-- UIStroke gives the text a slightly stronger
	-- readable outline than TextStroke alone.

	local textStroke =
		label:FindFirstChild(
			"OwnerNameStroke"
		)


	if not textStroke then

		textStroke =
			Instance.new(
				"UIStroke"
			)


		textStroke.Name =
			"OwnerNameStroke"


		textStroke.Parent =
			label

	end


	textStroke.Color =
		Color3.fromRGB(
			0,
			0,
			0
		)


	textStroke.Thickness =
		2


	textStroke.Transparency =
		0


	--==================================================
	-- TEXT SIZE LIMIT
	--==================================================

	local textSizeConstraint =
		label:FindFirstChild(
			"OwnerNameTextSizeConstraint"
		)


	if not textSizeConstraint then

		textSizeConstraint =
			Instance.new(
				"UITextSizeConstraint"
			)


		textSizeConstraint.Name =
			"OwnerNameTextSizeConstraint"


		textSizeConstraint.Parent =
			label

	end


	textSizeConstraint.MinTextSize =
		12


	textSizeConstraint.MaxTextSize =
		52


	return label

end


--==================================================
-- UPDATE OWNER DISPLAY
--==================================================

local function SetOwnerDisplay(
	plot,
	player
)

	-- Get the TextLabel.
	local label =
		GetOrCreateOwnerDisplay(
			plot
		)


	-- If there is no display...
	if not label then
		return
	end


	-- Show the player's DisplayName.
	--
	-- DisplayName is what players normally
	-- recognize visually in Roblox.
	label.Text = player.DisplayName --.. "'s Pumpkin Patch"

end


--==================================================
-- RESET OWNER DISPLAY
--==================================================

local function ResetOwnerDisplay(
	plot
)

	local label =
		GetOrCreateOwnerDisplay(
			plot
		)


	if not label then

		return

	end


	-- Empty plots display nothing.

	label.Text =
		""

end


--==================================================
-- CLEAR OWNER ATTRIBUTES
--==================================================

local function ClearOwnerAttributes(plot)

	-- 0 means nobody owns the plot.
	plot:SetAttribute(
		"OwnerUserId",
		0
	)


	-- Empty owner name.
	plot:SetAttribute(
		"OwnerName",
		""
	)


	-- Plot is available.
	plot:SetAttribute(
		"IsOccupied",
		false
	)

end


--==================================================
-- SET OWNER ATTRIBUTES
--==================================================

local function SetOwnerAttributes(
	plot,
	player
)

	-- Save the owner's UserId as a runtime Attribute.
	plot:SetAttribute(
		"OwnerUserId",
		player.UserId
	)


	-- Save the owner's username.
	plot:SetAttribute(
		"OwnerName",
		player.Name
	)


	-- Mark the plot as occupied.
	plot:SetAttribute(
		"IsOccupied",
		true
	)

end


--==================================================
-- CLEAR PHYSICAL PUMPKINS
--==================================================

local function ClearPlacedPumpkins(plot)

	-- Get the PlacedPumpkins Folder.
	local placedPumpkins =
		GetOrCreatePlacedPumpkinsFolder(
			plot
		)


	-- Go through every physical object inside it.
	for _, object in ipairs(
		placedPumpkins:GetChildren()
		) do

		-- Destroy the physical pumpkin.
		--
		-- IMPORTANT:
		-- This does NOT alter saved PlayerData.
		object:Destroy()

	end

end


--==================================================
-- INITIALIZE
--==================================================

function PlotService.Initialize()

	-- Empty the runtime plot list.
	table.clear(
		AllPlots
	)


	-- Go through Plot1 through Plot8.
	for _, plot in ipairs(
		PlotsFolder:GetChildren()
		) do

		-- You are using Folders for your plots.
		--
		-- We also allow Models in case this
		-- architecture changes later.
		if plot:IsA("Folder")
			or plot:IsA("Model") then

			-- Read the permanent PlotId.
			local plotId =
				GetPlotId(plot)


			-- If there is no PlotId...
			if not plotId then

				-- Warn about the mistake.
				warn(
					plot.Name,
					"is missing its PlotId Attribute."
				)

			else

				-- Add this plot to the runtime list.
				table.insert(
					AllPlots,
					plot
				)


				-- Nobody owns it yet.
				PlotOwners[plot] =
					nil


				-- Make sure PlacedPumpkins exists.
				GetOrCreatePlacedPumpkinsFolder(
					plot
				)


				-- Reset ownership information.
				ClearOwnerAttributes(
					plot
				)


				-- Reset owner sign.
				ResetOwnerDisplay(
					plot
				)


				-- Clear anything left inside
				-- PlacedPumpkins.
				ClearPlacedPumpkins(
					plot
				)

			end

		end

	end


	-- Sort plots using PlotId.
	table.sort(
		AllPlots,

		function(plotA, plotB)

			return GetPlotId(plotA)
				< GetPlotId(plotB)

		end
	)


	-- We expect exactly eight.
	if #AllPlots ~= 8 then

		warn(
			"PlotService expected 8 plots but found",
			#AllPlots
		)

	end


	print(
		"PlotService initialized with",
		#AllPlots,
		"plots."
	)

end


--==================================================
-- GET AVAILABLE PLOT
--==================================================

function PlotService.GetAvailablePlot()

	-- Check every plot.
	for _, plot in ipairs(
		AllPlots
		) do

		-- If nobody owns this plot...
		if PlotOwners[plot] == nil then

			-- Return it.
			return plot

		end

	end


	-- No available plots.
	return nil

end


--==================================================
-- ASSIGN PLOT
--==================================================

function PlotService.AssignPlot(player)

	-- Check if the player already owns a plot.
	local existingPlot =
		PlayerPlots[player]


	-- If they do, return it.
	if existingPlot then
		return existingPlot
	end


	-- Find an available plot.
	local plot =
		PlotService.GetAvailablePlot()


	-- If none exist...
	if not plot then

		warn(
			"No available plot for",
			player.Name
		)

		return nil

	end


	-- Store:
	--
	-- Player -> Plot
	PlayerPlots[player] =
		plot


	-- Store:
	--
	-- Plot -> Player
	PlotOwners[plot] =
		player


	-- Update Attributes.
	SetOwnerAttributes(
		plot,
		player
	)


	-- Update the owner's name sign.
	SetOwnerDisplay(
		plot,
		player
	)


	-- Find PlayerSpawn.
	local playerSpawn =
		plot:FindFirstChild(
			"PlayerSpawn"
		)


	-- Verify it's actually a SpawnLocation.
	if playerSpawn
		and playerSpawn:IsA("SpawnLocation") then

		-- Tell Roblox that this player's future
		-- respawns should happen here.
		player.RespawnLocation =
			playerSpawn

	else

		warn(
			plot.Name,
			"is missing PlayerSpawn SpawnLocation."
		)

	end


	print(
		player.Name,
		"was assigned",
		GetPlotId(plot)
	)


	return plot

end


--==================================================
-- GET PLAYER PLOT
--==================================================

function PlotService.GetPlayerPlot(player)

	return PlayerPlots[player]

end


--==================================================
-- GET PLOT OWNER
--==================================================

function PlotService.GetPlotOwner(plot)

	return PlotOwners[plot]

end


--==================================================
-- GET PLOT FLOOR
--==================================================

function PlotService.GetPlotFloor(player)

	-- Get the player's assigned plot.
	local plot =
		PlayerPlots[player]


	-- If they don't have one...
	if not plot then
		return nil
	end


	-- Find PlotFloor.
	local plotFloor =
		plot:FindFirstChild(
			"PlotFloor"
		)


	-- Make sure it's actually a BasePart.
	if not plotFloor
		or not plotFloor:IsA("BasePart") then

		warn(
			plot.Name,
			"is missing a valid PlotFloor."
		)

		return nil

	end


	-- Return the player's placement floor.
	return plotFloor

end


--==================================================
-- GET PLACED PUMPKINS FOLDER
--==================================================

function PlotService.GetPlacedPumpkinsFolder(
	player
)

	-- Find the player's plot.
	local plot =
		PlayerPlots[player]


	-- No plot means no folder.
	if not plot then
		return nil
	end


	-- Return the folder.
	return GetOrCreatePlacedPumpkinsFolder(
		plot
	)

end


--==================================================
-- TELEPORT PLAYER TO PLOT
--==================================================

function PlotService.TeleportPlayerToPlot(
	player,
	character
)

	-- Find their assigned plot.
	local plot =
		PlayerPlots[player]


	-- If they don't have one...
	if not plot then
		return
	end


	-- Find PlayerSpawn.
	local playerSpawn =
		plot:FindFirstChild(
			"PlayerSpawn"
		)


	-- Make sure it's a valid SpawnLocation.
	if not playerSpawn
		or not playerSpawn:IsA("SpawnLocation") then

		return

	end


	-- If no character was supplied,
	-- use the player's current character.
	character =
		character
		or player.Character


	-- If they don't currently have a character...
	if not character then
		return
	end


	-- Move the complete character slightly above
	-- the SpawnLocation.
	--
	-- The extra Y height helps avoid spawning
	-- partially inside the floor.
	character:PivotTo(
		playerSpawn.CFrame
			* CFrame.new(
				0,
				3,
				0
			)
	)

end


--==================================================
-- RELEASE PLOT
--==================================================

function PlotService.ReleasePlot(player)

	-- Find their current plot.
	local plot =
		PlayerPlots[player]


	-- No assigned plot means nothing to release.
	if not plot then
		return
	end


	-- Remember the ID for our debug message.
	local plotId =
		GetPlotId(plot)


	-- Remove physical pumpkins.
	ClearPlacedPumpkins(
		plot
	)


	-- Remove:
	--
	-- Plot -> Player
	PlotOwners[plot] =
		nil


	-- Remove:
	--
	-- Player -> Plot
	PlayerPlots[player] =
		nil


	-- Reset Attributes.
	ClearOwnerAttributes(
		plot
	)


	-- Reset sign.
	ResetOwnerDisplay(
		plot
	)


	-- This SpawnLocation should no longer
	-- belong to the leaving player.
	player.RespawnLocation =
		nil


	print(
		player.Name,
		"released",
		plotId
	)

end


--==================================================
-- RETURN MODULE
--==================================================

return PlotService
