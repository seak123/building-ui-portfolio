-- Selected feature implementation. External runtime and widget assets are not included.
local AdditionItem, super = CreateUIBehaviourFromListItem("AdditionItem")
local PzItemManager = UE4.PzInventoryLibrary.GetInventoryManager(_G.GlobalContext)
local AdditionModel = ModelManager:GetModel("AdditionModel")
local AdditionBuildModel = ModelManager:GetModel("AdditionBuildModel")
local GuideTable = GetTableDefine("GuideTable")

local setting =
{
	Elements =
	{
		{
			Name = "UIItemSelectBtn",
			Handles = {
				OnClicked = "OnClickItem"
			}
		},
		{
			Name = "CustomText",
		},
		{
			Name = "CustomOverlay",
		},
		{
			Name = "GuideTraceRed",
		},
	},
	Behaviours = {
		{
			Name = "WBP_Common_Item_Slot",
			Alias = "itemSlot"
		},
	},
}

function AdditionItem:_init(go)
	super._init(self, go, setting)
	UE4.PzUILibrary.ClearWidget(self.itemSlot.IconImg)
end

function AdditionItem:OnDataSet(data)
	self.dataInfo = data

	local ItemTypeId = 0

	if self.dataInfo.itemClientID and self.dataInfo.itemClientID > 0 then
		self.itemSlot:SetSlotItem(self.dataInfo.itemClientID)
		local Item = PzItemManager:GetItemByClientId(self.dataInfo.itemClientID)
		if Item then
			ItemTypeId = Item.ItemTypeId
		end
	elseif self.dataInfo.itemTypeID and self.dataInfo.itemTypeID > 0 then
		self.itemData = PzItemManager:CreateLocalItem(self.dataInfo.itemTypeID)
		if self.itemData then
			self.itemSlot:SetSlotItem(self.itemData.itemClientID)
			self.itemSlot:SetNum(self.dataInfo.itemCount or 0)
			self.itemSlot:RemoveLocalItem()
		end
		ItemTypeId = self.dataInfo.itemTypeID
	end

	local hintType = GuideTable.Get_GuideTraceItem_RedHintType("Addition", ItemTypeId)
	self.GuideTraceRed:RegisterHintType(hintType)

	UIUtil.SetWidgetVisible(self.CustomOverlay,false)
	if self.dataInfo.Key == AdditionModel:GetAdditionKeys().BuildCharger then
		local Energy = FPzBinBuildChanger.GetEnergyByItemId(_G.GlobalContext,AdditionBuildModel:GetCurPieceID(),self.dataInfo.itemTypeID)
		self.CustomText:SetText(Energy)
		UIUtil.SetWidgetVisible(self.CustomOverlay,true)
	end
end

function AdditionItem:OnClickItem()
	if AdditionModel:CheckInCold() then
		EventSystem.Fire("Ineraction_Addition_ItemClick", self.dataInfo)
		AdditionModel:CacheInteractionTime()
	else
	end
end

function AdditionItem:OnReleased()
	UE4.PzUILibrary.ClearWidget(self.itemSlot.IconImg)
end

return AdditionItem
