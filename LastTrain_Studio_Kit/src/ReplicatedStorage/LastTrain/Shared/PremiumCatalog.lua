-- Set real PassId values from this experience's Creator Dashboard before sale.
local Catalog={Order={"NeonFlashlight","PremiumStaff","MysteryPassenger","LuxuryPass","LiveryBundle","VIP","RoyalCarriage","StarTrain"}}
Catalog.Items={
 NeonFlashlight={Name="霓虹手電筒",BasePrice=79,PassId=0,Kind="Flashlight",Description="霓虹燈框、三種光色、專屬手電筒。永久解鎖。",Color=Color3.fromRGB(77,218,225)},
 PremiumStaff={Name="高級站務員",BasePrice=149,PassId=0,Kind="Skin",Skin="PremiumStaff",Description="深藍訂製制服、橘色領帶與金屬名牌。永久角色。",Color=Color3.fromRGB(226,126,54)},
 MysteryPassenger={Name="神祕乘客",BasePrice=199,PassId=0,Kind="Skin",Skin="NightGuard",Description="黑色長外套、銀色面罩與神祕配件。永久角色。",Color=Color3.fromRGB(151,164,211)},
 LuxuryPass={Name="豪華列車通行證",BasePrice=299,PassId=0,Kind="Access",Description="第二車商務座位與白橘商務票面。保留一般乘客走道。",Color=Color3.fromRGB(224,176,101)},
 LiveryBundle={Name="列車外觀組合包",BasePrice=399,PassId=0,Kind="Livery",Description="解鎖晨光橘、午夜藍、香檳白；房主出發前選用。",Color=Color3.fromRGB(222,139,76)},
 VIP={Name="VIP 通行證",BasePrice=499,PassId=0,Kind="Skin",Skin="VIP",Description="VIP 正式服裝、金色名牌與專屬候車區。",Color=Color3.fromRGB(235,200,105)},
 RoyalCarriage={Name="皇家豪華車廂",BasePrice=799,PassId=0,Kind="Royal",Description="香檳白金皇家列車、第三車包廂、觀景座位、餐桌、休息床與茶飲吧。可邀同車朋友。",Color=Color3.fromRGB(206,171,101)},
 StarTrain={Name="銀河高鐵・限定500台",BasePrice=999,PassId=0,ProductId=0,Limited=500,Kind="Livery",Description="全遊戲限量500台，一人一台永久編號。銀河車身、星空頂棚與觀景內裝。",Color=Color3.fromRGB(126,135,231)},
}
Catalog.Liveries={
 Taiwan={Name="台灣高鐵・白橘",Body=Color3.fromRGB(241,243,241),Stripe=Color3.fromRGB(219,106,38)},
 Sunrise={Name="晨光橘",Pass="LiveryBundle",Body=Color3.fromRGB(246,241,229),Stripe=Color3.fromRGB(235,126,54)},
 Midnight={Name="午夜藍",Pass="LiveryBundle",Body=Color3.fromRGB(37,52,76),Stripe=Color3.fromRGB(175,190,207)},
 Champagne={Name="香檳白",Pass="LiveryBundle",Body=Color3.fromRGB(241,235,219),Stripe=Color3.fromRGB(173,143,86)},
 Royal={Name="皇家白金",Pass="RoyalCarriage",Body=Color3.fromRGB(245,237,216),Stripe=Color3.fromRGB(210,165,72)},
 Starfield={Name="銀河限定500台",Pass="StarTrain",Body=Color3.fromRGB(23,28,64),Stripe=Color3.fromRGB(153,160,234)},
}
Catalog.LiveryOrder={"Taiwan","Sunrise","Midnight","Champagne","Royal","Starfield"}
return Catalog
