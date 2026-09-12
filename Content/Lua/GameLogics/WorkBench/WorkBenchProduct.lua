-- Selected feature implementation. External runtime and widget assets are not included.
local WorkBenchProduct, super = CreateUIBehaviour("WorkBenchProduct")
local ESlateVisibility = import("ESlateVisibility")
local KUILibrary = UE4.PzUILibrary
local WorkBenchExport = import("WorkBenchExport")
local EquipMadeExport = import("EquipMadeExport")
local WorkBenchModel = ModelManager:GetModel("WorkBenchModel")
local DimensionalDataExport = import("DimensionalDataExport")
local ItemMakeTable = GetTableDefine("ItemMakeTable")
local KGItemLibrary = UE4.PzInventoryLibrary
local KGItemManager = KGItemLibrary.GetInventoryManager(_G.GlobalContext)
local Timer = require "GameCore.GameEvent.Timer"
local PanelSetting =
{
    Elements =
    {
        { Name = "UIRootCanvasPanel", },
        { Name = "UIItemIcon", },
        { Name = "Fx_UIItemIcon_Add", },
        { Name = "UIItemName", },
        { Name = "UIItemCount", },
        { Name = "UIFirstUseExp", },
        { Name = "UIItemQualityImg", },
        { Name = "UIItemTypeIcon", },
        { Name = "UIItemPartDesc", },
        { Name = "UIItemEnhanceLevelGroup", },
        { Name = "UIItemEnhanceLevel", },
        { Name = "UIItemEnhanceLevel2", },
        { Name = "UIConditionGroup", },
        { Name = "UINeedBenchLevelDescSwitcher", },
        { Name = "UINeedBenchLevelDesc", },
        { Name = "UINeedBenchLevelDesc2", },
        { Name = "UIAccessoryAttrGroup", },
        { Name = "UIAccessoryAttrList", },
        { Name = "UIDescSwitcher", },
        { Name = "UIItemMaterialGroupSwitch", },
        { Name = "UIItemMaterialList", Type = UE4.ListView, },
        { Name = "UIItemMaterialList2", Type = UE4.ListView, },
        { Name = "UIMaterialEmpty", },
        { Name = "UIEquipMaterialGroup", },
        { Name = "UIBtnGroupSwitcher", },
        { Name = "UIBtnMakeSwitcher", },
        { Name = "UIBtnMake", Handles = { OnClicked = "OnBtnMake", }, },
        { Name = "UIBtnMakeCancel", Handles = { OnClicked = "OnBtnMake", }, },
        { Name = "UIBtnEnhance", Handles = { OnClicked = "OnBtnMake", }, },
        { Name = "UIBtnRepair", Handles = { OnClicked = "OnBtnMake", }, },
        { Name = "UIBtnViewRecipe", Handles = { OnClicked = "OnBtnViewRecipe", }, },
        { Name = "UICostTimeGroup", },
        { Name = "UICostTime", },
        { Name = "UIBtnMakeInProducing", Handles = { OnClicked = "OnBtnInProducing", }, },
        { Name = "UIBtnMakeCanTake", Handles = { OnClicked = "OnBtnMakeCanTake", }, },
        { Name = "UIProductAttrGroup", },
        { Name = "UIProductAttrListBox", },
        { Name = "UIProductAttrList", },
        { Name = "UIBtnProductTotalBG", Handles = { OnClicked = "OnBtnProductTotalBG", }, },
        { Name = "UIBtnSwitchMaterialGroup", },
        { Name = "UIBtnSwitchMaterial", Handles = { OnClicked = "OnBtnProductSelectMaterial", }, },
        { Name = "UIBtnGroupSpacer", },
        { Name = "UIProductGroup2", },
        { Name = "UIProductSuitGroup", },
        { Name = "UIProductSuitIcon", },
        { Name = "UIProductSuitName", },
        { Name = "UIProductSuitNeedBenchLevelDesc"},
        { Name = "UIModifySkillInfo", },
    },
    Behaviours =
    {
        { Name = "UIItemTips2", },
        { Name = "UIProductAbility", },
        { Name = "UIProductEnhance", },
        { Name = "UIProductSuitEffect", },
        { Name = "UIProductSelectMaterial", },
        { Name = "UIEquipMaterial", },
        { Name = "UIModifySkillInfo", Alias = "UIModifySkillInfoBehavior"},
    },
    Events =
    {
        ["UIEvent_WorkBenchProductMaterial_ShowItemTips"] = "ShowItemTips",
        ["UIEvent_WorkBench_ProductPanelBGClicked"] = "OnBtnProductTotalBG",
        ["UIEvent_WorkBenchProductSelectMaterialClicked"] = "OnProductSelectMaterial",
        ["LogicEvent_UI_ProduceInfoChanged"] = "OnProduceInfoChanged", --生产状态发生了变化
    },
}
local WorkType_Make = ItemMakeTable.BenchWorkType_Make    --本界面为打造物件工作
local WorkType_Enhance = ItemMakeTable.BenchWorkType_Enhance --本界面为升级物件工作
local WorkType_Repair = ItemMakeTable.BenchWorkType_Repair --本界面为修理物件工作
local MakeAnimName = "Make_0"
function WorkBenchProduct:_init(go)
    super._init(self, go, PanelSetting)
    self.m_WorkType = WorkType_Make
    self.m_MakeRecipeInfoList = {} --打造路径列表
    self.m_EquipMaterialInfoList = {} --基底材料列表
    self.m_EquipMaterialWaitItemClientID = 0
    self.m_MakeMakeID = 0 --打造ID
    self.m_MakeRecipeID = 0 --配方ID
    self.m_MakeRepeat = 1 --制造多少份，总是制造一份
    self.m_ProductItemTypeID = 0
    self.m_ProductItemClientID = 0
    self.m_EnhanceMaterialData = nil
    self.m_EnhanceChangeData = nil
    self.m_WorkBench_CurLevel = 0 --当前的工作台等级
    self.m_WorkBench_NeedLevel = 0 --需要的工作台等级
    self.m_IsConditionEnough = true --工作台等级是否足够
    self.m_IsMaterialEnough = true --材料是否足够
    self.m_ArriveTakeLimit = false --达到携带上限
    self.m_EquipMaterialItemTypeID = 0
    self.m_EquipMaterialItemClientID = 0
end
function WorkBenchProduct:OnInitialize()
    -- Implementation omitted.
end
function WorkBenchProduct:OnDestroy()
    -- Implementation omitted.
end
function WorkBenchProduct:ShowProductForMake(MakeID, bShouldFindBestMakeID, NewSuitID)
    -- Implementation omitted.
end
function WorkBenchProduct:SwitchToMakeID(MakeID)
    -- Implementation omitted.
end
function WorkBenchProduct:Func_ClearWorkBenchNewFlag()
    -- Implementation omitted.
end
function WorkBenchProduct:ShowProductForEnhance(ItemClientID)
    -- Implementation omitted.
end
function WorkBenchProduct:ShowProductForRepair(ItemClientID)
    -- Implementation omitted.
end
function WorkBenchProduct:FillProductPanel()
    -- Implementation omitted.
end
function WorkBenchProduct:IsConditionEnough()
    -- Implementation omitted.
end
function WorkBenchProduct:IsMaterialEnough()
    -- Implementation omitted.
end
function WorkBenchProduct:IsArriveTakeLimit()
    -- Implementation omitted.
end
function WorkBenchProduct:SetMaterialSelectIndex(Index)
    -- Implementation omitted.
end
function WorkBenchProduct:func_GetEnhanceLevel()
    -- Implementation omitted.
end
function WorkBenchProduct:FillEnhanceLevelGroup(EquipMaterialItemEnhanceLevel)
    -- Implementation omitted.
end
function WorkBenchProduct:FillCondition()
    -- Implementation omitted.
end
function WorkBenchProduct:Func_FillConditionForMake()
    -- Implementation omitted.
end
function WorkBenchProduct:Func_FillConditionWithParam(NeedWorkBenchLevel, bSatisfy)
    -- Implementation omitted.
end
function WorkBenchProduct:Func_FillConditionForEnhance()
    -- Implementation omitted.
end
function WorkBenchProduct:Func_FillConditionForRepair()
    -- Implementation omitted.
end
function WorkBenchProduct:FillAttrList()
    -- Implementation omitted.
end
function WorkBenchProduct:Func_FillAttrListForMake()
    -- Implementation omitted.
end
function WorkBenchProduct:Func_FillAttrListForMake_Ornaments(curProductItemTypeID, curEquipType)
    -- Implementation omitted.
end
function WorkBenchProduct:Func_FillAttrListForMake_OtherEquip()
    -- Implementation omitted.
end
function WorkBenchProduct:Func_FillAttrListForEnhance()
    -- Implementation omitted.
end
function WorkBenchProduct:Func_DoFillAttrList(CollectAttrInfo, UIHeight)
    -- Implementation omitted.
end
function WorkBenchProduct:FillEquipSuitEffect()
    -- Implementation omitted.
end
function WorkBenchProduct:FillMaterialList()
    -- Implementation omitted.
end
function WorkBenchProduct:Func_FillMaterialListForMake(SelectEquipClientIDForMaterial)
    -- Implementation omitted.
end
function WorkBenchProduct:Func_FillEquipMaterialForMake()
    -- Implementation omitted.
end
function WorkBenchProduct:Func_FillCostTime()
    -- Implementation omitted.
end
function WorkBenchProduct:Func_FillFirstUseExp()
    -- Implementation omitted.
end
function WorkBenchProduct:Func_FillMaterialListForEnhance()
    -- Implementation omitted.
end
function WorkBenchProduct:Func_FillMaterialListForRepair()
    -- Implementation omitted.
end
function WorkBenchProduct:FillEnhanceGroup()
    -- Implementation omitted.
end
function WorkBenchProduct:RefreshProductBtnGroup()
    self:PalProduce_StopCountDown()
    if self.m_WorkType == WorkType_Make then
        self:RefreshProductBtnGroupForMake()
    elseif self.m_WorkType == WorkType_Enhance then
        self:RefreshProductBtnGroupForEnhance()
    elseif self.m_WorkType == WorkType_Repair then
        self:RefreshProductBtnGroupForRepair()
    end
end
function WorkBenchProduct:RefreshProductBtnGroupForMake()
    local curCarryMakeId = WorkBenchModel.m_BenchMakeId
    self.UIBtnGroupSwitcher:SetActiveWidgetIndex(0)
    self.UIBtnMakeSwitcher:SetActiveWidgetIndex(0)
    if curCarryMakeId == 0 then
        self.UIBtnMake:SetVisibility(ESlateVisibility.Hidden)
        return
    end
    self.UIBtnMake:SetVisibility(ESlateVisibility.Visible)
    local IsProducing = EquipMadeExport.InteractivePiece_IsProducing(_G.GlobalContext)
    if IsProducing == true then
        self:PalProduce_StartCountDown()
        return
    end
    local IsPausing = EquipMadeExport.InteractivePiece_IsPausing(_G.GlobalContext)
    if IsPausing == true then
        self.UIBtnMakeSwitcher:SetActiveWidgetIndex(4)
        return
    end
    local IsCanTake = EquipMadeExport.InteractivePiece_IsCanTake(_G.GlobalContext)
    if IsCanTake == true then
        self:PalProduce_CountDownFinished()
        return
    end
        if WorkBenchModel.m_State_ConditionEnough == false then
            self.UIBtnMake:SetText(string.format(ItemMakeTable.MakeText_ConditionError, self.m_WorkBench_NeedLevel))
            self.UIBtnMake.CommonButton:SetIsEnabled(true)
        elseif WorkBenchModel.m_State_MaterialEnough == false then
            self.UIBtnMake:SetText(ItemMakeTable.MakeText_MaterialError)
            self.UIBtnMake.CommonButton:SetIsEnabled(true)
        elseif WorkBenchModel.m_State_ArriveTakeLimit == true then
            self.UIBtnMake:SetText(ItemMakeTable.MakeText_BagLimitError)
            self.UIBtnMake.CommonButton:SetIsEnabled(false)
        else
            if WorkBenchModel.m_State_InMaking == true then
                self.UIBtnMakeSwitcher:SetActiveWidgetIndex(1)
            else
                self.UIBtnMake:SetText(ItemMakeTable.MakeText_StartMake)
                self.UIBtnMake.CommonButton:SetIsEnabled(true)
            end
        end
end
function WorkBenchProduct:RefreshProductBtnGroupForEnhance()
    -- Implementation omitted.
end
function WorkBenchProduct:RefreshProductBtnGroupForRepair()
    -- Implementation omitted.
end
function WorkBenchProduct:PlayMakeEffect(ProductItemTypeID, IsPlay, TotalTime)
    -- Implementation omitted.
end
function WorkBenchProduct:Func_StopAllMakeAnim()
    -- Implementation omitted.
end
function WorkBenchProduct:PlayEffectSuccess()
    -- Implementation omitted.
end
function WorkBenchProduct:HideAllPopPanel()
    self:HideItemTips()
    self:HideProductSelectMaterialPanel()
    self:HideProductTotalBG()
end
function WorkBenchProduct:ShowItemTips(_, _, MaterialIndex, ItemTypeID, ItemCount, ItemClientID)
    -- Implementation omitted.
end
function WorkBenchProduct:HideItemTips()
    -- Implementation omitted.
end
function WorkBenchProduct:IsItemTipsVisible()
    -- Implementation omitted.
end
function WorkBenchProduct:RefreshBtnProductSelectMaterial()
    -- Implementation omitted.
end
function WorkBenchProduct:OnBtnProductSelectMaterial()
    -- Implementation omitted.
end
function WorkBenchProduct:ShowProductSelectMaterialPanel(ItemTypeID, ItemClientID, EquipMaterialInfoList)
    -- Implementation omitted.
end
function WorkBenchProduct:HideProductSelectMaterialPanel()
    -- Implementation omitted.
end
function WorkBenchProduct:IsProductSelectMaterialPanelVisible()
    -- Implementation omitted.
end
function WorkBenchProduct:OnProductSelectMaterial(_, _, MaterialIndex, ItemTypeID, ItemCount, ItemClientID)
    -- Implementation omitted.
end
function WorkBenchProduct:ShowProductTotalBG()
    -- Implementation omitted.
end
function WorkBenchProduct:HideProductTotalBG()
    -- Implementation omitted.
end
function WorkBenchProduct:OnBtnProductTotalBG()
    -- Implementation omitted.
end
function WorkBenchProduct:OnBtnMake()
    if WorkBenchModel.m_State_ConditionEnough == false then
        WorkBenchModel.Panel:OnBuildLvBtnClicked()
    elseif WorkBenchModel.m_State_MaterialEnough == false then
        local RecipeModel = ModelManager:GetModel("RecipeModel")
        if self.m_EnhanceChangeData == nil then
            RecipeModel:AddMaterialTrackingFrame(self.m_MakeRecipeID)
        else
            local curLevel = self.m_EnhanceChangeData.EnhanceLevelA
            local itemTypeId = self.m_EnhanceChangeData.ItemTypeId
            local RecipeId = EquipMadeExport.CraftRecipe_GetCraftIdByItemTypeId(_G.GlobalContext, itemTypeId)
            RecipeModel:AddMaterialTrackingFrame(RecipeId, curLevel, UE4.EPzTrackingRecipeType.TRACK_RECIPE_ENHANCE)
        end
    else
        EventSystem.Fire("UIEvent_WorkBenchProduct_MakeClicked")
    end
    self:HideAllPopPanel()
end
function WorkBenchProduct:OnBtnViewRecipe()
    -- Implementation omitted.
end
function WorkBenchProduct:OnBtnInProducing()
    local PieceGUID = EquipMadeExport.InteractivePiece_GetPieceGUID(_G.GlobalContext)
    local PieceOpType = EquipMadeExport.InteractivePiece_GetPieceOpType(_G.GlobalContext)
    EventSystem.Fire("LogicEvent_WorkBenchUI_CancelMake", PieceGUID, PieceOpType)
end
function WorkBenchProduct:OnBtnMakeCanTake()
    local PieceGUID = EquipMadeExport.InteractivePiece_GetPieceGUID(_G.GlobalContext)
    WorkBenchExport.WorkBench_ReqTakeProductWithPal(_G.GlobalContext, PieceGUID)
end
function WorkBenchProduct:ShowProductSuitPanel(SuitID)
    -- Implementation omitted.
end
function WorkBenchProduct:HideProductSuitPanel()
    -- Implementation omitted.
end
function WorkBenchProduct:OnSelectNewSuit(ValidSuitID)
    -- Implementation omitted.
end
function WorkBenchProduct:PalProduce_StartCountDown()
    self.UIBtnMakeSwitcher:SetActiveWidgetIndex(4)
    self._visibleScope:CloseEvent("PalProduce_CountDownTimer")
    self._visibleScope:ListenEvent("PalProduce_CountDownTimer", Timer:Always(1),
        function()
            self:PalProduce_CountDownUpdate()
        end)
    self:PalProduce_CountDownUpdate()
end
function WorkBenchProduct:PalProduce_StopCountDown()
    self._visibleScope:CloseEvent("PalProduce_CountDownTimer")
end
function WorkBenchProduct:PalProduce_CountDownFinished()
    self.UIBtnMakeSwitcher:SetActiveWidgetIndex(5)
    self._visibleScope:CloseEvent("PalProduce_CountDownTimer")
end
function WorkBenchProduct:PalProduce_CountDownUpdate()
    local IsProducing = EquipMadeExport.InteractivePiece_IsProducing(_G.GlobalContext)
    local IsCanTake = EquipMadeExport.InteractivePiece_IsCanTake(_G.GlobalContext)
    if IsProducing == true then
    elseif IsCanTake == true then
        self:PalProduce_CountDownFinished()
    else
        self:PalProduce_StopCountDown()
        self:RefreshProductBtnGroup()
    end
end
function WorkBenchProduct:OnProduceInfoChanged()
    self:RefreshProductBtnGroup()
end
return WorkBenchProduct
