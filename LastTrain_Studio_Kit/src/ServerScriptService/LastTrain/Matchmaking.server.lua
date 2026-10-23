-- Server-owned 1–4 player matchmaking. The public place stays a lobby;
-- each completed group receives its own reserved round server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

while Workspace:GetAttribute("LastTrainMode") == nil do
	Workspace:GetAttributeChangedSignal("LastTrainMode"):Wait()
end
if Workspace:GetAttribute("LastTrainMode") ~= "Lobby" then return end

local remotes = ReplicatedStorage:WaitForChild("LastTrain"):WaitForChild("Remotes")
local request = remotes:WaitForChild("MatchmakingRequest")
local update = remotes:WaitForChild("MatchmakingUpdate")
local queue = {}
local targetCount
local phase = "Idle"
local busy = false
local launchRunning = false
local queueGeneration = 0
local lastRequest = {}

local function queued(player)
	return table.find(queue, player) ~= nil
end

local function broadcast(seconds, message)
	local info = {
		phase = phase,
		count = #queue,
		target = targetCount or 1,
		seconds = seconds or 0,
		message = message or "",
	}
	for _, player in ipairs(Players:GetPlayers()) do
		update:FireClient(player, info, queued(player))
	end
end

local function removeFromQueue(player)
	local index = table.find(queue, player)
	if index then table.remove(queue, index) end
	if #queue == 0 and not busy then
		targetCount = nil
		phase = "Idle"
		launchRunning = false
		queueGeneration += 1
	end
end

local function studioRound(party)
	Workspace:SetAttribute("LastTrainMode", "Game")
	local lobby = Workspace:FindFirstChild("LastTrainLobby")
	if lobby then lobby:Destroy() end
	local world = Workspace:WaitForChild("LastTrainWorld", 45)
	if not world then error("Studio local round did not create LastTrainWorld") end
	local deadline = os.clock() + 45
	while not world:GetAttribute("Ready") and os.clock() < deadline do task.wait(0.1) end
	if not world:GetAttribute("Ready") then error("Studio local round did not finish building") end
	Players.CharacterAutoLoads = false
	local config = require(ReplicatedStorage:WaitForChild("LastTrain"):WaitForChild("Shared"):WaitForChild("GameConfig"))
	local function placeCharacter(player, character)
		local station = math.clamp(Workspace:GetAttribute("LastTrainStation") or 1, 1, #config.Stations)
		character:PivotTo(CFrame.new((station - 1) * config.StationSpacing - 40, 3.4, -22) * CFrame.Angles(0, math.rad(-90), 0))
		local humanoid = character:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			humanoid.Died:Once(function()
				task.delay(3, function()
					if not player.Parent then return end
						pcall(function() player:LoadCharacterAsync() end)
				end)
			end)
		end
	end
	for _, player in ipairs(party) do
		player.CharacterAdded:Connect(function(character) placeCharacter(player, character) end)
		if player.Character then placeCharacter(player, player.Character)
		else
			pcall(function() player:LoadCharacterAsync() end)
		end
	end
end

local function launchParty()
	if launchRunning then return end
	launchRunning = true
	queueGeneration += 1
	local myGeneration = queueGeneration
	phase = "Waiting"
	broadcast(10, "等候同車玩家；滿 10 秒會以目前人數出發。")
	for remaining = 10, 1, -1 do
		if myGeneration ~= queueGeneration then return end
		if #queue == 0 then
			launchRunning = false
			phase = "Idle"
			targetCount = nil
			broadcast(0, "隊伍已取消。")
			return
		end
		if #queue >= (targetCount or 1) then break end
		broadcast(remaining, "等候同車玩家；滿 10 秒會以目前人數出發。")
		task.wait(1)
	end
	if #queue == 0 then
		launchRunning = false
		phase = "Idle"
		targetCount = nil
		broadcast(0, "隊伍已取消。")
		return
	end

	phase = "Boarding"
	busy = true
	local party = table.create(math.min(#queue, targetCount or 4))
	for index = 1, math.min(#queue, targetCount or 4) do
		party[index] = queue[index]
	end
	for remaining = 3, 1, -1 do
		broadcast(remaining, "列車即將出發。")
		task.wait(1)
	end
	for index = #party, 1, -1 do
		if not party[index].Parent then table.remove(party, index) end
	end
	if #party == 0 then
		queue = {}
		targetCount = nil
		phase = "Idle"
		busy = false
		launchRunning = false
		broadcast(0, "隊伍已取消。")
		return
	end

	if RunService:IsStudio() then
		local ok, err = pcall(studioRound, party)
		busy = false
		launchRunning = false
		if not ok then
			phase = "Idle"
			queue = {}
			targetCount = nil
			broadcast(0, "本機測試啟動失敗：" .. tostring(err))
			return
		end
		phase = "Launched"
		queue = {}
		targetCount = nil
		broadcast(0, "本機遊戲已啟動。")
		return
	end

	local ok, err = pcall(function()
		local accessCode = TeleportService:ReserveServerAsync(game.PlaceId)
		local options = Instance.new("TeleportOptions")
		options.ReservedServerAccessCode = accessCode
		options:SetTeleportData({ LastTrainRound = true })
		TeleportService:TeleportAsync(game.PlaceId, party, options)
	end)
	if ok then
		queue = {}
		targetCount = nil
		phase = "Idle"
		busy = false
		launchRunning = false
		broadcast(0, "末班車已發車。")
	end
	if not ok then
		warn("LastTrain matchmaking teleport failed: " .. tostring(err))
		phase = "Idle"
		busy = false
		launchRunning = false
		for _, player in ipairs(party) do
			update:FireClient(player, { phase = "Error", message = "傳送失敗，請按「重新配對」再試一次。" }, false)
		end
		queue = {}
		targetCount = nil
	end
end

TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
	update:FireClient(player, {
		phase = "Error",
		message = "傳送中斷（" .. tostring(teleportResult) .. "），請重新配對。 " .. tostring(errorMessage),
	}, false)
end)

local function handleRequest(player, action, selectedCount)
	if type(action) ~= "string" then return { ok = false, message = "無效的請求。" } end
	local now = os.clock()
	if now - (lastRequest[player.UserId] or 0) < 0.5 then
		return { ok = false, message = "操作太快，請稍候。" }
	end
	lastRequest[player.UserId] = now

	if action == "PortalJoin" then
		if type(selectedCount) ~= "number" or selectedCount % 1 ~= 0 or selectedCount < 1 or selectedCount > 4 then
			return { ok = false, message = "無效的隊伍入口。" }
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
		local lobby = Workspace:FindFirstChild("LastTrainLobby")
		local gates = lobby and lobby:FindFirstChild("MatchmakingGates")
		local promptAnchor = gates and gates:FindFirstChild("GatePrompt" .. selectedCount)
		if not root or not humanoid or humanoid.Health <= 0 or not promptAnchor
			or promptAnchor:GetAttribute("PartySize") ~= selectedCount
			or (root.Position - promptAnchor.Position).Magnitude > 15 then
			return { ok = false, message = "請走到隊伍入口旁再加入配對。" }
		end
		if targetCount and targetCount ~= selectedCount then
			return { ok = false, message = string.format("目前等候的是 %d 人列車，請進入相同人數的光圈箱。", targetCount) }
		end
		action = "Join"
	end

	if action == "Status" then
		return { ok = true, phase = phase, count = #queue, target = targetCount or 1, queued = queued(player) }
	elseif action == "Leave" then
		if busy and phase == "Boarding" then return { ok = false, message = "列車已開始登車，現在不能離隊。" } end
		removeFromQueue(player)
		broadcast(0, "已離開配對隊伍。")
		return { ok = true, message = "已離開隊伍。" }
	elseif action == "Join" then
		if busy or phase == "Boarding" or phase == "Launched" then
			return { ok = false, message = "這班列車已開始登車，請稍後再配對。" }
		end
		if queued(player) then return { ok = true, message = "你已在等候隊伍中。" } end
		if targetCount and #queue >= targetCount then
			return { ok = false, message = "這班列車的人數已滿，請等下一班。" }
		end
		if #queue >= 4 then return { ok = false, message = "這班列車最多 4 人，請稍後再加入。" } end
		if not targetCount then
			if type(selectedCount) ~= "number" or selectedCount % 1 ~= 0 or selectedCount < 1 or selectedCount > 4 then
				return { ok = false, message = "請選擇 1 到 4 人。" }
			end
			targetCount = selectedCount
		end
		table.insert(queue, player)
		phase = "Waiting"
		broadcast(10, "等候同車玩家；滿 10 秒會以目前人數出發。")
		if not busy then task.spawn(launchParty) end
		return { ok = true, message = "已加入配對。" }
	end
	return { ok = false, message = "不支援的配對操作。" }
end
request.OnServerInvoke = handleRequest

-- Entering a physical matchmaking pod queues the player directly; the server
-- still checks that their character is alive and standing inside that pod.
task.spawn(function()
	local lobby = Workspace:WaitForChild("LastTrainLobby", 30)
	local gates = lobby and lobby:WaitForChild("MatchmakingGates", 20)
	if not gates then return end
	local touchDebounce = {}
	for partySize = 1, 4 do
		local zone = gates:WaitForChild("GatePrompt" .. partySize, 10)
		if zone then
			zone.Touched:Connect(function(hit)
				local character = hit:FindFirstAncestorOfClass("Model")
				local player = character and Players:GetPlayerFromCharacter(character)
				if not player or touchDebounce[player.UserId] then return end
				touchDebounce[player.UserId] = true
				task.delay(1.2, function() touchDebounce[player.UserId] = nil end)
				handleRequest(player, "PortalJoin", partySize)
			end)
			zone.TouchEnded:Connect(function(hit)
				local character = hit:FindFirstAncestorOfClass("Model")
				local player = character and Players:GetPlayerFromCharacter(character)
				if not player then return end
				task.delay(0.6, function()
					local current = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
					if not current then return end
					local delta = current.Position - zone.Position
					local half = zone.Size * 0.5 + Vector3.new(2, 2, 2)
					if math.abs(delta.X) <= half.X and math.abs(delta.Y) <= half.Y and math.abs(delta.Z) <= half.Z then return end
					if targetCount == partySize and phase ~= "Boarding" then
						removeFromQueue(player)
						broadcast(0, "乘客離開了光圈箱。")
					end
				end)
			end)
		end
	end
end)

Players.PlayerAdded:Connect(function(player)
	update:FireClient(player, { phase = phase, count = #queue, target = targetCount or 1, seconds = 0 }, false)
end)
Players.PlayerRemoving:Connect(function(player)
	removeFromQueue(player)
	lastRequest[player.UserId] = nil
	if not busy then broadcast(0, "") end
end)
