-- Selected feature implementation. External runtime and widget assets are not included.
local AdditionFrame, super = CreateUIBehaviourFromListView("AdditionFrame")
local AdditionModel = ModelManager:GetModel("AdditionModel")
local InterActiveModel = ModelManager:GetModel("InteractiveModel")
local LuaLibrary = UE4.PzGameLuaLibrary

local setting = {
	Elements = {
		{
			Name = "TitleText",
		},
		{
			Name = "IconImg"
		},
		{
			Name = "UIListMaterial",
			Alias = "NativeListView"
		},
		{
			Name = "BackButton",
			Handles = {
				OnClicked = "OnHideView"
			}
		}
	},
	Behaviours = {

	},

	Events = {
		["Ineraction_Addition_HideView"] = "OnHideView",
		["BuildLeaveInteractive"] = "OnBuildInteractionLeave",

		["PZ_EVENT_MAINUI_FRAME_STATECHANGE"] = "OnHUDStateChange",
		["MainUIEntranceFrameShowEvent"] = "OnMainUIEntranceFrameShow",
	},
}

function AdditionFrame:_init(go)
	super._init(self, go, setting)
	self.ActorGuid = FGuid(0,0,0,0)
end

function AdditionFrame:OnInitialize()
	self._target:StopAnimation(self._target.OpenAni)
	self._target:PlayAnimation(self._target.OpenAni, 0, 1, UE4.EUMGSequencePlayMode.Forward, 1, false)
	InterActiveModel:SetHideReason(true, "AdditionFrame")
end

function AdditionFrame:OnDestroy()
	InterActiveModel:SetHideReason(false, "AdditionFrame")
	AdditionModel:SetFrameBehaviousNil()
	EventSystem.Fire("Ineraction_Addition_Closed")
end

function AdditionFrame:CheckValid()
    if not FrameManager:IsHUDFrameShow() then
        self:OnHideView()
    end
end

function AdditionFrame:OnHUDStateChange()
    self:CheckValid()
end

function AdditionFrame:OnMainUIEntranceFrameShow()
	self:OnHideView()
end

function AdditionFrame:ShowData(data)
	self.additionData = data
	self.ActorGuid = data.ActorGuid
	self:SetListItems(self.additionData.interactionData)
	AdditionModel:SetInteractionColdTime(self.additionData.interactionID or 0)
	self:SetTitleInfo()

	self:CheckValid()
end

function AdditionFrame:RefreshList(data)
	self.additionData = data
	self:SetListItems(self.additionData.interactionData)
	self:SetTitleInfo()
end

function AdditionFrame:SetTitleInfo()
	self.TitleText:SetText(LocalizationFText.FromStr(self.additionData.TitleName or ""))
	UIUtil.SetImagePathAsync(self.IconImg, self.additionData.TitleIcon, false)
end

function AdditionFrame:OnHideView()
	self._target:Hide()
end

function AdditionFrame:OnBuildInteractionLeave(e,r,InteractId,ActorGuid,IsLeaveBox)
	if  LuaLibrary.CheckGuidIsEqualValid(self.ActorGuid,ActorGuid) and InteractId == self.additionData.interactionID then
		self:OnHideView()
	end
end

return AdditionFrame
