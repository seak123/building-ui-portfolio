-- Selected feature implementation. External runtime and widget assets are not included.
local SemiProduceSlotEntry,super = CreateUIBehaviourFromListItem("SemiProduceSlotEntry")
local ESlateVisibility = import("ESlateVisibility")
local BuildProduceModel = ModelManager:GetModel("BuildProduceModel")
local CraftConfig = ConfigManager.GetTable("ResCarryonCraft")
local Timer = require "GameCore.GameEvent.Timer"
local QueueWorkState = UE4.EPzQueueWorkShortCtxStatus
local LuaLibrary = UE4.PzGameLuaLibrary
local TimeInterval = 0.05
local BuildInteractionSystem = UE4.PzBuildUtil.GetBuildInteractionSystem(_G.GlobalContext)

local setting =
{
    Elements =
    {
        {
            Name = "ProduceProgress",
        },
        {
            Name = "FinishOverlay",
        },
        {
            Name = "OperationOverlay",
        },
        {
            Name = "ItemName",
        },
        {
            Name = "LeftTimeText",
        },
        {
            Name = "Number"
        },
        {
            Name = "StateSwitcher",
        },
        {
            Name = "CancelBtn",
            Handles =
            {
                OnClicked = "OnCancelBtn",
            },
        },
        {
            Name = "TopBtn",
            Handles =
            {
                OnClicked = "OnTopBtn",
            },
        },
        {
            Name = "GetItemBtn",
            Handles =
            {
                OnClicked = "OnGetItemBtn",
            },
        },
    },
    Event =
    {
        ["QueueWorkEntityProduceInfoChanged"] = "OnProduceInfoChanged",
    },
    Behaviours =
    {
        {
            Name = "CommonDisplayItem",
            Alias = "CommonDisplayItemBehaviour",
        },
    },
}

function SemiProduceSlotEntry:_init(go)
    super._init(self, go, setting)
    UIUtil.SetWidgetVisible(self.TopBtn,false)
    self.Data = nil
    self.IsWoking = false
    self.UpdateEventName = "SemiProduceSlotEntry_SimulateTickEvent"..tostring(self._targetID)

    self.TotalTime = 0
    self.PassTime = 0
    self.Speed = 0
    self.IsSimulating = false

    self._target.CustomTick:Add(
        function (DeltaTime)
            if self.IsSimulating then
                self:UpdataValue(DeltaTime)
            end
        end
    )
end

function SemiProduceSlotEntry:OnDestroy()
    self._target.CustomTick:Clear()
end

function SemiProduceSlotEntry:OnDataSet(Data)

    self.Data = Data
    self.WorkStatus = Data.WorkData.Status

    self.IsWoking = self:GetIsWorking()

    local ItemID = FKBinCraftBasicTable.GetProductItemID(_G.GlobalContext, self.Data.WorkData.RecipeId)
    self.CommonDisplayItemBehaviour:SetItemTypeId(ItemID)
    self.ItemName:SetText(FKBinItemTable.GetName(_G.GlobalContext, ItemID))

    local Entity = BuildProduceModel:GetQueueWorkEntityByGuid(self.Data.PieceGuid)
    if Entity then
        self.Number:SetText(string.format( "%d/%d",Entity:GetQueueWorkFinishLeftNum(self.Data.Index),Entity:GetQueueWorkTotalNum(self.Data.Index)))
    end

    self:RefreshTimeData()

    if self.WorkStatus == QueueWorkState.Doing then
        self:StartTick()
    else
        self:EndTick()
    end
    if self.WorkStatus == QueueWorkState.Done then
        self.ProduceProgress:SetPercent(1)
    else
        self.ProduceProgress:SetPercent(self:GetPercent())
    end

    self.StateSwitcher:SetActiveWidgetIndex(self.WorkStatus)
    UIUtil.SetWidgetVisible(self.FinishOverlay,self.WorkStatus == QueueWorkState.Done)
    UIUtil.SetWidgetVisible(self.OperationOverlay,self.WorkStatus ~= QueueWorkState.Done)
end

function SemiProduceSlotEntry:RefreshTimeData()
    self.LeftTimeText:SetText(self:GetLeftTimeStr())
    self.ProduceProgress:SetPercent(self:GetPercent())
end

function SemiProduceSlotEntry:OnProduceInfoChanged(e,r,PieceGuid)
    if self.Data then
        if LuaLibrary.CheckGuidIsEqual(self.Data.PieceGuid,PieceGuid) then
            self:ResetSimulateTime()
        end
    end
end

function SemiProduceSlotEntry:OnGetItemBtn()
    if not self.Data then
        return
    end
    local Entity = BuildProduceModel:GetQueueWorkEntityByGuid(self.Data.PieceGuid)
    if not Entity then
        return
    end

    local LeftNum = Entity:GetQueueWorkFinishLeftNum(self.Data.Index)
    if LeftNum <= 0 then
        return
    end
    if self.Data then
        local Data = {}
        Data[1] = self.Data.Index
        BuildInteractionSystem:SendFetch_QueueWorkReq(self.Data.PieceGuid,BuildProduceModel:GetSmeiGetInteractID(),Data)
    end
end

function SemiProduceSlotEntry:OnCancelBtn()
    if self.Data then
        local Slot = self.Data.Index
        BuildInteractionSystem:SendCancel_QueueWorkReq(self.Data.PieceGuid,BuildProduceModel:GetSmeiCancelInteractID(),Slot)
    end
end

function SemiProduceSlotEntry:OnTopBtn()

end

function SemiProduceSlotEntry:GetLeftTimeStr()
    local TimeSecond = 0
    if self.WorkStatus == QueueWorkState.Doing then
        local Entity = BuildProduceModel:GetQueueWorkEntityByGuid(self.Data.PieceGuid)
        if Entity then
           TimeSecond = Entity:GetQueueWorkRemainTimeUnit(self.Data.Index)
        end
    else
        local Config = CraftConfig:GetRowByKey(self.Data.CraftId)
        if Config then
            TimeSecond = Config.PalWorkloadAmount.WorkloadAmount / Config.AutoworkWorkrate
        end
    end

    return BuildProduceModel:GetTimeStringBySecond(TimeSecond)
end

function SemiProduceSlotEntry:GetPercent()
    local Percent = 0
    if self.IsWoking then
        local Entity = BuildProduceModel:GetQueueWorkEntityByGuid(self.Data.PieceGuid)
        if Entity then
            local WorkData = Entity:GetQueueWorkData(self.Data.Index)
            Percent = WorkData.ProcessedWorkloadAmount / WorkData.UnitProcessWorkloadAmount
        end
    end
    return Percent
end

function SemiProduceSlotEntry:GetIsWorking()
    if self.WorkStatus then
        return self.WorkStatus == QueueWorkState.Doing or self.WorkStatus == QueueWorkState.Paused
    end
    return false
end

function SemiProduceSlotEntry:StartTick()
    if not self.Data then
        return
    end
    self:ResetSimulateTime()
    self.IsSimulating = true
end

function SemiProduceSlotEntry:EndTick()
    self.IsSimulating = false
end

function SemiProduceSlotEntry:UpdataValue(DeltaTime)
    self.PassTime = self.PassTime + DeltaTime * self.Speed
    self:RefreshSimulateTime()
end

function SemiProduceSlotEntry:ResetSimulateTime()
    local Entity = BuildProduceModel:GetQueueWorkEntityByGuid(self.Data.PieceGuid)
    if Entity then
        local WorkData = Entity:GetQueueWorkData(self.Data.Index)
        self.PassTime = WorkData.ProcessedWorkloadAmount
        self.TotalTime = WorkData.UnitProcessWorkloadAmount
        self.Speed = WorkData.WorkRate
    end
end

function SemiProduceSlotEntry:RefreshSimulateTime()
    self.LeftTimeText:SetText(self:GetLeftTimeStr())
    self.ProduceProgress:SetPercent(self.PassTime / self.TotalTime)
end

return SemiProduceSlotEntry
