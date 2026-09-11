-- Selected feature implementation. External runtime and widget assets are not included.
local StorageBagWidget, super = CreateUIBehaviour("StorageBagWidget")
local KGItemLibrary = UE4.PzInventoryLibrary
local KGItemManager = KGItemLibrary.GetInventoryManager(_G.GlobalContext)
local setting = {
	Elements = {
		{
			Name = "RootPanel"
		},
		{
			Name = "ItemListView",
		},
		{
			Name = "ArrangeBtn",
			Handles = {
				OnClicked = "OnArrange",
			}
		},
	},
	Events = {
		["ContainerUpdateEvent"] = "OnBagContainerUpdate",
		["ItemTipsFrame_On_Hide"] = "OnItemTipsHide",
		["ContainerWeightUpdateEvent"] = "UpdateWeightShow",
	},
	Behaviours = {
		{
			Name = "WeightPart",
		},
		{
            Name = "ItemBagCounter",
            Alias = "ItemBagCounterBehaviour",
        },
	},
}

function StorageBagWidget:_init(go)
	super._init(self, go, setting)
	self.BagMaxCountRecord = 0
	self.DefaultClientId = 0
	self.ItemListViewData = {}
	self.ItemListView_SelectIndexId = -1
	self.boxModel = ModelManager:GetModel("BoxModel")
end

function StorageBagWidget:OnInitialize()
	self:SetBagInfo()
end

function StorageBagWidget:OnDestroy()

end

function StorageBagWidget:ClearListView()
	self.ItemListView:ClearListItems()
	self.ItemListViewData = {}
end

function StorageBagWidget:SetBagInfo()
	self.ItemListView_SelectIndexId = -1
	local ContainerType = ProtoMacro.MACROS_XY_CS_CONSTS.E_CONT_ITEM_BAG
	local validCount = 0
	local showCount = 0
	local defaultIndex = -1
	local ContainerData = KGItemManager:GetContainerData(ContainerType)
	if ContainerData then
		local maxCount = ContainerData.ContainerCurSize
		local maxCountRecordOld = self.BagMaxCountRecord
		self.BagMaxCountRecord = maxCount
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
				data.IsCheckPutInDisable = true
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

	self.ItemBagCounterBehaviour:SetCounterData(validCount, showCount)
	self:UpdateWeightShow()
end

function StorageBagWidget:IsInManageOperate()
	return false
end

function StorageBagWidget:InterruptListScroll(bInterrupt)
	self.ItemListView:InterruptScroll(bInterrupt)
end

function StorageBagWidget:ItemListView_SetSelectedIndex(IndexId, clientId)
	local oldIndex = self.ItemListView_SelectIndexId or -1
	self.ItemListView_SelectIndexId = IndexId
	EventSystem.Fire("Box_BagSelectIndexChangeEvent", IndexId, oldIndex)
	self.ItemListView:SetSelectedIndex(IndexId)
	if clientId then
		self.tipsItemClientID = clientId
		self.boxModel:ShowBoxItemTips(clientId,true)
	end
end

function StorageBagWidget:OnItemTipsHide(_, _, clientId)
	if self.tipsItemClientID == clientId then
		self:ItemListView_SetSelectedIndex(-1)
		self.tipsItemClientID = -1
	end
end

function StorageBagWidget:ItemListView_DoubleTouch(clientId)
	self.boxModel:FastMoveToBox(clientId, 0)
end

function StorageBagWidget:OnArrange()
	local MergeResult = false
	local SortResult = false
	MergeResult = KGItemManager:ContainerMergeReq(ProtoMacro.MACROS_XY_CS_CONSTS.E_CONT_ITEM_BAG)
	if not MergeResult then
		SortResult = KGItemManager:ContainerSortReq(ProtoMacro.MACROS_XY_CS_CONSTS.E_CONT_ITEM_BAG)
	end

	if MergeResult or SortResult then
		self:ItemListView_SetSelectedIndex(-1)
	end
end

function StorageBagWidget:OnBagContainerUpdate()
	self:SetBagInfo()
end

function StorageBagWidget:UpdateWeightShow()
	local TotalWeight = KGItemManager:GetContainerWeight()
	self.WeightPart:SetWeightData(TotalWeight)
end

return StorageBagWidget
