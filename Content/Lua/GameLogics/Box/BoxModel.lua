-- Selected feature implementation. External runtime and widget assets are not included.
local BoxModel, super = ModelManager:CreateModel("BoxModel")
local PzLogicLibrary = UE4.PzLogicLibrary
local KGItemLibrary = UE4.PzInventoryLibrary
local KGItemManager = KGItemLibrary.GetInventoryManager(_G.GlobalContext)
local PzBuildUtil = UE4.PzBuildUtil
local setting = {
	Events = {
		["LogicEvent_Box_Open"] = "OnOpenBox",
		["LogicEvent_MoveToStorageBox_ErrorCode"] = "OnMoveToStorageBoxErrorCode",
        ["OpenFishPondManageUI"] = "OpenFishPondManageUI",
	},
}
local BoxMainFrame_Patn = "WidgetBlueprint'/Game/UI/Panel/Box/WBP_Storage_Frame.WBP_Storage_Frame_C'"
local fishPondFramePath = "WidgetBlueprint'/Game/UI/Panel/Fishing/WBP_FishPond_Frame.WBP_FishPond_Frame_C'"
local CurBoxGuid = nil
local CurBoxConfigId = 0

function BoxModel:_init()
	self.BagMaxCountRecord = 0
	super._init(self, setting)
end

function BoxModel:OnOpenBox(_, _, ConfigId, Guid)
	if CurBoxGuid and not PzLogicLibrary.CheckFGUIDEqual(_G.GlobalContext, Guid, CurBoxGuid) then
		self:SetBoxInteractiveState(false)
	end
	CurBoxGuid = Guid
	CurBoxConfigId = ConfigId
	UIUtil.AddUniqueFrameAsync(BoxMainFrame_Patn, function(frame)
		if frame then

		end
	end)
end

function BoxModel:OpenFishPondManageUI(_, _, ConfigId, Guid)
    -- Implementation omitted.
end

function BoxModel:GetCurBoxGuid()
	return CurBoxGuid
end

function BoxModel:IsPersonalBox()
	return PzLogicLibrary.IsPersonalBox(_G.GlobalContext, CurBoxGuid)
end

function BoxModel:GetCurBoxContainerData()
	return PzLogicLibrary.GetContainerDataFromBox(_G.GlobalContext, CurBoxGuid)
end

function BoxModel:SetBoxInteractiveState(state)
	if state then
		PzBuildUtil.RequestEnterPieceInteraction(_G.GlobalContext, CurBoxGuid, false)
		CurBoxGuid = nil
		CurBoxConfigId = 0
	else
		PzBuildUtil.RequestExitPieceInteraction(_G.GlobalContext, CurBoxGuid)
	end
end

function BoxModel:FastMoveToBox(itemClientID, count)
	if itemClientID <= 0 then
		return false
	end
	local item = KGItemManager:GetItemByClientId(itemClientID)
	if item then
		if count <= 0 then
			count = item:GetCount()
		end
		if count > 0 then
			PzLogicLibrary.MoveToStorageBox(_G.GlobalContext, CurBoxGuid, item.ContainerType, item.ContainerPos, -1, count)
			return true
		end
	end
end

function BoxModel:FastMoveFromStorage(itemClientID, count)
	if itemClientID <= 0 then
		return false
	end
	PzLogicLibrary.FastMoveOutStorage(_G.GlobalContext, CurBoxGuid, itemClientID, count)
	return true
end

function BoxModel:FastMoveAllToBag()
	PzLogicLibrary.TakeoutAllItemFromBox(_G.GlobalContext, CurBoxGuid)
end

function BoxModel:DragMoveItem(srcItemClientId, dstContainerType, dstItemClientId, dstContainerPos)
	if CurBoxGuid ~= nil then
		PzLogicLibrary.OnBoxDragMoveItem(_G.GlobalContext, CurBoxGuid, srcItemClientId, dstContainerType, dstItemClientId, dstContainerPos)
	end
end

function BoxModel:OnMoveToStorageBoxErrorCode(e, r, ErrorCode)
	if ErrorCode == 1 then
		EventSystem.Fire("AppendNotice", EKGNoticeType.Normal, LocalizationFText.FromStr("道具不存在").str)
	elseif ErrorCode == 2 then
		UE4.PzGameLuaLibrary.ShowMsgErrorNotice(_G.GlobalContext, 0, -1002200)
	elseif ErrorCode == 3 then
		UE4.PzGameLuaLibrary.ShowMsgErrorNotice(_G.GlobalContext, 0, -1002201)
	elseif ErrorCode == 4 then
	elseif ErrorCode == 5 then -- 种子配方未解锁，不能放入维护箱
		UE4.PzGameLuaLibrary.ShowMsgErrorNotice(_G.GlobalContext, 0, -1002466) -- Pz_ERR_CRAFT_RECIPE_NOT_UNLOCKED = -1002466
	end
end

function BoxModel:ShowBoxItemTips(itemClientID, bMoveToBox)
	local Item = KGItemManager:GetItemByClientId(itemClientID)
	if Item then
		local count = Item:GetCount()
		if count > 0 then
			local function moveToBox(mcount)
				local result = self:FastMoveToBox(itemClientID, mcount)
				if result then
					EventSystem.Fire("ItemTipsFrame_Do_Hide")
				end
			end
			local function moveOutBox(mcount)
				local result = self:FastMoveFromStorage(itemClientID, mcount)
				if result then
					EventSystem.Fire("ItemTipsFrame_Do_Hide")
				end
			end
			local Config = {
				ItemClientID = itemClientID,
				AutoHide = true,
				ForceHideShotCut = true,
				BtnText = bMoveToBox and LocalizationFText.FromStr("放入").str or LocalizationFText.FromStr("取出").str,
				NumMax = count,
				NumMin = 1,
				ActionCallback = bMoveToBox and moveToBox or moveOutBox
			}
			UIUtil.AddCustomizeSingleItemTips(Config, false)
		end
	end
end

function BoxModel:OnBoxArrange()
	PzLogicLibrary.SortBoxContainer(_G.GlobalContext, CurBoxGuid)
end

function BoxModel:OnFastAbsorbItem()
	if PzLogicLibrary.C_CheckEnableAbsorb(_G.GlobalContext, CurBoxGuid) then
		PzLogicLibrary.FastAbsorbItemIntoBox(_G.GlobalContext, CurBoxGuid)
	else
		EventSystem.Fire("AppendNotice", EKGNoticeType.Normal, LocalizationFText.FromStr("当前没有可以快速放入储物箱的同种道具").str)
	end
end

function BoxModel:DropItemsFromBox(Info)
    -- Implementation omitted.
end

function BoxModel:CheckPlayerDistance()
	return PzBuildUtil.C_CheckPlayerInDistance2D(_G.GlobalContext, CurBoxGuid, 300)
end

function BoxModel:GetBoxName()
	local buildSpaceModel = ModelManager:GetModel("BuildSpaceModel")
	if buildSpaceModel then
		local PieceName = buildSpaceModel:GetBuildNameByID(CurBoxConfigId)
		local AddName = self:IsPersonalBox() and string.format(LocalizationFText.FromStr("%s的").str, GameUtil.GetPlayerName()) or ""
		return string.format("%s%s", AddName, PieceName)
	end
	return ""
end

function BoxModel:GetBoxTitleIconPath()
	return PzLogicLibrary.GetBoxTitleIconPath(_G.GlobalContext, CurBoxConfigId)
end

function BoxModel:GetCurBoxConfigId()
	return CurBoxConfigId
end

return BoxModel
