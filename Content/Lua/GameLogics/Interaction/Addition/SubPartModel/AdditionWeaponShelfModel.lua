-- Selected feature implementation. External runtime and widget assets are not included.
local AdditionWeaponShelfModel, super = ModelManager:CreateModel("AdditionWeaponShelfModel")
local AdditionModel = ModelManager:GetModel("AdditionModel")
local HangableItemConfig = ConfigManager.GetTable("ResHomelandHangableItemConfig")
local PzLogicLibrary = UE4.PzLogicLibrary
local KGItemManager = UE4.PzInventoryLibrary.GetInventoryManager(_G.GlobalContext)

local setting = {
	Events = {
		["WeaponShelf_OpenHangView"] = "OnOpenHangView",
		["Ineraction_Addition_ItemClick"] = "OnItemHang",
		["ContainerUpdateEvent"] = "OnContainerUpdate",
		["SingleHook_HangItemChange"] = "OnHangeItemChange"
	},
}

local CurHookGuid = FGuid(0,0,0,0)
local ConfigId = 0
local CurOpId = 0

function AdditionWeaponShelfModel:_init()
	super._init(self, setting)
	self.AdditionKey = AdditionModel:GetAdditionKeys().WeaponShelf
end

function AdditionWeaponShelfModel:OnOpenHangView(_, _, PieceConfigId, PieceGuid, InteractionId)
	ConfigId = PieceConfigId
	CurHookGuid = PieceGuid
	CurOpId = InteractionId
	if CurOpId > 0 and ConfigId > 0 then
		local hangeData = self:GetWeaponShelfHangData()
		if hangeData and hangeData.interactionData and #hangeData.interactionData > 0 then
			AdditionModel:ShowAdditionPanel(hangeData)
		else
			local resultText = LocalizationFText.FromStr("没有可悬挂的道具").str
			EventSystem.Fire("AppendNotice", EKGNoticeType.Normal, resultText)
		end
	end
end

function AdditionWeaponShelfModel:GetWeaponShelfHangData()
	local hangData = {}
	if ConfigId then
		hangData.ActorGuid = CurHookGuid
		hangData.interactionID = CurOpId
		hangData.InteractionType = self.AdditionKey
		hangData.interactionData = {}
		hangData.TitleName = AdditionModel:GetInteractionName(CurOpId, CurHookGuid)
		hangData.TitleIcon = AdditionModel:GetInteractionIconByID(CurOpId)
		local DataIndex = 0
		local Count = HangableItemConfig:GetCount()
		local function MakeInteractionData(infoData, containerType)
			local ContainerData = KGItemManager:GetContainerData(containerType)
			if ContainerData then
				local maxCount = ContainerData.ContainerCurSize
				for j = 1, maxCount do
					local data = {}
					data.ItemClientId = 0
					DataIndex = DataIndex+1
					local Item = ContainerData:GetContainerItem(j - 1)
					if Item and Item.ItemTypeId == infoData.ItemId then
						table.insert(hangData.interactionData, {
							Key = self.AdditionKey,
							index = DataIndex,
							itemTypeID = infoData.ItemId,
							itemCount = Item:GetCount(),
							containerType = containerType,
							containerPos = j - 1
						})
					end
				end
			end
		end
		for i = 0, Count - 1 do
			local info = HangableItemConfig:GetRowByIndex(i)
			if info and info.TargetObj == ConfigId then
				MakeInteractionData(info,ProtoMacro.MACROS_XY_CS_CONSTS.E_CONT_ITEM_BAG)
				MakeInteractionData(info,ProtoMacro.MACROS_XY_CS_CONSTS.E_CONT_SHORTCUT_BAR)
			end
		end
	end
	return hangData
end

function AdditionWeaponShelfModel:OnItemHang(_, _, data)
	if data.Key == self.AdditionKey and CurOpId > 0 and CurHookGuid then
		PzLogicLibrary.OnWeaponShelfHang(_G.GlobalContext, CurHookGuid, data.itemTypeID, data.containerType, data.containerPos)
	end
end

function AdditionWeaponShelfModel:OnContainerUpdate()
	if AdditionModel:CheckIsCurInteractionEntity(CurHookGuid,self.AdditionKey) then
		local hangeData = self:GetWeaponShelfHangData()
		AdditionModel:RefreshAdditionPanel(hangeData)
	end
end

function AdditionWeaponShelfModel:OnHangeItemChange(_, _, guid, itemId, playerId)
	if CurHookGuid and PzLogicLibrary.CheckFGUIDEqual(_G.GlobalContext, guid, CurHookGuid) and itemId > 0 then
		if AdditionModel:CheckIsCurInteractionEntity(CurHookGuid,self.AdditionKey) then
			EventSystem.Fire("Ineraction_Addition_HideView")
		end

		if playerId ~= UE.UGameLuaLibrary.GetMyPlayerRID(_G.GlobalContext) then
			EventSystem.Fire("AppendNotice", EKGNoticeType.Normal, LocalizationFText.FromStr("空位已经被占用了~").str)
		end
	end
end

return AdditionWeaponShelfModel
