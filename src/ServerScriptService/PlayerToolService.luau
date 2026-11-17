--==================================================
-- SERVICES
--==================================================

local ServerStorage =
	game:GetService(
		"ServerStorage"
	)


--==================================================
-- MODULE
--==================================================

local PlayerToolService =
	{}


--==================================================
-- REFERENCES
--==================================================

local toolTemplates =
	ServerStorage
	:WaitForChild(
		"ToolTemplates"
	)


-- The old BaseballBat template is no longer used.
--
-- Baseball Bat R15 now lives in StarterPack,
-- so Roblox automatically gives it to players.

local hammerTemplate =
	toolTemplates
	:WaitForChild(
		"Hammer"
	)


--==================================================
-- FIND TOOL
--==================================================

local function FindTool(
	player,
	toolName
)

	--==================================================
	-- CHECK BACKPACK
	--==================================================

	local backpack =
		player:FindFirstChild(
			"Backpack"
		)


	if backpack then

		local tool =
			backpack:FindFirstChild(
				toolName
			)


		if tool then

			return tool

		end

	end


	--==================================================
	-- CHECK CHARACTER
	--==================================================

	-- Equipped Tools are moved from Backpack
	-- into the player's Character.

	local character =
		player.Character


	if character then

		local tool =
			character:FindFirstChild(
				toolName
			)


		if tool then

			return tool

		end

	end


	return nil

end


--==================================================
-- GIVE HAMMER
--==================================================

local function GiveHammer(
	player
)

	-- Don't create another Hammer if the player
	-- already has one in their Backpack or Character.

	if FindTool(
		player,
		"Hammer"
		) then

		return

	end


	local backpack =
		player:WaitForChild(
			"Backpack"
		)


	local hammer =
		hammerTemplate:Clone()


	hammer.Parent =
		backpack

end


--==================================================
-- GIVE DEFAULT TOOLS
--==================================================

function PlayerToolService.GiveDefaultTools(
	player
)

	-- Baseball Bat R15 is NOT created here.
	--
	-- It lives inside StarterPack, so Roblox
	-- automatically gives it to the player's
	-- Backpack when they spawn.
	--
	-- This service only gives the Hammer.

	GiveHammer(
		player
	)

end


--==================================================
-- RETURN MODULE
--==================================================

return PlayerToolService
