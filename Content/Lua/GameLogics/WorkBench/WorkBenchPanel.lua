-- Selected feature implementation. External runtime and widget assets are not included.
local WorkBenchPanel, super = CreateUIBehaviourFromListView("WorkBenchPanel")
local ESlateVisibility = import("ESlateVisibility")
local KUILibrary = UE4.PzUILibrary
local WorkBenchExport = import("WorkBenchExport")
local EquipMadeExport = import("EquipMadeExport")
local ItemMakeTable = GetTableDefine("ItemMakeTable")
local WorkBenchTable = GetTableDefine("WorkBenchTable")
local GuideTable = GetTableDefine("GuideTable")
local DimensionalDataExport = UE4.DimensionalDataExport
local KGItemLibrary = UE4.PzInventoryLibrary
local KGItemManager = KGItemLibrary.GetInventoryManager(_G.GlobalContext)
local GameLuaLibrary = UE4.PzGameLuaLibrary
local Timer = require "GameCore.GameEvent.Timer"
local WorkBenchModel = ModelManager:GetModel("WorkBenchModel")
local BuildingManager  = UE4.BuildingFunctionLibrary.GetBuildingManager(_G.GlobalContext)
local BuildLvUpSystem = UE4.PzBuildUtil.GetBuildILeveUpSystem(_G.GlobalContext)
local BuildUIManager = UE4.PzBuildUtil.GetPieceUIManager(_G.GlobalContext)
local OpenAnim = "OpenAni"
local CloseAnim = "CloseAni"
local ShowProductAnim = "UITotalListChangedAni"
local TabCategory_Weapon = 1 --武器
local TabCategory_Armor = 2 --防具
local TabCategory_Accessory = 8 --饰品
local TabCategory_Tool = 3 --生存工具
local PanelSetting =
{
    Elements =
    {
        { Name = "UIRootPanel", },
        { Name = "UISafeZoneCanvasPanel", },
        { Name = "UITitleSwitcher", },
        { Name = "UICommonTitle", },
        { Name = "UIBenchMakeBtn", Handles = { OnClicked = "OnBtnBenchMake", }, },
        { Name = "UIBenchEnhanceBtn", Handles = { OnClicked = "OnBtnBenchEnhance", }, },
        { Name = "UIBenchRepairBtn", Handles = { OnClicked = "OnBtnBenchRepair", }, },
        { Name = "UIBenchGemstoneBtn", Handles = { OnClicked = "OnBtnBenchGemstone", }, Necessary = false, },
        { Name = "UIBenchAbilityBtn", Handles = { OnClicked = "OnBtnBenchAbility", }, Necessary = false, },
        { Name = "UIBenchEnhanceSpacer", },
        { Name = "UIBenchRepairSpacer", },
        { Name = "UIBenchGemstoneSpacer", Necessary = false, },
        { Name = "UIBenchAbilitySpacer", Necessary = false, },
        { Name = "UIModifySkillGroup", },
        { Name = "UIEquipSkillSelectWeapon", },
        { Name = "UIDynamicProductGroup", },
        { Name = "UIDynamicProductForChange", },
        { Name = "UIDynamicTreeListAccessory", },
        { Name = "UIDynamicTreeListTool", },
        { Name = "UIDynamicTotalList", },
        { Name = "UIBtnClose", Handles = { OnClicked = "OnBtnClose", }, },
        { Name = "UIBtnTotalBG", Handles = { OnClicked = "OnBtnTotalBG", }, },
        { Name = "UIBlockClickBtnOnMake", Handles = { OnClicked = "OnBtnBlockClickOnMake", }, },
        { Name = "UIBtnProductPanelBG", Handles = { OnClicked = "OnBtnProductPanelBG", }, },
        { Name = "UICategoryWeapon", Handles = { OnClicked = "OnBtnCategoryWeapon", }, },
        { Name = "UICategoryArmor", Handles = { OnClicked = "OnBtnCategoryArmor", }, },
        { Name = "UICategoryAccessory", Handles = { OnClicked = "OnBtnCategoryAccessory", }, },
        { Name = "UICategoryTool", Handles = { OnClicked = "OnBtnCategoryTool", }, },
        { Name = "UIMakeCategoryGroup", },
        { Name = "UIEnhanceCategoryGroup", },
        { Name = "UIEnhanceCategoryGroupText", },
        { Name = "UIRepairCategoryGroup", },
        { Name = "UIRepairCategoryGroupText", },
        { Name = "UIChangeCategoryGroup", },
        { Name = "UIChangeCategoryGroupText", },
        { Name = "UIListBG", },
        { Name = "UIProductPanel", },
        { Name = "UIUpgradeGroup", },
        { Name = "WorkLvText", },
        { Name = "BuildLvBtn", Handles = { OnClicked = "OnBuildLvBtnClicked", }, },
        { Name = "UIMainLeftSwitcher", },
        { Name = "UIMainLeft", },
        { Name = "UIEmptyGroup", },
        { Name = "UIEmptyString", },
        { Name = "UIRedHintEdge", },
        { Name = "UICloseBtnSwitcher", },
        { Name = "UIBtnBack", Handles = { OnClicked = "NewChange_OnBackChange", }, },
    },
    Behaviours =
    {
        { Name = "UITreeListWeapon", Type = "WorkBenchListWeapon", },
        { Name = "UITreeListArmor", Type = "WorkBenchListArmor", },
    },
    Events =
    {
        ["UIEvent_WorkBench_CategoryChanged"] = "OnCategoryChanged",
        ["UIEvent_WorkBenchList_SelectChanged"] = "OnSelectChangedRefreshProduct", --刷新产物详情界面
        ["UIEvent_WorkBench_RefreshSuitInfo"] = "OnSelectChangedRefreshSuitInfo", --刷新套装信息界面
        ["UIEvent_WorkBenchProduct_MakeClicked"] = "OnBtnMake",
        ["UIEvent_WorkBench_ShowTotalBG"] = "OnShowTotalBG",
        ["UIEvent_WorkBench_ShowProductPanelBG"] = "OnShowProductPanelBG",
        ["UIEvent_WorkBench_ShowGemstoneBG"] = "UIGemstone_OnShowGemstoneBG",
        ["WorkBenchGemstoneMain_OnBGClicked"] = "UIGemstone_OnBtnGemstoneBG",
        ["UIEvent_WorkBench_ClearNewFlag"] = "OnClearNewFlag", --去掉“新”标签的事件
        ["UIEvent_WorkBench_ChangeNewFlagArrowVisible"] = "OnChangeNewFlagArrowVisible",
        ["ContainerItemCountChanged_CombineNtf"] = "OnEventBagContainerUpdate", --背包道具发生了变化
        ["PZ_EVENT_TOTEM_ITEM_UPDATE"] = "OnEventBagContainerUpdate",
        ["NetEvent_NoticeUnlockNewRecipe"] = "OnUnlockNewRecipe", --刚刚解锁了新配方
        ["OnLevelBuildFromChange"] = "OnBuildsFromChange", --与工作台相关升级的建筑变动
        ["OnPiecelvChange"] = "OnPieceLvChange",
        ["OnSystemFunctionStatusUnlock"] = "OnSystemFuncUnlock", --新功能解锁了
		["BuildLevelPieceItem_ReqBuild"] = "OnHide",
        ["UIEvent_ModificationTable_ModifySkill"] = "OnModifySkillBegin", --开始改造技能
        ["UIEvent_SkillModofySuccess"] = "OnSkillModofySuccess", --改造技能成功
        ["NetEvent_EquipEnhanceRsp"] = "Enhance_CloseWaitForEnhanceRspMsg", --请求强化后，收到服务器回复
        ["NetEvent_EquipRepairRsp"] = "Repair_CloseWaitForRepairRspMsg", --请求修理后，收到服务器回复
        ["UIEvent_EquipSkill_ShowSelectWeapon"] = "NewChange_OnShowSelectWeapon", --点击了战技装配按钮，显示选择武器界面
    },
}
function WorkBenchPanel:_init(go)
    -- Implementation omitted.
end
function WorkBenchPanel:OnInitialize()
    -- Implementation omitted.
end
function WorkBenchPanel:OnDestroy()
    -- Implementation omitted.
end
function WorkBenchPanel:OnMyShowPanel()
    -- Implementation omitted.
end
function WorkBenchPanel:NextStepShowPanel()
    -- Implementation omitted.
end
function WorkBenchPanel:RefreshAllByBenchOpenType()
    -- Implementation omitted.
end
function WorkBenchPanel:RefreshUpgradeGroupVisible()
    -- Implementation omitted.
end
function WorkBenchPanel:OnMyHidePanel()
    -- Implementation omitted.
end
function WorkBenchPanel:UIGemstone_LoadRes()
    -- Implementation omitted.
end
function WorkBenchPanel:UIGemstone_UnloadRes()
    -- Implementation omitted.
end
function WorkBenchPanel:UIGemstone_SetPanelVisible(IsVisible)
    -- Implementation omitted.
end
function WorkBenchPanel:UIGemstone_OnShowGemstoneBG(e, r, IsShow)
    -- Implementation omitted.
end
function WorkBenchPanel:UIGemstone_OnBtnGemstoneBG()
    -- Implementation omitted.
end
function WorkBenchPanel:HelpFunc_GetItemsMakeDataByCategoryID(ProductItemTypeID, DataTable)
    -- Implementation omitted.
end
function WorkBenchPanel:GetItemsMakeDataByCategoryID(category)
    -- Implementation omitted.
end
function WorkBenchPanel:InitAllCategoryTab()
    -- Implementation omitted.
end
function WorkBenchPanel:Func_FillSingleCategoryTab(UITab, itemData)
    -- Implementation omitted.
end
function WorkBenchPanel:Func_FindFirstNewFlagInArmorDataList()
    -- Implementation omitted.
end
function WorkBenchPanel:RefreshAllTabText()
    -- Implementation omitted.
end
function WorkBenchPanel:Func_FillAllCategoryNewFlage()
    -- Implementation omitted.
end
function WorkBenchPanel:Func_IsNewFlageExist(CategoryID)
    -- Implementation omitted.
end
function WorkBenchPanel:RefreshCategoryTabForMake()
    -- Implementation omitted.
end
function WorkBenchPanel:RefreshCategoryTabForEnhance()
    -- Implementation omitted.
end
function WorkBenchPanel:RefreshCategoryTabForRepair()
    -- Implementation omitted.
end
function WorkBenchPanel:RefreshCategoryTabForChange()
    -- Implementation omitted.
end
function WorkBenchPanel:ShowWorkType(newWorkType)
    -- Implementation omitted.
end
function WorkBenchPanel:ShowTabCategory(Category)
    -- Implementation omitted.
end
function WorkBenchPanel:ShowTabCategory_2(Category)
    -- Implementation omitted.
end
function WorkBenchPanel:RefreshTotalListAndProductPanel()
    -- Implementation omitted.
end
function WorkBenchPanel:LoadUITreeListAccessory()
    -- Implementation omitted.
end
function WorkBenchPanel:LoadUITreeListTool()
    -- Implementation omitted.
end
function WorkBenchPanel:LoadUITotalList()
    -- Implementation omitted.
end
function WorkBenchPanel:LoadUIProductGroup()
    -- Implementation omitted.
end
function WorkBenchPanel:UIProductPlayEffectSuccess()
    -- Implementation omitted.
end
function WorkBenchPanel:ShowProductPanelForMake(BenchMakeId, bShouldFindBestMakeID, NewSuitID)
    -- Implementation omitted.
end
function WorkBenchPanel:ShowProductPanelForEnhance(ItemClientID)
    -- Implementation omitted.
end
function WorkBenchPanel:ShowProductPanelForRepair(ItemClientID)
    -- Implementation omitted.
end
function WorkBenchPanel:ShowProductPanelForChange(ItemClientID)
    -- Implementation omitted.
end
function WorkBenchPanel:HideProductPanel()
    -- Implementation omitted.
end
function WorkBenchPanel:PlayProductMakeEffect(ProductItemTypeID, IsPlay, TotalTime)
    -- Implementation omitted.
end
function WorkBenchPanel:Func_CalculateAllItemCountForMake()
    -- Implementation omitted.
end
function WorkBenchPanel:Func_CalculateMaxRepeatForMake()
    -- Implementation omitted.
end
function WorkBenchPanel:Func_RefreshAllBtn()
    if self.m_UIProductGroup then
        self.m_UIProductGroup:RefreshProductBtnGroup()
    end
end
function WorkBenchPanel:OnBtnBenchMake()
    -- Implementation omitted.
end
function WorkBenchPanel:OnBtnBenchEnhance()
    -- Implementation omitted.
end
function WorkBenchPanel:OnBtnBenchRepair()
    -- Implementation omitted.
end
function WorkBenchPanel:OnBtnBenchGemstone()
    -- Implementation omitted.
end
function WorkBenchPanel:OnBtnBenchAbility()
    -- Implementation omitted.
end
function WorkBenchPanel:OnHide()
    -- Implementation omitted.
end

function WorkBenchPanel:OnBtnClose()
    -- Implementation omitted.
end
function WorkBenchPanel:OnShowTotalBG(e, r, IsShow)
    -- Implementation omitted.
end
function WorkBenchPanel:OnBtnTotalBG()
    -- Implementation omitted.
end
function WorkBenchPanel:SetBtnVisible_BlockClickOnMake(IsShow)
    -- Implementation omitted.
end
function WorkBenchPanel:OnBtnBlockClickOnMake()
    -- Implementation omitted.
end
function WorkBenchPanel:OnShowProductPanelBG(e, r, IsShow)
    -- Implementation omitted.
end
function WorkBenchPanel:OnBtnProductPanelBG()
    -- Implementation omitted.
end
function WorkBenchPanel:AddAnimationDelegate()
    -- Implementation omitted.
end
function WorkBenchPanel:OnBtnCategoryWeapon()
    -- Implementation omitted.
end
function WorkBenchPanel:OnBtnCategoryArmor()
    -- Implementation omitted.
end
function WorkBenchPanel:OnBtnCategoryAccessory()
    -- Implementation omitted.
end
function WorkBenchPanel:OnBtnCategoryTool()
    -- Implementation omitted.
end
function WorkBenchPanel:OnCategoryChanged(e, r, Index, CategoryID)
    -- Implementation omitted.
end
function WorkBenchPanel:OnSelectChangedRefreshProduct(e, r, BenchMakeId, ItemClientID, bShouldFindBestMakeID)
    -- Implementation omitted.
end
function WorkBenchPanel:OnSelectChangedRefreshSuitInfo(e, r, NewSuitID)
    -- Implementation omitted.
end
function WorkBenchPanel:OnBtnMake()
    local CurBenchWorkType = self.m_BindModel.m_BenchWorkType
    local CurTabCategory = self.m_BindModel.m_TabCategory
    if CurBenchWorkType == ItemMakeTable.BenchWorkType_Make then
        local _ShowConfirmMsgBox = false
        if CurTabCategory ~= TabCategory_Accessory then
            if self.m_BindModel.m_SuccessGainFirstUseExpNum == 0 then
                _ShowConfirmMsgBox = true
            end
        end
        self.m_BindModel.m_IsShowConfirmMsgBox = _ShowConfirmMsgBox
        self.m_BindModel:OnMakeClicked()
    elseif CurBenchWorkType == ItemMakeTable.BenchWorkType_Enhance then
        self:Enhance_OnBtnEnhance()
    elseif CurBenchWorkType == ItemMakeTable.BenchWorkType_Repair then
        self:Repair_OnBtnRepair()
    elseif CurBenchWorkType == ItemMakeTable.ModificationTableWorkType_Change then
    end
end
function WorkBenchPanel:OnEventBagContainerUpdate()
    -- Implementation omitted.
end
function WorkBenchPanel:OnUnlockNewRecipe()
    -- Implementation omitted.
end
function WorkBenchPanel:OnClearNewFlag(e, r, MakeID, RecipeID, ProductTypeID, EquipSuitID)
    -- Implementation omitted.
end
function WorkBenchPanel:OnChangeNewFlagArrowVisible(e, r, IsVisible)
    -- Implementation omitted.
end
function WorkBenchPanel:Make_CheckExist_TotalSatisfiedMakeID()
    -- Implementation omitted.
end
function WorkBenchPanel:Enhance_CollectAllEquip()
    -- Implementation omitted.
end
function WorkBenchPanel:Enhance_GetChangeData()
    -- Implementation omitted.
end
function WorkBenchPanel:Enhance_OnBtnEnhance()
    -- Implementation omitted.
end
function WorkBenchPanel:Enhance_CloseWaitForEnhanceRspMsg()
    -- Implementation omitted.
end
function WorkBenchPanel:Repair_CollectAllEquip()
    -- Implementation omitted.
end
function WorkBenchPanel:Repair_OnBtnRepair()
    -- Implementation omitted.
end
function WorkBenchPanel:Repair_CloseWaitForRepairRspMsg()
    -- Implementation omitted.
end
function WorkBenchPanel:Change_CollectAllEquip()
    -- Implementation omitted.
end
function WorkBenchPanel:OnBuildsFromChange(e,r,PieceGuid)
    -- Implementation omitted.
end
function WorkBenchPanel:OnPieceLvChange(e,r,PieceGuid)
    -- Implementation omitted.
end
function WorkBenchPanel:SetLvText()
    -- Implementation omitted.
end
function WorkBenchPanel:OnBuildLvBtnClicked()
    local workBenchModel = ModelManager:GetModel("WorkBenchModel")
    local BuildLevelModel = ModelManager:GetModel("BuildLevelModel")
    local Data = {}
    Data.PieceGuid = workBenchModel:GetCurWorkBenchGuid(_G.GlobalContext)
	Data.LevelDescType = BuildLevelModel.LevelDescType.Make
    BuildLevelModel:ActiveBuildLevelFrame(Data)
end
function WorkBenchPanel:RefreshBenchBtnByAllReason()
    -- Implementation omitted.
end
function WorkBenchPanel:RefreshBenchBtnBySystemFunc()
    -- Implementation omitted.
end
function WorkBenchPanel:OnSystemFuncUnlock(e, r, SystemFuncID)
    -- Implementation omitted.
end
function WorkBenchPanel:OnModifySkillBegin()
    -- Implementation omitted.
end
function WorkBenchPanel:OnBackChange()
    -- Implementation omitted.
end
function WorkBenchPanel:OnSkillModofySuccess()
    -- Implementation omitted.
end
function WorkBenchPanel:NewChange_OnShowSelectWeapon(e, r, IsShow, SingleData)
    -- Implementation omitted.
end
function WorkBenchPanel:NewChange_OnBackChange()
    -- Implementation omitted.
end
return WorkBenchPanel
