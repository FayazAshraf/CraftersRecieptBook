--  ///////////////////////////////////////////////////////////////////////////////////////////
--
--   
--  Author: SLOKnightfall

--  


--  ///////////////////////////////////////////////////////////////////////////////////////////

local addonName, addon = ...
addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local reagentSlotSchematic={
	quantityRequired=1,
	slotIndex=1,
	dataSlotIndex=1,
	dataSlotType=2,
	slotInfo={
		mcrSlotID=143,
		requiredSkillRank=0,
		slotText="Shimmering Clasp (DNT)"
	},
	reagentType=1,
	orderSource=0,
	reagents={
	[1]={itemID=191499},
	[2]={itemID=191500},
	[3]={itemID=191501}
	}
}

local useIncense = false
local function SetIncense(item)
	useIncense = item
	addon.incense.Button:SetItem(item);
	addon.incense:SetHighlightShown(not addon.incense:IsOriginalItemSet());
	addon.CraftButton:Show()
	ProfessionsFrame.OrdersPage.OrderView.CreateButton:Hide()
end

local function ClearIncense()
	useIncense = false
	addon.incense.Button:SetItem();
	addon.incense.Button.InputOverlay.AddIcon:Show();
	addon.incense:SetHighlightShown(false);
	if addon.CraftButton:IsShown() then
		addon.CraftButton:Hide()
		ProfessionsFrame.OrdersPage.OrderView.CreateButton:Show()
	end
end

function addon:DisableIncense()
	addon.incense.Button:SetLocked(true);
	addon.incense.Button.InputOverlay.AddIcon:SetDesaturated(true);
	addon.incense.unallocatable = true
	ClearIncense()
end

function addon:EnableIncense()
	addon.incense.Button:SetLocked(false);
	addon.incense.Button.InputOverlay.AddIcon:SetDesaturated(false);
	addon.incense.unallocatable = false
end


function addon:InitIncense()

	if not addon.incense then
		local b = CreateFrame("Button", nil, ProfessionsFrame.OrdersPage.OrderView, "UIPanelButtonTemplate")
		b:SetPoint("BOTTOMRIGHT",ProfessionsFrame.OrdersPage.OrderView.CreateButton, "BOTTOMRIGHT", -50,0)	
		b:SetSize(80,22)
		b:SetText("ASDFASDFSADFASDF") --CREATE_PROFESSION);
		b:SetScript("OnClick", function()
			if ProfessionsFrame.OrdersPage.OrderView:IsRecrafting() then
				ProfessionsFrame.OrdersPage.OrderView:RecraftOrder();
			else
				ProfessionsFrame.OrdersPage.OrderView:CraftOrder();
			end
		 end);
		addon.CraftButton = b

		local b = CreateFrame("Button", nil, ProfessionsFrame.OrdersPage.OrderView.OrderDetails, "ProfessionsReagentSlotTemplate")
		b:SetPoint("BOTTOMRIGHT",ProfessionsFrame.OrdersPage.OrderView.OrderDetails.SchematicForm.Details, "BOTTOMRIGHT", -45, 42 )
		b:SetSize(24,24)

		local transaction = ProfessionsFrame.OrdersPage.OrderView.OrderDetails.SchematicForm:GetTransaction();
		b.reagentSlotSchematic = reagentSlotSchematic

		local button = b.Button
		button:SetLocked(false);
		b.Button.InputOverlay.AddIcon:SetDesaturated(true);
		b.unallocatable = true

		button:SetScript("OnEnter", function()
			GameTooltip:SetOwner(button, "ANCHOR_RIGHT");
			local item = Item:CreateFromItemID(191499);
			local colorData = item:GetItemQualityColor();
			GameTooltip_SetTitle(GameTooltip, item:GetItemName(), colorData.color, false);
		
			GameTooltip_AddHighlightLine(GameTooltip, "Drop incense before crafting");
			GameTooltip:Show();
		end);
				
		button:SetScript("OnMouseDown", function(button, buttonName, down)
			if not b.unallocatable then

				if buttonName == "LeftButton" then
					local flyout = ToggleProfessionsItemFlyout(button, ProfessionsCustomerOrdersFrame);
					if flyout then
						local function OnFlyoutItemSelected(o, flyout, elementData)
							local item = elementData.item;
							SetIncense(item:GetItemID())
						end

						flyout.GetElementsImplementation = function(self, filterOwned)
							local itemIDs = Professions.ExtractItemIDsFromCraftingReagents(reagentSlotSchematic.reagents);
							if filterOwned then
								itemIDs = ItemUtil.FilterOwnedItems(itemIDs);
							end
							local items = ItemUtil.TransformItemIDsToItems(itemIDs);
							local elementData = {items = items};
							return elementData;
						end
						
						flyout.OnElementEnterImplementation = function(elementData, tooltip)
							local item = elementData.item;
							local itemID = item:GetItemID()
							local colorData = item:GetItemQualityColor();


							GameTooltip_SetTitle(tooltip, item:GetItemName(), colorData.color);
							local bonusText 
							if itemID == 191499 then
								bonusText = "Increase Inspiration for 10 min"
							elseif itemID == 191500 then
								bonusText = "Increase Inspiration for 20 min"
							elseif itemID == 191501 then
								bonusText = "Increase Inspiration for 30 min"
							end

							GameTooltip_AddHighlightLine(tooltip, bonusText);
							local quality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(itemID);
							if quality then
								--GameTooltip_AddBlankLineToTooltip(tooltip);
								local atlasSize = 26;
								local atlasMarkup = CreateAtlasMarkup(Professions.GetIconForQuality(quality, true), atlasSize, atlasSize);
								GameTooltip_AddHighlightLine(tooltip, PROFESSIONS_CRAFTING_QUALITY:format(atlasMarkup));
							end

							local count = ItemUtil.GetCraftingReagentCount(itemID);
							if count <= 0 then
								GameTooltip_AddErrorLine(tooltip, OPTIONAL_REAGENT_NONE_AVAILABLE);
							end
						end

						flyout:Init(button, transaction);
						flyout:RegisterCallback(ProfessionsItemFlyoutMixin.Event.ItemSelected, OnFlyoutItemSelected, b);
					end
				elseif buttonName == "RightButton" and not b.originalItem then
					ClearIncense()
				end
			end
		end);
		addon.incense = b
	end

	addon.incense:Show()
	addon.DisableIncense()	
end

function addon:InspirationReminder()
	local OrderDetails = ProfessionsFrame.OrdersPage.OrderView.OrderDetails.SchematicForm.Details.operationInfo
	local skillNeeded = OrderDetails.upperSkillTreshold
	local skill = OrderDetails.baseSkill
	local bounsSkill = OrderDetails.bonusSkill
	if skillNeeded <= (skill + bounsSkill) then 
		local itemLink = GetInventoryItemLink("player", GetInventorySlotInfo("PROF0TOOLSLOT"))
		local extractedStats = GetItemStats(itemLink)
		if extractedStats["ITEM_MOD_INSPIRATION_SHORT"] then
			addon.GearSwapWarning:Show()
		else
			addon.GearSwapWarning:Hide()
		end
	end
end