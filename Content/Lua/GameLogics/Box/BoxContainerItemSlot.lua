-- Selected feature implementation. External runtime and widget assets are not included.
local BoxContainerItemSlot, super = CreateUIBehaviour("BoxContainerItemSlot", 'GameLogics/Bag/BagContainerItemSlotBase')

local KGItemLibrary = UE4.PzInventoryLibrary
local KGItemManager = KGItemLibrary.GetInventoryManager(_G.GlobalContext)
local PzLogicLibrary = UE4.PzLogicLibrary
local BagModel = ModelManager:GetModel("BagModel")
local ItemTable = GetTableDefine("ItemTable")
local Timer = require "GameCore.GameEvent.Timer"

local setting = {
	Elements = {
		{
			Name = "EditArrow"
		},
		{
			Name = "EmptyImg",
		},
		{
			Name = "SpecialEmpty",
			Necessary = false
		},
		{
			Name = "SelectBGImg"
		},
		{
			Name = "DoubleClickTip"
		},
		{
			Name = "TrackPart",
			Necessary = false
		},
		{
			Name = "TrackNumText",
			Necessary = false
		},
        {
            Name = "UISkillPart",
            Necessary = false,
        },
        {
            Name = "SkillIcon",
            Necessary = false,
        },
	},
	Events = {
		["Storage_InEdit"] = "OnStorageInEdit",
		["ExitWaitDrag"] = "OnExitWaitDrag",
        ["PZ_EVENT_QUEST_MATERIAL_TRACK_CHANGE"] = "OnQuestMaterialTrackChange",
	},
	Behaviours = {
		{
			Name = "DoubleClickTip",
			Alias = "DoubleClickTipBehaviour"
		}
	},
}

function BoxContainerItemSlot:_init(go)
	super._init(self, go, setting)
	self.matchEdit = false
	self.inEdit = false
	self.boxModel = ModelManager:GetModel("BoxModel")
	self.DoubleClickCDTimestamp = 0
	self.InDragDetected = false
	UIUtil.SetWidgetVisible(self.SelectBGImg, false)
	if self.EditArrow then
		UIUtil.SetWidgetVisible(self.EditArrow, false)
	end
    self.DelayItemTouchEvent = "BoxItemDelayItemTouch"..tostring(self._targetID)
end

function BoxContainerItemSlot:OnDestroy()
    super.OnDestroy(self)

    self:CloseDelayItemTouch()
end

function BoxContainerItemSlot:SetDoubleClickTipInfo()
	if self.ContainerType == ProtoMacro.MACROS_XY_CS_CONSTS.E_CONT_STORAGE_BOX then
		self.DoubleClickTipBehaviour:SetText(LocalizationFText.FromStr("双击取出"))
	else
		self.DoubleClickTipBehaviour:SetText(LocalizationFText.FromStr("双击放入"))
	end
	self:ShowDoubleClickTip(false)
end

function BoxContainerItemSlot:SetListViewBehaviour(behaviour)
    self.ListViewBehaviour = behaviour
    self:SetDragItemRoot(self.ListViewBehaviour.RootPanel)
end

function BoxContainerItemSlot:UpdateSelect()
    if self.ListViewBehaviour then
        local bSelect = self.ShowIndex == self.ListViewBehaviour.ItemListView_SelectIndexId
        local Item = KGItemManager:GetItemByClientId(self.ItemClientId)
        if self.matchEdit then
            UIUtil.SetWidgetVisible(self.SelectBGImg, self.inEdit)
        else
            if Item then
                UIUtil.SetWidgetVisible(self.SelectBGImg, bSelect)
            else
                UIUtil.SetWidgetVisible(self.SelectBGImg, false)
            end
        end
        if self.SpecialEmpty then
            local showSpecialEmpty = self.ContainerType == ProtoMacro.MACROS_XY_CS_CONSTS.E_CONT_BODY_BAG and not Item
            UIUtil.SetWidgetVisible(self.SpecialEmpty, showSpecialEmpty)
            UIUtil.SetWidgetVisible(self.EmptyImg, not showSpecialEmpty)
        end
        self:SetSlotSelect(bSelect)
		if bSelect == false then
			self:ShowDoubleClickTip(false)
		end
    end
end

function BoxContainerItemSlot:UpdatePutInDisable()
    if self.ItemClientId > 0 then
        local BoxGuid = self.boxModel:GetCurBoxGuid()
        local CheckResult = PzLogicLibrary.CheckEnableMoveToStorageBoxByPos(_G.GlobalContext, BoxGuid, self.ContainerType, self.ContainerPos)
        self:SetDisabledFlag(CheckResult ~= 0)
    else
        self:SetDisabledFlag(false)
    end
end

function BoxContainerItemSlot:ShowDoubleClickTip(bShow)
    if bShow then
        self.DoubleClickTipBehaviour:Show()
    else
        self.DoubleClickTipBehaviour:Hide()
    end
end

function BoxContainerItemSlot:UpdateView()
    super.UpdateView(self)

    self:ShowTrackInfo()
end

function BoxContainerItemSlot:OnItemTouch()
    if self:GetIsDisable() then return end
	self:ShowDoubleClickTip(self.ItemClientId > 0)
    if self.ListViewBehaviour then

        if self.ItemClientId > 0 then
            self:StartDelayItemTouch()
        else
            self.ListViewBehaviour:ItemListView_SetSelectedIndex(self.ShowIndex, self.ItemClientId)
        end
    end
end

function BoxContainerItemSlot:OnDoubleItemTouch()
    if self.ListViewBehaviour then
        self.ListViewBehaviour:ItemListView_DoubleTouch(self.ItemClientId)
        self.ListViewBehaviour:ItemListView_SetSelectedIndex(-1)
    end
end

function BoxContainerItemSlot:StartDelayItemTouch()
    self:CloseDelayItemTouch()
    self.bInDelayItemTouch = true
    local Threshold = BagModel:GetDoubleClickThreshold()
    self._visibleScope:ListenEvent(self.DelayItemTouchEvent, Timer:Once(Threshold),
        function()
            if self.ListViewBehaviour and self.ShowIndex and self.ItemClientId then
                self.ListViewBehaviour:ItemListView_SetSelectedIndex(self.ShowIndex, self.ItemClientId)
            end
        end)
end

function BoxContainerItemSlot:CloseDelayItemTouch()
    self.bInDelayItemTouch = false
    self._visibleScope:CloseEvent(self.DelayItemTouchEvent)
end

function BoxContainerItemSlot:TouchStartedHandler()

end

function BoxContainerItemSlot:TouchEndedHandler()
    BagModel:DoubleClickDebug()
    local currentClock = UIUtil.GetRealTimeSeconds()
    local Threshold = BagModel:GetDoubleClickThreshold()
    if self.bWaitDoubleClick == true and currentClock - self.DoubleClickCDTimestamp < Threshold then
        self.bWaitDoubleClick = false
        self:CloseDelayItemTouch()
        self.DoubleClickCDTimestamp = currentClock
        self:OnDoubleItemTouch()
		if BagModel.DragItemId then
			self.ListViewBehaviour:InterruptListScroll(false)
			if not BagModel.WaitContainerMove then
				self:UpdateView()
			end
            EventSystem.Fire("ExitWaitDrag")
		end
        return
    end
    self.DoubleClickCDTimestamp = currentClock
    if BagModel.DragItemId then
        self:UpdateView()
        self.ListViewBehaviour:InterruptListScroll(false)
        BagModel.DragItemId = nil

        self.bWaitDoubleClick = false
    else
        self:OnItemTouch()

        self.bWaitDoubleClick = true
    end
    EventSystem.Fire("Storage_InEdit", false, self.ItemClientId)
end

function BoxContainerItemSlot:WaitDragEventHandler()
    if self.bInDelayItemTouch == true then
        EventSystem.Fire("ItemTipsFrame_Do_Hide")
    end
    self:CloseDelayItemTouch()
    self.ListViewBehaviour:ItemListView_SetSelectedIndex(-1)

    EventSystem.Fire("Storage_InEdit", true, self.ItemClientId)
    self.ListViewBehaviour:InterruptListScroll(true)
    local Item = KGItemManager:GetItemByClientId(self.ItemClientId)
    if Item then
        BagModel.DragItemId = self.ItemClientId
		UIUtil.SetWidgetVisible(self.TrackPart, false)
        BagModel:CloseItemTips()
    end
end

function BoxContainerItemSlot:DragDetectedHandler()
    self.InDragDetected = true
end

function BoxContainerItemSlot:DragCancelledHandler()
    self.ListViewBehaviour:InterruptListScroll(false)
    if self.InDragDetected and BagModel.DragItemId then
        self:UpdateView()
    end
    BagModel.DragItemId = nil
    self.ListViewBehaviour:ItemListView_SetSelectedIndex(-1)
    self.InDragDetected = false
    EventSystem.Fire("Storage_InEdit", false, self.ItemClientId)
end

function BoxContainerItemSlot:DragEnterHandler()
    if BagModel.DragItemId then
        self.ListViewBehaviour:ItemListView_SetSelectedIndex(self.ShowIndex)
    end
end

function BoxContainerItemSlot:DragLeaveHandler()
    if BagModel.DragItemId then
        self.ListViewBehaviour:ItemListView_SetSelectedIndex(-1)
    end
end

function BoxContainerItemSlot:DragDropHandler()
    if BagModel.DragItemId and BagModel.DragItemId ~= self.ItemClientId then
        local DragItem = KGItemManager:GetItemByClientId(BagModel.DragItemId)
        if DragItem then
            if self.ContainerType == ProtoMacro.MACROS_XY_CS_CONSTS.E_CONT_SHORTCUT_BAR then
                local canPutInShortcutBar = DragItem:CanPutInShortcutBar()
                if not canPutInShortcutBar then
                    EventSystem.Fire("AppendNotice", EKGNoticeType.Normal, LocalizationFText.FromStr("该道具无法放入该快捷栏").str)
                    self:UpdateView()
                    return
                end
            end
            if self.ContainerType == ProtoMacro.MACROS_XY_CS_CONSTS.E_CONT_FOOD_SHORTCUT_BAG then
                local canPutInFoodBar = DragItem:CanPutInFoodShortcutBar()
                if not canPutInFoodBar then
                    EventSystem.Fire("AppendNotice", EKGNoticeType.Normal, LocalizationFText.FromStr("该道具无法放入该食物快捷栏").str)
                    self:UpdateView()
                    return
                end
            end
            if self.ContainerType == ProtoMacro.MACROS_XY_CS_CONSTS.E_CONT_BODY_BAG then
                local canPutInEquipBar = DragItem:IsNormalEquip() and DragItem:GetEquipType() > 0 and DragItem:CanPutInShortcutBar() == false
                    and DragItem:CanPutInFoodShortcutBar() == false and (DragItem:GetEquipType() == self.ContainerPos or
					ItemTable.IsSubsistenceSlotIndex(DragItem:GetEquipType()) and ItemTable.IsSubsistenceSlotIndex(self.ContainerPos))
                if not canPutInEquipBar then
                    EventSystem.Fire("AppendNotice", EKGNoticeType.Normal, LocalizationFText.FromStr("该道具无法放入该装备栏").str)
                    self:UpdateView()
                    return
                end
            end
            local selfItem = KGItemManager:GetItemByClientId(self.ItemClientId)
            if selfItem then
                local dragContainerType = DragItem.ContainerType
                if dragContainerType == ProtoMacro.MACROS_XY_CS_CONSTS.E_CONT_SHORTCUT_BAR then
                    local canPutInShortcutBar = selfItem:CanPutInShortcutBar()
                    if not canPutInShortcutBar then
                        EventSystem.Fire("AppendNotice", EKGNoticeType.Normal, LocalizationFText.FromStr("类型不满足交换条件").str)
                        self:UpdateView()
                        return
                    end
                end
                if dragContainerType == ProtoMacro.MACROS_XY_CS_CONSTS.E_CONT_FOOD_SHORTCUT_BAG then
                    local canPutInFoodBar = selfItem:CanPutInFoodShortcutBar()
                    if not canPutInFoodBar then
                        EventSystem.Fire("AppendNotice", EKGNoticeType.Normal, LocalizationFText.FromStr("类型不满足交换条件").str)
                        self:UpdateView()
                        return
                    end
                end
                if dragContainerType == ProtoMacro.MACROS_XY_CS_CONSTS.E_CONT_BODY_BAG then
                    local canPutInEquipBar = selfItem:IsNormalEquip() and selfItem:GetEquipType() > 0 and selfItem:CanPutInShortcutBar() == false
                        and selfItem:CanPutInFoodShortcutBar() == false and (selfItem:GetEquipType() == DragItem.ContainerPos or
						ItemTable.IsSubsistenceSlotIndex(selfItem:GetEquipType()) and ItemTable.IsSubsistenceSlotIndex(DragItem.ContainerPos))
                    if not canPutInEquipBar then
                        EventSystem.Fire("AppendNotice", EKGNoticeType.Normal, LocalizationFText.FromStr("类型不满足交换条件").str)
                        self:UpdateView()
                        return
                    end
                end
            end
            self.boxModel:DragMoveItem(BagModel.DragItemId, self.ContainerType, self.ItemClientId, self.ContainerPos)
            self:UpdateView()
            return
        end
    else
        self:UpdateView()
    end
    BagModel.DragItemId = nil
end

function BoxContainerItemSlot:OnStorageInEdit(_, _, inEdit, clientId)
    self.inEdit = inEdit
    local Item = KGItemManager:GetItemByClientId(clientId)
    if Item then
        local canPutInShortcutBar = Item:CanPutInShortcutBar()
        self.matchEdit = canPutInShortcutBar and self.ContainerType == ProtoMacro.MACROS_XY_CS_CONSTS.E_CONT_SHORTCUT_BAR
        if not self.matchEdit then
            local canPutInFoodBar = Item:CanPutInFoodShortcutBar()
            self.matchEdit = canPutInFoodBar and self.ContainerType == ProtoMacro.MACROS_XY_CS_CONSTS.E_CONT_FOOD_SHORTCUT_BAG
        end
		if not self.matchEdit then
			local canPutInEquipBar = Item:IsNormalEquip() and Item:GetEquipType() > 0 and Item:CanPutInShortcutBar() == false and Item:CanPutInFoodShortcutBar() == false
			self.matchEdit = canPutInEquipBar and self.ContainerType == ProtoMacro.MACROS_XY_CS_CONSTS.E_CONT_BODY_BAG and (self.ContainerPos == Item:GetEquipType() or
				ItemTable.IsSubsistenceSlotIndex(Item:GetEquipType()) and ItemTable.IsSubsistenceSlotIndex(self.ContainerPos))
		end
    end
    if self.matchEdit then
        UIUtil.SetWidgetVisible(self.SelectBGImg, inEdit)
        if self.EditArrow then
            UIUtil.SetWidgetVisible(self.EditArrow, inEdit)
        end
        self._target:PlayAnimation(self._target.EditArrowLoopAnim, 0, 1, UE4.EUMGSequencePlayMode.Forward, 1, false)
    end
end

function BoxContainerItemSlot:ShowTrackInfo()
	if self.TrackPart and self.TrackNumText then
		if self.ContainerType == ProtoMacro.MACROS_XY_CS_CONSTS.E_CONT_STORAGE_BOX then
			local Item = KGItemManager:GetItemByClientId(self.ItemClientId)
			if Item then
				local trackNum = PzLogicLibrary.C_GetTrackingItemCount(_G.GlobalContext, Item.ItemTypeId)
                local trackNumQuest = UE4.PzQuestInstanceLibrary.QuestMaterialTrack_GetNum(_G.GlobalContext, Item.ItemTypeId)
				local ownNum = KGItemManager:GetItemCount(Item.ItemTypeId)
				local needNum = trackNum + trackNumQuest - ownNum
				UIUtil.SetWidgetVisible(self.TrackPart, needNum > 0)
				if needNum > 0 then
					self.TrackNumText:SetText(needNum)
				end
				return
			end
		end
		UIUtil.SetWidgetVisible(self.TrackPart, false)
	end
end

function BoxContainerItemSlot:OnQuestMaterialTrackChange()
    self:ShowTrackInfo()
end

function BoxContainerItemSlot:OnExitWaitDrag()
	UIUtil.SetWidgetVisible(self.SelectBGImg, false)
	if self.EditArrow then
		UIUtil.SetWidgetVisible(self.EditArrow, false)
	end
end

function BoxContainerItemSlot:OnDataSetUpdate()
    self._target:ResetDrag()

    if self.bInDelayItemTouch == true then
        EventSystem.Fire("ItemTipsFrame_Do_Hide")
    end
    self:CloseDelayItemTouch()
end

function BoxContainerItemSlot:SetSkillPart()
	if self.UISkillPart then
		UIUtil.SetWidgetVisible(self.UISkillPart, false)
        local skillID = UE4.EquipMadeExport.GetSkillIdByItemClientID(_G.GlobalContext, self.ItemClientId)
        if skillID > 0 then
            local _EquipSkillCurLevel = UE4.WorkBenchExport.WorkBench_GetEquipSkillCurLevel(_G.GlobalContext, skillID)
            local config = FKBinEquipSkillTable.GetConfigByID(_G.GlobalContext, skillID, _EquipSkillCurLevel)
            if config then
                UIUtil.SetWidgetVisible(self.UISkillPart, true)
                UIUtil.SetImagePathAsync(self.SkillIcon, config.szSkill_small_icon_path, false)
            end
        end
	end
end

return BoxContainerItemSlot
