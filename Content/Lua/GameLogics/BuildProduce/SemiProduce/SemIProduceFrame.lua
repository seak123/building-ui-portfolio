-- Selected feature implementation. External runtime and widget assets are not included.
local SemiProduceFrame, super = CreateUIBehaviour("SemiProduceFrame")
local LuaLibrary = UE4.PzGameLuaLibrary
local BuildProduceModel = ModelManager:GetModel("BuildProduceModel")
local CraftConfig = ConfigManager.GetTable("ResCarryonCraft")
local BuildInteractionSystem = UE4.PzBuildUtil.GetBuildInteractionSystem(_G.GlobalContext)
local DimensionalDataExport = import("DimensionalDataExport")
local ItemMakeTable = GetTableDefine("ItemMakeTable")
local RecipeCultivateTable = ConfigManager.GetTable("ResCraftRecipeCultivate")
local EquipMadeExport = UE4.EquipMadeExport
local WorkBenchExport = UE4.WorkBenchExport
local RecipeModel = ModelManager:GetModel("RecipeModel")

local BtnState =
{
    None = 0,
    Normal = 1,
    WorkFull = 2,
    CanNotMake_Material = 3,
    CanNotMake_Cond = 4,
}

local setting =
{
    Elements =
    {
        {
            Name = "CloseBtn",
            Handles =
            {
                OnClicked = "Hide",
            },
        },
        {
            Name = "BgCloseBtn",
            Handles =
            {
                OnClicked = "Hide",
            },
        },
        {
            Name = "TipsBtn",
            Handles =
            {
                OnClicked = "OnTipsBtn",
            },
        },
        {
            Name = "RecipeListView",
        },
        {
            Name = "PieceName",
        },
        {
            Name = "ItemName",
        },
        {
            Name = "ItemCount",
        },
        {
            Name = "ItemDescText",
        },
        {
            Name = "WorkLoadText",
        },
        {
            Name = "FirstUseExpOverlay",
        },
        {
            Name = "UIFirstUseExp",
        },
        {
            Name = "ItemAttrListView",
        },
        {
            Name = "ItemAttrOverlay",
        },
        {
            Name = "ConsumeItemListView",
        },
        {
            Name = "AmountEdit",
        },
        {
            Name = "StartProduceBtn",
            Handles =
            {
                OnClicked = "OnStartProduceBtn",
            },
        },
        {
            Name = "QueueNumText",
        },
        {
            Name = "ConsumeItemListView",
        },
        {
            Name = "GetProductionBtn",
            Handles =
            {
                OnClicked = "OnGetProductionBtn",
            },
        },
        {
            Name = "QueueWorkListView",
        },
        {
            Name = "CraftStateSwitcher",
        },
    },
    Events =
    {
        ["OnSemiSelectCraftChanged"] = "OnSemiSelectCraftChanged",
        ["QueueWorkEntityWorkDataChanged"] = "OnQueueWorkEntityWorkDataChanged",
        ["PZ_EVENT_TOTEM_ITEM_UPDATE"] = "OnContainerUpdated",
        ["BuildLeaveInteractive"] = "OnBuildInteractionLeave",
        ["SendCreateCraftRsp"] = "SendCreateCraftRsp",
    },
    Behaviours =
    {

    }
}

function SemiProduceFrame:_init(go)
    super._init(self, go, setting)

    self.PieceID = 0
    self.PieceGuid = nil
    self.InteractionID = 0
    self.CraftData = nil
    self.SelectCraftData = {}
    self.SelectCraftData.CraftID = 0
    self.SelectCraftData.RecipeID = 0
    self.SelectCraftData.MakeCount = 1
    self.SelectCraftData.ProduceItemID = 0
    self.SelectCraftData.WorkLoad = 0
    self.SelectCraftData.ProduceOneMakeCount = 1
    self.SelectCraftData.ShowName = ""
    self.CurStartBtnState = BtnState.None

    self.AmountEdit:SetCurrValue(1)
	self.AmountEdit:SetMinValue(1)
	self.AmountEdit.OnAmountEditValueChange:Add(
		function()
			self:OnMakeCountChanged()
		end)
     self.AmountEdit.OnClickedMax:Add(
        function()
			self:OnClickedMaxBtn()
		end)
end

function SemiProduceFrame:OnInitialize()

end

function SemiProduceFrame:OnDestroy()
    self.AmountEdit.OnAmountEditValueChange:Clear()
    self.AmountEdit.OnClickedMax:Clear()
end

function SemiProduceFrame:Hide()
    self._target:Hide()
end

function SemiProduceFrame:OnBuildInteractionLeave(e,r,InteractId,ActorGuid,IsLeaveBox)
    if LuaLibrary.CheckGuidIsEqualValid(self.PieceGuid,ActorGuid) and InteractId == self.InteractionID then
        self:Hide()
    end
end

function SemiProduceFrame:SetData(PieceID,PieceGuid,InteractionID)
    self.PieceID = PieceID
    self.PieceGuid = PieceGuid
    self.InteractionID = InteractionID

    self.PieceName:SetText(FKBinHomelandBuildingItemTable.GetName(_G.GlobalContext,self.PieceID))

    self.CraftData = BuildProduceModel:GetCraftData(PieceID,self.PieceGuid)
    local SelectID = 0
    if SelectID <= 0 then
        if #self.CraftData > 0 then
            SelectID = self.CraftData[1].CraftId
        end
    end
    BuildProduceModel:SetSemiSelectCraftID(SelectID,true)
    self:OnSelectChanged(SelectID)
    self:RefreshFrameData()
    self:RefreshQueueWorkData()
end

function SemiProduceFrame:OnContainerUpdated(e,r)
    self.CraftData = BuildProduceModel:GetCraftData(self.PieceID,self.PieceGuid)
    self:RefreshFrameData()
    if self.SelectCraftData then
        self:RefreshSelectRecipeState(self.SelectCraftData.CraftID,self.SelectCraftData.MakeCount)
    end
    self:CheckBtnState()
end

function SemiProduceFrame:OnSemiSelectCraftChanged(e,r,CraftID)
    self:OnSelectChanged(CraftID)
end

function SemiProduceFrame:OnSelectChanged(CraftID)
    if self.SelectCraftData.CraftID > 0 and self.SelectCraftData.CraftID == CraftID then
        return
    end

    self.SelectCraftData.CraftID = CraftID
    self.SelectCraftData.MakeCount = 1

    local Config = CraftConfig:GetRowByKey(CraftID)
    if Config then
        self.SelectCraftData.RecipeID =  Config.CraftRecipeId
        self.SelectCraftData.ProduceItemID = FKBinCraftBasicTable.GetProductItemID(_G.GlobalContext,Config.CraftRecipeId)
        self.SelectCraftData.WorkLoad = Config.PalWorkloadAmount.WorkloadAmount
        self.SelectCraftData.ProduceOneMakeCount = FKBinCraftBasicTable.GetCraftMakeItemCount(_G.GlobalContext,self.SelectCraftData.RecipeID,self.SelectCraftData.ProduceItemID)
        self.SelectCraftData.ShowName = Config.Name
        if self.SelectCraftData.ShowName == "" then
            self.SelectCraftData.ShowName = FKBinItemTable.GetName(_G.GlobalContext,self.SelectCraftData.ProduceItemID)
        end
        self:RefreshSelectRecipeState(CraftID,self.SelectCraftData.MakeCount)
    end
    self.AmountEdit:SetCurrValue(self.SelectCraftData.MakeCount)
    self:RefreshFrameDataOnSelect()
end

function SemiProduceFrame:RefreshSelectRecipeState(CraftID, MakeCount)
    if self.SelectCraftData then
        self.SelectCraftData.RecipeState = BuildProduceModel:GetCraftProduceItemState(CraftID,self.PieceGuid,MakeCount)
    end
end

function SemiProduceFrame:RefreshFrameDataOnSelect()
    if self.SelectCraftData.RecipeState == BuildProduceModel:GetRecipeState().Lock then
        self.CraftStateSwitcher:SetActiveWidgetIndex(0)
    else
        self.CraftStateSwitcher:SetActiveWidgetIndex(1)
    end
    if self.SelectCraftData then
        self:RefreshSelectRecipeState(self.SelectCraftData.CraftID,self.SelectCraftData.MakeCount)
    end
    self:RefreshSelectRecipeData()
    self:CheckBtnState(true)
    self:CheckUIFirstUseExp()
end

function SemiProduceFrame:RefreshFrameData()
    self.RecipeListView:ClearListItems()
    for index, value in ipairs(self.CraftData) do
        local uobject = DataObjectPool:Get(value)
        self.RecipeListView:AddItem(uobject)
    end

    self:RefreshFrameDataOnSelect()
end

function SemiProduceFrame:RefreshSelectRecipeData()

    if self.SelectCraftData then
        local ProduceItemID = self.SelectCraftData.ProduceItemID
        self.ItemName:SetText(self.SelectCraftData.ShowName)
        self.ItemCount:SetText(string.format("x%d", self.AmountEdit:GetCurrValue() * self.SelectCraftData.ProduceOneMakeCount ))
        self.WorkLoadText:SetText(self.SelectCraftData.WorkLoad * self.SelectCraftData.MakeCount)
        self.ItemDescText:SetText(FKBinItemTable.GetDesc(_G.GlobalContext, ProduceItemID))
        self:RefreshRecipeAttribute()

        self:RefreshConsumeItemData()
    end
end

function SemiProduceFrame:RefreshRecipeAttribute()
    -- Implementation omitted.
end

function SemiProduceFrame:RefreshConsumeItemData()
    if self.SelectCraftData then
        self.SelectCraftData.MakeCount = self.AmountEdit:GetCurrValue()
        self.ItemCount:SetText(string.format("x%d", self.AmountEdit:GetCurrValue() * self.SelectCraftData.ProduceOneMakeCount))
        self:RefreshSelectRecipeState(self.SelectCraftData.CraftID,self.SelectCraftData.MakeCount)
        self.WorkLoadText:SetText(self.SelectCraftData.WorkLoad * self.SelectCraftData.MakeCount)
        self.ConsumeItemListView:ClearListItems()
        local ConsumeItemData = BuildProduceModel:GetRecipeMaterialItemData(self.SelectCraftData.RecipeID,self.SelectCraftData.MakeCount)
        for index, value in ipairs(ConsumeItemData) do
            local uobject = DataObjectPool:Get(value)
            self.ConsumeItemListView:AddItem(uobject)
        end
    end
end

function SemiProduceFrame:OnMakeCountChanged()
    self:RefreshConsumeItemData()
    self:CheckBtnState()
end

function SemiProduceFrame:OnClickedMaxBtn()
    if not self.SelectCraftData then
        return
    end
    local MaxCount = 1
    local config = CraftConfig:GetRowByKey(self.SelectCraftData.CraftID)
	local bagModel = ModelManager:GetModel("BagModel")
	if config then
		local RecipeId = config.CraftRecipeId
		if RecipeId > 0 then
			MaxCount = bagModel:GetMaxCountBayCraftID(RecipeId)
		end
	end
    self.AmountEdit:SetCurrValue(MaxCount)
end

function SemiProduceFrame:OnStartProduceBtn()
    if self.SelectCraftData then
        if self.CurStartBtnState == BtnState.Normal then
            if self.SelectCraftData.CraftID > 0 then
                BuildInteractionSystem:SendCraftMakeReq(self.PieceGuid,BuildProduceModel:GetSmeiCreateInteractID(),self.SelectCraftData.CraftID,self.SelectCraftData.MakeCount)
            end
        elseif self.CurStartBtnState == BtnState.WorkFull then
            EventSystem.Fire("AppendNotice", EKGNoticeType.Normal,LocalizationFText.FromStr("Build.SemiProduceFame_WorkFull_TipsDesc"))
        elseif self.CurStartBtnState == BtnState.CanNotMake_Material then
            RecipeModel:AddMaterialTrackingFrame(self.SelectCraftData.RecipeID)
            RecipeModel.trackNum = self.SelectCraftData.MakeCount
        end
    end
end

function SemiProduceFrame:OnGetProductionBtn()

    if self.SelectCraftData then
        local WorkEntity = BuildProduceModel:GetQueueWorkEntityByGuid(self.PieceGuid)
        if WorkEntity then
            local QueueWorkData = WorkEntity:GetAllQueueWorkData()
            local Slots = {}
            for i = 1,QueueWorkData:Num() do
                Slots[i] = i - 1
            end
            BuildInteractionSystem:SendFetch_QueueWorkReq(self.PieceGuid,BuildProduceModel:GetSmeiGetInteractID(),Slots)
        end
    end
end

function SemiProduceFrame:OnTipsBtn()
    -- Implementation omitted.
end

function SemiProduceFrame:SendCreateCraftRsp(e,r,InteractId,Result)
    if Result == 0 and BuildProduceModel:GetSmeiCreateInteractID() == InteractId then
        self.AmountEdit:SetCurrValue(1)
    end
end

function SemiProduceFrame:CheckBtnState(Force)
    local NewState = self:GetBtnState()
    self:SetBtnState(NewState,Force)
end

function SemiProduceFrame:SetBtnState(NewState,Force)
    if self.CurStartBtnState == NewState and not Force then
        return
    end
    self.StartProduceBtn:SetIsEnabled(true)
    self.CurStartBtnState = NewState
    if self.CurStartBtnState == BtnState.Normal then
        self.StartProduceBtn:SetText(LocalizationFText.FromStr("Build.SemiProduceFame_Btn_Normal"))
    elseif self.CurStartBtnState == BtnState.WorkFull then
        self.StartProduceBtn:SetText(LocalizationFText.FromStr("Build.SemiProduceFame_Btn_WorkFull"))
        self.StartProduceBtn:SetIsEnabled(false)
    elseif self.CurStartBtnState == BtnState.CanNotMake_Material then
        local TraceText =  LocalizationFText.FromStr("材料追踪").str
        self.StartProduceBtn:SetText(TraceText)
    elseif self.CurStartBtnState == BtnState.CanNotMake_Cond then
        self.StartProduceBtn:SetIsEnabled(false)
        local Text = ""
        local BuildCheck,CheckData =  BuildProduceModel:GetCraftConditionValid(self.SelectCraftData.CraftID,self.PieceGuid)
        if CheckData.Type == ResMacros.E_CRAFT_COND_TYPE_WORKBENCH_LEVEL then
            Text = LocalizationFText.Format('<t08>需要{0}级{1}</>',CheckData.Param[0], FKBinHomelandBuildingItemTable.GetName(_G.GlobalContext,self.PieceID))
        elseif CheckData.Type == ResMacros.E_CRAFT_COND_TYPE_ACTOR_LEVEL then
            Text = LocalizationFText.Format('<t08>需要角色等级{0}级</>',CheckData.Param[0])
        elseif CheckData.Type == ResMacros.E_CRAFT_COND_TYPE_MANOR_LEVEL then
            Text = LocalizationFText.Format('<t08>需要家园核心等级{0}级</>',CheckData.Param[0])
        else
            Text = LocalizationFText.Format('<t08>未达成制造条件</>')
        end
        self.StartProduceBtn:SetText(Text)
    end
end

function SemiProduceFrame:GetBtnState()
    local WorkEntity = BuildProduceModel:GetQueueWorkEntityByGuid(self.PieceGuid)
    if not WorkEntity then
        return BtnState.Normal
    end

    local QueueWorkData = WorkEntity:GetAllQueueWorkData()
    local CurSlotCount = QueueWorkData:Num()
    local MaxSlotCount = BuildProduceModel:GetQueueWorkSlotMaxCount(self.PieceGuid)
    if CurSlotCount >= MaxSlotCount then
        return BtnState.WorkFull
    end

    if self.SelectCraftData then
        if  self.SelectCraftData.RecipeState == BuildProduceModel:GetRecipeState().CanNotMake_Material then
           return BtnState.CanNotMake_Material
        elseif  self.SelectCraftData.RecipeState == BuildProduceModel:GetRecipeState().CanNotMake_Cond then
            return BtnState.CanNotMake_Cond
        end
    end
    return BtnState.Normal
end

function SemiProduceFrame:CheckUIFirstUseExp()
    -- Implementation omitted.
end

function SemiProduceFrame:RefreshQueueWorkData()
    local WorkEntity = BuildProduceModel:GetQueueWorkEntityByGuid(self.PieceGuid)
    if not WorkEntity then
        return
    end

    local QueueWorkData = WorkEntity:GetAllQueueWorkData()

    local CurSlotCount = QueueWorkData:Num()
    local MaxSlotCount = BuildProduceModel:GetQueueWorkSlotMaxCount(self.PieceGuid)

    self.QueueNumText:SetText(string.format( "%d/%d",CurSlotCount,MaxSlotCount))

    self.QueueWorkListView:ClearListItems()
    for i = 1,QueueWorkData:Num() do
        local Data = {}
        Data.Index = i - 1
        Data.WorkData = QueueWorkData:Get(i - 1)
        Data.PieceGuid = self.PieceGuid
        local uobject = DataObjectPool:Get(Data)
        self.QueueWorkListView:AddItem(uobject)
    end

    UIUtil.SetWidgetVisible(self.GetProductionBtn, WorkEntity:HasProduceItem(),true)
    self:CheckBtnState()
end

function SemiProduceFrame:OnQueueWorkEntityWorkDataChanged(e,r,PieceGuid)
    if LuaLibrary.CheckGuidIsEqualValid(self.PieceGuid,PieceGuid) then
        self:RefreshQueueWorkData()
    end
end
return SemiProduceFrame
