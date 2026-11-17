local RarityConfig = {}

RarityConfig.Rarities = {
	Common = {
		Id = "Common",
		DisplayName = "Common",
		Order = 1,
		Color = Color3.fromRGB(
			200,
			200,
			200
		),
		MinOneIn = 1,
		MaxOneIn = 10,
	},

	Uncommon = {
		Id = "Uncommon",
		DisplayName = "Uncommon",
		Order = 2,
		Color = Color3.fromRGB(
			85,
			255,
			127
		),
		MinOneIn = 10,
		MaxOneIn = 50,
	},

	Rare = {
		Id = "Rare",
		DisplayName = "Rare",
		Order = 3,
		Color = Color3.fromRGB(
			85,
			170,
			255
		),
		MinOneIn = 50,
		MaxOneIn = 500,
	},

	Epic = {
		Id = "Epic",
		DisplayName = "Epic",
		Order = 4,
		Color = Color3.fromRGB(
			170,
			85,
			255
		),
		MinOneIn = 500,
		MaxOneIn = 5000,
	},

	Legendary = {
		Id = "Legendary",
		DisplayName = "Legendary",
		Order = 5,
		Color = Color3.fromRGB(
			255,
			170,
			0
		),
		MinOneIn = 5000,
		MaxOneIn = 100000,
	},

	Mythic = {
		Id = "Mythic",
		DisplayName = "Mythic",
		Order = 6,
		Color = Color3.fromRGB(
			255,
			85,
			127
		),
		MinOneIn = 100000,
		MaxOneIn = math.huge,
	},
}

--==================================================
-- GET RARITY
--==================================================
function RarityConfig.GetRarity(rarityId)
	return RarityConfig.Rarities[rarityId]
end
--==================================================
-- CHECK IF RARITY EXISTS
--==================================================
function RarityConfig.IsValidRarity(rarityId)
	return RarityConfig.Rarities[rarityId] ~= nil
end

return RarityConfig
