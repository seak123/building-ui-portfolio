-- Selected feature implementation. External runtime and widget assets are not included.
local PalWorkBenchModel, super = ModelManager:CreateModel("PalWorkBenchModel")
local WorkBenchExport = import("WorkBenchExport")
local EquipMadeExport = import("EquipMadeExport")
local ItemMakeTable = GetTableDefine("ItemMakeTable")
local setting =
{
    Events =
    {
        ["LogicEvent_PalWorkBenchUI_SetVisible"] = "OnSetUIVisible", --打开界面或者关闭界面
        ["LogicEvent_PalWorkBenchUI_Leave"] = "OnLeaveBuildPiece", --玩家移动了位置，远离了建造物件
        ["UIEvent_CarryMake_ClosePanelOnBeHit"] = "func_ClosePanelOnBeHit", --受到攻击了，关闭打造界面
        ["UIEvent_CarryMake_PrograssInterrupt"] = "func_OnMsgProgressInterrupt", --收到了进度条中断的消息
        ["UIEvent_CarryMake_PrograssFinished"] = "func_MyMakeProgressBarEnd", --收到了进度条转圈结束的消息
        ["NetEvent_WorkBench_MakeRsp"] = "func_MyMakeReceiveNetRsp", --请求制造后，收到服务器的回复
        ["MaterialListTraceStart"] = "OnTargetCheckListChanged", --追踪目标发生了变化
        ["MaterialListTraceEnd"] = "OnTargetCheckListChanged", --追踪目标发生了变化
    },
}
local Panel_Path = "WidgetBlueprint'/Game/UI/Panel/PalWorkBench/WBP_PalWorkBench_Frame.WBP_PalWorkBench_Frame_C'"
function PalWorkBenchModel:_init()
    super._init(self, setting)
    self:MyResetData()
end
function PalWorkBenchModel:MyResetData()
    self.m_SuccessWorkType = 0
    self.m_SuccessMakeID = 0
    self.m_SuccessRecipeID = 0
    self.m_SuccessMakeRepeat = 0
    self.m_SuccessProductItemTypeID = 0
    self.m_SuccessEquipClientIDForDecompose = 0
    self.m_SuccessGainFirstUseExpNum = 0
    self.m_State_InMaking = false
    self.m_SuccessGainItemClientID = 0
    self.m_State_ReceivedSuccessMsg = false
    self.m_State_ReceivedPrograssMsg = false
    self.m_BindMakeSoundHandle = 0
end
function PalWorkBenchModel:MyShowPanel(PieceGUID)
    local _TraceLimit = WorkBenchExport.Synthesis_GetInteractiveTraceLimit(_G.GlobalContext)
    WorkBenchExport.StartCheckLeavePieceEntity(_G.GlobalContext, PieceGUID, _TraceLimit+30, "LogicEvent_PalWorkBenchUI_Leave")
    if self:IsPanelVisible() then
        self.Panel:OnMyShowPanel()
    else
        UIUtil.AddUniqueFrameAsync(Panel_Path, function(frame)
            if frame then
                local targetID = frame:GetUniqueID()
                self.Panel = __BehaviourManager:GetBehaviour(targetID)
                self.Panel.m_BindModel = self
                self.Panel:OnMyShowPanel()
            end
        end)
    end
end
function PalWorkBenchModel:MyHidePanel()
    if self.Panel ~= nil then
        self.Panel._target:Hide()
    end
end
function PalWorkBenchModel:OnHidePanel()
    WorkBenchExport.StopCheckLeavePieceEntity(_G.GlobalContext)
    EquipMadeExport.InteractivePiece_ClearPieceParam(_G.GlobalContext)
    if self.Panel ~= nil then
        self.Panel:OnMyHidePanel()
        self.Panel = nil
    end
    if self.m_State_InMaking == true then
        self:func_MyMakeInterrupt()
    end
    self:MyResetData()
end
function PalWorkBenchModel:IsPanelVisible()
    if self.Panel ~= nil then
        return true
    else
        return false
    end
end
function PalWorkBenchModel:OnSetUIVisible(e, r, IsShow, PieceGUID)
    if IsShow == true then
        self:MyShowPanel(PieceGUID)
    else
        self:MyHidePanel()
    end
end
function PalWorkBenchModel:OnLeaveBuildPiece()
    self:MyHidePanel()
end
function PalWorkBenchModel:func_MyMakeStart()
    -- Implementation omitted.
end
function PalWorkBenchModel:func_MyMakeInterrupt()
    -- Implementation omitted.
end
function PalWorkBenchModel:func_OnMsgProgressInterrupt()
    -- Implementation omitted.
end
function PalWorkBenchModel:func_MyMakeProgressBarEnd(e, r, CarryMakeId)
    -- Implementation omitted.
end
function PalWorkBenchModel:func_MyMakeReceiveNetRsp(e, r, nResultCode, nProductItemClientId, nItemRepeatCount, expValue, expValueMax)
    -- Implementation omitted.
end
function PalWorkBenchModel:func_MyMakeFinish(nResultCode, nProductItemClientId, nItemRepeatCount, expValue, expValueMax)
    -- Implementation omitted.
end
function PalWorkBenchModel:func_ClosePanelOnBeHit()
    -- Implementation omitted.
end
function PalWorkBenchModel:OnTargetCheckListChanged()
    -- Implementation omitted.
end
return PalWorkBenchModel
