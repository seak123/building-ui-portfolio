-- Selected feature implementation. External runtime and widget assets are not included.
local BuildSpaceModel, super = ModelManager:CreateModel("BuildSpaceModel")
local BuildItemTable = ConfigManager.GetTable("ResHomelandBuildingItemConfig")
local BuildCatalogTable = ConfigManager.GetTable("ResHomelandCatalogConfig")
local BuildSpecialTable = ConfigManager.GetTable("ResHomelandBuildingSpecialConfig")
local BuildCoatTable = ConfigManager.GetTable("ResHomelandBuildCoatingConfig")
local ManorMoveTable = ConfigManager.GetTable("ResManorMoveConfig")
local PzBuildUtil = UE4.PzBuildUtil
local HomelandTotemSubSystem = PzBuildUtil.GetHomelandTotemSubSystem(_G.GlobalContext)
local DimensionalDataExport = UE4.DimensionalDataExport
local ResCraftRecipe = ConfigManager.GetTable("ResCraftRecipe")
local RecipeCultivateTable = ConfigManager.GetTable("ResCraftRecipeCultivate")
local RecipeCultivateLvTable = ConfigManager.GetTable("ResCraftRecipeCultivateLv")
local CraftTable = ConfigManager.GetTable("ResCraftRecipe")
local BuildHoldFlowSystem = PzBuildUtil.GetBuildHoldFlowSystem(_G.GlobalContext)
local EBuildingUnitType = import("EBuildingUnitType")
local NewFeaturesMgr = UE4.PzGameLuaLibrary.GetNewFeaturesManager(_G.GlobalContext)
local MainUILibrary = UE4.PzMainUILibrary
local ManorCfg = require("GameLogics.Manor.ManorConfig")
local PzLogicLibrary = UE4.PzLogicLibrary
local NewFeaturesUnlockMgr = UE4.PzGameLuaLibrary.GetNewFeaturesManager(_G.GlobalContext)

local setting = {
	Events = {
		["OnCharacterLevelChange"] = "OnPlayerLvChange",
		["OnCharacterLevelChange"] = "OnPlayerLvChange",
		["PZ_EVENT_LOCAL_PLAYER_READY"] = "OnPlayerReady",
		["BuildSpace_OpState_Change"] = "OnBuildSpaceOpStateChange",
		["PZ_EVENT_BUILDING_CREAT_RET"] = "OnCreatPieceRet",
		["OnNotifyIAOpenView"] = "OnNotifyIAOpenView",
		["NetEvent_NoticeUnlockNewRecipe"] = "OnUnlockNewRecipe", --刚刚解锁了新配方
		["PZ_EVENT_ACTION_BUILD"] = "OnBuildAction",
		["BUILD_UNIT_RECIPE_LOCK"] = "OnBuildUnitRecipeLock",
		["COAT_UNIT_RECIPE_LOCK"] = "OnCoatUnitRecipeLock",
		["OnSystemFunctionStatusUnlock"] = "OnSystemFuncUnlock",
		["BuildCoat_Change_Suc"] = "OnCoatSucRet",
	}
}

local BuildSpaceMainFrame = "WidgetBlueprint'/Game/UI/Panel/NewBuildSpace/WBP_BuildSpace_Main_Frame.WBP_BuildSpace_Main_Frame_C'"
local BuildSpaceSearchWidget = "WidgetBlueprint'/Game/UI/Panel/NewBuildSpace/WBP_BuildSpace_Search.WBP_BuildSpace_Search_C'"
local BuildSpacePalFrame = "WidgetBlueprint'/Game/UI/Panel/NewBuildSpace/WBP_BuildSpace_Pal_Frame.WBP_BuildSpace_Pal_Frame_C'"
local BuildTotemPackageFrame = "WidgetBlueprint'/Game/UI/Panel/HomeCore/WBP_HomelandTotem_Package.WBP_HomelandTotem_Package_C'"
local BuildSpaceDebugFrame = "WidgetBlueprint'/Game/UI/Panel/NewBuildSpace/WBP_BuildSpace_Setting_Frame.WBP_BuildSpace_Setting_Frame_C'"

local PlowCatalogId = 16
local UnitListItemMinNum = 7

local SearchHistoryMaxNum = 3

local SearchHistoryData = {}

local RecentCatalogId = 0

local HomelandTotemTypeId = 1050
local CustomBuildItemConfig = {
	{
		Id = 99001,
		Category = PlowCatalogId,
		UnitInfoDesc = LocalizationFText.FromStr("将瞄准区域的地面进行开垦"),
		Name = LocalizationFText.FromStr("开垦"),
		ItemIcon = "Texture2D'/Game/common_resource/UI/Texture/BuildObjects/Icon_BuildItem_Reclamation.Icon_BuildItem_Reclamation'",
		IsLevelUpItem = false,
		IsPlow = true,
		SortId = 1,
		RecipeUnlock = true,
		SelectedHandle = function()
			local FarmingSystem = UE4.PzLogicLibrary.GetFarmingSystem(_G.GlobalContext)
			if FarmingSystem then
				FarmingSystem:SwitchFarmingMode(UE4.EFarmingMode.Plow)
			end
		end,
		UnSelectedHandle = function()
			local FarmingSystem = UE4.PzLogicLibrary.GetFarmingSystem(_G.GlobalContext)
			if FarmingSystem then
				FarmingSystem:SwitchFarmingMode(UE4.EFarmingMode.None)
			end
		end,
	},
	{
		Id = 99002,
		Category = PlowCatalogId,
		Name = LocalizationFText.FromStr("退耕"),
		UnitInfoDesc = LocalizationFText.FromStr("将瞄准区域的地面进行退耕"),
		ItemIcon = "Texture2D'/Game/common_resource/UI/Texture/BuildObjects/Icon_BuildItem_Growgrass.Icon_BuildItem_Growgrass'",
		IsLevelUpItem = false,
		IsPlow = true,
		SortId = 2,
		RecipeUnlock = true,
		SelectedHandle = function()
			local FarmingSystem = UE4.PzLogicLibrary.GetFarmingSystem(_G.GlobalContext)
			if FarmingSystem then
				FarmingSystem:SwitchFarmingMode(UE4.EFarmingMode.Grass)
			end
		end,
		UnSelectedHandle = function()
			local FarmingSystem = UE4.PzLogicLibrary.GetFarmingSystem(_G.GlobalContext)
			if FarmingSystem then
				FarmingSystem:SwitchFarmingMode(UE4.EFarmingMode.None)
			end
		end,
	}
}

function BuildSpaceModel:_init()
	super._init(self, setting)
	self.buildItemData = {}
	self.cacheRecent = {}
end

function BuildSpaceModel:OnShowBuildPalFrame(id, palGuid)
    -- Implementation omitted.
end

function BuildSpaceModel:OnShowBuildSpaceFrame(id)
	local bUnlock = NewFeaturesMgr:IsFeatureUnlock(ResMacros.E_SYS_FUNC_UNLOCK_BUILD_HOUSE)
	if not bUnlock then
		GameUtil.Notice(LocalizationFText.FromStr("功能未开启"))
		return
	end
	if not MainUILibrary.CheckNodeCanResponseWithTip(_G.GlobalContext, "BuildEntrance") then
		return
	end
	if PzLogicLibrary.C_PlayerInMountCalling(_G.GlobalContext) then
		GameUtil.Notice(LocalizationFText.FromStr("当前状态不可使用"))
		return
	end
	self:InitBuildItemData()

	if id == nil then
		if HomelandTotemSubSystem:C_GetSelfTotemLv(_G.GlobalContext) < 1 then
			id = HomelandTotemTypeId
		end
	end

	if id and id > 0 then
		self:SetUnitDefaultSelected(id)
	end
	UIUtil.AddUniqueFrameAsync(BuildSpaceMainFrame)
end

function BuildSpaceModel:OnShowBuildTotemMoveFrame()
    -- Implementation omitted.
end

function BuildSpaceModel:CheckShowBuildOrRecipe(id)
    -- Implementation omitted.
end

function BuildSpaceModel:SetUnitDefaultSelected(id)
    -- Implementation omitted.
end

function BuildSpaceModel:RefeshUnitDefaultSelected(MenuId,CatalogId)
    -- Implementation omitted.
end

function BuildSpaceModel:InitBuildItemData()
    -- Implementation omitted.
end

function BuildSpaceModel:OnSystemFuncUnlock(e, r, SystemFuncID)
    -- Implementation omitted.
end

function BuildSpaceModel:AddBuildCoatData()
    -- Implementation omitted.
end

function BuildSpaceModel:OnUnlockNewRecipe(_, _, id, needRepair)
    -- Implementation omitted.
end

function BuildSpaceModel:OnCreatPieceRet(_, _, id)
	self:CacheRecentPiece(id)
	self:CheckContinueBuild(id)
end

function BuildSpaceModel:CheckContinueBuild(id)
	if self.curSelectedUnitId == id and self:NotContinueBuild(id) then
		self:CancelHold()
	end
end

function BuildSpaceModel:NotContinueBuild(id)
	local config = BuildSpecialTable:GetRowByKey(id)
	if config and config.Uninterrupted > 0 then
		return true
	end
	return false
end

function BuildSpaceModel:GetUnitBuildScore(id)
    -- Implementation omitted.
end

function BuildSpaceModel:OnCoatSucRet(_, _, id)
    -- Implementation omitted.
end

function BuildSpaceModel:CacheRecentPiece(id)
    -- Implementation omitted.
end

function BuildSpaceModel:CacheRecentInfo(unitId, catalogId)
    -- Implementation omitted.
end

function BuildSpaceModel:GetBuildContainsType(id, type)
    -- Implementation omitted.
end

function BuildSpaceModel:MakeBuildItemByConfig(buildInfo)
    -- Implementation omitted.
end

function BuildSpaceModel:AddBuildItem(info)
    -- Implementation omitted.
end

function BuildSpaceModel:OnPlayerReady()
    -- Implementation omitted.
end

function BuildSpaceModel:OnPlayerLvChange()
    -- Implementation omitted.
end

function BuildSpaceModel:CheckRecipeShow(recipeId)
    -- Implementation omitted.
end

function BuildSpaceModel:CheckCoatAndUnitMatch(unitId, coatId)
    -- Implementation omitted.
end

function BuildSpaceModel:GetCurCoatCraftId(coatId)
    -- Implementation omitted.
end

function BuildSpaceModel:CheckEnoughResByRecipeId(CraftId)
    -- Implementation omitted.
end

function BuildSpaceModel:SetBuildSpaceMenuSelected(id,Force)
	if id == nil then
		return
	end
	if self.curSelectedMenuId == id then
		if Force == nil or Force == false then
			return
		end
	end
	if self.curSelectedMenuId then
		self:ClearUnit()
		self.curSelectedCatalogId = nil
		EventSystem.Fire("BuildSpace_MenuSelected", self.curSelectedMenuId, false)
	end
	self.curSelectedMenuId = id
	BuildHoldFlowSystem:ChangeBuildSpaceMenuType(id)
	EventSystem.Fire("BuildSpace_MenuSelected", id, true)
end

function BuildSpaceModel:SetBuildSpaceCatalogSelected(id,Force)
	if id == nil then
		return
	end
	if self.curSelectedCatalogId == id then
		if Force == nil or Force == false then
			return
		end
	end
	if self.curSelectedCatalogId then
		self:ClearUnit()
		EventSystem.Fire("BuildSpace_CatalogSelected", self.curSelectedCatalogId, false)
	end
	self.curSelectedCatalogId = id
	EventSystem.Fire("BuildSpace_CatalogSelected", id, true)
end

function BuildSpaceModel:SetBuildSpaceUnitSelected(id, Force)
	if self.curSelectedUnitId then
		local IsCoatItem = self:CheckIsCoatUnitItem(self.curSelectedUnitId)
		if not IsCoatItem then
			self:ClearUnit()
		else
			BuildHoldFlowSystem:SetCurSelectedCoatId(0)
		end
		EventSystem.Fire("BuildSpace_UnitSelected", self.curSelectedUnitId, false)
	end
	if id and id ~= self.curSelectedUnitId or Force then
		self.curSelectedUnitId = id
		local IsCoatItem = self:CheckIsCoatUnitItem(self.curSelectedUnitId)
		if IsCoatItem then
			BuildHoldFlowSystem:SetCurSelectedCoatId(id)
		else
			self:HoldUnit()
		end
		EventSystem.Fire("BuildSpace_UnitSelected", id, true)
	else
		self.curSelectedUnitId = nil
	end
	EventSystem.Fire("BuildSpace_UnitSelectedChange")
end

function BuildSpaceModel:CheckIsCoatUnitItem(id)
	for i, v in pairs(self.buildItemData) do
		for j, k in pairs(v.CatalogData) do
			for m, n in pairs(k.BuildItem) do
				if m == id then
					return n.IsCoating or false
				end
			end
		end
	end
end

function BuildSpaceModel:CancelHold()
	local IsCoatItem = self:CheckIsCoatUnitItem(self.curSelectedUnitId)
	if IsCoatItem then
		BuildHoldFlowSystem:SetCurSelectedCoatId(0)
	else
		self:ClearUnit()
	end
	EventSystem.Fire("BuildSpace_UnitSelected", self.curSelectedUnitId, false)
	self.curSelectedUnitId = nil
	EventSystem.Fire("BuildSpace_UnitSelectedChange")
end

function BuildSpaceModel:HoldUnit()
	local curSelectedUnitInfo = self:GetSelectedUnitInfo()
	if not curSelectedUnitInfo then
		return
	end
	if curSelectedUnitInfo.SelectedHandle then
		curSelectedUnitInfo.SelectedHandle()
		return
	end

	local unitType = EBuildingUnitType.Piece
	if curSelectedUnitInfo.IsVehicle then
		unitType = EBuildingUnitType.Vehicle
	end
	BuildHoldFlowSystem:HoldUnit(curSelectedUnitInfo.Id, unitType)
end

function BuildSpaceModel:ClearUnit()
	local curSelectedUnitInfo = self:GetSelectedUnitInfo()
	if curSelectedUnitInfo and curSelectedUnitInfo.UnSelectedHandle then
		curSelectedUnitInfo.UnSelectedHandle()
	end
	BuildHoldFlowSystem:CleanHoldUnit()
end

function BuildSpaceModel:HoldPackagedHouse()
    -- Implementation omitted.
end

function BuildSpaceModel:ClearSelectedInfo()
	self.curSelectedMenuId = nil
	self.curSelectedCatalogId = nil
	self.curSelectedUnitId = nil
end

function BuildSpaceModel:CheckHasRecent(CatalogData)
    -- Implementation omitted.
end

function BuildSpaceModel:GetBuildSpaceMenuDataByType(Type)
    -- Implementation omitted.
end

function BuildSpaceModel:GetCatalogByMenuId(id)
    -- Implementation omitted.
end

function BuildSpaceModel:GetCurUnitDataByCatalogId(id)
    -- Implementation omitted.
end

function BuildSpaceModel:GetCurUnLockNumByCatalogId(id)
    -- Implementation omitted.
end

function BuildSpaceModel:GetSelectedUnitInfo()
	for i, v in pairs(self.buildItemData) do
		for j, k in pairs(v.CatalogData) do
			for m, n in pairs(k.BuildItem) do
				if m == self.curSelectedUnitId then
					return n
				end
			end
		end
	end
end

function BuildSpaceModel:GetBuildContainsTrait(id, type)
    -- Implementation omitted.
end

function BuildSpaceModel:OnBuildSpaceOpStateChange(_, _, stateMask)
	self.opStateMask = stateMask
	EventSystem.Fire("BuildSpace_OpBitMask_Change", stateMask)
end

function BuildSpaceModel:CheckOpBitMask(opType)
	if self.opStateMask then
		return (self.opStateMask & (1 << opType)) ~= 0
	end
	return false
end

function BuildSpaceModel:GetUnitDepDataById(Id)
    -- Implementation omitted.
end

function BuildSpaceModel:GetUnitComposeDataById(Id)
    -- Implementation omitted.
end

function BuildSpaceModel:GetUnitIconPathById(id)
    -- Implementation omitted.
end

function BuildSpaceModel:InCustomBuildAll()
    -- Implementation omitted.
end

function BuildSpaceModel:GetBuildNameByID(id)
    -- Implementation omitted.
end

function BuildSpaceModel:GetBuildDescByID(id)
    -- Implementation omitted.
end

function BuildSpaceModel:GetCoatDescByID(id)
    -- Implementation omitted.
end
function BuildSpaceModel:OnBuildAction()
    -- Implementation omitted.
end

function BuildSpaceModel:SetBuildSpaceHoverSelect(id, bSelect)
    -- Implementation omitted.
end

function BuildSpaceModel:GetBuildSpaceHoverSelectId()
    -- Implementation omitted.
end

function BuildSpaceModel:GetBuildSpaceHoverSelectInfo()
    -- Implementation omitted.
end

function BuildSpaceModel:OnNotifyIAOpenView(e, r, viewId, pieceGuid)
    -- Implementation omitted.
end

function BuildSpaceModel:GetPieceInfoByComfortType(Type)
    -- Implementation omitted.
end

function BuildSpaceModel:CheckHoldTotem()
    -- Implementation omitted.
end

function BuildSpaceModel:GetRecentCatalogId()
    -- Implementation omitted.
end

function BuildSpaceModel:OnBuildUnitRecipeLock(_, _, id)
    -- Implementation omitted.
end

function BuildSpaceModel:OnCoatUnitRecipeLock(_, _, id)
    -- Implementation omitted.
end

function BuildSpaceModel:OnSearchUnitByName(name)
    -- Implementation omitted.
end

function BuildSpaceModel:CacheSearch(name)
    -- Implementation omitted.
end

function BuildSpaceModel:OnSearchUnit()
    -- Implementation omitted.
end

function BuildSpaceModel:GetSearchHistoryData()
    -- Implementation omitted.
end

function BuildSpaceModel:GetSkillLimitDataById(id)
    -- Implementation omitted.
end

function BuildSpaceModel:GetTotemMoveCD()
    -- Implementation omitted.
end

function BuildSpaceModel:ShowTotemPackageFrame()
    -- Implementation omitted.
end

function BuildSpaceModel:CheckDelUnit()
    -- Implementation omitted.
end

function BuildSpaceModel:ShowBuildSpaceDebugFrame()
    -- Implementation omitted.
end

return BuildSpaceModel
