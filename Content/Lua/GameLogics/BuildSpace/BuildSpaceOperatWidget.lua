-- Selected feature implementation. External runtime and widget assets are not included.
local BuildSpaceOperatWidget, super = CreateUIBehaviour("BuildSpaceOperatWidget")
local BuildHoldFlowSystem = UE4.PzBuildUtil.GetBuildHoldFlowSystem(_G.GlobalContext)
local BuildSpaceOpBitState = import("EBUILD_OP_MASK")
local BuildMiscConfig = ConfigManager.GetTable("ResHomelandMiscValueConfig")
local PzLogicLibrary = UE4.PzLogicLibrary
local HomelandTotemSubSystem = UE4.PzBuildUtil.GetHomelandTotemSubSystem(_G.GlobalContext)
local setting = {
	Elements = {
		{
			Name = "CancelBtn",
			Handles = {
				OnClicked = "OnCancelBtn"
			}
		},
		{
			Name = "AntiRotateBtn",
			Handles = {
				OnPressed = "OnAntiRotatePress",
				OnReleased = "OnAntiRotateRelease"
			}
		},
		{
			Name = "RotateBtn",
			Handles = {
				OnPressed = "OnRotatePress",
				OnReleased = "OnRotateRelease"
			}
		},
		{
			Name = "UnValidBuildBtn",
			Handles = {
				OnClicked = "OnBuildBtn"
			}
		},
		{
			Name = "BuildBtn",
			Handles = {
				OnClicked = "OnBuildBtn"
			}
		},
		{
			Name = "RepairBtn",
			Handles = {
				OnClicked = "OnRepair"
			}
		},
		{
			Name = "MoveBtn",
			Handles = {
				OnClicked = "OnMovePiece"
			}
		},
		{
			Name = "DeleteBtn",
			Handles = {
				OnClicked = "OnDeleteBtn"
			}
		},
		{
			Name = "UpCameraBtn",
			Handles = {
				OnPressed = "OnPressUpCameraBtn",
				OnReleased = "OnReleaseUpCameraBtn"
			}
		},
		{
			Name = "DownCameraBtn",
			Handles = {
				OnPressed = "OnPressDownCameraBtn",
				OnReleased = "OnReleaseDownCameraBtn"
			}
		},
		{
			Name = "OpGroup",
		},
		{
			Name = "CameraMoveGroup",
		},
		{
			Name = "HpPart"
		},
		{
			Name = "HpBar"
		},
		{
			Name = "UnitEarthgrabGroup"
		},
		{
			Name = "EarthgrabUpSwitcher"
		},
		{
			Name = "EarthgrabDownSwitcher"
		},
		{
			Name = "Earthgrab_up_enable",
			Handles = {
				OnPressed = "OnPressEarthgrabUp",
				OnReleased = "OnReleaseEarthgrabUp"
			}
		},
		{
			Name = "Earthgrab_down_enable",
			Handles = {
				OnPressed = "OnPressEarthgrabDown",
				OnReleased = "OnReleaseEarthgrabDown"
			}
		},
		{
			Name = "Earthgrab_up_disable",
			Handles = {
				OnClicked = "OnDisEarthgrabUp",
			}
		},
		{
			Name = "Earthgrab_down_disable",
			Handles = {
				OnClicked = "OnDisEarthgrabDown",
			}
		},
		{
			Name = "CoatBtn",
			Handles = {
				OnClicked = "OnUnitCoat",
			}
		},
		{
			Name = "UnValidCoatBtn",
			Handles = {
				OnClicked = "OnUnValidCoat",
			}
		},
		{
			Name = "TearCoatBtn",
			Handles = {
				OnClicked = "OnTearCoat",
			}
		},
		{
			Name = "Coat",
		},
		{
			Name = "UnValidCoat",
		},
		{
			Name = "TearCoat",
		},
		{
			Name = "HouseOffsetGroup",
		},
		{
			Name = "HouseOffsetUp",
			Handles = {
				OnPressed = "OnPressHouseOffsetUp",
				OnReleased = "OnReleaseHouseOffsetUp"
			}
		},
		{
			Name = "HouseOffsetDown",
			Handles = {
				OnPressed = "OnPressHouseOffsetDown",
				OnReleased = "OnReleaseHouseOffsetDown"
			}
		},
	},
	Events = {
		["PZ_EVENT_CAMERA_STATE_CHANGE"] = "OnBuildCameraStateChange",
		["BuildSpace_OpBitMask_Change"] = "OnBuildSpaceBitMaskChange",

		["PZ_EVENT_USE_PC_INTERACTION_CHANGE"] = "OnUsePCInteractionChange",
		["PZ_EVENT_ACTION_BUILD_ROTATE"] = "OnBuildActionRotate",
		["PZ_EVENT_ACTION_BUILD_ANTIROTATE"] = "OnBuildActionAntiRotate",
		["PZ_EVENT_ACTION_BUILD_CONFIRM"] = "OnBuildActionConfirm",
		["PZ_EVENT_ACTION_BUILD_CANCEL"] = "OnBuildActionCancel",
		["PZ_EVENT_ACTION_BUILD_DELETE"] = "OnBuildActionDelete",
		["PZ_EVENT_ACTION_BUILD_MOVE"] = "OnBuildActionMove",
		["PZ_EVENT_ACTION_BUILD_REPAIR"] = "OnBuildActionRepair",
		["PZ_EVENT_ACTION_BUILD_EARTHGRAB_UP"] = "OnBuildActionEarthgrabUp",
		["PZ_EVENT_ACTION_BUILD_EARTHGRAB_DOWN"] = "OnBuildActionEarthgrabDown",
		["PZ_EVENT_ACTION_BUILD_CLEAR_COAT"] = "OnBuildActionClearCoat",
	},
}

function BuildSpaceOperatWidget:_init(go)
	super._init(self, go, setting)
	self.buildSpaceModel = ModelManager:GetModel("BuildSpaceModel")
end

function BuildSpaceOperatWidget:OnInitialize()
	self:RefreshOperateState()
	self:SetCameraState()
	self:UpdateOpGroupState()
	self:UpdateEarthgrabGroupState()
	self:UpdateHouseOffsetGroupState()
end

function BuildSpaceOperatWidget:OnDestroy()

end

function BuildSpaceOperatWidget:OnCancelBtn()
	self.buildSpaceModel:CancelHold()
end

function BuildSpaceOperatWidget:OnAntiRotatePress()
	BuildHoldFlowSystem:RotateUnit(true, false)
end
function BuildSpaceOperatWidget:OnAntiRotateRelease()
	BuildHoldFlowSystem:RotateUnit(false, false)
end

function BuildSpaceOperatWidget:OnRotatePress()
	BuildHoldFlowSystem:RotateUnit(true, true)
end

function BuildSpaceOperatWidget:OnRotateRelease()
	BuildHoldFlowSystem:RotateUnit(false, true)
end

function BuildSpaceOperatWidget:OnBuildBtn()
	if self.buildSpaceModel:CheckHoldTotem() then
		if HomelandTotemSubSystem:C_IsTotemPackaged(_G.GlobalContext) then
			EventSystem.Fire("AppendNotice", EKGNoticeType.Normal, UE4.PzLogicLibrary.GetUIString("Build", "Build_Notice_143"))
			return
		end
		if HomelandTotemSubSystem:C_GetSelfTotemLv(_G.GlobalContext) >= 1 then
			local TotemDelConfig = BuildMiscConfig:GetRowByKey(ResMacros.E_HOMELAND_KVT_TOTEM_DEL_CD)
			local TimeFormat = {
				["{Time}"] = PzLogicLibrary.GetTimeStr(TotemDelConfig.Value)
			}
			local MessageBoxParam = {
				ConfirmLambda = function()
					BuildHoldFlowSystem:PlaceUnit()
				end,
				DescText = PzLogicLibrary.FormatUIString("Build", "Build_Notice_106", TimeFormat),
				IsBGClickedAutoHide = true
			}
			EventSystem.Fire("UIEvent_MessageBox_Show", MessageBoxParam)
			return
		end
	end
	local checkQustBuildInTotem = BuildHoldFlowSystem:CheckConfirmQuestBuildInTotem()
	if checkQustBuildInTotem > 0 then
		local NameFormat = {
			["{Name}"] = self.buildSpaceModel:GetBuildNameByID(checkQustBuildInTotem)
		}
		local MessageBoxParam = {
			ConfirmLambda = function()
				BuildHoldFlowSystem:PlaceUnit()
			end,
			DescText = PzLogicLibrary.FormatUIString("Build", "Build_Notice_153", NameFormat),
			IsBGClickedAutoHide = true
		}
		EventSystem.Fire("UIEvent_MessageBox_Show", MessageBoxParam)
		return
	end
	BuildHoldFlowSystem:PlaceUnit()
end

function BuildSpaceOperatWidget:OnRepair()
	BuildHoldFlowSystem:RepairUnit()
end

function BuildSpaceOperatWidget:OnMovePiece()
	BuildHoldFlowSystem:MoveSelectedEntity()
end

function BuildSpaceOperatWidget:OnDeleteBtn()
	self.buildSpaceModel:CheckDelUnit()
end

function BuildSpaceOperatWidget:OnPressUpCameraBtn()
    -- Implementation omitted.
end
function BuildSpaceOperatWidget:OnReleaseUpCameraBtn()
    -- Implementation omitted.
end
function BuildSpaceOperatWidget:OnPressDownCameraBtn()
    -- Implementation omitted.
end
function BuildSpaceOperatWidget:OnReleaseDownCameraBtn()
    -- Implementation omitted.
end

function BuildSpaceOperatWidget:OnPressEarthgrabUp()
    -- Implementation omitted.
end

function BuildSpaceOperatWidget:OnReleaseEarthgrabUp()
    -- Implementation omitted.
end

function BuildSpaceOperatWidget:OnPressEarthgrabDown()
    -- Implementation omitted.
end

function BuildSpaceOperatWidget:OnReleaseEarthgrabDown()
    -- Implementation omitted.
end

function BuildSpaceOperatWidget:OnDisEarthgrabUp()
    -- Implementation omitted.
end

function BuildSpaceOperatWidget:OnDisEarthgrabDown()
    -- Implementation omitted.
end

function BuildSpaceOperatWidget:UpdateEarthgrabGroupState()
    -- Implementation omitted.
end

function BuildSpaceOperatWidget:SetCameraState()
    -- Implementation omitted.
end

function BuildSpaceOperatWidget:UpdateOpGroupState()
	local bVis = false
	while true do
		local bUsePCInteraction = UE4.PzPCInteractionLibrary.IsUsePCInteraction(_G.GlobalContext)
		if bUsePCInteraction then
			break
		end

		bVis = true
		break
	end

	UIUtil.SetWidgetVisible(self.OpGroup, bVis)
end

function BuildSpaceOperatWidget:RefreshOperateState()
	UIUtil.SetWidgetVisible(self.CancelBtn, self:CheckOpBitMask(BuildSpaceOpBitState.CANCEL))
	UIUtil.SetWidgetVisible(self.AntiRotateBtn, self:CheckOpBitMask(BuildSpaceOpBitState.REVERSE_ROT))
	UIUtil.SetWidgetVisible(self.RotateBtn, self:CheckOpBitMask(BuildSpaceOpBitState.ROT))
	UIUtil.SetWidgetVisible(self.BuildBtn, self:CheckOpBitMask(BuildSpaceOpBitState.CAN_BUILD))
	UIUtil.SetWidgetVisible(self.UnValidBuildBtn, self:CheckOpBitMask(BuildSpaceOpBitState.CANT_BUILD))
	UIUtil.SetWidgetVisible(self.MoveBtn, self:CheckOpBitMask(BuildSpaceOpBitState.MOVE))
	UIUtil.SetWidgetVisible(self.DeleteBtn, self:CheckOpBitMask(BuildSpaceOpBitState.DEL))
	UIUtil.SetWidgetVisible(self.Coat, self:CheckOpBitMask(BuildSpaceOpBitState.CAN_COAT))
	UIUtil.SetWidgetVisible(self.UnValidCoat, self:CheckOpBitMask(BuildSpaceOpBitState.CANT_COAT))
	UIUtil.SetWidgetVisible(self.TearCoat, self:CheckOpBitMask(BuildSpaceOpBitState.TEAR_COAT))
	local needRepair = self:CheckOpBitMask(BuildSpaceOpBitState.REPAIR)
	UIUtil.SetWidgetVisible(self.RepairBtn, needRepair)
	UIUtil.SetWidgetVisible(self.HpPart, needRepair)
	local HpChange = self:CheckOpBitMask(BuildSpaceOpBitState.HP_CHANGE)
	if HpChange then
		self:OnCurSelectedUnitHpChange()
	end

	self:UpdateEarthgrabGroupState()
	self:UpdateHouseOffsetGroupState()
end

function BuildSpaceOperatWidget:CheckOpBitMask(opType)
	return self.buildSpaceModel:CheckOpBitMask(opType)
end

function BuildSpaceOperatWidget:OnBuildCameraStateChange(_, _, isSpeMode)
    -- Implementation omitted.
end

function BuildSpaceOperatWidget:OnBuildSpaceBitMaskChange(_, _, bitMask)
	self:RefreshOperateState()
end

function BuildSpaceOperatWidget:OnCurSelectedUnitHpChange()
	local hpPercent = BuildHoldFlowSystem:GetCurSelectedUnitHpPercent()
	self.HpBar:SetPercent(hpPercent)
end

function BuildSpaceOperatWidget:OnUnitCoat()
    -- Implementation omitted.
end

function BuildSpaceOperatWidget:OnUnValidCoat()
    -- Implementation omitted.
end

function BuildSpaceOperatWidget:OnTearCoat()
    -- Implementation omitted.
end

function BuildSpaceOperatWidget:OnPressHouseOffsetUp()
    -- Implementation omitted.
end

function BuildSpaceOperatWidget:OnReleaseHouseOffsetUp()
    -- Implementation omitted.
end

function BuildSpaceOperatWidget:OnPressHouseOffsetDown()
    -- Implementation omitted.
end

function BuildSpaceOperatWidget:OnReleaseHouseOffsetDown()
    -- Implementation omitted.
end

function BuildSpaceOperatWidget:UpdateHouseOffsetGroupState()
    -- Implementation omitted.
end

function BuildSpaceOperatWidget:OnUsePCInteractionChange()
	self:SetCameraState()
	self:UpdateOpGroupState()
	self:UpdateEarthgrabGroupState()
	self:UpdateHouseOffsetGroupState()
end

function BuildSpaceOperatWidget:CheckBuildActionValid()
	local bActionValid = false
	while true do
		local bUsePCInteraction = UE4.PzPCInteractionLibrary.IsUsePCInteraction(_G.GlobalContext)
		if not bUsePCInteraction then
			break
		end

		local bInBuildHUDState = FrameManager:IsInModeHUDState("BuildSystem")
		if not bInBuildHUDState then
			break
		end

		local CurSystemMode = BuildHoldFlowSystem:GetCurSystemMode()
		local bModeValid = CurSystemMode == UE4.EBuildingSystemMode.BuildMode or CurSystemMode == UE4.EBuildingSystemMode.FarmMode
		if not bModeValid then
			break
		end

		bActionValid = true
		break
	end

	return bActionValid
end

function BuildSpaceOperatWidget:OnBuildActionRotate()
	if self:CheckBuildActionValid() then
		if self:CheckOpBitMask(BuildSpaceOpBitState.ROT) then
			BuildHoldFlowSystem:RotateUnitOnce(true)
		end
	end
end

function BuildSpaceOperatWidget:OnBuildActionAntiRotate()
	if self:CheckBuildActionValid() then
		if self:CheckOpBitMask(BuildSpaceOpBitState.REVERSE_ROT) then
			BuildHoldFlowSystem:RotateUnitOnce(false)
		end
	end
end

function BuildSpaceOperatWidget:OnBuildActionConfirm()
	if self:CheckBuildActionValid() then
		if self:CheckOpBitMask(BuildSpaceOpBitState.CAN_BUILD) or self:CheckOpBitMask(BuildSpaceOpBitState.CANT_BUILD) then
			self:OnBuildBtn()
		elseif self:CheckOpBitMask(BuildSpaceOpBitState.CAN_COAT) then
			self:OnUnitCoat()
		elseif self:CheckOpBitMask(BuildSpaceOpBitState.CANT_COAT) then
			self:OnUnValidCoat()
		end
	end
end

function BuildSpaceOperatWidget:OnBuildActionCancel()
	if self:CheckBuildActionValid() then
		self:OnCancelBtn()
	end
end

function BuildSpaceOperatWidget:OnBuildActionDelete()
	if self:CheckBuildActionValid() then
		if self:CheckOpBitMask(BuildSpaceOpBitState.DEL) then
			self:OnDeleteBtn()
		end
	end
end

function BuildSpaceOperatWidget:OnBuildActionMove()
	if self:CheckBuildActionValid() then
		if self:CheckOpBitMask(BuildSpaceOpBitState.MOVE) then
			self:OnMovePiece()
		end
	end
end

function BuildSpaceOperatWidget:OnBuildActionRepair()
	if self:CheckBuildActionValid() then
		if self:CheckOpBitMask(BuildSpaceOpBitState.REPAIR) then
			self:OnRepair()
		end
	end
end

function BuildSpaceOperatWidget:OnBuildActionEarthgrabUp()
    -- Implementation omitted.
end

function BuildSpaceOperatWidget:OnBuildActionEarthgrabDown()
    -- Implementation omitted.
end

function BuildSpaceOperatWidget:OnBuildActionClearCoat()
    -- Implementation omitted.
end

return BuildSpaceOperatWidget
