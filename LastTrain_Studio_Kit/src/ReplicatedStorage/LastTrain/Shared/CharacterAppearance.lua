-- Shared visual-only uniforms. Currency and unlocks remain in ProfileService.
local GameConfig = require(script.Parent:WaitForChild("GameConfig"))
local Appearance = {}
function Appearance.Apply(character, skinKey)
    local skin = GameConfig.Skins[skinKey]
    if not skin or not character then return end
    -- A purchased role is a complete uniform set. Clear layered clothes and
    -- headwear that would cover it, while retaining the player's face and skin.
    for _, item in ipairs(character:GetChildren()) do
        if item:IsA("Accessory") or item:IsA("ShirtGraphic") then
            item:Destroy()
        elseif item:IsA("Shirt") and (not skin.ShirtTemplate or skin.ShirtTemplate <= 0) then
            item:Destroy()
        elseif item:IsA("Pants") and (not skin.PantsTemplate or skin.PantsTemplate <= 0) then
            item:Destroy()
        end
    end

    local bodyColors = character:FindFirstChildOfClass("BodyColors")
    if not bodyColors then
        bodyColors = Instance.new("BodyColors")
        bodyColors.Parent = character
    end
    local main = skin.Colors.Main
    local accent = skin.Colors.Accent
    local darkTrim = main:Lerp(Color3.fromRGB(8, 15, 20), 0.36)
    -- Keep the player's actual skin tone. Earlier skins painted the head in the
    -- uniform accent color, which made every preview look like a plastic mask.
    local originalHeadColor = character:GetAttribute("LastTrainOriginalHeadColor")
    if typeof(originalHeadColor) ~= "Color3" then
        originalHeadColor = bodyColors.HeadColor3
        character:SetAttribute("LastTrainOriginalHeadColor", originalHeadColor)
    end
    bodyColors.HeadColor3 = originalHeadColor
    bodyColors.LeftArmColor3 = main
    bodyColors.RightArmColor3 = main
    bodyColors.LeftLegColor3 = main
    bodyColors.RightLegColor3 = main
    bodyColors.TorsoColor3 = main

    local oldVisuals = character:FindFirstChild("LastTrainSkinVisuals")
    if oldVisuals then oldVisuals:Destroy() end
    local visuals = Instance.new("Folder")
    visuals.Name = "LastTrainSkinVisuals"
    visuals.Parent = character
    local head = character:FindFirstChild("Head")
    local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")

    local function weldedPart(name, parentPart, size, color, offset, material, shape)
        if not parentPart then return end
        local visual = Instance.new("Part")
        visual.Name = name
        visual.Size = size
        visual.Color = color
        visual.Material = material or Enum.Material.SmoothPlastic
        visual.Shape = shape or Enum.PartType.Block
        visual.Anchored = false
        visual.Massless = true
        visual.CanCollide = false
        visual.CanTouch = false
        visual.CanQuery = false
        visual.CastShadow = true
        visual.CFrame = parentPart.CFrame * offset
        visual.Parent = visuals
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = parentPart
        weld.Part1 = visual
        weld.Parent = visual
        return visual
    end

    if torso then
        local width, height, depth = torso.Size.X, torso.Size.Y, torso.Size.Z
        local front = -(depth / 2 + 0.045)
        local softMain = main:Lerp(Color3.fromRGB(255, 255, 255), 0.08)

        -- Tailored front panels, collar, pockets, buttons and a readable badge
        -- make each loadout feel like a designed uniform on R6 and R15 bodies.
        weldedPart("UniformJacketFront", torso, Vector3.new(width * 0.76, height * 0.78, 0.08), softMain, CFrame.new(0, 0, front), Enum.Material.Fabric)
        weldedPart("UniformCollarLeft", torso, Vector3.new(width * 0.23, 0.12, 0.1), accent, CFrame.new(-width * 0.18, height * 0.34, front - 0.025), Enum.Material.SmoothPlastic)
        weldedPart("UniformCollarRight", torso, Vector3.new(width * 0.23, 0.12, 0.1), accent, CFrame.new(width * 0.18, height * 0.34, front - 0.025), Enum.Material.SmoothPlastic)
        weldedPart("UniformPlacket", torso, Vector3.new(0.1, height * 0.55, 0.07), accent, CFrame.new(0, 0, front - 0.06), Enum.Material.Metal)
        weldedPart("UniformPocketLeft", torso, Vector3.new(width * 0.2, height * 0.18, 0.07), darkTrim, CFrame.new(-width * 0.23, height * 0.1, front - 0.04), Enum.Material.Fabric)
        weldedPart("UniformPocketRight", torso, Vector3.new(width * 0.2, height * 0.18, 0.07), darkTrim, CFrame.new(width * 0.23, height * 0.1, front - 0.04), Enum.Material.Fabric)
        weldedPart("UniformNameBadge", torso, Vector3.new(0.2, 0.24, 0.09), accent, CFrame.new(-width * 0.24, height * 0.28, front - 0.08), Enum.Material.Metal, Enum.PartType.Ball)
        weldedPart("UniformBelt", torso, Vector3.new(width * 0.7, 0.1, 0.07), darkTrim, CFrame.new(0, -height * 0.38, front - 0.035), Enum.Material.Metal)
        weldedPart("UniformBuckle", torso, Vector3.new(0.2, 0.16, 0.09), accent, CFrame.new(0, -height * 0.38, front - 0.08), Enum.Material.Metal)
        local back = depth / 2 + 0.04
        weldedPart("UniformBackYoke", torso, Vector3.new(width * 0.72, height * 0.2, 0.07), darkTrim, CFrame.new(0, height * 0.29, back), Enum.Material.Fabric)
        weldedPart("UniformBackSeam", torso, Vector3.new(0.045, height * 0.48, 0.08), accent, CFrame.new(0, -height * 0.04, back + 0.015), Enum.Material.Metal)
        weldedPart("UniformBackReflector", torso, Vector3.new(width * 0.67, 0.09, 0.08), accent, CFrame.new(0, -height * 0.3, back), Enum.Material.SmoothPlastic)
    end

    for _, side in ipairs({"Left", "Right"}) do
        local upperArm = character:FindFirstChild(side .. "UpperArm") or character:FindFirstChild(side .. " Arm")
        local lowerArm = character:FindFirstChild(side .. "LowerArm")
        local arm = lowerArm or upperArm
        if arm then
            local front = -(arm.Size.Z / 2 + 0.035)
            weldedPart("UniformSleeveStripe_" .. side, arm, Vector3.new(arm.Size.X * 0.86, 0.075, 0.06), accent, CFrame.new(0, -arm.Size.Y * 0.28, front), Enum.Material.SmoothPlastic)
        end
        if upperArm then
            local front = -(upperArm.Size.Z / 2 + 0.035)
            weldedPart("UniformShoulderTab_" .. side, upperArm, Vector3.new(upperArm.Size.X * 0.72, 0.12, 0.08), darkTrim, CFrame.new(0, upperArm.Size.Y * 0.35, front), Enum.Material.Metal)
        end
    end

    local lowerTorso = character:FindFirstChild("LowerTorso")
    if lowerTorso then
        local front = -(lowerTorso.Size.Z / 2 + 0.04)
        weldedPart("UniformUtilityBelt", lowerTorso, Vector3.new(lowerTorso.Size.X * 0.78, 0.12, 0.08), darkTrim, CFrame.new(0, -lowerTorso.Size.Y * 0.3, front), Enum.Material.Metal)
    end

    for _, footName in ipairs({"LeftFoot", "RightFoot"}) do
        local foot = character:FindFirstChild(footName)
        if foot then
            weldedPart("UniformBoot_" .. footName, foot, Vector3.new(foot.Size.X * 1.08, foot.Size.Y * 0.62, foot.Size.Z * 1.08), darkTrim, CFrame.new(0, -foot.Size.Y * 0.16, 0), Enum.Material.Leather, Enum.PartType.Ball)
            weldedPart("UniformBootTrim_" .. footName, foot, Vector3.new(foot.Size.X * 0.8, 0.07, foot.Size.Z * 1.1), accent, CFrame.new(0, -foot.Size.Y * 0.42, 0), Enum.Material.Metal)
        end
    end

    if head then
        local headTop = head.Size.Y / 2
        local brimSize = Vector3.new(0.2, head.Size.X * 0.88, head.Size.Z * 0.86)
        local brimOffset = CFrame.new(0, headTop + 0.02, 0) * CFrame.Angles(0, 0, math.rad(90))
        local crownColor = skinKey == "Signalman" and Color3.fromRGB(184, 67, 48) or main
        weldedPart("UniformCapBrim", head, brimSize, darkTrim, brimOffset, Enum.Material.Metal, Enum.PartType.Cylinder)

        if skinKey == "Signalman" then
            weldedPart("SignalHelmetCrown", head, Vector3.new(head.Size.X * 0.9, head.Size.Y * 0.46, head.Size.Z * 0.88), crownColor, CFrame.new(0, headTop + head.Size.Y * 0.12, 0), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
            weldedPart("SignalHelmetRim", head, Vector3.new(0.12, head.Size.X * 1.02, head.Size.Z * 0.92), accent, CFrame.new(0, headTop - 0.03, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Metal, Enum.PartType.Cylinder)
        else
            weldedPart("UniformCapCrown", head, Vector3.new(head.Size.X * 0.78, head.Size.Y * 0.34, head.Size.Z * 0.76), crownColor, CFrame.new(0, headTop + head.Size.Y * 0.13, 0), Enum.Material.Fabric, Enum.PartType.Ball)
            weldedPart("UniformCapVisor", head, Vector3.new(head.Size.X * 0.56, 0.1, head.Size.Z * 0.42), accent, CFrame.new(0, headTop + 0.015, -head.Size.Z * 0.42), Enum.Material.Metal)
        end
        weldedPart("UniformCapBadge", head, Vector3.new(0.17, 0.2, 0.08), accent, CFrame.new(0, headTop + head.Size.Y * 0.13, -head.Size.Z * 0.47), Enum.Material.Metal, Enum.PartType.Ball)
    end

    if skinKey == "NightGuard" and torso then
        local front = -(torso.Size.Z / 2 + 0.11)
        weldedPart("NightGuardScarf", torso, Vector3.new(torso.Size.X * 0.74, torso.Size.Y * 0.22, 0.22), accent, CFrame.new(0, torso.Size.Y * 0.34, front), Enum.Material.Fabric, Enum.PartType.Ball)
        weldedPart("NightGuardScarfTail", torso, Vector3.new(0.22, torso.Size.Y * 0.48, 0.12), accent, CFrame.new(torso.Size.X * 0.2, torso.Size.Y * 0.05, front - 0.02), Enum.Material.Fabric)
    elseif skinKey == "Signalman" and torso then
        weldedPart("SignalmanToolRadio", torso, Vector3.new(0.25, 0.34, 0.14), darkTrim, CFrame.new(torso.Size.X * 0.31, torso.Size.Y * 0.28, -(torso.Size.Z / 2 + 0.1)), Enum.Material.Metal)
        weldedPart("SignalmanRadioLamp", torso, Vector3.new(0.08, 0.08, 0.06), Color3.fromRGB(255, 90, 68), CFrame.new(torso.Size.X * 0.31, torso.Size.Y * 0.34, -(torso.Size.Z / 2 + 0.19)), Enum.Material.Neon, Enum.PartType.Ball)
    elseif skinKey == "PlatformWorker" and torso then
        weldedPart("ReflectiveVestStripe", torso, Vector3.new(torso.Size.X * 0.76, 0.12, 0.08), accent, CFrame.new(0, -torso.Size.Y * 0.08, -(torso.Size.Z / 2 + 0.1)), Enum.Material.Neon)
    end

    if skin.ShirtTemplate and skin.ShirtTemplate > 0 then
        local shirt = character:FindFirstChildOfClass("Shirt") or Instance.new("Shirt")
        shirt.ShirtTemplate = "rbxassetid://" .. tostring(skin.ShirtTemplate)
        shirt.Parent = character
    end
    if skin.PantsTemplate and skin.PantsTemplate > 0 then
        local pants = character:FindFirstChildOfClass("Pants") or Instance.new("Pants")
        pants.PantsTemplate = "rbxassetid://" .. tostring(skin.PantsTemplate)
        pants.Parent = character
    end
end
return Appearance
