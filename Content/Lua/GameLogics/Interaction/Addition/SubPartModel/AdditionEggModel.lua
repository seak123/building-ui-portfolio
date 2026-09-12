-- Selected feature implementation. External runtime and widget assets are not included.
local AdditionEggModel, super = ModelManager:CreateModel("AdditionEggModel")
local AdditionModel = ModelManager:GetModel("AdditionModel")
local BuildingManager = UE4.BuildingFunctionLibrary.GetBuildingManager(_G.GlobalContext)
local BuildInteractionSystem = UE4.PzBuildUtil.GetBuildInteractionSystem(_G.GlobalContext)
local LuaLibrary = UE4.PzGameLuaLibrary
local PalEggItemConfig = ConfigManager.GetTable("ResPalEgg")
local KGItemManager = UE4.PzInventoryLibrary.GetInventoryManager(_G.GlobalContext)
local PzBuildUtil = UE4.PzBuildUtil
local PzLogicLibrary = UE4.PzLogicLibrary

local setting = {
	Events = {
		["Incubator_OpenEggView"] = "OnOpenEggView",
		["Incubator_GetPal"] = "OnPalGet",
		["Incubator_Check"] = "OnEggCheck",
		["Ineraction_Addition_ItemClick"] = "OnEggPutDown",
		["PZ_EVENT_TOTEM_ITEM_UPDATE"] = "OnContainerUpdate",
		["MechPetIncubateCompleted"] = "OnPalIncubateCompleted"
	},
}

local CurObjId = FGuid(0, 0, 0, 0)
local CurOpId = 0

local PutEggData = nil

function AdditionEggModel:_init()
	super._init(self, setting)
	self.AdditionKey = AdditionModel:GetAdditionKeys().PutEgg
end

function AdditionEggModel:OnOpenEggView(_, _, PieceGuid, InteractionId)
	CurObjId = PieceGuid
	CurOpId = InteractionId
	self:RefreshPutEggData()
	if PutEggData and PutEggData.interactionData and #PutEggData.interactionData > 0 then
		AdditionModel:ShowAdditionPanel(PutEggData)
	else
		local resultText = LocalizationFText.FromStr("没有可放入的蛋")
		EventSystem.Fire("AppendNotice", EKGNoticeType.Normal, resultText)
	end
end

function AdditionEggModel:RefreshPutEggData()
	PutEggData = {}
	PutEggData.ActorGuid = CurObjId
	PutEggData.interactionID = CurOpId
	PutEggData.InteractionType = self.AdditionKey
	PutEggData.interactionData = {}
	PutEggData.TitleName = AdditionModel:GetInteractionName(CurOpId, CurObjId)
	PutEggData.TitleIcon = AdditionModel:GetInteractionIconByID(CurOpId)

	local PieceId = 0
	local Entity = self:GetIncubatorEntity()
	if Entity then
		PieceId = Entity:PieceID()
	end

	local Count = PalEggItemConfig:GetCount()
	for i = 0, Count - 1 do
		local Info = PalEggItemConfig:GetRowByIndex(i)
		if Info then
			local IncubatorIds = Info.IncubatorIdGroup
			local IsIncubatorSupport = false
			for j = 0, ResMacros.C_RES_PAL_EGG_INCUBATOR_MAX_COUNT - 1 do
				if IncubatorIds[j] == PieceId then
					IsIncubatorSupport = true
				end
			end
			local count = PzLogicLibrary.C_GetItemNumCheckInTotem(_G.GlobalContext, Info.Id)
			if count > 0 and IsIncubatorSupport then
				table.insert(PutEggData.interactionData, {
					Key = self.AdditionKey,
					index = i + 1,
					itemTypeID = Info.Id,
					itemCount = count
				})
			end
		end
	end
end

function AdditionEggModel:OnEggPutDown(_, _, data)
	if data.Key == self.AdditionKey and CurOpId > 0 then
		local SlotIndex = self:GetNextSlotIndex()
		if SlotIndex >= 0 then
			BuildInteractionSystem:SendPutEggReq(CurObjId, CurOpId, data.itemTypeID, SlotIndex)
			BuildInteractionSystem:ActiveUseBuildAbilityWithGuid(CurOpId, CurObjId)
			UE4.PzAudioUtil.PlayAudio(_G.GlobalContext, 10291)
			UE4.PzAudioUtil.PlayAudio(_G.GlobalContext, 10292)
		end
	end
end

function AdditionEggModel:OnPalGet(_, _, ObjId, OpId)
	CurObjId = ObjId
	CurOpId = OpId
	local Entity = self:GetIncubatorEntity()
	if Entity then
		local SlotIndex = Entity:GetMatureCompletedSlotIndex()
		if SlotIndex >= 0 then
			BuildInteractionSystem:SendGetPalReq(CurObjId, CurOpId, SlotIndex)
		end
	end
end

function AdditionEggModel:OnPalIncubateCompleted()
end

function AdditionEggModel:GetNextSlotIndex()
	local entity = self:GetIncubatorEntity()
	if entity then
		local emptySlots = entity:GetCanPutDownSlotsIndex()
		local count = emptySlots:Num()
		if count > 0 then
			return emptySlots:Get(0)
		end
	end
	return -1
end

function AdditionEggModel:OnContainerUpdate()
	if AdditionModel:CheckIsCurInteractionEntity(CurObjId, self.AdditionKey) then
		local Entity = self:GetIncubatorEntity()
		if Entity then
			self:RefreshPutEggData()
			AdditionModel:RefreshAdditionPanel(PutEggData)
		end
	end
end

function AdditionEggModel:OnEggCheck(_, _, ObjId, OpId)
	CurObjId = ObjId
	CurOpId = OpId
	local Entity = self:GetIncubatorEntity()
	if Entity then
		local SlotsIndex = Entity:GetIncubatingSlotsIndex()
		for i = 0, SlotsIndex:Num() - 1 do
			local LeftTime = math.floor(Entity:GetMatureLeftTime(SlotsIndex:Get(i)))
			local ItemId = Entity:GetEggItemIdBySlotIndex(SlotsIndex:Get(i))
			local ItemName = FKBinItemTable.GetName(_G.GlobalContext, ItemId)
			local NoticeText = ""
			if LeftTime <= 0 then
				NoticeText = LocalizationFText.FromStr("Pal.Incubate_Completed").str
			else
				if LeftTime > 60 then
					local Min = math.floor(LeftTime / 60)
					NoticeText = LocalizationFText.FromStr("Pal.Remain_Incubate_Minute").str
					NoticeText = UIUtil.TextStringFormat(NoticeText, "minute", Min)
				else
					NoticeText = LocalizationFText.FromStr("Pal.Remain_Incubate_Second").str
					NoticeText = UIUtil.TextStringFormat(NoticeText, "second", LeftTime)
				end
			end
			NoticeText = UIUtil.TextStringFormat(NoticeText, "item_name", ItemName)
			EventSystem.Fire("AppendNotice", EKGNoticeType.Normal, NoticeText)
			return
		end
	end
end

function AdditionEggModel:GetIncubatorEntity()
	local Entity = BuildingManager:GetIncubatorEntityByGuid(CurObjId)
	return Entity
end

return AdditionEggModel
