local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NeedsConfig = require(ReplicatedStorage.Configs.NeedsConfig)

-- Convert task keys into an indexed array for fast random picking
local taskKeys = {}
for taskName in pairs(NeedsConfig.Tasks) do
	table.insert(taskKeys, taskName)
end

local function pickRandomNeed()
	local randomIndex = math.random(1, #taskKeys)
	return taskKeys[randomIndex]
end

local function startNeedsCycle(petModel)
	task.spawn(function()
		while petModel and petModel.Parent do
			-- 1. Wait until the pet is completely idle / satisfied
			local currentNeed = petModel:GetAttribute("CurrentNeed")
			while currentNeed and currentNeed ~= "" do
				-- Wait until the attribute changes back to empty
				petModel:GetAttributeChangedSignal("CurrentNeed"):Wait()
				currentNeed = petModel:GetAttribute("CurrentNeed")
			end

			-- 2. NOW start the cooldown before picking the next need
			local cooldown = math.random(NeedsConfig.IntervalRange.Min, NeedsConfig.IntervalRange.Max)
			task.wait(cooldown)

			-- 3. Assign the new need if the pet still exists
			if petModel and petModel.Parent then
				local chosenNeed = pickRandomNeed()
				petModel:SetAttribute("CurrentNeed", chosenNeed)
				print(petModel.Name .. " now needs: " .. chosenNeed)
			end
		end
	end)
end

-- Export function for whenever a pet is spawned into Workspace
workspace.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("Model") and descendant.Name:match("_Pet$") then
		-- Default attribute state
		descendant:SetAttribute("CurrentNeed", "")
		startNeedsCycle(descendant)
	end
end)