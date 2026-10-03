local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local catTemplate = ReplicatedStorage:WaitForChild("Pets"):WaitForChild("Cat")

local START_DISTANCE = 13
local STOP_DISTANCE = 7

local function spawnPetForPlayer(player, character)
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	local humanoid = character:WaitForChild("Humanoid")

	local pet = catTemplate:Clone()
	pet.Name = player.Name .. "_Pet"

	local primaryPart = pet.PrimaryPart
	if not primaryPart then
		warn("Please assign a PrimaryPart to your Cat model!")
		return
	end

	-- Spawn behind the player
	pet:PivotTo(humanoidRootPart.CFrame * CFrame.new(0, 0, 5))
	pet.Parent = workspace

	-- Attachment on the cat
	local petAttachment = Instance.new("Attachment")
	petAttachment.Name = "PetRootAttachment"
	petAttachment.Parent = primaryPart

	-- AlignPosition in OneAttachment mode: aims toward a world coordinate
	local alignPosition = Instance.new("AlignPosition")
	alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
	alignPosition.Attachment0 = petAttachment
	alignPosition.MaxForce = 30000
	alignPosition.Responsiveness = 15   -- Lower value = looser, smoother follow
	alignPosition.Position = primaryPart.Position
	alignPosition.Parent = primaryPart

	-- AlignOrientation in OneAttachment mode: aims toward a target rotation
	local alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.Attachment0 = petAttachment
	alignOrientation.MaxTorque = 30000
	alignOrientation.Responsiveness = 15
	alignOrientation.CFrame = primaryPart.CFrame
	alignOrientation.Parent = primaryPart

	primaryPart:SetNetworkOwner(player)

	local isFollowing = false

	-- Update loop running every frame
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not character or not humanoidRootPart or not primaryPart then 
			return 
		end

		local playerPos = humanoidRootPart.Position
		local petPos = primaryPart.Position

		-- Flatten player position to match the cat's height (ignores jumping)
		local targetFloorPos = Vector3.new(playerPos.X, petPos.Y, playerPos.Z)
		local horizontalDistance = (targetFloorPos - petPos).Magnitude

		-- State check: decide whether the cat should start or stop moving
		if horizontalDistance > START_DISTANCE then
			isFollowing = true
		elseif horizontalDistance <= STOP_DISTANCE then
			isFollowing = false
		end

		if isFollowing then
			-- Aim for a point STOP_DISTANCE away from the player, not right inside their feet
			local directionFromPlayer = (petPos - targetFloorPos).Unit
			local destination = targetFloorPos + (directionFromPlayer * (STOP_DISTANCE - 1))

			alignPosition.Position = destination

			-- Turn the cat to face the direction it is traveling
			if (destination - petPos).Magnitude > 0.1 then
				alignOrientation.CFrame = CFrame.lookAt(petPos, Vector3.new(destination.X, petPos.Y, destination.Z))
			end
		else
			-- When idle, keep its current position so it doesn't drift
			alignPosition.Position = petPos
		end
	end)

	-- Clean up when the player resets
	humanoid.Died:Connect(function()
		connection:Disconnect()
		pet:Destroy()
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		spawnPetForPlayer(player, character)
	end)
end)