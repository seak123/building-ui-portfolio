-- Selected feature implementation. External runtime and widget assets are not included.
local BuildSpaceListWidget, super = CreateUIBehaviour("BuildSpaceListWidget")
local BuildHoldFlowSystem = UE4.PzBuildUtil.GetBuildHoldFlowSystem(_G.GlobalContext)
local EBuildingSystemMode = import("EBuildingSystemMode")
local FarmingSystem = UE4.PzLogicLibrary.GetFarmingSystem(_G.GlobalContext)

local setting = {
	Elements = {
		{
			Name = "MenuGuid",
		},
		{
			Name = "CategoryList",
		},
		{
			Name = "BuildingList",
		},
		{
			Name = "BuildingGrid",
		},
		{
			Name = "CategoryArrowGroup",
		},
		{
			Name = "CategoryArrowBtn",
			Handles =
			{
				OnClicked = "OnCategoryArrowBtn",
			},
		},
		{
			Name = "ExpandBox"
		},
		{
			Name = "UnitGridSwitcher"
		},
		{
			Name = "CatalogSwitcher"
		},
		{
			Name = "ExpandBtn",
			Handles = {
				OnClicked = "OnExpand"
			}
		},
		{
			Name = "DelSearch",
			Handles = {
				OnClicked = "OnDelSearch"
			}
		},
		{
			Name = "SeachBtn",
			Handles = {
				OnClicked = "OnSearchUnit"
			}
		},
		{
			Name = "SearchNum"
		}
	},
	Events = {
		["BuildSpace_FuncTab_Change"] = "OnBuildSpaceFuncTabChange",
		["BuildSpace_MenuSelected"] = "OnMenuSelectedChange",
		["BuildSpace_CatalogSelected"] = "OnCatalogSelectedChange",
		["TOTEM_PLACED_SELF"] = "OnSelfTotemPlaced",
		["NetEvent_NoticeUnlockNewRecipeSyncOver"] = "BuildSpaceBuildItemDataChanged",
		["Build_Unit_Search"] = "OnBuildUnitSearch",
		["BuildSpace_UnitSelected"] = "OnUnitSelectedChange"
	},
}
local UnitLineCount = 7
local CatalogLineCount = 4

function BuildSpaceListWidget:_init(go)
	super._init(self, go, setting)
	self.buildSpaceModel = ModelManager:GetModel("BuildSpaceModel")
	self.isExpand = false
	self.CurSelectedCatalogId = nil
	self.CurSelectedMenuId = nil
	self.CurSelectedUnitId = nil
end

function BuildSpaceListWidget:OnInitialize()
	BuildHoldFlowSystem:ReqBuildNumInfo()
end

function BuildSpaceListWidget:OnDestroy()
	self.buildSpaceModel:ClearSelectedInfo()
end

function BuildSpaceListWidget:OnBuildSpaceFuncTabChange(_, _, id)
    -- Implementation omitted.
end

function BuildSpaceListWidget:SetMenuData()
	self.MenuGuid:ClearListItems()
	local Type = 0
	local curSystMode = BuildHoldFlowSystem:GetCurSystemMode()
	if curSystMode == EBuildingSystemMode.BuildMode then
		Type = ResMacros.HOMELAND_CATALOG_MODULE_TYPE_BUILD
		UIUtil.SetWidgetVisible(self.SeachBtn, true)
	elseif curSystMode == EBuildingSystemMode.FarmMode then
		Type = ResMacros.HOMELAND_CATALOG_MODULE_TYPE_PLANT
		UIUtil.SetWidgetVisible(self.SeachBtn, false)
	end
	self.MenuData = self.buildSpaceModel:GetBuildSpaceMenuDataByType(Type)
	local MenuCount = #self.MenuData
	local scrollToIndex = 0
	for i = 1, MenuCount do
		if self.buildSpaceModel.defaultSelectedMenuId == self.MenuData[i].Id then
			scrollToIndex = i - 1

		end
		local uobject = DataObjectPool:Get(self.MenuData[i])
		self.MenuGuid:AddItem(uobject)
	end
	if MenuCount > 0 then
		self.MenuGuid:ScrollIndexIntoView(scrollToIndex)
		self.buildSpaceModel:SetBuildSpaceMenuSelected(self.MenuData[scrollToIndex + 1].Id)
	end
	self.buildSpaceModel.defaultSelectedMenuId = nil
end

function BuildSpaceListWidget:OnMenuSelectedChange(_, _, id, isSelected)
	if isSelected then
		self.CatalogSwitcher:SetActiveWidgetIndex(0)
		self.CategoryList:ClearListItems()
		self.CatalogData = self.buildSpaceModel:GetCatalogByMenuId(id)
		local CatalogCount = #self.CatalogData
		local scrollToIndex = self.buildSpaceModel:CheckHasRecent(self.CatalogData) and 1 or 0
		for i = 1, CatalogCount do
			if self.buildSpaceModel.defaultSelectedCatalogId == self.CatalogData[i].Id then
				scrollToIndex = i - 1

			end
			local uobject = DataObjectPool:Get(self.CatalogData[i])
			self.CategoryList:AddItem(uobject)
		end
		if CatalogCount > 0 then
			self.CategoryList:ScrollIndexIntoView(scrollToIndex)
			self.buildSpaceModel:SetBuildSpaceCatalogSelected(self.CatalogData[scrollToIndex + 1].Id)
		end
		self.buildSpaceModel.defaultSelectedCatalogId = nil
		UIUtil.SetWidgetVisible(self.CategoryArrowGroup, CatalogCount > CatalogLineCount)
		self.CategoryList:ScrollToTop()
		self.CurSelectedMenuId = id
	else
		self.CurSelectedMenuId = nil
	end
	if id == ResMacros.HOMELAND_FIRST_MENU_PLOW then
		if isSelected then
			FarmingSystem:PlayerEnterFarmStatus()
		else
			FarmingSystem:PlayerExitFarmStatus()
		end
	elseif id == ResMacros.HOMELAND_FIRST_MENU_PLANT then
		FarmingSystem:SetPlantState(isSelected)
	end
end

function BuildSpaceListWidget:OnCategoryArrowBtn()
    -- Implementation omitted.
end

function BuildSpaceListWidget:OnCatalogSelectedChange(_, _, id, isSelected)
	if isSelected then
		self.BuildingList:ClearListItems()
		self.BuildingGrid:ClearListItems()
		self.UnitData = self.buildSpaceModel:GetCurUnitDataByCatalogId(id)
		local scrollToIndex = 0
		local validUnitCount = 0
		for i = 1, #self.UnitData do
			if self.buildSpaceModel.defaultSelectedUnitId == self.UnitData[i].Id then
				scrollToIndex = i - 1
			end
			local uobject = DataObjectPool:Get(self.UnitData[i])
			self.BuildingList:AddItem(uobject)
			self.BuildingGrid:AddItem(uobject)
			if self.UnitData[i].Id and self.UnitData[i].Id > 0 then
				validUnitCount = validUnitCount + 1
			end
		end
		self.isExpand = validUnitCount > UnitLineCount
		UIUtil.SetWidgetVisible(self.ExpandBox, self.isExpand)
		self.UnitGridSwitcher:SetActiveWidgetIndex(self.isExpand and 1 or 0)
		if self.buildSpaceModel.defaultSelectedUnitId then
			self.BuildingList:ScrollIndexIntoView(scrollToIndex)
			self.BuildingGrid:ScrollIndexIntoView(scrollToIndex)
		end
		self.buildSpaceModel:SetBuildSpaceUnitSelected(self.buildSpaceModel.defaultSelectedUnitId)
		self.buildSpaceModel.defaultSelectedUnitId = nil
		self.CurSelectedCatalogId = id
	else
		self.CurSelectedCatalogId = nil
	end
end

function BuildSpaceListWidget:OnUnitSelectedChange(_, _, id, isSelected)
	if isSelected then
		self.CurSelectedUnitId = id
	else
		self.CurSelectedUnitId = nil
	end
end

function BuildSpaceListWidget:BuildSpaceBuildItemDataChanged()
	self.buildSpaceModel:InitBuildItemData()
	self.buildSpaceModel:RefeshUnitDefaultSelected(self.CurSelectedMenuId,self.CurSelectedCatalogId)
end

function BuildSpaceListWidget:OnExpand()
    -- Implementation omitted.
end

function BuildSpaceListWidget:OnSelfTotemPlaced()
    -- Implementation omitted.
end

function BuildSpaceListWidget:OnDelSearch()
    -- Implementation omitted.
end

function BuildSpaceListWidget:OnBuildUnitSearch(_, _, name)
    -- Implementation omitted.
end

function BuildSpaceListWidget:OnSearchUnit()
    -- Implementation omitted.
end

return BuildSpaceListWidget
