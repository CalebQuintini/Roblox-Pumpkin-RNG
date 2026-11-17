--==================================================
-- NUMBER FORMATTER
--==================================================

local NumberFormatter = {}


--==================================================
-- ABBREVIATIONS
--==================================================

-- Every suffix represents another group of
-- 3 zeroes.
--
-- 1,000 = K
-- 1,000,000 = M
-- 1,000,000,000 = B
--
-- This list goes far beyond what most games
-- will ever realistically need.

local SUFFIXES = {
	"",
	"K",
	"M",
	"B",
	"T",

	"Qa", -- Quadrillion
	"Qi", -- Quintillion
	"Sx", -- Sextillion
	"Sp", -- Septillion
	"Oc", -- Octillion
	"No", -- Nonillion
	"Dc", -- Decillion

	"Ud",
	"Dd",
	"Td",
	"Qad",
	"Qid",
	"Sxd",
	"Spd",
	"Ocd",
	"Nod",
	"Vg",

	"Uvg",
	"Dvg",
	"Tvg",
	"Qavg",
	"Qivg",
	"Sxvg",
	"Spvg",
	"Ocvg",
	"Novg",
	"Tg",

	"Utg",
	"Dtg",
	"Ttg",
	"Qatg",
	"Qitg",
	"Sxtg",
	"Sptg",
	"Octg",
	"Notg",
	"Qag",

	"Uqag",
	"Dqag",
	"Tqag",
	"Qaqag",
	"Qiqag",
	"Sxqag",
	"Spqag",
	"Ocqag",
	"Noqag",
	"Qig",

	"Uqig",
	"Dqig",
	"Tqig",
	"Qaqig",
	"Qiqig",
	"Sxqig",
	"Spqig",
	"Ocqig",
	"Noqig",
	"Sxg",

	"Usxg",
	"Dsxg",
	"Tsxg",
	"Qasxg",
	"Qisxg",
	"Sxsxg",
	"Spsxg",
	"Ocsxg",
	"Nosxg",
	"Spg",

	"Uspg",
	"Dspg",
	"Tspg",
	"Qaspg",
	"Qispg",
	"Sxspg",
	"Spspg",
	"Ocspg",
	"Nospg",
	"Ocg",

	"Uocg",
	"Docg",
	"Tocg",
	"Qaocg",
	"Qiocg",
	"Sxocg",
	"Spocg",
	"Ococg",
	"Noocg",
	"Nog",

	"Unog",
	"Dnog",
	"Tnog",
	"Qanog",
	"Qinog",
	"Sxnog",
	"Spnog",
	"Ocnog",
	"Nonog",

	"Ce", -- Centillion (10^303)
}


--==================================================
-- REMOVE UNNECESSARY ZEROES
--==================================================

local function CleanNumberText(text)

	-- 1.00 -> 1
	-- 1.50 -> 1.5

	text =
		text:gsub(
			"(%..-)0+$",
			"%1"
		)


	text =
		text:gsub(
			"%.$",
			""
		)


	return text

end


--==================================================
-- FORMAT MONEY
--==================================================

function NumberFormatter.FormatMoney(
	amount
)

	if type(amount) ~= "number" then

		return "0"

	end


	--==================================================
	-- BAD / INVALID NUMBER
	--==================================================

	if amount ~= amount then

		return "MAX"

	end


	if amount == math.huge then

		return "MAX"

	end


	if amount == -math.huge then

		return "-MAX"

	end


	--==================================================
	-- NEGATIVE MONEY
	--==================================================

	local negative =
		amount < 0


	amount =
		math.abs(amount)


	--==================================================
	-- SMALL NUMBERS
	--==================================================

	if amount < 1000 then

		local value =
			math.floor(amount)


		if negative then

			return "-"
				.. tostring(value)

		end


		return tostring(value)

	end


	--==================================================
	-- FIND ABBREVIATION GROUP
	--==================================================

	local group =
		math.floor(
			math.log10(amount) / 3
		)


	--==================================================
	-- BEYOND OUR ABBREVIATION TABLE
	--==================================================

	if group >= #SUFFIXES then

		return "MAX"

	end


	local divisor =
		10 ^ (group * 3)


	local shortened =
		amount / divisor


	--==================================================
	-- DECIMAL PRECISION
	--==================================================

	local formatted


	if shortened >= 100 then

		formatted =
			string.format(
				"%.0f",
				shortened
			)


	elseif shortened >= 10 then

		formatted =
			string.format(
				"%.1f",
				shortened
			)


	else

		formatted =
			string.format(
				"%.2f",
				shortened
			)

	end


	formatted =
		CleanNumberText(
			formatted
		)


	local result =
		formatted
		.. SUFFIXES[group + 1]


	if negative then

		result =
			"-"
			.. result

	end


	return result

end


--==================================================
-- FORMAT LUCK
--==================================================

function NumberFormatter.FormatLuck(
	multiplier
)

	if type(multiplier) ~= "number" then

		return "x1"

	end


	-- Examples:
	--
	-- 1    -> x1
	-- 1.1  -> x1.1
	-- 2.6  -> x2.6
	-- 10   -> x10
	-- 10.5 -> x10.5

	local text =
		string.format(
			"%.2f",
			multiplier
		)


	text =
		CleanNumberText(
			text
		)


	return "x"
		.. text

end

--==================================================
-- FORMAT MONEY WITH DOLLAR SIGN
--==================================================

function NumberFormatter.FormatMoneyWithDollar(
	amount
)

	return "$"
		.. NumberFormatter.FormatMoney(
			amount
		)

end


return NumberFormatter
