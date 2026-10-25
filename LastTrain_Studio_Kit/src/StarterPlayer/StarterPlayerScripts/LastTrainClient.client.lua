local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
while Workspace:GetAttribute("LastTrainMode") == nil do
    Workspace:GetAttributeChangedSignal("LastTrainMode"):Wait()
end
local inGame = Workspace:GetAttribute("LastTrainMode") == "Game"
player.CameraMode = inGame and Enum.CameraMode.LockFirstPerson or Enum.CameraMode.Classic

local root = ReplicatedStorage:WaitForChild("LastTrain")
local remotes = root:WaitForChild("Remotes")
local objectiveEvent = remotes:WaitForChild("ObjectiveUpdate")
local shopRequest = remotes:WaitForChild("ShopRequest")
local GameConfig = require(root:WaitForChild("Shared"):WaitForChild("GameConfig"))
local CharacterAppearance = require(root.Shared:WaitForChild("CharacterAppearance"))

local gui = Instance.new("ScreenGui")
gui.Name = "LastTrainHUD"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 8
gui.Parent = player:WaitForChild("PlayerGui")

local function rounded(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 10)
    corner.Parent = instance
end

local function stroke(instance, color, transparency)
    local line = Instance.new("UIStroke")
    line.Color = color
    line.Transparency = transparency or 0.3
    line.Thickness = 1
    line.Parent = instance
end

local objectiveCard = Instance.new("Frame")
objectiveCard.Size = UDim2.fromOffset(410, 118)
-- Leave room for Roblox's built-in chat panel so the mission stays readable.
objectiveCard.Position = UDim2.new(0, 24, 0, 154)
objectiveCard.BackgroundColor3 = Color3.fromRGB(12, 18, 24)
objectiveCard.BackgroundTransparency = 0.18
objectiveCard.Parent = gui
objectiveCard.Visible = inGame
rounded(objectiveCard, 12)
stroke(objectiveCard, Color3.fromRGB(89, 152, 166), 0.35)
local eyebrow = Instance.new("TextLabel")
eyebrow.BackgroundTransparency = 1
eyebrow.Position = UDim2.fromOffset(17, 11)
eyebrow.Size = UDim2.new(1, -34, 0, 22)
eyebrow.Font = Enum.Font.GothamBold
eyebrow.Text = "末班車  /  夜間維修任務"
eyebrow.TextColor3 = Color3.fromRGB(107, 201, 211)
eyebrow.TextSize = 13
eyebrow.TextXAlignment = Enum.TextXAlignment.Left
eyebrow.Parent = objectiveCard
local objectiveLabel = Instance.new("TextLabel")
objectiveLabel.BackgroundTransparency = 1
objectiveLabel.Position = UDim2.fromOffset(17, 39)
objectiveLabel.Size = UDim2.new(1, -34, 0, 65)
objectiveLabel.Font = Enum.Font.GothamMedium
objectiveLabel.Text = "等待站內廣播…"
objectiveLabel.TextColor3 = Color3.fromRGB(235, 239, 241)
objectiveLabel.TextSize = 17
objectiveLabel.TextWrapped = true
objectiveLabel.TextXAlignment = Enum.TextXAlignment.Left
objectiveLabel.TextYAlignment = Enum.TextYAlignment.Top
objectiveLabel.Parent = objectiveCard

local shopButton = Instance.new("TextButton")
shopButton.Size = UDim2.fromOffset(150, 44)
shopButton.Position = UDim2.new(1, -174, 0, 24)
shopButton.BackgroundColor3 = Color3.fromRGB(22, 36, 43)
shopButton.Text = "角色與補給  [M]"
shopButton.TextColor3 = Color3.fromRGB(224, 239, 239)
shopButton.TextSize = 14
shopButton.Font = Enum.Font.GothamBold
shopButton.Parent = gui
shopButton.Visible = inGame
rounded(shopButton, 10)
stroke(shopButton, Color3.fromRGB(91, 171, 181), 0.25)

local crosshair = Instance.new("Frame")
crosshair.Size = UDim2.fromOffset(5, 5)
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.Position = UDim2.fromScale(0.5, 0.5)
crosshair.BackgroundColor3 = Color3.fromRGB(223, 232, 229)
crosshair.BackgroundTransparency = 0.15
crosshair.Parent = gui
rounded(crosshair, 5)
crosshair.Visible = inGame

local controlsHint = Instance.new("TextLabel")
controlsHint.Size = UDim2.fromOffset(340, 30)
controlsHint.Position = UDim2.new(0, 24, 0, 136)
controlsHint.BackgroundColor3 = Color3.fromRGB(12, 18, 24)
controlsHint.BackgroundTransparency = 0.28
controlsHint.Text = "WASD 移動  •  E 互動  •  F 手電筒  •  M 商店"
controlsHint.TextColor3 = Color3.fromRGB(205, 218, 220)
controlsHint.TextSize = 12
controlsHint.Font = Enum.Font.GothamMedium
controlsHint.Parent = gui
rounded(controlsHint, 8)
-- Keep the first-person view clear; the controls are explained at the lobby entrance.
controlsHint.Visible = false

-- A local camera-mounted flashlight keeps the station readable in first person.
local flashlightPart = Instance.new("Part")
flashlightPart.Name = "LastTrainFlashlight"
flashlightPart.Size = Vector3.new(0.15, 0.15, 0.15)
flashlightPart.Transparency = 1
flashlightPart.Anchored = true
flashlightPart.CanCollide = false
flashlightPart.CanTouch = false
flashlightPart.CanQuery = false
flashlightPart.CastShadow = false
flashlightPart.Parent = Workspace.CurrentCamera

local flashlight = Instance.new("SpotLight")
flashlight.Name = "LastTrainBeam"
flashlight.Face = Enum.NormalId.Front
flashlight.Angle = 62
flashlight.Brightness = 1.65
flashlight.Range = 58
flashlight.Shadows = false
flashlight.Enabled = inGame
flashlight.Parent = flashlightPart

local function attachFlashlightToCamera()
    local camera = Workspace.CurrentCamera
    if camera then
        flashlightPart.Parent = camera
        flashlightPart.CFrame = camera.CFrame
    end
end
attachFlashlightToCamera()
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(attachFlashlightToCamera)
RunService:BindToRenderStep("LastTrainFlashlight", Enum.RenderPriority.Camera.Value + 1, attachFlashlightToCamera)

local shop = Instance.new("Frame")
shop.Name = "CharacterShop"
shop.Size = UDim2.new(0.82, 0, 0.78, 0)
shop.Position = UDim2.fromScale(0.5, 0.5)
shop.AnchorPoint = Vector2.new(0.5, 0.5)
shop.BackgroundColor3 = Color3.fromRGB(10, 15, 20)
shop.BackgroundTransparency = 0.04
shop.Visible = false
shop.Parent = gui
rounded(shop, 16)
stroke(shop, Color3.fromRGB(78, 146, 159), 0.2)
local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MinSize = Vector2.new(310, 310)
sizeLimit.MaxSize = Vector2.new(900, 620)
sizeLimit.Parent = shop

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(25, 18)
title.Size = UDim2.new(1, -100, 0, 34)
title.Font = Enum.Font.GothamBold
title.Text = "車票幣服裝"
title.TextColor3 = Color3.fromRGB(238, 241, 239)
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = shop
local balance = Instance.new("TextLabel")
balance.BackgroundTransparency = 1
balance.Position = UDim2.new(0, 25, 0, 56)
balance.Size = UDim2.new(1, -50, 0, 25)
balance.Font = Enum.Font.GothamMedium
balance.Text = "車票幣：…"
balance.TextColor3 = Color3.fromRGB(224, 183, 93)
balance.TextSize = 15
balance.TextXAlignment = Enum.TextXAlignment.Left
balance.Parent = shop
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.fromOffset(40, 36)
closeButton.Position = UDim2.new(1, -58, 0, 18)
closeButton.BackgroundColor3 = Color3.fromRGB(34, 43, 48)
closeButton.Text = "×"
closeButton.Modal = true
closeButton.TextColor3 = Color3.fromRGB(232, 236, 235)
closeButton.TextSize = 24
closeButton.Font = Enum.Font.Gotham
closeButton.Parent = shop
rounded(closeButton, 8)

local sectionLabel = Instance.new("TextLabel")
sectionLabel.BackgroundTransparency = 1
sectionLabel.Position = UDim2.fromOffset(25, 91)
sectionLabel.Size = UDim2.new(0.43, -24, 0, 23)
sectionLabel.Font = Enum.Font.GothamBold
sectionLabel.Text = "今晚值班"
sectionLabel.TextColor3 = Color3.fromRGB(151, 194, 196)
sectionLabel.TextSize = 13
sectionLabel.TextXAlignment = Enum.TextXAlignment.Left
sectionLabel.Parent = shop

local cards = Instance.new("ScrollingFrame")
cards.BackgroundTransparency = 1
cards.BorderSizePixel = 0
cards.Position = UDim2.fromOffset(24, 118)
cards.Size = UDim2.new(0.44, -20, 1, -212)
cards.CanvasSize = UDim2.new(0, 0, 0, 0)
cards.AutomaticCanvasSize = Enum.AutomaticSize.Y
cards.ScrollBarThickness = 3
cards.ScrollBarImageColor3 = Color3.fromRGB(108, 151, 152)
cards.Parent = shop
local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 9)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = cards
local cardButtons, cardFrames = {}, {}
local selectedKey
local details = Instance.new("Frame")
details.Position = UDim2.new(0.46, 0, 0, 100)
details.Size = UDim2.new(0.5, -25, 1, -202)
details.BackgroundColor3 = Color3.fromRGB(19, 29, 33)
details.Parent = shop
rounded(details, 13)
local detailAccent = Instance.new("Frame")
detailAccent.Size = UDim2.new(1, 0, 0, 5)
detailAccent.BackgroundColor3 = Color3.fromRGB(226, 181, 91)
detailAccent.Parent = details
rounded(detailAccent, 4)
local portrait = Instance.new("Frame")
portrait.Size = UDim2.new(1, -28, 0.42, 0)
portrait.Position = UDim2.fromOffset(14, 18)
portrait.BackgroundColor3 = Color3.fromRGB(32, 47, 52)
portrait.Parent = details
rounded(portrait, 11)
local characterViewport = Instance.new("ViewportFrame")
characterViewport.Name = "UniformPreview"
characterViewport.Size = UDim2.fromScale(1, 1)
characterViewport.BackgroundTransparency = 1
characterViewport.Ambient = Color3.fromRGB(168, 177, 190)
characterViewport.LightColor = Color3.fromRGB(255, 240, 217)
characterViewport.LightDirection = Vector3.new(-1, -1, -2)
characterViewport.Parent = portrait
local previewCamera = Instance.new("Camera")
previewCamera.FieldOfView = 31
previewCamera.Parent = characterViewport
characterViewport.CurrentCamera = previewCamera
local previewWorld = Instance.new("WorldModel")
previewWorld.Parent = characterViewport
local previewKey
local function showUniformPreview(key)
    if previewKey == key and #previewWorld:GetChildren() > 0 then return end
    local character = player.Character
    if not character then return end
    local wasArchivable = character.Archivable
    character.Archivable = true
    local model = character:Clone()
    character.Archivable = wasArchivable
    if not model then return end
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("LuaSourceContainer") or descendant:IsA("Tool") then
            descendant:Destroy()
        elseif descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.LocalTransparencyModifier = 0
        end
    end
    CharacterAppearance.Apply(model, key)
    -- The same tailored uniform and preserved face are visible before purchase.
    model:PivotTo(CFrame.Angles(0, math.rad(16), 0))
    previewWorld:ClearAllChildren()
    model.Parent = previewWorld
    local bounds, size = model:GetBoundingBox()
    local focus = bounds.Position + Vector3.new(0, size.Y * 0.05, 0)
    local verticalFov = math.rad(previewCamera.FieldOfView / 2)
    local distance = math.max(size.Y * 0.56, size.X * 0.68) / math.tan(verticalFov)
    previewCamera.CFrame = CFrame.lookAt(focus + Vector3.new(0, size.Y * 0.04, -distance), focus)
    previewKey = key
end
local selectedName = Instance.new("TextLabel")
selectedName.BackgroundTransparency = 1
selectedName.Position = UDim2.new(0, 18, 0.48, 0)
selectedName.Size = UDim2.new(1, -36, 0, 31)
selectedName.Font = Enum.Font.GothamBlack
selectedName.TextSize = 20
selectedName.TextColor3 = Color3.fromRGB(240, 239, 227)
selectedName.TextXAlignment = Enum.TextXAlignment.Left
selectedName.Parent = details
local flavorLine = Instance.new("TextLabel")
flavorLine.BackgroundTransparency = 1
flavorLine.Position = UDim2.new(0, 18, 0.48, 34)
flavorLine.Size = UDim2.new(1, -36, 0, 32)
flavorLine.Font = Enum.Font.GothamMedium
flavorLine.TextSize = 12
flavorLine.TextWrapped = true
flavorLine.TextColor3 = Color3.fromRGB(171, 190, 187)
flavorLine.TextXAlignment = Enum.TextXAlignment.Left
flavorLine.Parent = details
local abilityLine = Instance.new("TextLabel")
abilityLine.BackgroundTransparency = 1
abilityLine.Position = UDim2.new(0, 18, 0.68, 0)
abilityLine.Size = UDim2.new(1, -36, 0, 44)
abilityLine.Font = Enum.Font.GothamBold
abilityLine.TextSize = 13
abilityLine.TextWrapped = true
abilityLine.TextColor3 = Color3.fromRGB(228, 203, 142)
abilityLine.TextXAlignment = Enum.TextXAlignment.Left
abilityLine.Parent = details
local actionButton = Instance.new("TextButton")
actionButton.Name = "SelectedAction"
actionButton.Size = UDim2.new(1, -36, 0, 40)
actionButton.Position = UDim2.new(0, 18, 1, -54)
actionButton.BackgroundColor3 = Color3.fromRGB(43, 91, 98)
actionButton.TextColor3 = Color3.fromRGB(245, 247, 245)
actionButton.TextSize = 14
actionButton.Font = Enum.Font.GothamBold
actionButton.Parent = details
rounded(actionButton, 8)

local shopFlavor = {
    PlatformWorker = { Icon = "✦", Line = "第一晚先熟悉路線。", Ability = "無特殊能力・免費上車", Tag = "新手" },
    Conductor = { Icon = "↗", Line = "鞋底沾著月台的白漆。", Ability = "跑得更快・移動速度 +15%", Tag = "快腳" },
    Signalman = { Icon = "◉", Line = "他修好的燈，總會多亮一站。", Ability = "照得更遠・手電筒 +40%", Tag = "探照" },
    NightGuard = { Icon = "☾", Line = "監視器拍不到他的正臉。", Ability = "比較不容易被發現・感知 -25%", Tag = "隱匿" },
}

local function makeSkinCard(key, info, order)
    local flavor = shopFlavor[key] or { Icon = "✦", Line = "夜班還有空位。", Ability = info.Ability or "一般調查員", Tag = "服裝" }
    local button = Instance.new("TextButton")
    button.Name = key
    button.LayoutOrder = order
    button.Size = UDim2.new(1, -6, 0, 66)
    button.BackgroundColor3 = Color3.fromRGB(25, 37, 41)
    button.Text = ""
    button.AutoButtonColor = true
    button.Parent = cards
    rounded(button, 10)
    stroke(button, info.Colors.Accent, 0.78)
    local swatch = Instance.new("Frame")
    swatch.Size = UDim2.new(0, 46, 0, 46)
    swatch.Position = UDim2.fromOffset(10, 10)
    swatch.BackgroundColor3 = info.Colors.Main
    swatch.Parent = button
    rounded(swatch, 10)
    local swatchMark = Instance.new("Frame")
    swatchMark.AnchorPoint = Vector2.new(0.5, 0.5)
    swatchMark.Position = UDim2.fromScale(0.5, 0.5)
    swatchMark.Size = UDim2.new(0, 9, 0, 30)
    swatchMark.BackgroundColor3 = info.Colors.Accent
    swatchMark.Parent = swatch
    rounded(swatchMark, 5)
    local name = Instance.new("TextLabel")
    name.BackgroundTransparency = 1
    name.Position = UDim2.fromOffset(67, 11)
    name.Size = UDim2.new(1, -137, 0, 23)
    name.Font = Enum.Font.GothamBold
    name.Text = info.DisplayName
    name.TextColor3 = Color3.fromRGB(232, 237, 236)
    name.TextSize = 15
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Parent = button
    local tag = Instance.new("TextLabel")
    tag.BackgroundTransparency = 1
    tag.Position = UDim2.fromOffset(67, 35)
    tag.Size = UDim2.new(1, -137, 0, 18)
    tag.Font = Enum.Font.GothamMedium
    tag.Text = flavor.Tag
    tag.TextColor3 = info.Colors.Accent
    tag.TextSize = 11
    tag.TextXAlignment = Enum.TextXAlignment.Left
    tag.Parent = button
    local price = Instance.new("TextLabel")
    price.Name = "Price"
    price.BackgroundTransparency = 1
    price.AnchorPoint = Vector2.new(1, 0.5)
    price.Position = UDim2.new(1, -12, 0.5, 0)
    price.Size = UDim2.fromOffset(86, 36)
    price.Font = Enum.Font.GothamBold
    price.Text = info.RequiresGamePass and "R$" or (info.PriceCoins == 0 and "免費" or ("票 " .. tostring(info.PriceCoins)))
    price.TextColor3 = Color3.fromRGB(224, 198, 134)
    price.TextSize = 12
    price.TextXAlignment = Enum.TextXAlignment.Right
    price.Parent = button
    cardButtons[key] = { Button = button, Info = info }
    cardFrames[key] = { Button = button, Icon = flavor.Icon, Flavor = flavor, Info = info }
    button.Activated:Connect(function() selectedKey = key end)
end

local skinKeys = {}
for key,skin in pairs(GameConfig.Skins) do if not skin.CatalogPass then table.insert(skinKeys,key) end end
table.sort(skinKeys, function(a, b)
    local rank = { PlatformWorker = 1, Conductor = 2, Signalman = 3, NightGuard = 4 }
    return (rank[a] or 99) < (rank[b] or 99)
end)
for index, key in ipairs(skinKeys) do makeSkinCard(key, GameConfig.Skins[key], index) end

local exchangeLabel = Instance.new("TextLabel")
exchangeLabel.BackgroundTransparency = 1
exchangeLabel.Position = UDim2.new(0, 24, 1, -82)
exchangeLabel.Size = UDim2.new(1, -48, 0, 20)
exchangeLabel.Font = Enum.Font.GothamBold
exchangeLabel.Text = "補給票"
exchangeLabel.TextColor3 = Color3.fromRGB(233, 203, 128)
exchangeLabel.TextSize = 12
exchangeLabel.TextXAlignment = Enum.TextXAlignment.Left
exchangeLabel.Parent = shop
local productRow = Instance.new("Frame")
productRow.BackgroundTransparency = 1
productRow.Position = UDim2.new(0, 24, 1, -56)
productRow.Size = UDim2.new(1, -48, 0, 36)
productRow.Parent = shop
local productButtons = {}
local productKeys = {}
for key in pairs(GameConfig.Products) do table.insert(productKeys, key) end
table.sort(productKeys, function(a, b)
    local order = { CoinPouch = 1, CoinCrate = 2 }
    return (order[a] or 99) < (order[b] or 99)
end)
for productIndex, key in ipairs(productKeys) do
    local product = GameConfig.Products[key]
    local button = Instance.new("TextButton")
    button.Name = key
    button.Size = UDim2.new(1 / #productKeys, -8, 1, 0)
    button.Position = UDim2.new((productIndex - 1) / #productKeys, (productIndex - 1) * 8, 0, 0)
    button.BackgroundColor3 = Color3.fromRGB(57, 57, 43)
    button.Text = product.DisplayName .. "  ·  Robux"
    button.TextColor3 = Color3.fromRGB(241, 222, 166)
    button.TextSize = 12
    button.Font = Enum.Font.GothamBold
    button.Parent = productRow
    rounded(button, 8)
    productButtons[key] = button
end

local currentState
local function renderSelection()
    local entry = cardFrames[selectedKey]
    if not entry then return end
    local info, flavor = entry.Info, entry.Flavor
    selectedName.Text = info.DisplayName
    flavorLine.Text = flavor.Line
    abilityLine.Text = flavor.Ability
    portrait.BackgroundColor3 = info.Colors.Main
    detailAccent.BackgroundColor3 = info.Colors.Accent
    showUniformPreview(selectedKey)
    for key, card in pairs(cardFrames) do
        card.Button.BackgroundColor3 = key == selectedKey and Color3.fromRGB(39, 54, 56) or Color3.fromRGB(25, 37, 41)
    end
    if not currentState then
        actionButton.Text = info.RequiresGamePass and "Robux 解鎖" or (info.PriceCoins == 0 and "免費解鎖" or "使用車票幣")
        return
    end
    local owned = currentState.OwnedSkins[selectedKey] == true
    local equipped = currentState.EquippedSkin == selectedKey
    if equipped then
        actionButton.Text = "已穿上"
        actionButton.BackgroundColor3 = Color3.fromRGB(49, 73, 69)
    elseif owned then
        actionButton.Text = "穿上這套"
        actionButton.BackgroundColor3 = Color3.fromRGB(43, 91, 98)
    elseif info.RequiresGamePass then
        actionButton.Text = info.GamePassId > 0 and "Robux 解鎖" or "尚未開放"
        actionButton.BackgroundColor3 = info.GamePassId > 0 and Color3.fromRGB(103, 73, 36) or Color3.fromRGB(57, 62, 64)
    elseif info.PriceCoins > 0 then
        actionButton.Text = "購買・" .. tostring(info.PriceCoins) .. " 票"
        actionButton.BackgroundColor3 = Color3.fromRGB(43, 91, 98)
    else
        actionButton.Text = "免費解鎖"
        actionButton.BackgroundColor3 = Color3.fromRGB(43, 91, 98)
    end
end
selectedKey = skinKeys[1]
renderSelection()

local toast = Instance.new("TextLabel")
toast.Size = UDim2.new(0, 620, 0, 70)
toast.Position = UDim2.new(0.5, 0, 1, -96)
toast.AnchorPoint = Vector2.new(0.5, 0.5)
toast.BackgroundColor3 = Color3.fromRGB(12, 18, 22)
toast.BackgroundTransparency = 0.12
toast.Text = ""
toast.TextColor3 = Color3.fromRGB(236, 239, 234)
toast.TextSize = 14
toast.TextWrapped = true
toast.Font = Enum.Font.GothamMedium
toast.Visible = false
toast.Parent = gui
rounded(toast, 9)

local toastId = 0
local function showToast(message, duration)
    toastId += 1
    local thisToast = toastId
    toast.Text = tostring(message or "")
    toast.Visible = true
    task.delay(duration or 4.5, function() if toastId == thisToast then toast.Visible = false end end)
end

local function refreshShop()
    local ok, response = pcall(function()
        return shopRequest:InvokeServer("GetState")
    end)
    if not ok or not response or not response.state then return end
    currentState = response.state
    balance.Text = "車票幣：" .. tostring(currentState.Coins)
    for key, entry in pairs(cardButtons) do
        local owned = currentState.OwnedSkins[key] == true
        local equipped = currentState.EquippedSkin == key
        local price = entry.Button:FindFirstChild("Price")
        if price then
            if equipped then price.Text = "使用中"
            elseif owned then price.Text = "已擁有"
            elseif entry.Info.RequiresGamePass then price.Text = entry.Info.GamePassId > 0 and "R$" or "未開放"
            elseif entry.Info.PriceCoins == 0 then price.Text = "免費"
            else price.Text = "票 " .. tostring(entry.Info.PriceCoins) end
        end
    end
    renderSelection()
end

local function doRequest(action, key)
    local ok, response = pcall(function()
        return shopRequest:InvokeServer(action, key)
    end)
    if not ok or not response then
        showToast("連線忙碌，請稍後再試。")
        return
    end
    if response.promptType == "GamePass" and response.id > 0 then
        MarketplaceService:PromptGamePassPurchase(player, response.id)
    elseif response.promptType == "Product" and response.id > 0 then
        MarketplaceService:PromptProductPurchase(player, response.id)
    else
        showToast(response.message or "完成。")
        refreshShop()
    end
end

actionButton.Activated:Connect(function()
    local entry = cardButtons[selectedKey]
    if not entry then return end
    if currentState and currentState.OwnedSkins[selectedKey] then
        doRequest("Equip", selectedKey)
    elseif entry.Info.RequiresGamePass then
        doRequest("PromptPass", selectedKey)
    else
        doRequest("BuyCoins", selectedKey)
    end
end)
for key, entry in pairs(cardButtons) do
    entry.Button.Activated:Connect(function()
        selectedKey = key
        renderSelection()
    end)
end
for key, button in pairs(productButtons) do
    button.Activated:Connect(function() doRequest("PromptProduct", key) end)
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(purchaser, _passId, wasPurchased)
    if purchaser == player and wasPurchased then
        task.delay(1.5, refreshShop) -- UI refresh only; the server verifies and grants ownership.
    end
end)

local function setShopVisible(value)
    if value and (player:GetAttribute("PlatformTaskOpen") or player:GetAttribute("LastTrainCinematic")) then return end
    shop.Visible = value
    player:WaitForChild("PlayerGui"):SetAttribute("OpenLastTrainShop", value)
    if value then refreshShop() end
end
player:WaitForChild("PlayerGui"):GetAttributeChangedSignal("OpenLastTrainShop"):Connect(function()
    if player.PlayerGui:GetAttribute("OpenLastTrainShop") and not shop.Visible then
        setShopVisible(true)
    end
end)
shopButton.Activated:Connect(function() setShopVisible(not shop.Visible) end)
closeButton.Activated:Connect(function() setShopVisible(false) end)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.M then setShopVisible(not shop.Visible) end
    if input.KeyCode == Enum.KeyCode.F and inGame then flashlight.Enabled = not flashlight.Enabled end
    if input.KeyCode == Enum.KeyCode.Escape and shop.Visible then setShopVisible(false) end
end)

local function orientFirstPersonCamera(character)
    if not inGame or not character then return end
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")
    if not humanoid or not rootPart or not head then return end

    -- The lobby's orbit camera can retain its old heading when the local round
    -- switches to first person. Seed the camera from the server-set character
    -- heading so players face along the platform toward the train on arrival.
    player.CameraMode = Enum.CameraMode.LockFirstPerson
    local camera = Workspace.CurrentCamera
    if not camera then return end
    camera.CameraType = Enum.CameraType.Scriptable
    camera.CameraSubject = humanoid
    local flatLook = Vector3.new(1, 0, 0) -- train and platform run along the X axis
    local eye = head.Position
    camera.CFrame = CFrame.lookAt(eye, eye + flatLook.Unit)
    camera.Focus = CFrame.new(eye + flatLook.Unit * 12)
    RunService.RenderStepped:Wait()
    if inGame and player.Character == character and Workspace.CurrentCamera == camera then
        -- Hand the aligned view back to Roblox's normal first-person controller
        -- after it has received the new heading.
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = humanoid
    end
end

local function queueFirstPersonCamera(character)
    task.spawn(function()
        character:WaitForChild("HumanoidRootPart", 10)
        character:WaitForChild("Humanoid", 10)
        character:WaitForChild("Head", 10)
        task.wait(0.2) -- let server spawn placement and Roblox camera subject settle
        orientFirstPersonCamera(character)
    end)
end

player.CharacterAdded:Connect(function(character)
    if inGame then queueFirstPersonCamera(character) end
end)

local function applyMode()
    inGame = Workspace:GetAttribute("LastTrainMode") == "Game"
    player.CameraMode = inGame and Enum.CameraMode.LockFirstPerson or Enum.CameraMode.Classic
    objectiveCard.Visible = inGame
    controlsHint.Visible = false
    crosshair.Visible = inGame
    flashlight.Enabled = inGame
    shopButton.Visible = inGame
    if inGame and player.Character then queueFirstPersonCamera(player.Character) end
end
Workspace:GetAttributeChangedSignal("LastTrainMode"):Connect(applyMode)
if inGame and player.Character then queueFirstPersonCamera(player.Character) end
local function applyFlashlightAbility()
    flashlight.Range = 58 * (player:GetAttribute("FlashlightMultiplier") or 1)
end
player:GetAttributeChangedSignal("FlashlightMultiplier"):Connect(applyFlashlightAbility)
applyFlashlightAbility()

local lastRideState=nil
objectiveEvent.OnClientEvent:Connect(function(stage, text, completed, stationName, storyText, endingKey,rideState,stationIndex)
    local stopNumber = stationIndex or math.clamp(tonumber(stage) or 0, 0, #GameConfig.Stations - 1) + 1
    eyebrow.Text = string.format("第 %d / 7 站   /   %s", stopNumber, tostring(stationName or "末班車"))
    if completed then
        objectiveLabel.Text = tostring(text or "旅程結束。")
        showToast(tostring(text or "旅程結束。"), 9)
    elseif rideState=="Entry" then
        objectiveLabel.Text="第一站 · 進站任務\n"..tostring(text or "請領取車票")
        if lastRideState~="Entry" then showToast(tostring(text),4) end
    elseif rideState=="Boarding" or rideState=="Countdown" or rideState=="Closing" or rideState=="Moving" then
        objectiveLabel.Text=tostring(text or "請返回列車")
        if rideState~=lastRideState then showToast(objectiveLabel.Text,3) end
    else
        local objectiveNo = math.clamp((tonumber(stage) or 0) + 1, 1, #GameConfig.Objectives)
        objectiveLabel.Text = string.format("任務 %d / 7\n%s", objectiveNo, tostring(text or "等待下一個指示"))
        if storyText and storyText ~= "" then showToast(tostring(storyText), 6)
        end
    end
    lastRideState=rideState
    if shop.Visible then refreshShop() end
end)

-- The ticket is personal; attribute changes restore its face after respawn.
local ticketCard=Instance.new("Frame")
ticketCard.Name="PassengerTicket"; ticketCard.AnchorPoint=Vector2.new(1,1)
ticketCard.Position=UDim2.new(1,-18,1,-80); ticketCard.Size=UDim2.fromOffset(220,108)
ticketCard.BackgroundColor3=Color3.fromRGB(250,249,245); ticketCard.BorderSizePixel=0
ticketCard.Parent=gui; rounded(ticketCard,8)
local ticketBand=Instance.new("TextLabel")
ticketBand.Name="OrangeBand"; ticketBand.Size=UDim2.new(1,0,0,28)
ticketBand.BackgroundColor3=Color3.fromRGB(219,106,38); ticketBand.BorderSizePixel=0
ticketBand.Text="末班車  LAST TRAIN"; ticketBand.Font=Enum.Font.GothamBold
 ticketBand.TextColor3=Color3.fromRGB(255,255,255); ticketBand.TextSize=14; ticketBand.Parent=ticketCard
local ticketDetails=Instance.new("TextLabel")
ticketDetails.Name="TicketDetails"; ticketDetails.Position=UDim2.fromOffset(10,34)
ticketDetails.Size=UDim2.new(1,-20,1,-40); ticketDetails.BackgroundTransparency=1
 ticketDetails.TextColor3=Color3.fromRGB(25,29,35); ticketDetails.Font=Enum.Font.GothamMedium
 ticketDetails.TextSize=13; ticketDetails.TextWrapped=true; ticketDetails.Parent=ticketCard
local function refreshTicket()
 ticketCard.Visible=Workspace:GetAttribute("LastTrainMode")=="Game" and player:GetAttribute("FirstStationHasTicket")==true and player:GetAttribute("HiddenRouteStation")==nil
 local serial=player:GetAttribute("GalaxyEditionSerial")
 local ticketType=serial and string.format("銀河收藏票 #%03d/500",serial) or player:GetAttribute("Owns_RoyalCarriage") and "皇家乘車票" or player:GetAttribute("Owns_LuxuryPass") and "商務乘車票" or "單程車票"
 ticketDetails.Text="新月站 → 目的地未定\n"..ticketType.."\n"..(player:GetAttribute("FirstStationValidated") and "已驗票 · 本次旅程有效" or "尚未驗票 · 請至閘門感應")
end
player:GetAttributeChangedSignal("FirstStationHasTicket"):Connect(refreshTicket)
player:GetAttributeChangedSignal("FirstStationValidated"):Connect(refreshTicket)
player:GetAttributeChangedSignal("GalaxyEditionSerial"):Connect(refreshTicket)
player:GetAttributeChangedSignal("Owns_RoyalCarriage"):Connect(refreshTicket)
player:GetAttributeChangedSignal("Owns_LuxuryPass"):Connect(refreshTicket)
Workspace:GetAttributeChangedSignal("LastTrainMode"):Connect(refreshTicket)
refreshTicket()

local readerVersions={}
remotes:WaitForChild("TicketUpdate").OnClientEvent:Connect(function(data)
    local screen=data.Screen
    if not screen then return end
    local display=screen:FindFirstChild("ReaderDisplay")
    local text=display and display:FindFirstChild("StatusText")
    if not text then return end
    readerVersions[screen]=(readerVersions[screen] or 0)+1
    local version=readerVersions[screen]
    local function current() return text.Parent and readerVersions[screen]==version end
    if data.Kind=="Rejected" then
        text.Text="未偵測到車票\n請先領票"; text.TextColor3=Color3.fromRGB(255,190,102)
    elseif data.Anomaly then
        -- This display change is local to the passenger who scanned.
        text.Text="你已於二十年前進站"; text.TextColor3=Color3.fromRGB(255,89,83)
        showToast("你已於二十年前進站",1.4)
        task.delay(1.2,function()
            if current() then text.Text="驗票成功\n請通行"; text.TextColor3=Color3.fromRGB(145,231,200) end
        end)
    else
        text.Text="驗票成功\n請通行"; text.TextColor3=Color3.fromRGB(145,231,200)
    end
    task.delay(3.8,function()
        if current() then text.Text="感應車票\nTAP TO ENTER"; text.TextColor3=Color3.fromRGB(145,231,200) end
    end)
end)

local function updateCoins()
    if shop.Visible then refreshShop() end
end
local leaderstats = player:WaitForChild("leaderstats", 20)
if leaderstats then
    local coins = leaderstats:WaitForChild("車票幣", 10)
    if coins then coins.Changed:Connect(updateCoins) end
end

-- The hidden chapter has its own station numbers after the original seven-stop ending.
remotes:WaitForChild("HiddenRouteUpdate").OnClientEvent:Connect(function(state)
 if state.left then eyebrow.Text="末班車 · 調查完成";objectiveLabel.Text="隱藏調查已完成，已返回列車月台。"
 elseif state.station then
  eyebrow.Text=state.station==9 and "隱藏第九站 · 被刪除的名字" or "隱藏第八站 · 封存檔案室"
  objectiveLabel.Text=state.ending and GameConfig.Endings.Station09 or state.done and "原始證據已公開，失蹤乘客終於回家。" or state.goal or "繼續調查。"
 end
end)

player:GetAttributeChangedSignal("HiddenRouteStation"):Connect(refreshTicket)
