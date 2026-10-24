local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local root = ReplicatedStorage:WaitForChild("LastTrain")
local GameConfig = require(root:WaitForChild("Shared"):WaitForChild("GameConfig"))
local shopRequest = root:WaitForChild("Remotes"):WaitForChild("ShopRequest")
local Profiles = require(script.Parent:WaitForChild("ProfileService"))
local Catalog=require(root.Shared.PremiumCatalog)
local Edition=require(script.Parent.LimitedEdition)

local passToSkin = {}
local productById = {}
local lastRequestAt = {}
for skinKey, skin in pairs(GameConfig.Skins) do
    if skin.GamePassId and skin.GamePassId > 0 then
        passToSkin[skin.GamePassId] = skinKey
    end
end
for productKey, product in pairs(GameConfig.Products) do
    if product.ProductId and product.ProductId > 0 then
        productById[product.ProductId] = { Key = productKey, Coins = product.Coins }
    end
end

local function waitForProfile(player)
    local deadline = os.clock() + 20
    while player.Parent and not Profiles.IsLoaded(player) and os.clock() < deadline do
        task.wait(0.1)
    end
    return player.Parent ~= nil and Profiles.IsLoaded(player)
end

local function refreshPassOwnership(player, skinKey)
    local skin = GameConfig.Skins[skinKey]
    if not skin or not skin.GamePassId or skin.GamePassId <= 0 then return end
    for attempt = 1, 3 do
        local success, ownsPass = pcall(function()
            return MarketplaceService:UserOwnsGamePassAsync(player.UserId, skin.GamePassId)
        end)
        if success then
            if ownsPass and player.Parent then
                Profiles.GrantSkin(player, skinKey)
            end
            return
        end
        if attempt < 3 then task.wait(attempt) end
    end
    warn("Could not verify game pass for user " .. tostring(player.UserId))
end

Players.PlayerAdded:Connect(function(player)
    task.spawn(function()
        if not waitForProfile(player) then return end
        for _,skinKey in pairs(passToSkin) do
            refreshPassOwnership(player, skinKey)
        end
    end)
end)
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        if not waitForProfile(player) then return end
        for _,skinKey in pairs(passToSkin) do
            refreshPassOwnership(player, skinKey)
        end
    end)
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
    local skinKey = passToSkin[gamePassId]
    if not skinKey or not wasPurchased then return end
    task.spawn(function()
        -- Verify ownership against Roblox before the experience grants the permanent character.
        refreshPassOwnership(player, skinKey)
    end)
end)

shopRequest.OnServerInvoke = function(player, action, key)
    if type(action) ~= "string" then
        return { ok = false, message = "無效的商店請求。" }
    end
    local now = os.clock()
    if action ~= "GetState" then
        if now - (lastRequestAt[player.UserId] or 0) < 0.25 then
            return { ok = false, message = "操作太快，請稍候。" }
        end
        lastRequestAt[player.UserId] = now
    end
    if not waitForProfile(player) then
        return { ok = false, message = "資料尚未載入，請稍後再試。" }
    end

    if action == "GetState" then
        return { ok = true, state = Profiles.GetState(player) }
    end
    if type(key) ~= "string" then
        return { ok = false, message = "無效的商店請求。" }
    end

    if action == "BuyCoins" then
        local succeeded, message = Profiles.BuySkin(player, key)
        return { ok = succeeded, message = message, state = Profiles.GetState(player) }
    elseif action == "Equip" then
        local succeeded, message = Profiles.EquipSkin(player, key)
        return { ok = succeeded, message = message, state = Profiles.GetState(player) }
    elseif action == "PromptPass" then
        local skin = GameConfig.Skins[key]
        if not skin or not skin.GamePassId or skin.GamePassId <= 0 then
            return { ok = false, message = "這個角色尚未設定 Robux 商品。" }
        end
        return { ok = true, promptType = "GamePass", id = skin.GamePassId }
    elseif action == "PromptProduct" then
        local product = GameConfig.Products[key]
        if not product or not product.ProductId or product.ProductId <= 0 then
            return { ok = false, message = "這個商品尚未設定 Robux 商品 ID。" }
        end
        return { ok = true, promptType = "Product", id = product.ProductId }
    end

    return { ok = false, message = "不支援的商店操作。" }
end

-- ProcessReceipt is the sole authority for granting repeatable Robux products.
Players.PlayerRemoving:Connect(function(player)
    lastRequestAt[player.UserId] = nil
end)

MarketplaceService.ProcessReceipt = function(receiptInfo)
    if Catalog.Items.StarTrain.ProductId>0 and receiptInfo.ProductId==Catalog.Items.StarTrain.ProductId then
        local buyer=Players:GetPlayerByUserId(receiptInfo.PlayerId)
        if not buyer or not Profiles.IsLoaded(buyer) then return Enum.ProductPurchaseDecision.NotProcessedYet end
        local serial=Edition.Confirm(buyer.UserId,receiptInfo.PurchaseId)
        if not serial then return Enum.ProductPurchaseDecision.NotProcessedYet end
        if not Profiles.GrantEdition(buyer,serial) then return Enum.ProductPurchaseDecision.NotProcessedYet end
        root.Remotes.PremiumNotice:FireClient(buyer,string.format("銀河高鐵 #%03d / 500 已解鎖。",serial),"StarTrain")
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    local product = productById[receiptInfo.ProductId]
    if not player or not product then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local granted = Profiles.GrantCoinsFromReceipt(
        receiptInfo.PlayerId,
        receiptInfo.PurchaseId,
        product.Coins
    )
    if granted then
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end
    return Enum.ProductPurchaseDecision.NotProcessedYet
end
