-- Selected feature implementation. External runtime and widget assets are not included.
local StorageBoxWidget, super = CreateUIBehaviour("StorageBoxWidget")
local PzLogicLibrary = UE4.PzLogicLibrary
local setting = {
	Elements = {
		{
			Name = "RootPanel"
		},
		{
			Name = "ItemListView",
		},
		{
			Name = "PlayerName",
		},
		{
			Name = "TitleIcon",
		},
		{
			Name = "GetAllBtn",
			Handles = {
				OnClicked = "OnGetAll",
			}
		},
		{
			Name = "AbsorbBtn",
			Handles = {
				OnClicked = "OnAbsorbItem",
			}
		},

		{
			Name = "ArrangeBtn",
			Handles = {
				OnClicked = "OnArrange",
			}
		},
	},
	Events = {
		["LogicEvent_Box_ContainerUpdate"] = "OnBoxContainerUpdate",
		["ItemTipsFrame_On_Hide"] = "OnItemTipsHide"
	}

}

function StorageBoxWidget:_init(go)
	super._init(self, go, setting)
	self.boxMaxCountRecord = 0
	self.DefaultClientId = 0
	self.ItemListViewData = {}
	self.ItemListView_SelectIndexId = -1
	self.boxModel = ModelManager:GetModel("BoxModel")
end

function StorageBoxWidget:OnInitialize()
	self:SetContainerInfo()
	self:SetTitleInfo()
	self:SetUIElementsVisible()
end

function StorageBoxWidget:OnDestroy()

end

function StorageBoxWidget:SetTitleInfo()
	self.PlayerName:SetText(self.boxModel:GetBoxName())
	UIUtil.SetImagePathAsync(self.TitleIcon, self.boxModel:GetBoxTitleIconPath(), false)
end

function StorageBoxWidget:SetUIElementsVisible()
	local bCanUserPutIn = FKBinHomelandStorageBoxTable.CanUserPutIn(_G.GlobalContext, self.boxModel:GetCurBoxConfigId(), ResMacros.E_HSBU_PLAYER)
	UIUtil.SetWidgetVisible(self.AbsorbBtn, bCanUserPutIn)
end

function StorageBoxWidget:ClearListView()
	self.ItemListView:ClearListItems()
	self.ItemListViewData = {}
end

function StorageBoxWidget:SetContainerInfo()
	local ContainerType = ProtoMacro.MACROS_XY_CS_CONSTS.E_CONT_STORAGE_BOX
	self.ItemListView_SelectIndexId = -1
	local showCount = 0
	local validCount = 0
	local defaultIndex = -1
	local ContainerData = self.boxModel:GetCurBoxContainerData()
	if ContainerData then
		local maxCount = ContainerData.ContainerCurSize
		local maxCountRecordOld = self.boxMaxCountRecord
		self.boxMaxCountRecord = maxCount
		showCount = maxCount
		local bNeedRebuild = true
		if maxCountRecordOld > 0 and maxCountRecordOld == maxCount then
			bNeedRebuild = false
		end
		if bNeedRebuild then
			self:ClearListView()
			for i = 1, maxCount do
				local data = {}
				data.ScrollOrientation = UE4.EPzDragScrollOrientation.Vertical
				data.ItemClientId = 0
				local Item = ContainerData:GetContainerItem(i - 1)
				if Item then
					data.ItemClientId = Item.ItemClientId
				end
				if data.ItemClientId > 0 then
					validCount = validCount + 1
				end
				data.ContainerType = ContainerType
				data.ContainerPos = i - 1
				data.ContainerCurSize = ContainerData.ContainerCurSize
				data.ContainerMaxSize = ContainerData.ContainerMaxSize
				data.Parent = self
				data.ShowIndex = #self.ItemListViewData
				if defaultIndex < 0 and self.DefaultClientId > 0 then
					if data.ItemClientId == self.DefaultClientId then
						defaultIndex = data.ShowIndex
					end
				end

				table.insert(self.ItemListViewData, data)
				local uobject = DataObjectPool:Get(data)
				self.ItemListView:AddItem(uobject)
			end
		else
			for i = 1, maxCount do
				local data = self.ItemListViewData[i]
				if data then
					data.ItemClientId = 0
					local Item = ContainerData:GetContainerItem(i - 1)
					if Item then
						data.ItemClientId = Item.ItemClientId
					end

					if data.ItemClientId > 0 then
						validCount = validCount + 1
					end
				end
			end

			local activeWidgets = self.ItemListView:GetDisplayedEntryWidgets()
			for k = 1, activeWidgets:Num() do
				local activeWidget = activeWidgets:Get(k - 1)
				if activeWidget then
					local activeWidgetId = activeWidget:GetUniqueID()
					local activeWidgetBehaviour = __BehaviourManager:GetBehaviour(activeWidgetId)
					if activeWidgetBehaviour then
						activeWidgetBehaviour:UpdateView(true)
					end
				end
			end
		end
		if self.DefaultClientId > 0 then
			self.DefaultClientId = 0
		end
	end
end

function StorageBoxWidget:IsInManageOperate()
	return false
end

function StorageBoxWidget:InterruptListScroll(bInterrupt)
	self.ItemListView:InterruptScroll(bInterrupt)
end

function StorageBoxWidget:ItemListView_SetSelectedIndex(IndexId, clientId)
	local oldIndex = self.ItemListView_SelectIndexId or -1
	self.ItemListView_SelectIndexId = IndexId
	EventSystem.Fire("Box_BagSelectIndexChangeEvent", IndexId, oldIndex)
	self.ItemListView:SetSelectedIndex(IndexId)
	if clientId then
		self.tipsItemClientID = clientId
		self.boxModel:ShowBoxItemTips(clientId, false)
	end
end

function StorageBoxWidget:OnItemTipsHide(_, _, clientId)
	if self.tipsItemClientID == clientId then
		self:ItemListView_SetSelectedIndex(-1)
		self.tipsItemClientID = -1
	end
end

function StorageBoxWidget:ItemListView_DoubleTouch(clientId)
	self.boxModel:FastMoveFromStorage(clientId,0)
end

function StorageBoxWidget:OnGetAll()
	self.boxModel:FastMoveAllToBag()
end

function StorageBoxWidget:OnBoxContainerUpdate(_, _, BoxGuid)
	if PzLogicLibrary.CheckFGUIDEqual(_G.GlobalContext, BoxGuid, self.boxModel:GetCurBoxGuid()) then
		self:SetContainerInfo()
	end
end

function StorageBoxWidget:OnArrange()
	self.boxModel:OnBoxArrange()
end

function StorageBoxWidget:OnAbsorbItem()
	self.boxModel:OnFastAbsorbItem()
end

return StorageBoxWidget
