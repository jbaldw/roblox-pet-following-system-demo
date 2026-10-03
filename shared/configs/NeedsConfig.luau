local NeedsConfig = {
	-- Minimum and maximum time (in seconds) between new needs appearing
	IntervalRange = { Min = 5, Max = 5 },

	-- Definitions of each available need
	Tasks = {
		Hungry = {
			DisplayName = "Hungry",
			RewardCoins = 15,
			IconId = "rbxassetid://862675601", -- Replace with your decal asset ID
			StationTag = "FoodBowl",
		},
		Sleepy = {
			DisplayName = "Sleepy",
			RewardCoins = 20,
			IconId = "rbxassetid://259262109",
			StationTag = "PetBed",
		},
		Dirty = {
			DisplayName = "Dirty",
			RewardCoins = 15,
			IconId = "rbxassetid://219777033",
			StationTag = "Bathtub",
		},
	}
}

return NeedsConfig