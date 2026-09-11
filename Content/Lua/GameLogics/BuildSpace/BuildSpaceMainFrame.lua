-- Selected feature implementation. External runtime and widget assets are not included.
local BuildSpaceMainFrame, super = CreateUIBehaviour("BuildSpaceMainFrame")
local NewFeaturesUnlockMgr = UE4.PzGameLuaLibrary.GetNewFeaturesManager(_G.GlobalContext)
local BuildHoldFlowSystem = UE4.PzBuildUtil.GetBuildHoldFlowSystem(_G.GlobalContext)
local EBuildingSystemMode = import("EBuildingSystemMode")
local EMovementMode = import("EMovementMode")
local PzLuaLibrary = UE4.PzGameLuaLibrary
local HomelandTotemSubSystem = UE4.PzBuildUtil.GetHomelandTotemSubSystem(_G.GlobalContext)
local PzGameLuaLibrary = UE4.PzGameLuaLibrary
local setting = {
	Elements = {
		{
			Name = "JoyStick",
		},
		{
			Name = "LeaveBtn",
			Handles = {
				OnClicked = "OnClose",
			}
		},
		{
			Name = "FuncTab"
		},
		{
			Name = "FuncTypeText",
		},
		{
			Name = "FuncSwitcher"
		},
		{
			Name = "JumpBtnGroup",
		},
		{
			Name = "JumpBtn",
			Handles = {
				OnClicked = "OnJump",
			}
		},
		{
			Name = "TotemMoveSwitcher"
		},
		{
			Name = "TotemPackageBtn",
			Handles = {
				OnClicked = "OnTotemPackaged",
			}
		},
		{
			Name = "TotemMoveBtn",
			Handles = {
				OnClicked = "OnTotemMoved",
			}
		},
	},
	Events = {
		["OnSystemFunctionStatusUpdate"] = "RefreshSystemFunction",
		["BuildSpace_MainFrame_Hide"] = "OnBuildMainFrameHide",
		["BuildSpace_UnitSelectedChange"] = "OnUnitSelectedChange",
		["PZ_EVENT_ACTION_BUILD"] = "OnBuildAction",
		["PZ_EVENT_USE_PC_INTERACTION_CHANGE"] = "OnUsePCInteractionChange",
		["PZ_EVENT_FORCE_MOUSE_CONTROL_CHANGE"] = "OnForceMouseControlChange",
		["PZ_EVENT_ON_MY_PLAYER_DEAD_START"] = "OnBuildMainFrameHide",
		["PZ_SELF_PLAYER_MOVE_MODE_CHANGE"] = "OnSelfMovemodeChange",
		["PZ_EVENT_ON_MY_PLAYER_HIT_BY_MONSTER"] = "OnSelfPlayerHit",
		["PZ_EVENT_ON_MY_PLAYER_HIT"] = "OnSelfPlayerHitByAllDamageType",
		["PZ_EVENT_EXIT_BUILD_MODE"] = "OnExitBuildMode",
		["Build_TotemMove_Packaged_Suc"] = "OnPackagedSuc",
		["Build_TotemMove_Placed_Suc"] = "OnTotemMovePlacedSuc"
	},
}

local FuncTabGroupData =
{
	{

	},
	{
		RedHintType = function()
			return { string.format("SystemFunction_%d", ResMacros.E_SYS_FUNC_UNLOCK_TERRAIN_REFORM)}
		end,
		VisibleCond = function()
			return NewFeaturesUnlockMgr:IsFeatureUnlock(ResMacros.E_SYS_FUNC_UNLOCK_TERRAIN_SMOOTH) or
				NewFeaturesUnlockMgr:IsFeatureUnlock(ResMacros.E_SYS_FUNC_UNLOCK_TERRAIN_RAISE) or
				NewFeaturesUnlockMgr:IsFeatureUnlock(ResMacros.E_SYS_FUNC_UNLOCK_TERRAIN_LEVEL)
		end
	},
	{
		VisibleCond = function()
			return NewFeaturesUnlockMgr:IsFeatureUnlock(ResMacros.E_SYS_FUNC_UNLOCK_FARMING)
		end
	},
}

local FuncTypeStrFormat = LocalizationFText.FromStr("%s模式")

function BuildSpaceMainFrame:_init(go)
	super._init(self, go, setting)
	self.buildSpaceModel = ModelManager:GetModel("BuildSpaceModel")
end

function BuildSpaceMainFrame:OnInitialize()
	self._target:SetIsNeedGCWhenHide(true)
	self:SetTotemMoveBtnsState()
	FrameManager:SetModeHUDFrameUniqueId("BuildSystem", self._targetID)

	self:UpdateJumpBtnGroupState()

	self:UpdateJoyStickState()

	self:UpdateFuncTabState()

	local MainUIMgr = UE4.PzMainUILibrary.GetMainUIManager(_G.GlobalContext)
    MainUIMgr:SetIsLockMaxSpeed(false)
	TabUtil.SetTabGroupData(self.FuncTab, FuncTabGroupData)
	self.FuncTab.OnSelectTabChange:Add(
		function(index)
			self:OnFuncTabChange(index)

			local NameStr = self.FuncTab:GetTabShowText(index)
			local FuncTypeStr = string.format(FuncTypeStrFormat.str, NameStr)
			self.FuncTypeText:SetText(FuncTypeStr)
		end)
	if self.buildSpaceModel.defaultFuncId == ResMacros.HOMELAND_CATALOG_MODULE_TYPE_BUILD then
		self.FuncTab:SetSelectTabIndex(1)
	elseif self.buildSpaceModel.defaultFuncId == ResMacros.HOMELAND_CATALOG_MODULE_TYPE_PLANT then
		self.FuncTab:SetSelectTabIndex(3)
	elseif self.buildSpaceModel.defaultFuncId == ResMacros.HOMELAND_CATALOG_MODULE_TYPE_TM then
		self.FuncTab:SetSelectTabIndex(2)
	else
		self.FuncTab:SetSelectTabIndex(1)
	end
	self.buildSpaceModel.defaultFuncId = nil
	PzGameLuaLibrary.BuildUnLockTarget(_G.GlobalContext)
	if self.buildSpaceModel.waitInTotemMove then
		self.buildSpaceModel:HoldPackagedHouse()
	end
end

function BuildSpaceMainFrame:OnDestroy()
	FrameManager:SetModeHUDFrameUniqueId("BuildSystem", 0)

	self.FuncTab.OnSelectTabChange:Clear()
	BuildHoldFlowSystem:ChangeSystemMode(EBuildingSystemMode.None)
end

function BuildSpaceMainFrame:OnClose()
	self._target:Hide()
end

function BuildSpaceMainFrame:OnFuncTabChange(id)
    -- Implementation omitted.
end

function BuildSpaceMainFrame:RefreshSystemFunction(_, _, id)
    -- Implementation omitted.
end

function BuildSpaceMainFrame:OnBuildMainFrameHide()
	self:OnClose()
end

function BuildSpaceMainFrame:OnJump()
    -- Implementation omitted.
end

function BuildSpaceMainFrame:UpdateJumpBtnGroupState()
	local bUsePCInteraction = UE4.PzPCInteractionLibrary.IsUsePCInteraction(_G.GlobalContext)
	local bVis = not bUsePCInteraction
	UIUtil.SetWidgetVisible(self.JumpBtnGroup, bVis)
end

function BuildSpaceMainFrame:UpdateJoyStickState()
	local bUsePCInteraction = UE4.PzPCInteractionLibrary.IsUsePCInteraction(_G.GlobalContext)
	local bVis = not bUsePCInteraction
	UIUtil.SetWidgetVisible(self.JoyStick, bVis)
end

function BuildSpaceMainFrame:UpdateFuncTabState()
	local bVis = true
	while true do
		local bUsePCInteraction = UE4.PzPCInteractionLibrary.IsUsePCInteraction(_G.GlobalContext)
		if not bUsePCInteraction then
			break
		end

		local curSelectedUnitId = self.buildSpaceModel.curSelectedUnitId
		if curSelectedUnitId then
			bVis = false
			break
		end

		local bInForceMouseControl = UE4.PzPCInteractionLibrary.IsInForceMouseControlReason(_G.GlobalContext, "BuildEmptyHand")
									 or UE4.PzPCInteractionLibrary.IsInForceMouseControlReason(_G.GlobalContext, "BuildHold")
		if bInForceMouseControl then
			bVis = false
			break
		end

		break
	end

	UIUtil.SetWidgetVisible(self.FuncTab, bVis)
end

function BuildSpaceMainFrame:OnUsePCInteractionChange()
	self:UpdateJumpBtnGroupState()

	self:UpdateJoyStickState()

	self:UpdateFuncTabState()
end

function BuildSpaceMainFrame:OnForceMouseControlChange()
	self:UpdateFuncTabState()
end

function BuildSpaceMainFrame:OnUnitSelectedChange()
	self:UpdateFuncTabState()
end

function BuildSpaceMainFrame:OnBuildAction()
	local bUsePCInteraction = UE4.PzPCInteractionLibrary.IsUsePCInteraction(_G.GlobalContext)
	local bActionValid = bUsePCInteraction
	if bActionValid then
		if self._target:IsShow() then
			local Id = FrameManager:GetAutoHideFrameUniqueIdWithKey()
            if self._targetID == Id then
                self:OnClose()
            end
		end
	end
end

function BuildSpaceMainFrame:OnSelfMovemodeChange(_, _, mode)
	if mode == EMovementMode.MOVE_Swimming then
		self:OnClose()
	end
end

function BuildSpaceMainFrame:OnSelfPlayerHit()
	self:OnClose()
end

function BuildSpaceMainFrame:OnSelfPlayerHitByAllDamageType(_,_)
	local bIsFreeCamera = UE4.PzCameraFunctionLibrary.IsInFreeCameraState(_G.GlobalContext)
	if bIsFreeCamera then
		self:OnClose()
	end
end

function BuildSpaceMainFrame:OnExitBuildMode()
	self:OnClose()
end

function BuildSpaceMainFrame:SetTotemMoveBtnsState()
    -- Implementation omitted.
end

function BuildSpaceMainFrame:OnTotemMoveSuc()
    -- Implementation omitted.
end

function BuildSpaceMainFrame:OnTotemPackaged()
    -- Implementation omitted.
end

function BuildSpaceMainFrame:OnTotemMoved()
    -- Implementation omitted.
end

function BuildSpaceMainFrame:OnPackagedSuc()
    -- Implementation omitted.
end

function BuildSpaceMainFrame:OnTotemMovePlacedSuc()
    -- Implementation omitted.
end

return BuildSpaceMainFrame
