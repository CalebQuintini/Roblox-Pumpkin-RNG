--==================================================
-- SERVICES
--==================================================

local Players =
	game:GetService(
		"Players"
	)


local PhysicsService =
	game:GetService(
		"PhysicsService"
	)


--==================================================
-- SETTINGS
--==================================================

-- Roblox's usual default is 16.
--
-- 18 gives players a small movement increase
-- without making them feel extremely fast.

local PLAYER_WALK_SPEED =
	18


-- Collision group used by every player character.

local PLAYER_COLLISION_GROUP =
	"Players"


--==================================================
-- CREATE PLAYER COLLISION GROUP
--==================================================

-- RegisterCollisionGroup will error if the group
-- already exists, so we check first.

local groupAlreadyExists =
	false


for _, groupInfo in ipairs(
	PhysicsService:GetRegisteredCollisionGroups()
	) do

	if groupInfo.name
		== PLAYER_COLLISION_GROUP then

		groupAlreadyExists =
			true


		break

	end

end


if not groupAlreadyExists then

	PhysicsService:RegisterCollisionGroup(
		PLAYER_COLLISION_GROUP
	)

end


--==================================================
-- DISABLE PLAYER VS PLAYER COLLISION
--==================================================

-- Players in the "Players" collision group
-- will not collide with other objects in the
-- same collision group.
--
-- They will still collide with:
--
-- floors
-- walls
-- plots
-- barriers
-- pumpkins
-- etc.

PhysicsService:CollisionGroupSetCollidable(
	PLAYER_COLLISION_GROUP,
	PLAYER_COLLISION_GROUP,
	false
)


--==================================================
-- SETUP CHARACTER PART
--==================================================

local function SetupCharacterPart(
	descendant
)

	if not descendant:IsA(
		"BasePart"
		) then

		return

	end


	--==================================================
	-- PLAYER COLLISION GROUP
	--==================================================

	descendant.CollisionGroup =
		PLAYER_COLLISION_GROUP


	--==================================================
	-- DISABLE PLAYER SHADOW
	--==================================================

	descendant.CastShadow =
		false

end


--==================================================
-- SETUP CHARACTER
--==================================================

local function SetupCharacter(
	character
)

	if not character then

		return

	end


	--==================================================
	-- HUMANOID
	--==================================================

	local humanoid =
		character:WaitForChild(
			"Humanoid"
		)


	humanoid.WalkSpeed =
		PLAYER_WALK_SPEED


	--==================================================
	-- EXISTING CHARACTER PARTS
	--==================================================

	for _, descendant in ipairs(
		character:GetDescendants()
		) do

		SetupCharacterPart(
			descendant
		)

	end


	--==================================================
	-- FUTURE CHARACTER PARTS
	--==================================================

	-- Accessories or other character parts can
	-- sometimes be added after the character appears.
	--
	-- This makes sure they also:
	--
	-- don't collide with players
	-- don't cast shadows

	character.DescendantAdded:Connect(
		function(descendant)

			SetupCharacterPart(
				descendant
			)

		end
	)

end


--==================================================
-- SETUP PLAYER
--==================================================

local function SetupPlayer(
	player
)

	player.CharacterAdded:Connect(
		function(character)

			SetupCharacter(
				character
			)

		end
	)


	-- Character may already exist by the time
	-- this script connects.

	if player.Character then

		task.defer(
			SetupCharacter,
			player.Character
		)

	end

end


--==================================================
-- EXISTING PLAYERS
--==================================================

for _, player in ipairs(
	Players:GetPlayers()
	) do

	SetupPlayer(
		player
	)

end


--==================================================
-- FUTURE PLAYERS
--==================================================

Players.PlayerAdded:Connect(
	SetupPlayer
)


--==================================================
-- STARTED
--==================================================

print(
	"[GameSettingsServer] Started"
)
