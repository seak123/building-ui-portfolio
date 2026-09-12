-- Selected feature implementation. External runtime and widget assets are not included.
local WorkBenchModel, super = ModelManager:CreateModel("WorkBenchModel")
local WorkBenchExport = import("WorkBenchExport")
local EquipMadeExport = import("EquipMadeExport")
local ItemMakeTable = GetTableDefine("ItemMakeTable")
local WorkBenchTable = GetTableDefine("WorkBenchTable")
local GameLuaLibrary = UE4.PzGameLuaLibrary
local TimerModel = require "GameCore.GameEvent.Timer"
local setting =
{
    Events =
    {
        ["LogicEvent_WorkBenchUI_SetVisible"] = "OnSetUIVisible", --打开界面或者关闭界面
        ["LogicEvent_WorkBenchUI_ShowUIByMainMenu"] = "ShowUIByMainMenu", --从系统主菜单中打开界面
        ["LogicEvent_WorkBenchUI_Leave"] = "OnLeaveWorkBench", --玩家移动了位置，远离了工作台
        ["LogicEvent_WorkBenchUI_CancelMake"] = "OnCancelMake", --玩家请求取消制造。装备台，工艺台都会抛出这个事件
        ["LogicEvent_WorkBenchUI_FetchProduct"] = "OnFetchProduct", --玩家请求领取产物后收到回复。装备台，工艺台都会抛出这个事件
        ["UIEvent_CarryMake_ClosePanelOnBeHit"] = "func_ClosePanelOnBeHit", --受到攻击了，关闭打造界面
        ["UIEvent_Character_FightStateChanged"] = "func_OnFightStateChanged", --玩家的战斗状态发生变化，如果是进入战斗状态，就关闭界面
        ["UIEvent_CarryMake_PrograssInterrupt"] = "func_OnMsgProgressInterrupt", --收到了进度条中断的消息
        ["UIEvent_CarryMake_PrograssFinished"] = "func_MyMakeProgressBarEnd", --收到了进度条转圈结束的消息
        ["NetEvent_WorkBench_MakeRsp"] = "func_MyMakeReceiveNetRsp", --请求制造后，收到服务器的回复
        ["MaterialListTraceStart"] = "OnTargetCheckListChanged", --追踪目标发生了变化
        ["MaterialListTraceEnd"] = "OnTargetCheckListChanged", --追踪目标发生了变化
        ["NetEvent_EquipEnhanceRsp"] = "OnEquipEnhanceRsp", --请求强化后，收到服务器回复
        ["NetEvent_EquipRepairRsp"] = "OnEquipRepairRsp", --请求修理后，收到服务器回复
        ["PZ_ON_CULTURE_CHANGED"] = "OnCultureChange", --多语言发生变更
    },
}
local Panel_Path = "WidgetBlueprint'/Game/UI/Panel/WorkShop/WBP_WorkShop_Frame.WBP_WorkShop_Frame_C'"
local BuildLvGuidePanelPath = "WidgetBlueprint'/Game/UI/Panel/WorkShop/WBP_WorkShop_Window.WBP_WorkShop_Window_C'"
function WorkBenchModel:_init()
    super._init(self, setting)
    self.ShowBtnRedStep_Make = 0
    self.ShowBtnRedStep_Enhance = 0
    self.IsItemMakeWithPal = false
    self:MyResetData()
end
function WorkBenchModel:OnCultureChange()
    -- Implementation omitted.
end
function WorkBenchModel:MyResetData()
    self.m_BenchOpenType = ItemMakeTable.BenchOpenType_PieceObj
    self.m_WorkBenchLevel = 1
    self.m_BindSoundHandle = 0
    self.m_BindMakeSoundHandle = 0
    self.m_BenchWorkType = ItemMakeTable.BenchWorkType_Make
    self.m_TabCategory = 1
    self.m_BenchMakeId = 0
    self.m_ProductItemTypeId = 0
    self.m_EquipClientIDForMaterial = 0
    self.m_IsShowConfirmMsgBox = false
    self.m_SuccessCarryMakeId = 0
    self.m_SuccessMakeRepeat = 0
    self.m_SuccessEquipClientIDForMaterial = 0
    self.m_SuccessItemClientId = 0
    self.m_SuccessItemTypeId = 0
    self.m_SuccessGainFirstUseExpNum = 0
    self.m_State_MaterialEnough = false
    self.m_State_ArriveTakeLimit = false
    self.m_State_ConditionEnough = false
    self.m_State_InMaking = false
    self.m_State_ReceivedSuccessMsg = false
    self.m_State_ReceivedPrograssMsg = false
    self.m_CurEquipItemClientID = 0
    self.m_EnhanceChangeData = nil
    self.CurrMarkIdAllUse = 0
end
function WorkBenchModel:GetMakeDataByMakeID(makeID)
    -- Implementation omitted.
end
function WorkBenchModel:GetItemsEnhanceData(clientData)
    -- Implementation omitted.
end
function WorkBenchModel:GetItemsRepairData(clientData)
    -- Implementation omitted.
end
function WorkBenchModel:MyShowPanel(WorkBenchGUID, PieceOpType)
    local PieceGUIDString = UE4.PzLogicLibrary.GetFGUIDToString(_G.GlobalContext, WorkBenchGUID)
    local _TraceLimit = WorkBenchExport.WorkBench_GetInteractiveTraceLimit(_G.GlobalContext)
    WorkBenchExport.StartCheckLeavePieceEntity(_G.GlobalContext, WorkBenchGUID, _TraceLimit+30, "LogicEvent_WorkBenchUI_Leave")
    WorkBenchTable.StartWorkBenchPanel(PieceOpType)
    local TargetPanelPath = ""
    if PieceOpType == ResMacros.BUILDING_OP_TYPE_EQUIP_TABLE_2 then
        TargetPanelPath = Panel_Path
    elseif PieceOpType == ResMacros.BUILDING_OP_TYPE_EQUIP_TABLE_3 then
        TargetPanelPath = Panel_Path
    else
        TargetPanelPath = Panel_Path
    end
    UIUtil.AddUniqueFrameAsync(TargetPanelPath, function(frame)
            if frame then
                local targetID = frame:GetUniqueID()
                self.Panel = __BehaviourManager:GetBehaviour(targetID)
                self.Panel.m_BindModel = self
                self.Panel:OnMyShowPanel()
            end
        end)
end
function WorkBenchModel:MyHidePanel()
    if self.Panel ~= nil then
        self.Panel._target:Hide()
    end
end
function WorkBenchModel:OnHidePanel()
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
function WorkBenchModel:IsPanelVisible()
    if self.Panel ~= nil then
        return true
    else
        return false
    end
end
function WorkBenchModel:OnSetUIVisible(e, r, bFlag, WorkBenchGUID, PieceOpType)
	if bFlag == true then
        self.m_BenchOpenType = ItemMakeTable.BenchOpenType_PieceObj
		self:MyShowPanel(WorkBenchGUID, PieceOpType)
	else
		self:MyHidePanel()
	end
end
function WorkBenchModel:ShowUIByMainMenu(e, r)
    -- Implementation omitted.
end
function WorkBenchModel:GetCurWorkBenchGuid()
	return EquipMadeExport.InteractivePiece_GetPieceGUID(_G.GlobalContext)
end
function WorkBenchModel:OnLeaveWorkBench()
    if self.Panel ~= nil then
        self:MyHidePanel()
    end
end
function WorkBenchModel:OnCancelMake(e, r, PieceGUID, PieceOpType)
    -- Implementation omitted.
end
function WorkBenchModel:OnFetchProduct(e, r, nResultCode, PieceTypeID, ProductItemClientID, MakeID, MakeRepeat, IsRecipeFirstUsed)
    -- Implementation omitted.
end
function WorkBenchModel:OnMakeClicked()
    -- Implementation omitted.
end
function WorkBenchModel:func_MyMakeStart()
    -- Implementation omitted.
end
function WorkBenchModel:func_MyMakeInterrupt()
    -- Implementation omitted.
end
function WorkBenchModel:func_OnMsgProgressInterrupt()
    -- Implementation omitted.
end
function WorkBenchModel:func_MyMakeProgressBarEnd(e, r, CarryMakeId)
    -- Implementation omitted.
end
function WorkBenchModel:func_MyMakeReceiveNetRsp(e, r, nResultCode, nProductItemClientId, nItemRepeatCount, expValue, expValueMax)
    -- Implementation omitted.
end
function WorkBenchModel:func_MyMakeFinish(nItemRepeatCount, expValue, expValueMax)
    -- Implementation omitted.
end
function WorkBenchModel:func_ClosePanelOnBeHit()
    -- Implementation omitted.
end
function WorkBenchModel:func_OnFightStateChanged(e, r, IsInFightState)
    -- Implementation omitted.
end
function WorkBenchModel:OnTargetCheckListChanged()
    -- Implementation omitted.
end
function WorkBenchModel:OnEquipEnhanceRsp(e, r, nResultCode, nItemClientId)
    -- Implementation omitted.
end
function WorkBenchModel:OnEquipRepairRsp(e, r, nResultCode, nItemClientId)
    -- Implementation omitted.
end
function WorkBenchModel:GetBuilLvupGuideData(buildGuid, lv)
    -- Implementation omitted.
end
function WorkBenchModel:GetBuildLvupGuideRecipeIds(buildGuid, lv)
    -- Implementation omitted.
end
function WorkBenchModel:ShowBuildLvupGuidePanel(buildGuid, lv, type)
    -- Implementation omitted.
end
function WorkBenchModel:SetCurrMakeID(id)
    -- Implementation omitted.
end
function WorkBenchModel:GetCurrMakeID()
    -- Implementation omitted.
end
return WorkBenchModel
