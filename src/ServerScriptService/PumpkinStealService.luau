--==================================================
-- SERVICES
--==================================================

local HttpService =
	game:GetService(
		"HttpService"
	)


--==================================================
-- MODULE
--==================================================

local PumpkinStealService =
	{}


--==================================================
-- RUNTIME DATA
--==================================================

-- ReservedPumpkins:
--
-- [InstanceId] = reservation
--
-- This lets us quickly ask:
--
-- "Is this specific pumpkin currently being stolen?"

local ReservedPumpkins =
	{}


-- ActiveThefts:
--
-- [Player] = reservation
--
-- This lets us quickly ask:
--
-- "Is this player currently stealing something?"

local ActiveThefts =
	{}


--==================================================
-- CHECK IF PUMPKIN IS RESERVED
--==================================================

function PumpkinStealService.IsPumpkinReserved(
	instanceId
)

	if type(instanceId)
		~= "string"
		or instanceId == "" then

		return false

	end


	return ReservedPumpkins[instanceId] ~= nil

end


--==================================================
-- GET PUMPKIN RESERVATION
--==================================================

function PumpkinStealService.GetReservation(
	instanceId
)

	if type(instanceId)
		~= "string"
		or instanceId == "" then

		return nil

	end


	return ReservedPumpkins[instanceId]

end


--==================================================
-- CHECK IF PLAYER IS STEALING
--==================================================

function PumpkinStealService.IsStealing(
	player
)

	if not player then

		return false

	end


	return ActiveThefts[player] ~= nil

end


--==================================================
-- GET ACTIVE THEFT
--==================================================

function PumpkinStealService.GetActiveTheft(
	player
)

	if not player then

		return nil

	end


	return ActiveThefts[player]

end


--==================================================
-- APPLY RESERVED VISUAL STATE
--==================================================

local function ApplyReservedVisuals(
	reservation
)

	local pumpkinModel =
		reservation.PumpkinModel


	if not pumpkinModel
		or not pumpkinModel.Parent then

		return

	end


	--==================================================
	-- ORIGINAL TRANSPARENCY
	--==================================================

	reservation.OriginalTransparency =
		reservation.OriginalTransparency
		or {}


	--==================================================
	-- MAKE PUMPKIN SLIGHTLY TRANSPARENT
	--==================================================

	for _, descendant in ipairs(
		pumpkinModel:GetDescendants()
		) do

		if descendant:IsA(
			"BasePart"
			) then

			-- Store the EXACT original transparency.
			--
			-- This is important because different
			-- parts of a pumpkin may already use
			-- different transparency values.

			reservation.OriginalTransparency[descendant] =
				descendant.Transparency


			-- Make it visibly reserved.

			descendant.Transparency =
				math.clamp(
					descendant.Transparency
					+ 0.35,
					0,
					1
				)

		end

	end

end


--==================================================
-- RESTORE RESERVED VISUAL STATE
--==================================================

local function RestoreReservedVisuals(
	reservation
)

	if not reservation then

		return

	end


	local originalTransparency =
		reservation.OriginalTransparency


	if type(originalTransparency)
		~= "table" then

		return

	end


	for part, transparency in pairs(
		originalTransparency
		) do

		if part
			and part.Parent
			and part:IsA(
				"BasePart"
			) then

			part.Transparency =
				transparency

		end

	end

end


--==================================================
-- RESERVE PUMPKIN
--==================================================

function PumpkinStealService.ReservePumpkin(
	thief,
	victim,
	pumpkinModel,
	victimPlot,
	thiefPlot
)

	--==================================================
	-- VALIDATE PLAYERS
	--==================================================

	if not thief then

		return false,
			nil,
			"InvalidThief"

	end


	if not victim then

		return false,
			nil,
			"InvalidVictim"

	end


	if thief == victim then

		return false,
			nil,
			"CannotStealOwnPumpkin"

	end


	--==================================================
	-- THIEF ALREADY STEALING
	--==================================================

	if ActiveThefts[
		thief
		] then

		return false,
			nil,
			"AlreadyStealing"

	end


	--==================================================
	-- VALIDATE PUMPKIN MODEL
	--==================================================

	if not pumpkinModel
		or not pumpkinModel.Parent then

		return false,
			nil,
			"InvalidPumpkinModel"

	end


	--==================================================
	-- INSTANCE ID
	--==================================================

	local instanceId =
		pumpkinModel:GetAttribute(
			"InstanceId"
		)


	if type(instanceId)
		~= "string"
		or instanceId == "" then

		return false,
			nil,
			"InvalidInstanceId"

	end


	--==================================================
	-- PUMPKIN ID
	--==================================================

	local pumpkinId =
		pumpkinModel:GetAttribute(
			"PumpkinId"
		)


	if type(pumpkinId)
		~= "string"
		or pumpkinId == "" then

		return false,
			nil,
			"InvalidPumpkinId"

	end


	--==================================================
	-- ALREADY RESERVED
	--==================================================

	if ReservedPumpkins[
		instanceId
		] then

		return false,
			nil,
			"AlreadyReserved"

	end


	--==================================================
	-- CREATE RESERVATION
	--==================================================

	local reservation =
		{

			-- Unique ID for this theft attempt.
			--
			-- This is separate from the pumpkin's
			-- InstanceId.

			TheftId =
			HttpService:GenerateGUID(
				false
			),


			-- Pumpkin identity.

			InstanceId =
			instanceId,

			PumpkinId =
			pumpkinId,

			PumpkinModel =
			pumpkinModel,


			-- Players.

			Thief =
			thief,

			Victim =
			victim,


			-- Plot references.

			VictimPlot =
			victimPlot,

			ThiefPlot =
			thiefPlot,


			-- Exact original part transparency values.

			OriginalTransparency =
			{},


			-- Used by PumpkinStealServer so the
			-- same theft cannot complete twice.

			Completing =
			false,
		}


	--==================================================
	-- STORE RESERVATION
	--==================================================

	ReservedPumpkins[instanceId] =
		reservation


	ActiveThefts[thief] =
		reservation


	--==================================================
	-- APPLY RESERVED APPEARANCE
	--==================================================

	ApplyReservedVisuals(
		reservation
	)


	--==================================================
	-- DEBUG
	--==================================================

	print(
		"[PumpkinStealService]",
		thief.Name,
		"reserved",
		pumpkinId,
		"from",
		victim.Name,
		"InstanceId:",
		instanceId,
		"TheftId:",
		reservation.TheftId
	)


	--==================================================
	-- RETURN
	--==================================================

	-- IMPORTANT:
	--
	-- We return BOTH:
	--
	-- success boolean
	-- reservation table
	--
	-- PumpkinStealServer should use:
	--
	-- local success, reservation, reason =
	--     ReservePumpkin(...)
	--
	-- NOT:
	--
	-- local reservation =
	--     ReservePumpkin(...)

	return true,
		reservation,
		"Reserved"

end


--==================================================
-- RELEASE PUMPKIN
--==================================================

function PumpkinStealService.ReleasePumpkin(
	instanceId
)

	if type(instanceId)
		~= "string"
		or instanceId == "" then

		return false,
			"InvalidInstanceId"

	end


	--==================================================
	-- FIND RESERVATION
	--==================================================

	local reservation = ReservedPumpkins[instanceId]


	if not reservation then

		return false,
			"NotReserved"

	end


	--==================================================
	-- RESTORE VISUALS
	--==================================================

	RestoreReservedVisuals(
		reservation
	)


	--==================================================
	-- CLEAR PUMPKIN RESERVATION
	--==================================================

	ReservedPumpkins[instanceId] = nil


	--==================================================
	-- CLEAR THIEF ACTIVE THEFT
	--==================================================

	local thief =
		reservation.Thief


	if thief
		and ActiveThefts[
		thief
		] == reservation then

		ActiveThefts[thief] = nil

	end


	--==================================================
	-- DEBUG
	--==================================================

	print(
		"[PumpkinStealService] Released reservation",
		"InstanceId:",
		instanceId,
		"TheftId:",
		reservation.TheftId
	)


	return true,
		reservation

end


--==================================================
-- CANCEL THEFT
--==================================================

function PumpkinStealService.CancelTheft(
	thief
)

	if not thief then

		return false,
			"InvalidThief"

	end


	--==================================================
	-- FIND ACTIVE THEFT
	--==================================================

	local reservation = ActiveThefts[thief]


	if not reservation then

		return false,
			"NotStealing"

	end


	local instanceId =
		reservation.InstanceId


	if type(instanceId)
		~= "string"
		or instanceId == "" then

		-- Safety cleanup if somehow the reservation
		-- became malformed.

		ActiveThefts[thief] = nil


		return false,
			"InvalidReservation"

	end


	--==================================================
	-- RELEASE
	--==================================================

	local success,
		result =
		PumpkinStealService.ReleasePumpkin(
			instanceId
		)


	if not success then

		return false,
			result

	end


	return true,
		result

end


--==================================================
-- CLEAR PLAYER
--==================================================

function PumpkinStealService.ClearPlayer(
	player
)

	if not player then

		return

	end


	--==================================================
	-- PLAYER IS A THIEF
	--==================================================

	local activeTheft = ActiveThefts[player]


	if activeTheft then

		local instanceId =
			activeTheft.InstanceId


		if type(instanceId)
			== "string" then

			PumpkinStealService.ReleasePumpkin(
				instanceId
			)

		else

			ActiveThefts[player] = nil

		end

	end


	--==================================================
	-- PLAYER MAY BE A VICTIM
	--==================================================

	-- Make a separate list first.
	--
	-- We should not modify ReservedPumpkins while
	-- directly iterating through the same table.

	local reservationsToRelease =
		{}


	for instanceId, reservation in pairs(
		ReservedPumpkins
		) do

		if reservation.Victim
			== player then

			table.insert(
				reservationsToRelease,
				instanceId
			)

		end

	end


	for _, instanceId in ipairs(
		reservationsToRelease
		) do

		PumpkinStealService.ReleasePumpkin(
			instanceId
		)

	end

end


--==================================================
-- GET ALL ACTIVE THEFTS
--==================================================

-- Mostly useful for debugging.
--
-- Do not modify the returned table directly.

function PumpkinStealService.GetAllActiveThefts()

	return ActiveThefts

end


--==================================================
-- GET ALL RESERVED PUMPKINS
--==================================================

-- Mostly useful for debugging.
--
-- Do not modify the returned table directly.

function PumpkinStealService.GetAllReservedPumpkins()

	return ReservedPumpkins

end


--==================================================
-- RETURN MODULE
--==================================================

return PumpkinStealService
