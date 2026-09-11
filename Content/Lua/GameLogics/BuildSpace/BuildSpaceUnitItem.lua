-- Selected feature implementation. External runtime and widget assets are not included.
local BuildSpaceUnitItem, super = CreateUIBehaviourFromListItem("BuildSpaceUnitItem")
local GuideTable = GetTableDefine("GuideTable")
local setting = {
	Elements = {
		{
			Name = "BGSwitcher"
		},
		{
			Name = "BG"
		},
		{
			Name = "BuildingIcon",
			NeedClear = true,
		},
		{
			Name = "BuildingName"
		},
		{
			Name = "Lock"
		},
		{
			Name = "Mask"
		},
		{
			Name = "Selected"
		},
		{
			Name = "SelectBtn",
			Handles =
			{
				OnClicked = "OnClicked",
				OnHovered = "OnHovered",
				OnUnhovered = "OnUnhovered",
			},
		},
		{
			Name = "HoverMark",
		},
		{
			Name = "WorkbenchMark"
		},
		{
			Name = "GuideTraceItemRed",
		},
	},
	Behaviours =
	{
		{
			Name = "QualityPart",
			Alias = "QualityPartBehaviour",
		},
	},
	Events = {
		["BuildSpace_UnitSelected"] = "OnUnitSelectedChange",
		["NetEvent_NoticeUnlockNewRecipe"] = "OnUnlockNewRecipe", --刚刚解锁了新配方
		["PZ_EVENT_TOTEM_ITEM_UPDATE"] = "OnContainerUpdate",
		["BuildCoat_UnitSelected_Change"] = "OnBuildCoat_UnitSelectedChange"
	}
}

function BuildSpaceUnitItem:_init(go)
	super._init(self, go, setting)
	self.buildSpaceModel = ModelManager:GetModel("BuildSpaceModel")
end

function BuildSpaceUnitItem:OnDataSet(data)
	self.data = data
	if data.Id then
		self.BuildingName:SetText(LocalizationFText.FromStr(data.Name))
		UIUtil.SetWidgetVisible(self.BuildingIcon, true)
		UIUtil.SetImagePathAsync(self.BuildingIcon, data.ItemIcon)
		UIUtil.SetWidgetVisible(self.WorkbenchMark, data.IsLevelUpItem)
		local hintType = GuideTable.Get_GuideTraceItem_RedHintType("Build", data.Id)
		self.GuideTraceItemRed:RegisterHintType(hintType)
		if data.IsPlow then
			self._target:SetCustomName("PlowListItem_" .. tostring(data.Id))
		elseif data.IsCoating then
			self._target:SetCustomName("CoatListItem_" .. tostring(data.Id))
		else
			self._target:SetCustomName("BuildListItem_" .. tostring(data.Id))
		end
	else
		self.BuildingName:SetText("")
		UIUtil.SetWidgetVisible(self.BuildingIcon, false)
		UIUtil.SetWidgetVisible(self.WorkbenchMark, false)
		self.GuideTraceItemRed:UnRegisterAllHintTypes()
		self._target:SetCustomName("BuildListItem_Null")
	end
	self:SetValidState()
	self:SetSelectedState(data.Id and self.buildSpaceModel.curSelectedUnitId and
		data.Id == self.buildSpaceModel.curSelectedUnitId)
end

function BuildSpaceUnitItem:SetValidState()
	if self.data.Id then
		local showLock = not self.data.RecipeUnlock
		local resEnough = true
		if self.data.IsPlow then
			self.BGSwitcher:SetActiveWidgetIndex(0)
			self.BuildingName:SetLowPrioritydefaultFormat("d01")
			self.BuildingName:SetRenderOpacity(1)
		else
			local RecipeId = self.data.RecipeId
			if self.data.IsCoating then
				RecipeId = self.buildSpaceModel:GetCurCoatCraftId(self.data.Id)
			end
			resEnough = self.buildSpaceModel:CheckEnoughResByRecipeId(RecipeId)
			self.BuildingName:SetLowPrioritydefaultFormat(resEnough and "d01" or "D01")
			self.BuildingName:SetRenderOpacity(resEnough and 1 or 0.5)
			self.BGSwitcher:SetActiveWidgetIndex(1)
			local unitColor = self.data.Color
			if unitColor then
				self.QualityPartBehaviour:SetQualityData(math.max(1, unitColor))
			else
				self.BGSwitcher:SetActiveWidgetIndex(0)
			end
		end
		UIUtil.SetWidgetVisible(self.Lock, showLock)
		UIUtil.SetWidgetVisible(self.Mask, showLock or not resEnough)
	else
		self.BGSwitcher:SetActiveWidgetIndex(0)
		UIUtil.SetWidgetVisible(self.Lock, false)
		UIUtil.SetWidgetVisible(self.Mask, false)
	end
end

function BuildSpaceUnitItem:OnClicked()
	if self.data and self.data.Id then
		self.buildSpaceModel:SetBuildSpaceUnitSelected(self.data.Id)
	end
end

function BuildSpaceUnitItem:OnUnitSelectedChange(_, _, id, isSelected)
	if self.data and self.data.Id and self.data.Id == id then
		self:SetSelectedState(isSelected)
	end
end

function BuildSpaceUnitItem:SetSelectedState(isSelected)
	UIUtil.SetWidgetVisible(self.Selected, isSelected)
end

function BuildSpaceUnitItem:OnUnlockNewRecipe(_, _, id, needRepair)
	if self.data.Id and self.data.RecipeId and id == self.data.RecipeId then
		self:SetValidState()
	end
end

function BuildSpaceUnitItem:OnBuildCoat_UnitSelectedChange(_, _, coatId)
	if self.data and self.data.IsCoating and self.data.Id == coatId then
		self:SetValidState()
	end
end

function BuildSpaceUnitItem:OnContainerUpdate()
	if self.data.Id then
		self:SetValidState()
	end
end

function BuildSpaceUnitItem:SetHoverState(bHover)
	if bHover == true then
		if self.data and self.data.Id then
			local bUsePCInteraction = UE4.PzPCInteractionLibrary.IsUsePCInteraction(_G.GlobalContext)
			if bUsePCInteraction then
				UIUtil.SetWidgetVisible(self.HoverMark, true)
				self.buildSpaceModel:SetBuildSpaceHoverSelect(self.data.Id, true)
			end
		end
	else
		UIUtil.SetWidgetVisible(self.HoverMark, false)
		self.buildSpaceModel:SetBuildSpaceHoverSelect(0, false)
	end
end

function BuildSpaceUnitItem:OnHovered()
	self:SetHoverState(true)
end

function BuildSpaceUnitItem:OnUnhovered()
	self:SetHoverState(false)
end

return BuildSpaceUnitItem
