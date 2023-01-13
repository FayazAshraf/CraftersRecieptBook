--  ///////////////////////////////////////////////////////////////////////////////////////////
--
--   
--  Author: SLOKnightfall

--  


--  ///////////////////////////////////////////////////////////////////////////////////////////

local addonName, addon = ...
addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local AceGUI = LibStub("AceGUI-3.0")
--local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local function GetOrderData(id)
	for i, d in ipairs(addon.db.char.orders) do
		if d.orderInfo.orderID == id then 
		 	return d
		end
	end
end

function UpdateTransaction(data)
	--self.transaction
local reagents = data.orderInfo.orderInfo.reagents
--		xx = self.transaction.self.allocationTbls
if not reagents then return end
for i, d in ipairs(reagents) do
	xx = d
local quantity = d.reagent.quantity
local slot = d.reagentSlot

local reagent = d.reagent.itemID

if slot then 
	print(slot)
		--allocations = CreateAndInitFromMixin(AllocationsMixin)
	--	allocations.reagent.itemID
		  --  allocs={
    --  [1]={
      --  reagent={
        --  itemID=193370
      --  },
       -- quantity=3,

      --}
      --xxxx = data.transaction.allocationTbls[slot]
      --tbl = data.transaction.allocationTbls[slot]

		--table.insert(self.allocationTbls, allocations)
--data.transaction.allocationTbls[slot]:Allocate(reagent, math.min(quantity, quantity))
--print(tbl.allocs.quantity)
print(tbl.allocs)
if tbl.allocs  then
		print("settinsg")
	tbl.allocs:SetQuantity(60)
	end
end
end

end
ProfessionsRecipeSchematicFormMixin2 = CreateFromMixins(ProfessionsRecipeSchematicFormMixin)

function ProfessionsRecipeSchematicFormMixin2:OnLoad()
	CallbackRegistryMixin.OnLoad(self)

	self.elapsed = 0
	self.extraSlotFrames = {}

	local function PoolReset(pool, slot)
		slot:Reset()
		slot.Button:SetScript("OnEnter", nil)
		slot.Button:SetScript("OnClick", nil)
		slot.Button:SetScript("OnMouseDown", nil)
		FramePool_HideAndClearAnchors(pool, slot)
	end

	self.reagentSlotPool = CreateFramePool("FRAME", self, "ProfessionsReagentSlotTemplate", PoolReset)
	self.selectedRecipeLevels = {}

	self.RecraftingRequiredTools:SetPoint("TOPLEFT", self.RecraftingOutputText, "BOTTOMLEFT", 0, -4)
end

function ProfessionsRecipeSchematicFormMixin2:OnShow()
    --FrameUtil.RegisterFrameForEvents(self, ProfessionsRecipeFormEvents)
local order = GetOrderData(7302607) --7146948) --addon.db.char.orders[1]
	local recipeInfo = C_TradeSkillUI.GetRecipeInfo(order.orderInfo.spellID) --addon.db.char.orders[1]
self.orderInfo = order
	if recipeInfo then
		-- Details, including optional reagent unlocks, may have changed due to purchasing specialization points
		self:Init(recipeInfo, self.isRecraftOverride)
		--self:UpdateDetailsStats()
	end

	self.canUpdate = true
end

function ProfessionsRecipeSchematicFormMixin2:OnHide()
end

local function CreateVerticalLayoutOrganizer(anchor, xPadding, yPadding)
	local OrganizerMixin = {entries = {}}

	xPadding = xPadding or 0
	yPadding = yPadding or 0

	function OrganizerMixin:Add(frame, order, xPadding, yPadding)
		table.insert(self.entries, {
			frame = frame, 
			order = order, 
			xPadding = xPadding or 0,
			yPadding = yPadding or 0,
		})
	end

	function OrganizerMixin:Layout()
		table.sort(self.entries, function(lhs, rhs)
			return lhs.order < rhs.order
		end)

		local relative = nil
		for index, entry in ipairs(self.entries) do
			entry.frame:ClearAllPoints()

			if relative then
				local x = xPadding + entry.xPadding
				local y = -(yPadding + entry.yPadding)
				entry.frame:SetPoint("TOPLEFT", relative, "BOTTOMLEFT", x, y)
			else
				entry.frame:SetPoint(anchor:Get())
			end
			relative = entry.frame
		end
	end

	return CreateFromMixins(OrganizerMixin)
end

local LayoutEntry = EnumUtil.MakeEnum("Cooldown", "Description", "Source", "FirstCraftBonus")
local RequirementTypeToString =
{
	[Enum.RecipeRequirementType.SpellFocus] = "SpellFocusRequirement",
	[Enum.RecipeRequirementType.Totem] = "TotemRequirement",
	[Enum.RecipeRequirementType.Area] = "AreaRequirement",
}

local StringToRequirementType = tInvert(RequirementTypeToString)

local function FormatRequirements(requirements)
	local formattedRequirements = {}
	for index, recipeRequirement in ipairs(requirements) do
		table.insert(formattedRequirements, LinkUtil.FormatLink(RequirementTypeToString[recipeRequirement.type], recipeRequirement.name))
		table.insert(formattedRequirements, recipeRequirement.met)
	end
	return formattedRequirements
end
function ProfessionsRecipeSchematicFormMixin2:Init(recipeInfo, isRecraftOverride)
	local xPadding = 0
	local yPadding = 4
	local anchor = AnchorUtil.CreateAnchor("TOPLEFT", self.OutputIcon, "BOTTOMLEFT", -1, -12)
	local organizer = CreateVerticalLayoutOrganizer(anchor, xPadding, yPadding)

	self.UpdateRequiredTools = nil
	self.UpdateCooldown = nil

	self.OutputIcon:Hide()
	self.OutputText:Hide()
	self.OutputSubText:Hide()
	self.Description:Hide()
	self.RecraftingDescription:Hide()
	self.RequiredTools:Hide()
	self.RecraftingRequiredTools:Hide()
	self.RecraftingOutputText:Hide()



	self.RecipeSourceButton:Hide()
	self.FirstCraftBonus:Hide()


	self.Reagents:Hide()
	self.OptionalReagents:Hide()
	self.Details:Hide()

	self.currentRecipeInfo = recipeInfo

	local hasRecipe = recipeInfo ~= nil

	for _, frame in ipairs(self.extraSlotFrames) do
		frame:SetShown(false)
	end

	if not hasRecipe then
		self.Details:CancelAllAnims()
		return
	end

	local recipeID = recipeInfo.recipeID
	local isRecipeInfoRecraft = recipeInfo.isRecraft
	local isRecraft = isRecraftOverride
	if isRecraft == nil then
		isRecraft = isRecipeInfoRecraft
	end
	self.isRecraftOverride = isRecraftOverride

	local recraftTransitionData = Professions.GetRecraftingTransitionData()
	if recraftTransitionData and isRecraftOverride == nil then
		isRecraft = true
	end

	local newTransaction = not self.transaction or (self.transaction:GetRecipeID() ~= recipeID)
	if not newTransaction and (self.transaction and self.transaction:IsRecraft()) and isRecraftOverride == nil then
		isRecraft = true
	end
	
	if newTransaction then
		self.QualityDialog:Close()
	end

	ItemButtonUtil.TriggerEvent(ItemButtonUtil.Event.ItemContextChanged)

	self.RecraftingDescription:SetShown(isRecipeInfoRecraft)

	if isRecraft then
		self.RecraftingOutputText:Show()
	else
		self.OutputIcon:Show()
		self.OutputText:Show()
	end

	self.recipeSchematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, isRecraft, self:GetCurrentRecipeLevel())
	local isSalvage = self.recipeSchematic.recipeType == Enum.TradeskillRecipeType.Salvage

	if newTransaction then
		self.transaction = CreateProfessionsRecipeTransaction(self.recipeSchematic)
		--UpdateTransaction(self)
		self.transaction:SetRecraft(isRecraft)
	else
		-- Remove allocation handlers while we're initializing the form
		-- otherwise we're going to flood the details stats panel with
		-- irrelevant events. Altrnatively, the details panel could
		-- defer handling the changed event until end of frame, but it
		-- would first need to be guaranteed that no state is accessed
		-- off the details frame that would not have been set as expected.
		self.transaction:SetAllocationsChangedHandler(nil)
	end

	local function AllocateModification(slotIndex, reagentSlotSchematic)
		local modification = self.transaction:GetModification(reagentSlotSchematic.dataSlotIndex)
		if modification and modification.itemID > 0 then
			local reagent = Professions.CreateCraftingReagentByItemID(modification.itemID)
			self.transaction:OverwriteAllocation(slotIndex, reagent, reagentSlotSchematic.quantityRequired)
		end
	end

	if recraftTransitionData then
		self.transaction:SetRecraftAllocation(recraftTransitionData.itemGUID)

		if newTransaction then
			for slotIndex, reagentSlotSchematic in ipairs(self.recipeSchematic.reagentSlotSchematics) do
				if reagentSlotSchematic.dataSlotType == Enum.TradeskillSlotDataType.ModifiedReagent then
					AllocateModification(slotIndex, reagentSlotSchematic)
				end
			end
		end
	end

	if newTransaction or not self.transaction:IsManuallyAllocated() then
		self.transaction:SanitizeOptionalAllocations()
		-- Unless the allocation has been manually changed, the 'best quality reagent' option is used to
		-- auto-allocate the reagents.
		Professions.AllocateAllBasicReagents(self.transaction, Professions.ShouldAllocateBestQualityReagents())
	else
		-- We still need to sanitize the transaction to remove allocations we no longer have even if
		-- we're manually allocating. When we run out of a reagent, we expect the allocation to be
		-- removed.
		self.transaction:SanitizeAllocations()
	end



local reagents = data.orderInfo.orderInfo.reagents
--		xx = self.transaction.self.allocationTbls
if reagents then 
	for i, d in ipairs(reagents) do
		local quantity = d.reagent.quantity
		local slot = d.reagentSlot
		local reagent = d.reagent.itemID


		--AllocateModification
	end


end


	-- Verifies that targets are still valid, and that the item modifications
	-- for the item are updated if a recraft target.
	self.transaction:SanitizeTargetAllocations()

	if self.QualityDialog:IsShown() then
		local slotIndex = self.QualityDialog:GetSlotIndex()
		local allocationsCopy = self.transaction:GetAllocationsCopy(slotIndex)
		self.QualityDialog:ReinitAllocations(allocationsCopy)
	end

	local sourceText, sourceTextIsForNextRank
	if not recipeInfo.learned then
		sourceText = C_TradeSkillUI.GetRecipeSourceText(recipeID)
	elseif recipeInfo.nextRecipeID then
		sourceText = C_TradeSkillUI.GetRecipeSourceText(recipeInfo.nextRecipeID)
		sourceTextIsForNextRank = true
	end

	if sourceText then
		if sourceTextIsForNextRank then
			self.RecipeSourceButton.Text:SetText(TRADESKILL_NEXT_RANK_HEADER)
		else
			self.RecipeSourceButton.Text:SetText(TRADESKILL_UNLEARNED_RECIPE_HEADER)
		end

		self.RecipeSourceButton:SetScript("OnEnter", function()
			GameTooltip:SetOwner(self.RecipeSourceButton, "ANCHOR_RIGHT")
			GameTooltip_AddHighlightLine(GameTooltip, sourceText)
			GameTooltip:SetMinimumWidth(400)
			GameTooltip:Show()
		end)

		self.RecipeSourceButton:Show()
		organizer:Add(self.RecipeSourceButton, LayoutEntry.Source, 0, 10)
	end

	if recipeInfo.learned and not self.RecipeSourceButton:IsVisible() and recipeInfo.firstCraft and not isRecraft then
		self.FirstCraftBonus:Show()
		organizer:Add(self.FirstCraftBonus, LayoutEntry.FirstCraftBonus, 0, 10)
	end

	if self.loader then
		self.loader:Cancel()
	end
	self.loader = CreateProfessionsRecipeLoader(self.recipeSchematic, function()
		local reagents = self.transaction:CreateCraftingReagentInfoTbl()

		if not isRecraft then
			local firstRecipeInfo = Professions.GetFirstRecipe(recipeInfo)
			if not firstRecipeInfo then
				return
			end
			local spell = Spell:CreateFromSpellID(firstRecipeInfo.recipeID)
			local description = C_TradeSkillUI.GetRecipeDescription(spell:GetSpellID(), reagents, self.transaction:GetAllocationItemGUID())
			if description and description ~= "" then
				self.Description:SetText(description)
				self.Description:SetHeight(600)
				self.Description:SetHeight(self.Description:GetStringHeight() + 1)
				self.Description:Show()
			else
				self.Description:SetText("")
				self.Description:SetHeight(1)
			end
			organizer:Add(self.Description, LayoutEntry.Description, 0, 5)
			
			organizer:Layout()
		end

		local outputItemInfo = C_TradeSkillUI.GetRecipeOutputItemData(recipeID, reagents, self.transaction:GetAllocationItemGUID())
		local text
		if outputItemInfo.hyperlink then
			local item = Item:CreateFromItemLink(outputItemInfo.hyperlink)
			text = WrapTextInColor(item:GetItemName(), item:GetItemQualityColor().color)
		else
			text = WrapTextInColor(self.recipeSchematic.name, NORMAL_FONT_COLOR)
		end
		
		local function SetOutputText(fontString, text)
			fontString:SetText(text)
			fontString:SetWidth(800)
			fontString:SetWidth(fontString:GetStringWidth())
			fontString:SetHeight(fontString:GetStringHeight())
		end

		if isRecipeInfoRecraft then
			SetOutputText(self.RecraftingOutputText, PROFESSIONS_CRAFTING_RECRAFTING)
		elseif isRecraft then
			SetOutputText(self.RecraftingOutputText, PROFESSIONS_CRAFTING_FORM_RECRAFTING_HEADER:format(text))
		else
			SetOutputText(self.OutputText, text)
		end

		Professions.SetupOutputIcon(self.OutputIcon, self.transaction, outputItemInfo)
		self.OutputIcon.Count:SetShown(not recipeInfo.isGatheringRecipe)
	end)

	self.OutputIcon:SetScript("OnEnter", function()
		GameTooltip:SetOwner(self.OutputIcon, "ANCHOR_RIGHT")
		local reagents = self.transaction:CreateCraftingReagentInfoTbl()

		self.OutputIcon:SetScript("OnUpdate", function() 
			GameTooltip:SetRecipeResultItem(self.recipeSchematic.recipeID, reagents, self.transaction:GetAllocationItemGUID(), self:GetCurrentRecipeLevel())
		end)

	end)
	self.OutputIcon:SetScript("OnLeave", function()
		GameTooltip_Hide(); 
		self.OutputIcon:SetScript("OnUpdate", nil)
	end)

	do
		self.RecraftingRequiredTools:Hide()
		self.RequiredTools:Hide()

		if #C_TradeSkillUI.GetRecipeRequirements(recipeInfo.recipeID) > 0 then
			local fontString = isRecraft and self.RecraftingRequiredTools or self.RequiredTools
			fontString:Show()
			
			self.UpdateRequiredTools = function()
				-- Requirements need to be fetched on every update because it contains the updated
				-- .met field that we need to colorize the string correctly.
				local requirements = C_TradeSkillUI.GetRecipeRequirements(recipeInfo.recipeID)
				local requirementsText = BuildColoredListString(unpack(FormatRequirements(requirements)))
				fontString:SetText(PROFESSIONS_REQUIRED_TOOLS:format(requirementsText))
			end

			self.UpdateRequiredTools()
		end


		self.RequiredTools:SetPoint("TOPLEFT", self.OutputText, "BOTTOMLEFT", 0, -4)
		
	end

	self.reagentSlotPool:ReleaseAll()
	self.reagentSlots = {}
	self.Reagents:Show()
	self.OptionalReagents:Show()

	local slotParents =
	{
		[Enum.CraftingReagentType.Basic] = self.Reagents, 
		[Enum.CraftingReagentType.Optional] = self.OptionalReagents,
		[Enum.CraftingReagentType.Finishing] = self.Details.FinishingReagentSlotContainer,
	}

	if isRecraft then
		if not self.recraftSlot then
			self.recraftSlot = CreateFrame("FRAME", nil, self, "ProfessionsRecraftSlotTemplate")
			self.recraftSlot:SetPoint("TOPLEFT", self.RecraftingOutputText, "BOTTOMLEFT", 0, -30)
			table.insert(self.extraSlotFrames, self.recraftSlot)
		end
		self.recraftSlot:Show()
		self.recraftSlot:Init(self.transaction)

		self.recraftSlot.InputSlot:SetScript("OnEnter", function()
			GameTooltip:SetOwner(self.recraftSlot.InputSlot, "ANCHOR_RIGHT")

			local itemGUID = self.transaction:GetRecraftAllocation()
			if itemGUID then
				GameTooltip:SetItemByGUID(itemGUID)
				GameTooltip_AddBlankLineToTooltip(GameTooltip)
				GameTooltip_AddInstructionLine(GameTooltip, RECRAFT_REAGENT_TOOLTIP_CLICK_TO_REPLACE)
			else
				GameTooltip_AddInstructionLine(GameTooltip, RECRAFT_REAGENT_TOOLTIP_CLICK_TO_ADD)
			end
			GameTooltip:Show()
		end)

		self.recraftSlot.OutputSlot:SetScript("OnEnter", function()
			local itemGUID = self.transaction:GetRecraftAllocation()
			if itemGUID then
				GameTooltip:SetOwner(self.recraftSlot.OutputSlot, "ANCHOR_RIGHT")

				local reagents = self.transaction:CreateCraftingReagentInfoTbl()
				GameTooltip:SetRecipeResultItem(self.recipeSchematic.recipeID, reagents, self.transaction:GetRecraftAllocation(), self:GetCurrentRecipeLevel())
			end
		end)
	end

	if isRecipeInfoRecraft then
		self.RecraftingDescription:SetPoint("TOPLEFT", self.recraftSlot, "BOTTOMLEFT")
		self.RecraftingDescription:SetTextColor(GRAY_FONT_COLOR:GetRGB())
	end

	for slotIndex, reagentSlotSchematic in ipairs(self.recipeSchematic.reagentSlotSchematics) do
		local reagentType = reagentSlotSchematic.reagentType

		local slots = self.reagentSlots[reagentType]
		if not slots then
			slots = {}
			self.reagentSlots[reagentType] = slots
		end

		local slot = self.reagentSlotPool:Acquire()
		table.insert(slots, slot)

		slot:SetParent(slotParents[reagentType])
		
		slot.CustomerState:SetShown(false)
		xx = self.transaction.allocationTbls
		slot:Init(self.transaction, reagentSlotSchematic)
		slot:Show()

		if reagentType == Enum.CraftingReagentType.Basic then
			if Professions.InLocalCraftingMode() and Professions.GetReagentInputMode(reagentSlotSchematic) == Professions.ReagentInputMode.Quality then

				slot.Button:SetScript("OnEnter", function()
					GameTooltip:SetOwner(slot.Button, "ANCHOR_RIGHT")
					Professions.SetupQualityReagentTooltip(slot, self.transaction)
					GameTooltip:Show()
				end)
			else

				slot.Button:SetScript("OnEnter", function()
					GameTooltip:SetOwner(slot.Button, "ANCHOR_RIGHT")
					local currencyID = slot.Button:GetCurrencyID()
					if currencyID then
						GameTooltip:SetCurrencyByID(currencyID)
					else
						GameTooltip:SetRecipeReagentItem(recipeID, reagentSlotSchematic.dataSlotIndex)
					end
					GameTooltip:Show()
				end)
			end
		else
			local locked, lockedReason = Professions.GetReagentSlotStatus(reagentSlotSchematic, recipeInfo)
			slot.Button:SetLocked(locked)


			slot.Button:SetScript("OnEnter", function()
				GameTooltip:SetOwner(slot.Button, "ANCHOR_RIGHT")

				if locked then
					local title = (reagentType == Enum.CraftingReagentType.Finishing) and FINISHING_REAGENT_TOOLTIP_TITLE:format(reagentSlotSchematic.slotInfo.slotText) or EMPTY_OPTIONAL_REAGENT_TOOLTIP_TITLE
					GameTooltip_SetTitle(GameTooltip, title)
					GameTooltip_AddErrorLine(GameTooltip, lockedReason)
				else
					local exchangeOnly = self.transaction:HasModification(reagentSlotSchematic.dataSlotIndex)
					Professions.SetupOptionalReagentTooltip(slot, recipeID, reagentType, reagentSlotSchematic.slotInfo.slotText, exchangeOnly, self.transaction:GetAllocationItemGUID(), slot:IsUnallocatable())

					slot.Button.InputOverlay.AddIconHighlight:SetShown(not slot:IsUnallocatable())
				end
				GameTooltip:Show()
			end)
			

		end
	end
	
	if isSalvage then
		if not self.salvageSlot then
			self.salvageSlot = CreateFrame("FRAME", nil, self, "ProfessionsReagentSalvageTemplate")
			table.insert(self.extraSlotFrames, self.salvageSlot)
		end
		self.salvageSlot:Show()
		self.salvageSlot:Init(self.transaction, self.recipeSchematic.quantityMax)

		self.salvageSlot.Button:SetScript("OnMouseDown", function(button, buttonName, down)
			if buttonName == "LeftButton" then
				local flyout = ToggleProfessionsItemFlyout(self.salvageSlot.Button, ProfessionsFrame)
				if flyout then
					local function OnFlyoutItemSelected(o, flyout, elementData)
						local item = elementData.item
						if ItemUtil.GetCraftingReagentCount(item:GetItemID()) == 0 then
							return
						end

						self.transaction:SetSalvageAllocation(item)

						self.salvageSlot:SetItem(item)

						self:TriggerEvent(ProfessionsRecipeSchematicFormMixin.Event.AllocationsModified)
					end
					
		
					flyout.GetElementsImplementation = function(self, filterOwned)
						local itemIDs = C_TradeSkillUI.GetSalvagableItemIDs(recipeID)
						local targetItems = C_TradeSkillUI.GetCraftingTargetItems(itemIDs)
						local items = {}
						for index, targetItem in ipairs(targetItems) do
							table.insert(items, Item:CreateFromItemGUID(targetItem.itemGUID))
						end

						if not filterOwned then
							for index, itemID in ipairs(itemIDs) do
								local contained = ContainsIf(targetItems, function(targetItem)
									return targetItem.itemID == itemID
								end)
								if not contained then
									table.insert(items, Item:CreateFromItemID(itemID))
								end
							end
						end
						return {items = items, onlyCountStack = true,}
					end

					flyout.OnElementEnterImplementation = function(elementData, tooltip)
						Professions.FlyoutOnElementEnterImplementation(elementData, tooltip, recipeID, self.transaction:GetAllocationItemGUID())
					end

					flyout.OnElementEnabledImplementation = function(button, elementData)
						local item = elementData.item
						local quantity = item:GetItemGUID() and item:GetStackCount() or nil
						return (quantity ~= nil) and (quantity >= self.recipeSchematic.quantityMax)
					end

					flyout:Init(self.salvageSlot.Button, self.transaction)
					flyout:RegisterCallback(ProfessionsItemFlyoutMixin.Event.ItemSelected, OnFlyoutItemSelected, slot)
				end
			elseif buttonName == "RightButton" then
				self.transaction:ClearSalvageAllocations()

				self.salvageSlot:ClearItem()

				self:TriggerEvent(ProfessionsRecipeSchematicFormMixin.Event.AllocationsModified)
			end
		end)

		self.salvageSlot.Button:SetScript("OnEnter", function()
			GameTooltip:SetOwner(self.salvageSlot.Button, "ANCHOR_RIGHT")

			local salvageItem = self.transaction:GetSalvageAllocation()
			if salvageItem then
				local itemID = salvageItem:GetItemID()
				if itemID then
					GameTooltip:SetItemByID(itemID)
					GameTooltip_AddBlankLineToTooltip(GameTooltip)
					GameTooltip_AddInstructionLine(GameTooltip, SALVAGE_REAGENT_TOOLTIP_CLICK_TO_REMOVE)
				end
			else
				GameTooltip_AddInstructionLine(GameTooltip, SALVAGE_REAGENT_TOOLTIP_CLICK_TO_ADD)
			end
			GameTooltip:Show()
		end)
	end

	local isEnchant = (self.recipeSchematic.recipeType == Enum.TradeskillRecipeType.Enchant) and not C_TradeSkillUI.IsRuneforging()
	if isEnchant then
		if not self.enchantSlot then
			self.enchantSlot = CreateFrame("FRAME", nil, self, "ProfessionsReagentEnchantTemplate")
			table.insert(self.extraSlotFrames, self.enchantSlot)
		end
		self.enchantSlot:Show()
		self.enchantSlot:Init(self.transaction)
	
		self.enchantSlot.Button:SetScript("OnMouseDown", function(button, buttonName, down)
			if buttonName == "LeftButton" then
				local flyout = ToggleProfessionsItemFlyout(self.enchantSlot.Button, ProfessionsFrame)
				if flyout then
					local function OnFlyoutItemSelected(o, flyout, elementData)
						local item = elementData.item
						if ItemUtil.GetCraftingReagentCount(item:GetItemID()) == 0 then
							return
						end
	
						self.transaction:SetEnchantAllocation(item)
	
						self.enchantSlot:SetItem(item)
	
						self:TriggerEvent(ProfessionsRecipeSchematicFormMixin.Event.AllocationsModified)
					end
		
					flyout.GetElementsImplementation = function(self, filterOwned)
						local itemGUIDs = C_TradeSkillUI.GetEnchantItems(recipeID)

						local function CopyPredicate(item)
							return item:GetItemID()
						end
						local items = TableUtil.CopyUniqueByPredicate(ItemUtil.TransformItemGUIDsToItems(itemGUIDs), 
							TableUtil.Constants.IsIndexTable, CopyPredicate)

						local elementsData = {items = items, itemGUIDs = itemGUIDs}
						return elementsData
					end
	
					flyout.OnElementEnterImplementation = function(elementData, tooltip)
						tooltip:SetOwner(self.enchantSlot.Button, "ANCHOR_RIGHT")
						tooltip:SetItemByGUID(elementData.itemGUID)
						tooltip:Show()
					end
	
					flyout.OnElementEnabledImplementation = nil
	
					local canModifyFilter = false
					flyout:Init(self.enchantSlot.Button, self.transaction, canModifyFilter)
					flyout:RegisterCallback(ProfessionsItemFlyoutMixin.Event.ItemSelected, OnFlyoutItemSelected, slot)
				end
			elseif buttonName == "RightButton" then
				self.transaction:ClearEnchantAllocations()
	
				self.enchantSlot:ClearItem()
	
				self:TriggerEvent(ProfessionsRecipeSchematicFormMixin.Event.AllocationsModified)
			end
		end)

		self.enchantSlot.Button:SetScript("OnEnter", function(button)
			GameTooltip:SetOwner(button, "ANCHOR_RIGHT")

			local item = self.transaction:GetEnchantAllocation()
			if item then
				GameTooltip:SetItemByGUID(item:GetItemGUID())
				GameTooltip_AddBlankLineToTooltip(GameTooltip)
				GameTooltip_AddInstructionLine(GameTooltip, ENCHANT_TARGET_TOOLTIP_CLICK_TO_REPLACE)
			else
				GameTooltip_AddInstructionLine(GameTooltip, ENCHANT_TARGET_TOOLTIP_CLICK_TO_ADD)
			end
			GameTooltip:Show()
		end)
	end

	local basicSlots
	if isSalvage then
		basicSlots = {self.salvageSlot}
	else
		basicSlots = self:GetSlotsByReagentType(Enum.CraftingReagentType.Basic)
	end

	local optionalSlots
	if isEnchant then
		optionalSlots = {self.enchantSlot}
		self.OptionalReagents:SetText(PROFESSIONS_REAGENT_CONTAINER_ENCHANT_LABEL)
	else
		optionalSlots = self:GetSlotsByReagentType(Enum.CraftingReagentType.Optional)
		self.OptionalReagents:SetText(PROFESSIONS_OPTIONAL_REAGENT_CONTAINER_LABEL)
	end

	Professions.LayoutReagentSlots(basicSlots, self.Reagents, optionalSlots, self.OptionalReagents, self.VerticalDivider)
	
	if basicSlots and #basicSlots > 0 then
		self.Reagents:Show()

		self.Reagents:ClearAllPoints()
		if isRecraft then
			self.Reagents:SetPoint("TOP", self.OutputIcon, "BOTTOM", 66, -98 + PROFESSIONS_SCHEMATIC_REAGENTS_Y_OFFSET)
		else
			self.Reagents:SetPoint("TOPLEFT", self.Description, "BOTTOMLEFT", 0, -50)
		end
	else
		self.Reagents:Hide()
	end

	local operationInfo
	local professionLearned = Professions.GetProfessionInfo().skillLevel > 0
	if professionLearned then
		operationInfo = self:GetRecipeOperationInfo()
	end

	local finishingSlots = self:GetSlotsByReagentType(Enum.CraftingReagentType.Finishing)
	local hasFinishingSlots = finishingSlots ~= nil
	--if professionLearned and Professions.InLocalCraftingMode() and recipeInfo.supportsCraftingStats and ((operationInfo ~= nil and #operationInfo.bonusStats > 0) or recipeInfo.supportsQualities or recipeInfo.isGatheringRecipe or hasFinishingSlots) then
		Professions.LayoutFinishingSlots(finishingSlots, self.Details.FinishingReagentSlotContainer)
		self.Details:ClearAllPoints()
		if recipeInfo.isGatheringRecipe then
			self.Details:SetPoint("TOPLEFT", self.Description, "BOTTOMLEFT", 0, -30)
		else
			self.Details:SetPoint("TOPRIGHT", self, "TOPRIGHT", -30, -85)
		end
		
		self.Details:SetData(self.transaction, recipeInfo, hasFinishingSlots)
		self.Details:Show()
		self:UpdateDetailsStats(operationInfo)
	--end

	self:UpdateRecraftSlot(operationInfo)

slots = self:GetSlots()
	self.transaction:SetAllocationsChangedHandler(self.statsChangedHandler)

	organizer:Layout()

	if self.postInit then
		self.postInit()
	end
end

function ProfessionsRecipeSchematicFormMixin2:UpdateDetailsStats(operationInfo)
	if self.Details:IsShown() and self.Details:HasData() then
		if not operationInfo then
			operationInfo = self.orderInfo.details --self:GetRecipeOperationInfo()
		end

		if operationInfo then
			self.Details:SetStats(operationInfo, self.currentRecipeInfo.supportsQualities, self.currentRecipeInfo.isGatheringRecipe)
		end
	end
end
