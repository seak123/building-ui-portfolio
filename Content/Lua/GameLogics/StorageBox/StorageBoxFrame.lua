-- Selected feature implementation. External runtime and widget assets are not included.
local StorageBoxFrame, super = CreateUIBehaviour("StorageBoxFrame")
local PzLogicLibrary = UE4.PzLogicLibrary
local Timer = require "GameCore.GameEvent.Timer"
local setting = {
	Elements = {
		{
			Name = "Root"
		},
		{
			Name = "CloseBtn",
			Handles = {
				OnClicked = "OnCloseView",
			}
		},
	},
	Events = {
		["StorageFrameCloseEvent"] = "OnCloseView",
	},
	Behaviours = {
		{
			Name = "WBP_Storage_Box",
			Alias = "BoxBehavious"
		},
		{
			Name = "WBP_Storage_Food",
			Alias = "FoodBehavious"
		},
		{
			Name = "WBP_Storage_Bag",
			Alias = "BagBehavious"
		},
		{
			Name = "WBP_Storage_Equip",
			Alias = "EquipBehavious"
		},
		{
			Name = "WBP_Storage_Shortcut",
			Alias = "ShortBarBehavious"
		}
	},
	Timers = {
		{
			Name = "Storage_CheckDis",
			Timer = Timer:Always(0.2),
			Handler = "OnCheckPlayerDistance"
		}
	}

}

function StorageBoxFrame:_init(go)
	super._init(self, go, setting)
	self.boxModel = ModelManager:GetModel("BoxModel")
end

function StorageBoxFrame:OnInitialize()
	self._target:SetIsNeedGCWhenHide(true)

	local MainUIMgr = UE4.PzMainUILibrary.GetMainUIManager(_G.GlobalContext)
    MainUIMgr:SetIsLockMaxSpeed(false)

    UE4.PzQuestInstanceLibrary.QuestMaterialTrack_SetWorkReason(_G.GlobalContext, "StorageBoxFrame", true)
end

function StorageBoxFrame:OnDestroy()
	self.boxModel:SetBoxInteractiveState(false)

	UE4.PzQuestInstanceLibrary.QuestMaterialTrack_SetWorkReason(_G.GlobalContext, "StorageBoxFrame", false)
end

function StorageBoxFrame:OnCloseView()
	self._target:Hide()
end

function StorageBoxFrame:OnCheckPlayerDistance()
	local inArea = self.boxModel:CheckPlayerDistance()
	if not inArea then
		self:OnCloseView()
	end
end

return StorageBoxFrame
