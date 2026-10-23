local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ProximityPromptService = game:GetService("ProximityPromptService")

while Workspace:GetAttribute("LastTrainMode") == nil do
	Workspace:GetAttributeChangedSignal("LastTrainMode"):Wait()
end
if Workspace:GetAttribute("LastTrainMode") ~= "Lobby" then return end

local player = Players.LocalPlayer
player.CameraMode = Enum.CameraMode.Classic
local remotes = ReplicatedStorage:WaitForChild("LastTrain"):WaitForChild("Remotes")
local request = remotes:WaitForChild("MatchmakingRequest")
local update = remotes:WaitForChild("MatchmakingUpdate")
local gui = Instance.new("ScreenGui")
gui.Name = "LastTrainLobbyUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 20
gui.Parent = player:WaitForChild("PlayerGui")

local overlay = Instance.new("Frame")
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.fromRGB(5, 10, 15)
overlay.BackgroundTransparency = 0.15
overlay.Parent = gui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0.86, 0, 0, 430)
panel.BackgroundColor3 = Color3.fromRGB(12, 22, 29)
panel.BackgroundTransparency = 0.06
panel.Parent = overlay
local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 20); corner.Parent = panel
local border = Instance.new("UIStroke"); border.Color = Color3.fromRGB(79, 194, 207); border.Transparency = 0.4; border.Parent = panel
local size = Instance.new("UISizeConstraint"); size.MinSize = Vector2.new(330, 430); size.MaxSize = Vector2.new(690, 430); size.Parent = panel

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 28, 0, 22)
title.Size = UDim2.new(1, -220, 0, 42)
title.Font = Enum.Font.GothamBlack
title.Text = "末班車  /  LAST TRAIN"
title.TextColor3 = Color3.fromRGB(224, 242, 238)
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.new(0, 30, 0, 66)
subtitle.Size = UDim2.new(1, -60, 0, 24)
subtitle.Font = Enum.Font.GothamBold
subtitle.Text = "七站之後，列車將不再回頭。"
subtitle.TextColor3 = Color3.fromRGB(98, 211, 218)
subtitle.TextSize = 15
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = panel
local store = Instance.new("TextButton")
store.Size = UDim2.fromOffset(126, 34)
store.Position = UDim2.new(1, -202, 0, 26)
store.BackgroundColor3 = Color3.fromRGB(79, 71, 48)
store.Text = "角色商店"
store.TextColor3 = Color3.fromRGB(245, 226, 174)
store.TextSize = 13
store.Font = Enum.Font.GothamBold
store.Parent = panel
local storeCorner = Instance.new("UICorner"); storeCorner.CornerRadius = UDim.new(0, 8); storeCorner.Parent = store
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseLobbyPage"
closeButton.Size = UDim2.fromOffset(36, 36)
closeButton.Position = UDim2.new(1, -52, 0, 24)
closeButton.BackgroundColor3 = Color3.fromRGB(39, 52, 58)
closeButton.Text = "×"
closeButton.TextColor3 = Color3.fromRGB(236, 242, 239)
closeButton.TextSize = 25
closeButton.Font = Enum.Font.Gotham
closeButton.AutoButtonColor = true
closeButton.Parent = panel
local closeCorner = Instance.new("UICorner"); closeCorner.CornerRadius = UDim.new(0, 9); closeCorner.Parent = closeButton
local reopenButton = Instance.new("TextButton")
reopenButton.Name = "OpenLobbyPage"
reopenButton.AnchorPoint = Vector2.new(1, 0)
reopenButton.Position = UDim2.new(1, -22, 0, 22)
reopenButton.Size = UDim2.fromOffset(156, 42)
reopenButton.BackgroundColor3 = Color3.fromRGB(20, 43, 51)
reopenButton.Text = "大廳選單"
reopenButton.TextColor3 = Color3.fromRGB(221, 241, 237)
reopenButton.TextSize = 14
reopenButton.Font = Enum.Font.GothamBold
reopenButton.Visible = false
reopenButton.Parent = gui
local reopenCorner = Instance.new("UICorner"); reopenCorner.CornerRadius = UDim.new(0, 10); reopenCorner.Parent = reopenButton
local reopenStroke = Instance.new("UIStroke"); reopenStroke.Color = Color3.fromRGB(79, 194, 207); reopenStroke.Transparency = 0.3; reopenStroke.Parent = reopenButton
closeButton.Activated:Connect(function()
	overlay.Visible = false
	reopenButton.Visible = true
end)
reopenButton.Activated:Connect(function()
	overlay.Visible = true
	reopenButton.Visible = false
end)
local playerGui = player:WaitForChild("PlayerGui")
store.Activated:Connect(function()
	gui.Enabled = false
	playerGui:SetAttribute("OpenLastTrainShop", true)
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	if prompt.Parent and prompt.Parent.Name == "CharacterShopKioskBody" then
		gui.Enabled = false
		playerGui:SetAttribute("OpenLastTrainShop", true)
	elseif prompt.Parent and prompt.Parent.Name == "StoryKioskBody" then
		gui.Enabled = true
		overlay.Visible = true
		reopenButton.Visible = false
	end
end)

playerGui:GetAttributeChangedSignal("OpenLastTrainShop"):Connect(function()
	if playerGui:GetAttribute("OpenLastTrainShop") == false and Workspace:GetAttribute("LastTrainMode") == "Lobby" then
		gui.Enabled = true
	end
end)

local story = Instance.new("TextLabel")
story.BackgroundColor3 = Color3.fromRGB(21, 35, 42)
story.BackgroundTransparency = 0.12
story.Position = UDim2.new(0, 28, 0, 104)
story.Size = UDim2.new(1, -56, 0, 116)
story.Font = Enum.Font.GothamMedium
story.Text = ""
story.TextColor3 = Color3.fromRGB(216, 226, 226)
story.TextSize = 16
story.TextWrapped = true
story.TextXAlignment = Enum.TextXAlignment.Left
story.TextYAlignment = Enum.TextYAlignment.Center
story.Parent = panel
local storyCorner = Instance.new("UICorner"); storyCorner.CornerRadius = UDim.new(0, 12); storyCorner.Parent = story

local choose = Instance.new("TextLabel")
choose.BackgroundTransparency = 1
choose.Position = UDim2.new(0, 30, 0, 235)
choose.Size = UDim2.new(1, -60, 0, 25)
choose.Font = Enum.Font.GothamBold
choose.Text = "選擇本班人數（最多 4 人）"
choose.TextColor3 = Color3.fromRGB(228, 233, 229)
choose.TextSize = 14
choose.TextXAlignment = Enum.TextXAlignment.Left
choose.Parent = panel

local selected = 1
local countButtons = {}
for count = 1, 4 do
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0.22, 0, 0, 42)
	button.Position = UDim2.new(0.04 + (count - 1) * 0.24, 0, 0, 267)
	button.BackgroundColor3 = count == selected and Color3.fromRGB(35, 125, 137) or Color3.fromRGB(34, 49, 56)
	button.Text = tostring(count) .. " 人"
	button.TextColor3 = Color3.fromRGB(238, 242, 238)
	button.TextSize = 14
	button.Font = Enum.Font.GothamBold
	button.Parent = panel
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 9); c.Parent = button
	countButtons[count] = button
	button.Activated:Connect(function()
		selected = count
		for n, item in pairs(countButtons) do
			item.BackgroundColor3 = n == selected and Color3.fromRGB(35, 125, 137) or Color3.fromRGB(34, 49, 56)
		end
	end)
end

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Position = UDim2.new(0, 30, 0, 317)
status.Size = UDim2.new(1, -60, 0, 24)
status.Font = Enum.Font.GothamMedium
status.Text = "走進 1–4 人光圈箱加入配對；等待 10 秒，隊伍到齊後倒數 3 秒發車。"
status.TextColor3 = Color3.fromRGB(169, 183, 185)
status.TextSize = 13
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = panel

local start = Instance.new("TextButton")
start.Size = UDim2.new(1, -56, 0, 48)
start.Position = UDim2.new(0, 28, 1, -70)
start.BackgroundColor3 = Color3.fromRGB(38, 119, 129)
start.Text = "從選單加入隊伍"
start.TextColor3 = Color3.fromRGB(245, 247, 242)
start.TextSize = 15
start.Font = Enum.Font.GothamBold
start.Parent = panel
local startCorner = Instance.new("UICorner"); startCorner.CornerRadius = UDim.new(0, 10); startCorner.Parent = start

local busy = false
local isQueued = false
local transitioning = false
local transitionFrame
local portalLabels = {}
local portalCounters = {}
local function setSelectedCount(count)
	selected = count
	for n, item in pairs(countButtons) do
		item.BackgroundColor3 = n == selected and Color3.fromRGB(35, 125, 137) or Color3.fromRGB(34, 49, 56)
	end
end
local function submitQueueAction(action, count)
	if busy then return end
	busy = true
	local ok, result = pcall(function() return request:InvokeServer(action, count or selected) end)
	if not ok then
		status.Text = "連線忙碌，請再試一次。"
	elseif result and not result.ok then
		status.Text = result.message or "無法加入隊伍。"
	else
		if action == "Join" or action == "PortalJoin" then isQueued = true end
		if action == "Leave" then isQueued = false end
		start.Text = isQueued and "已加入隊伍  /  點此離隊" or "從選單加入隊伍"
	end
	busy = false
end
start.Activated:Connect(function()
	submitQueueAction(isQueued and "Leave" or "Join", selected)
end)

local function renderPortalLabels(info)
	local count = math.clamp(tonumber(info.count) or 0, 0, 4)
	local target = math.clamp(tonumber(info.target) or 1, 1, 4)
	for partySize, label in pairs(portalLabels) do
		local counter = portalCounters[partySize]
		local counterLabel = counter and counter:FindFirstChildWhichIsA("SurfaceGui") and counter.SurfaceGui:FindFirstChild("QueueCounter")
		local active = partySize == target and info.phase ~= "Idle"
		local shownCount = active and count or 0
		local seconds = active and (tonumber(info.seconds) or 0) or 10
		if info.phase == "Boarding" and active then
			label.Text = string.format("%d 人列車\n已滿員・登車中", partySize)
		elseif active and info.phase == "Waiting" then
			label.Text = string.format("%d 人列車\n等待乘客…\n走進光圈加入", partySize)
		else
			label.Text = string.format("%d 人列車\n走進光圈加入\n等待乘客…", partySize)
		end
		if counterLabel then counterLabel.Text = string.format("%d / %d   •   %02d", shownCount, partySize, seconds) end
	end
end

task.spawn(function()
	local lobby = Workspace:WaitForChild("LastTrainLobby", 30)
	local gates = lobby and lobby:WaitForChild("MatchmakingGates", 20)
	if not gates then return end
	for partySize = 1, 4 do
		local sign = gates:WaitForChild("GateSign" .. partySize, 10)
		local label = sign and sign:FindFirstChild("GateDisplay") and sign.GateDisplay:FindFirstChild("PortalStatus")
		if label then portalLabels[partySize] = label end
		local counter = gates:FindFirstChild("GateCounter" .. partySize)
		if counter then portalCounters[partySize] = counter end
	end
	local initial = request:InvokeServer("Status")
	if type(initial) == "table" then
		isQueued = initial.queued == true
		start.Text = isQueued and "已加入隊伍  /  點此離隊" or "從選單加入隊伍"
		renderPortalLabels(initial)
	end
end)

local intro = "凌晨 00:17，你收到一張沒有目的地的車票。末班車廣播忽然中斷，只剩一句低語：「如果你看見站務員，請不要下車。」車門正在打開——七個站點的旅程，現在開始。"
task.spawn(function()
	local characters = {}
	for first, last in utf8.graphemes(intro) do
		table.insert(characters, string.sub(intro, first, last))
	end
	for index = 1, #characters do
		if Workspace:GetAttribute("LastTrainMode") ~= "Lobby" then return end
		story.Text = table.concat(characters, "", 1, index)
		task.wait(0.035)
	end
end)

update.OnClientEvent:Connect(function(info, playerQueued)
	if type(info) ~= "table" then return end
	if playerQueued ~= nil then isQueued = playerQueued end
	renderPortalLabels(info)
	if info.phase == "Error" then
		transitioning = false
		if transitionFrame then transitionFrame:Destroy(); transitionFrame = nil end
		status.Text = info.message or "配對失敗，請再試一次。"
		start.Text = "重新配對"
		start.Active = true
	elseif info.phase == "Waiting" then
		status.Text = string.format("等待玩家　%d / %d　｜　倒數 %d 秒", info.count or 0, info.target or selected, info.seconds or 10)
		start.Text = isQueued and "已加入隊伍  /  點此離隊" or "加入這班列車"
	elseif info.phase == "Boarding" then
		if isQueued and not transitioning then
			transitioning = true
			status.Text = string.format("列車即將出發　%d 秒後進入遊戲", info.seconds or 3)
			start.Text = "登車中…"
			start.Active = false
			local fade = Instance.new("Frame")
			transitionFrame = fade
			fade.Size = UDim2.fromScale(1, 1)
			fade.BackgroundColor3 = Color3.fromRGB(3, 7, 10)
			fade.BackgroundTransparency = 1
			fade.ZIndex = 20
			fade.Parent = gui
			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Size = UDim2.fromScale(1, 1)
			label.Text = "末班車正在進站……"
			label.TextColor3 = Color3.fromRGB(211, 239, 234)
			label.Font = Enum.Font.GothamBlack
			label.TextSize = 26
			label.ZIndex = 21
			label.Parent = fade
			TweenService:Create(fade, TweenInfo.new(2.7), {BackgroundTransparency = 0.08}):Play()
		elseif not isQueued then
			status.Text = "另一班末班車正在發車。"
		end
	elseif info.phase == "Idle" then
		if info.message and info.message ~= "" then status.Text = info.message end
		start.Text = "從選單加入隊伍"
		start.Active = true
	elseif info.phase == "Launched" then
		status.Text = info.message or "本機遊戲已啟動。"
	end
end)

Workspace:GetAttributeChangedSignal("LastTrainMode"):Connect(function()
	if Workspace:GetAttribute("LastTrainMode") == "Game" then
		player.CameraMode = Enum.CameraMode.LockFirstPerson
		TweenService:Create(overlay, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
		task.delay(0.55, function()
			gui.Enabled = false
		end)
	end
end)
