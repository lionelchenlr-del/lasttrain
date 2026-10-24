-- Shared configuration. Replace every 0 marketplace ID with the ID from Creator Dashboard.
local GameConfig = {}

GameConfig.DataStoreName = "LastTrain_PlayerData_v1"
-- Shared geometry and timing: wheel contact, doors and safety use one layout.
GameConfig.StationSpacing = 2800
GameConfig.TravelDuration = 42
GameConfig.MinimumStopDuration = 8
GameConfig.DepartureCountdown = 3
GameConfig.FirstStationGateX = -120
GameConfig.FirstStationEntrySpawnX = -170
GameConfig.TrainCenterZ = -6.35
GameConfig.TrackHalfGauge = 4.05
GameConfig.RailTop = -1.55
GameConfig.PlatformHalfLength = 210
GameConfig.ObjectiveRewards = { 100, 150, 180, 180, 220, 250, 500 }
GameConfig.Objectives = {
	"領取無目的地車票，刷卡通過閘門後上車",
	"調查乘客紀錄簿，找出空白的離站紀錄",
	"找到真正的錄音，關閉錯誤的廣播",
	"拍下異常倒影，找回實驗報告缺頁",
	"調查乘客留下的物品與監視器影像",
	"搜尋事故紀錄，決定是否相信站務員",
	"進入 HOME TERMINAL，揭開列車循環的真相",
}

GameConfig.Stations = {
	{ Name = "新月站", English = "NEW MOON", Accent = Color3.fromRGB(94, 205, 230), Story = "車票沒有目的地。背面卻多了一行字：你的旅程早已開始。" },
	{ Name = "失語站", English = "SILENT", Accent = Color3.fromRGB(132, 220, 162), Story = "候車乘客全都面向牆壁。小女孩把照片塞進你手裡：「不要讓他知道你認出他了。」" },
	{ Name = "回聲站", English = "ECHO", Accent = Color3.fromRGB(250, 194, 93), Story = "錄音說這是第三次循環。控制室外有人敲玻璃，監視器裡卻空無一人。" },
	{ Name = "鏡湖站", English = "MIRROR LAKE", Accent = Color3.fromRGB(105, 190, 245), Story = "湖面倒影慢了幾秒。另一列相同的列車裡，所有乘客都正看著你。" },
	{ Name = "遺忘站", English = "FORGOTTEN", Accent = Color3.fromRGB(244, 181, 113), Story = "監視器拍到三天前的你。影像中的你轉向鏡頭：「不要讓列車到第七站。」" },
	{ Name = "終寂站", English = "LAST MAINTENANCE", Accent = Color3.fromRGB(244, 126, 82), Story = "維修基地停著數十列 LAST TRAIN。站務員摘下帽子，那張臉和你一模一樣。" },
	{ Name = "不存在的終點", English = "HOME TERMINAL", Accent = Color3.fromRGB(255, 218, 132), Story = "原始紀錄寫著你的名字：第七站事故調查員。站務員一直在阻止循環崩塌。" },
}

GameConfig.Endings = {
	Conductor = "你相信站務員，列車載你穿過明亮隧道。你回到熟悉的城市。身後廣播響起，傳出的卻是你的聲音。",
	Truth = "你關閉核心，七站燈光依序熄滅。站務員恢復原貌：「謝謝你，終於有人讓這趟列車停下來。」",
	Station08 = "你啟動封存系統。七個站名消失，電子看板亮起 STATION 08。廣播說：「歡迎回來，調查員。」",
}

-- Purchasable characters are visual loadouts. The default body colors work without any assets.
-- Optional ShirtTemplate/PantsTemplate values accept clothing template asset IDs (not catalog page IDs).
GameConfig.Skins = {
    PlatformWorker = {
        DisplayName = "月台巡守",
        Ability = "穩定步伐：標準移速，適合初次調查。",
        WalkSpeedMultiplier = 1,
        FlashlightMultiplier = 1,
        MonsterDetectionMultiplier = 1,
        PriceCoins = 0,
        GamePassId = 0,
        Colors = { Main = Color3.fromRGB(80, 104, 112), Accent = Color3.fromRGB(216, 171, 78) },
        ShirtTemplate = 0,
        PantsTemplate = 0,
    },
    Conductor = {
        DisplayName = "夜班列車長",
        Ability = "列車長步法：移動速度提高 15%。",
        WalkSpeedMultiplier = 1.15,
        FlashlightMultiplier = 1,
        MonsterDetectionMultiplier = 1,
        PriceCoins = 350,
        GamePassId = 0,
        Colors = { Main = Color3.fromRGB(38, 53, 72), Accent = Color3.fromRGB(220, 187, 111) },
        ShirtTemplate = 0,
        PantsTemplate = 0,
    },
    Signalman = {
        DisplayName = "號誌技師",
        Ability = "訊號探照燈：手電筒照射距離提高 40%。",
        WalkSpeedMultiplier = 1,
        FlashlightMultiplier = 1.4,
        MonsterDetectionMultiplier = 1,
        PriceCoins = 700,
        GamePassId = 0,
        Colors = { Main = Color3.fromRGB(112, 49, 42), Accent = Color3.fromRGB(225, 207, 166) },
        ShirtTemplate = 0,
        PantsTemplate = 0,
    },
    NightGuard = {
        DisplayName = "深夜站務員",
        Ability = "靜默巡查：站務員感知距離降低 25%。",
        WalkSpeedMultiplier = 1,
        FlashlightMultiplier = 1,
        MonsterDetectionMultiplier = 0.75,
        PriceCoins = 0,
        GamePassId = 0, -- Create a one-time game pass, then paste its ID here.
        RequiresGamePass = true,
        Colors = { Main = Color3.fromRGB(28, 31, 36), Accent = Color3.fromRGB(171, 47, 39) },
        ShirtTemplate = 0,
        PantsTemplate = 0,
    },
}

-- Developer products are repeatable Robux purchases. Receipt handling is server-side.
GameConfig.Products = {
    CoinPouch = { DisplayName = "300 張車票幣", ProductId = 0, Coins = 300 },
    CoinCrate = { DisplayName = "1,000 張車票幣", ProductId = 0, Coins = 1000 },
}

return GameConfig
