--==================================================
-- SERVICES
--==================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")


--==================================================
-- GUI REFERENCES
--==================================================
local gui = script.Parent
local currencyContainer = gui:WaitForChild("CurrencyContainer")
local luckResourceImage = currencyContainer:WaitForChild("LuckResourceImage")
local luckTextLabel = luckResourceImage:WaitForChild("LuckTextLabel")
local dollarResourceImage = currencyContainer:WaitForChild("DollarResourceImage")
local dollarTextLabel = dollarResourceImage:WaitForChild("DollarTextLabel")

--==================================================
-- MODULES
--==================================================

local NumberFormatter =
	require(
		ReplicatedStorage
		:WaitForChild(
			"Modules"
		)
		:WaitForChild(
			"NumberFormatter"
		)
	)


--==================================================
-- REMOTES
--==================================================

local Remotes =
	ReplicatedStorage
	:WaitForChild(
		"Remotes"
	)


local CurrencyUpdate =
	Remotes:WaitForChild(
		"CurrencyUpdate"
	)


local GetCurrencyState =
	Remotes:WaitForChild(
		"GetCurrencyState"
	)


--==================================================
-- UPDATE MONEY
--==================================================

local function UpdateMoney(
	dollars
)

	-- Safety fallback.
	if type(dollars)
		~= "number" then

		dollars =
			0

	end


	dollarTextLabel.Text =
		NumberFormatter.FormatMoney(
			dollars
		)

end


--==================================================
-- UPDATE LUCK
--==================================================

local function UpdateLuck(
	luckMultiplier
)

	-- Safety fallback.
	if type(luckMultiplier)
		~= "number" then

		luckMultiplier =
			1

	end


	luckTextLabel.Text =
		NumberFormatter.FormatLuck(
			luckMultiplier
		)

end


--==================================================
-- UPDATE BOTH CURRENCIES
--==================================================

local function UpdateCurrencyUI(
	dollars,
	luckMultiplier
)

	UpdateMoney(
		dollars
	)


	UpdateLuck(
		luckMultiplier
	)

end


--==================================================
-- RECEIVE CURRENCY UPDATE FROM SERVER
--==================================================

CurrencyUpdate.OnClientEvent:Connect(
	function(
		dollars,
		luckMultiplier
	)

		UpdateCurrencyUI(
			dollars,
			luckMultiplier
		)

	end
)


--==================================================
-- DEFAULT DISPLAY
--==================================================

-- These are temporary values shown before
-- the server sends the player's real data.

dollarTextLabel.Text =
	"$0"


luckTextLabel.Text =
	"x1"


--==================================================
-- REQUEST INITIAL PLAYER CURRENCY
--==================================================

-- Ask the server for the player's current
-- saved Dollars and Luck when the GUI loads.

GetCurrencyState:FireServer()
