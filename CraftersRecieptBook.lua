--  ///////////////////////////////////////////////////////////////////////////////////////////
--
--   
--  Author: SLOKnightfall

--  


--  ///////////////////////////////////////////////////////////////////////////////////////////

local addonName, addon = ...
addon = LibStub("AceAddon-3.0"):NewAddon(addon, addonName, "AceEvent-3.0", "AceConsole-3.0", "AceHook-3.0")
local AceGUI = LibStub("AceGUI-3.0")
--local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local frames = {} 
addon.frames = frames

function addon:GetProfessionName(id)
	for i, d in pairs(Enum.Profession) do
		if d == id then
			return i
		end
	end
end

function addon:EventHandler(event, arg1, ...)
	if event == "ADDON_LOADED" then
	elseif event == "CRAFTINGORDERS_UPDATE_ORDER_COUNT" then
	end


end

---Ace based addon initilization
function addon:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("CraftersRecieptBookDB")
  self.db.char.orders = self.db.char.orders or {}

  
end

function addon:ADDON_LOADED(...)
	--if ... = Blizzard_Professions
end

function addon:TRADE_SKILL_CURRENCY_REWARD_RESULT(...)
	local orderInfo = ProfessionsFrame.OrdersPage.OrderView.order
	local details = ProfessionsFrame.OrdersPage.OrderView.OrderDetails.SchematicForm.Details.operationInfo
	local orderID = orderInfo.orderID
	local _, data = ...
	addon.db.char.orders[orderID]["reward"] = data
end


function addon:TRADE_SKILL_ITEM_CRAFTED_RESULT(...)
	local orderInfo = ProfessionsFrame.OrdersPage.OrderView.order
	local details = ProfessionsFrame.OrdersPage.OrderView.OrderDetails.SchematicForm.Details.operationInfo
	local orderID = orderInfo.orderID
	local _, data = ...
	local index = #addon.db.char.orders
	addon.db.char.orders[1]["results"] = data
end


IsAddOnLoaded("Blizzard_Professions")
function addon:OnEnable()
	--addon:HookScript(ProfessionsFrame.OrdersPage.OrderView.OrderDetails, "OnShow", function() print("show0")end)
	--addon:HookScript(ProfessionsFrame.OrdersPage.OrderView.OrderInfo.StartOrderButton, "OnClick", function() addon:GetOrderData() end)
	addon:HookScript(ProfessionsFrame.OrdersPage.OrderView.CreateButton, "OnClick", function() addon:GetOrderData() end)
	addon:HookScript(ProfessionsFrame.OrdersPage, "OnShow", function() addon.profitTextFrame:Show(); addon:UpdateFrames() end)
	addon:HookScript(ProfessionsFrame.OrdersPage, "OnHide", function() 
		addon.profitTextFrame:Hide() 
		addon.orderListFrame:Hide() 
		addon.detailsTextFrame:Hide() 
		addon.detailsTextFrame2:Hide() 
		addon.detailsTextFrame3:Hide() 

	end)
	addon:HookScript(ProfessionsFrame.OrdersPage.OrderView.OrderDetails, "OnShow", function() addon.profitTextFrame:Hide() end)
	addon:HookScript(ProfessionsFrame.OrdersPage.OrderView.OrderDetails, "OnHide", function() addon.profitTextFrame:Show() end)

	addon:SecureHook(ProfessionsFrame.OrdersPage, "UpdateOrdersRemaining", function() addon:UpdateFrames() end)



	if IsAddOnLoaded("Blizzard_Professions") then
		addon:InitFrames()
	else
		addon:RegisterEvent("ADDON_LOADED")



	end
	--addon:RegisterEvent("TRADE_SKILL_CURRENCY_REWARD_RESULT")
	addon:RegisterEvent("TRADE_SKILL_ITEM_CRAFTED_RESULT")
end



--0 = public
--1 = guild
--2 = personal
function GetOrderType()
	for _, typeTab in ipairs(ProfessionsFrame.OrdersPage.BrowseFrame.orderTypeTabs) do
		if typeTab.isSelected then
			return typeTab.orderType
		end
	end

end

function addon:GetOrderData()
	print("Logged Data")
	local orderInfo = ProfessionsFrame.OrdersPage.OrderView.order
	local details = ProfessionsFrame.OrdersPage.OrderView.OrderDetails.SchematicForm.Details.operationInfo
	local orderID = orderInfo.orderID
	local profession = C_TradeSkillUI.GetChildProfessionInfo().profession
	local currentDate = date('*t')

	local data = {
		profession = profession,
		details = details,
		orderInfo = orderInfo,
		date = currentDate,
	}

	tinsert(addon.db.char.orders, 1, data)

end

function clearData()
	addon.db.char.orders = {}
end


local function GetProfessionCrafts()
	local profession1, profession2
	local profession1Crafts = 0
	local profession2Crafts =  0
	local profession1Profit = 0
	local profession2Profit =  0
	for i, data in ipairs(addon.db.char.orders) do
		if not profession1 then
			profession1 = data.profession
		end
		if data.profession == profession1 then
			profession1Crafts = profession1Crafts + 1
			profession1Profit = profession1Profit + data.orderInfo.tipAmount - data.orderInfo.consortiumCut
		elseif data.profession ~= profession1 then
			if not profession2 then
				profession2 = data.profession
	 		end

			profession2Crafts = profession2Crafts + 1
			profession2Profit = profession2Profit + data.orderInfo.tipAmount - data.orderInfo.consortiumCut
		end
	end

	return {profession1, profession1Crafts, profession1Profit, profession2, profession2Crafts, profession2Profit}
end


function addon:InitFrames()
	local f = CreateFrame("Frame", nil, ProfessionsFrame.OrdersPage, "DetailsWindowTemplate");
	f:Hide()
	f:SetPoint("TOPLEFT",ProfessionsFrame.OrdersPage.BrowseFrame.OrdersRemainingDisplay, "TOPLEFT", -21, 5 )

		f:SetScript("OnEnter", function(frame)
		GameTooltip:SetOwner(frame, "ANCHOR_RIGHT");
		local claimInfo = C_CraftingOrders.GetOrderClaimInfo(C_TradeSkillUI.GetChildProfessionInfo().profession);
		local tooltipText;
		if claimInfo.hoursToRecharge then
			tooltipText = CRAFTING_ORDERS_CLAIMS_REMAINING_REFRESH_TOOLTIP:format(claimInfo.claimsRemaining, claimInfo.hoursToRecharge);
		else
			tooltipText = CRAFTING_ORDERS_CLAIMS_REMAINING_TOOLTIP:format(claimInfo.claimsRemaining);
		end
		GameTooltip_AddNormalLine(GameTooltip, tooltipText);
		GameTooltip:Show();
	end);
	f:SetScript("OnLeave", GameTooltip_Hide);
	addon.profitTextFrame = f
	ProfessionsFrame.OrdersPage.BrowseFrame.OrdersRemainingDisplay:Hide()




	local b = CreateFrame("Button", "Blu2", ProfessionsFrame.OrdersPage, "UIPanelButtonTemplate");
	b:SetPoint("TOPLEFT",f, "TOPRIGHT", 5, -5 )

	b:Show()
	b:SetSize(24,24)
	b:SetText("?")
	b:SetScript("OnClick", function() addon:ToggleScreen() end)

	f = CreateFrame("Frame", nil, ProfessionsFrame.OrdersPage, "DetailsWindowTemplate");
	f:Hide()
	f:SetPoint("TOPRIGHT",addon.profitTextFrame, "TOPLEFT", -21, 0 )
	addon.detailsTextFrame3 = f

	f = CreateFrame("Frame", nil, ProfessionsFrame.OrdersPage, "DetailsWindowTemplate");
	f:Hide()
	f:SetPoint("TOPRIGHT",addon.detailsTextFrame3, "TOPLEFT", -21, 0 )
	addon.detailsTextFrame2 = f

	f = CreateFrame("Frame", nil, ProfessionsFrame.OrdersPage, "DetailsWindowTemplate");
	f:Hide()
	f:SetPoint("TOPRIGHT",addon.detailsTextFrame2, "TOPLEFT", -21, 0 )
	addon.detailsTextFrame = f

	local f = CreateFrame("Frame", "Blu", ProfessionsFrame, "ProfessionsCraftingOrderPageTemplate2");
	f:Hide()
	addon.orderListFrame = f

end

function addon:ToggleScreen()
ProfessionsFrame.OrdersPage.BrowseFrame:SetShown(not ProfessionsFrame.OrdersPage.BrowseFrame:IsShown())
addon.orderListFrame:SetShown(not ProfessionsFrame.OrdersPage.BrowseFrame:IsShown())
addon.detailsTextFrame:SetShown(not ProfessionsFrame.OrdersPage.BrowseFrame:IsShown())
addon.detailsTextFrame2:SetShown(not ProfessionsFrame.OrdersPage.BrowseFrame:IsShown())
addon.detailsTextFrame3:SetShown(not ProfessionsFrame.OrdersPage.BrowseFrame:IsShown())
end

function addon:ConvertToGold(value)
	local gold = floor(value / (COPPER_PER_SILVER * SILVER_PER_GOLD));
	local goldDisplay = BreakUpLargeNumbers(gold);
	local silver = floor((value - (gold * COPPER_PER_SILVER * SILVER_PER_GOLD)) / COPPER_PER_SILVER);
	local copper = mod(value, COPPER_PER_SILVER);

	local goldString = GOLD_AMOUNT_TEXTURE:format(gold, 0, 0);
	local silverString = SILVER_AMOUNT_TEXTURE:format(silver, 0, 0);
	local copperString = COPPER_AMOUNT_TEXTURE:format(copper, 0, 0);

	return {goldString, silverString, copperString}
end

function addon:UpdateFrames()
	ProfessionsFrame.OrdersPage.BrowseFrame.OrdersRemainingDisplay:Hide()
	--ProfessionsFrame.OrdersPage.BrowseFrame:Hide()
	addon:UpdateTotals()
end

function addon:UpdateTotals()
	local currentDate = date('*t')
	local totalProfit = 0
	local dailyProfit = 0
	local inspired = 0
	local resourceful = 0
	local multicraft = 0
	local profession = C_TradeSkillUI and C_TradeSkillUI.GetChildProfessionInfo()
	local profession1, profession2
	local profession1Profit = 0
	local profession2Profit = 0
	if not profession.profession then return end

	local remainingClaims = C_CraftingOrders.GetOrderClaimInfo(profession.profession).claimsRemaining or 0
	for id, data in ipairs(addon.db.char.orders) do
		local orderprofit = data.orderInfo.tipAmount - data.orderInfo.consortiumCut 
		totalProfit = totalProfit + orderprofit

		if data.date.month == currentDate.month and data.date.day == currentDate.day and data.date.year == currentDate.year then
			local orderprofit = data.orderInfo.tipAmount - data.orderInfo.consortiumCut 
			dailyProfit = dailyProfit + orderprofit
		end

		if data.results.isCrit then
			inspired = inspired + 1
		end
		if data.results.resourcesReturned then
			resourceful = resourceful + 1
		end
		if data.results.multicraft ~= 0 then
			multicraft = multicraft + 1
		end
	end

	totalProfit = addon:ConvertToGold(totalProfit)
	dailyProfit = addon:ConvertToGold(dailyProfit)

	addon.profitTextFrame.Field1:SetText("Orders Remaining: "..remainingClaims)
	addon.profitTextFrame.Field2:SetText("Daily Profit: "..dailyProfit[1].."   "..dailyProfit[2].."   "..dailyProfit[3])
	addon.profitTextFrame.Field3:SetText("Total Profit: "..totalProfit[1].."   "..totalProfit[2].."   "..totalProfit[3])
	
	local craftData = GetProfessionCrafts()
	if not craftData[1] then return end
	local profession1 = addon:GetProfessionName(craftData[1])
	local profession2
	addon.detailsTextFrame.Field1:SetText("Total Orders Crafted: "..#addon.db.char.orders)
	addon.detailsTextFrame.Field2:SetText(profession1..": "..craftData[2])

	if craftData[4] then
		profession2 = addon:GetProfessionName(craftData[4])
		addon.detailsTextFrame.Field3:SetText(profession2..": "..craftData[5])
		local profit = addon:ConvertToGold(craftData[6])
		addon.detailsTextFrame3.Field3:SetText(profession2..": ".. profit[1].."   "..profit[2].."   "..profit[3])
	else
		addon.detailsTextFrame.Field3:Hide()
		addon.detailsTextFrame3.Field2:Hide()

	end
	

	addon.detailsTextFrame2.Field1:SetText("Inspired Procs: "..inspired)
	addon.detailsTextFrame2.Field2:SetText("Resourceful Procs: ".. resourceful)
	addon.detailsTextFrame2.Field3:SetText("Multicraft Procs: "..multicraft)
	local profit = addon:ConvertToGold(craftData[3])
	addon.detailsTextFrame3.Field1:SetText("=Profit by Profession=")
	addon.detailsTextFrame3.Field2:SetText(profession1..": ".. profit[1].."   "..profit[2].."   "..profit[3])	 
	--return profit
end