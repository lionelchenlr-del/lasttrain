local Lighting = game:GetService("Lighting")

local Workspace = game:GetService("Workspace")
while Workspace:GetAttribute("LastTrainMode") == nil do
	Workspace:GetAttributeChangedSignal("LastTrainMode"):Wait()
end
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
atmosphere.Parent = Lighting
local color = Lighting:FindFirstChild("LastTrainColor") or Instance.new("ColorCorrectionEffect")
color.Name = "LastTrainColor"
color.Parent = Lighting
local bloom = Lighting:FindFirstChild("LastTrainBloom") or Instance.new("BloomEffect")
bloom.Name = "LastTrainBloom"
bloom.Parent = Lighting

local function applyLighting(isLobby)
	Lighting.ClockTime = isLobby and 20.4 or 20.15
	Lighting.Brightness = isLobby and 3.1 or 2.05
	Lighting.ExposureCompensation = isLobby and 0.18 or 0.04
	Lighting.GlobalShadows = true
	Lighting.Ambient = isLobby and Color3.fromRGB(158, 171, 180) or Color3.fromRGB(68, 82, 95)
	Lighting.OutdoorAmbient = isLobby and Color3.fromRGB(121, 136, 148) or Color3.fromRGB(47, 62, 78)
	Lighting.EnvironmentDiffuseScale = 0.42
	Lighting.EnvironmentSpecularScale = 0.8
	Lighting.FogColor = Color3.fromRGB(22, 31, 43)
	Lighting.FogStart = isLobby and 1000 or 250
	Lighting.FogEnd = isLobby and 3000 or 620
	atmosphere.Color = Color3.fromRGB(151, 174, 193)
	atmosphere.Decay = Color3.fromRGB(39, 53, 70)
	atmosphere.Density = isLobby and 0 or 0.035
	atmosphere.Glare = isLobby and 0.03 or 0.06
	atmosphere.Haze = isLobby and 0 or 0.16
	atmosphere.Offset = 0.1
	color.Brightness = 0.015
	color.Contrast = isLobby and 0.035 or 0.1
	color.Saturation = isLobby and 0.03 or -0.12
	color.TintColor = isLobby and Color3.fromRGB(222, 236, 232) or Color3.fromRGB(239, 243, 250)
	bloom.Intensity = isLobby and 0.06 or 0.07
	bloom.Size = 14
	bloom.Threshold = 1.45
end

applyLighting(Workspace:GetAttribute("LastTrainMode") == "Lobby")
Workspace:GetAttributeChangedSignal("LastTrainMode"):Connect(function()
	applyLighting(Workspace:GetAttribute("LastTrainMode") == "Lobby")
end)
