-- Selected feature implementation. External runtime and widget assets are not included.
local SemiProduceRecipeEntry,super = CreateUIBehaviourFromListItem("SemiProduceRecipeEntry")
local ESlateVisibility = import("ESlateVisibility")
local BuildProduceModel = ModelManager:GetModel("BuildProduceModel")
local EquipMadeExport = import("EquipMadeExport")

local setting =
{
    Elements =
    {
        {
            Name = "UIItemSelectImg",
        },
        {
            Name = "UIItemSelectBtn",
            Handles =
            {
                OnClicked = "OnUIItemSelectBtn",
            },
        },
        {
            Name = "ItemName",
        },
    },
    Events =
    {
        ["OnSemiSelectCraftChanged"] = "OnSemiSelectCraftChanged",
    },
    Behaviours =
    {
        {
            Name = "CommonDisplayItem",
            Alias = "CommonDisplayItemBehaviour",
        },
    },
}

function SemiProduceRecipeEntry:_init(go)
    super._init(self, go, setting)
    self.Data = nil
    self.IsSelect = false
end

function SemiProduceRecipeEntry:OnDataSet(Data)
    self.Data = Data

    self.CommonDisplayItemBehaviour:SetItemTypeId(Data.ProduceItemID)
    self.ItemName:SetText(Data.ShowName)
    local CurSelectCraftID = BuildProduceModel:GetSemiSelectCraftID()
    self.IsSelect = self.Data.CraftId == CurSelectCraftID
    UIUtil.SetWidgetVisible(self.UIItemSelectImg,self.IsSelect)

    self.CommonDisplayItemBehaviour:SetShortageFlag(Data.RecipeState ~= BuildProduceModel:GetRecipeState().CanMake)
    self.CommonDisplayItemBehaviour:SetLockFlag(Data.RecipeState == BuildProduceModel:GetRecipeState().Lock)

end
function SemiProduceRecipeEntry:OnSemiSelectCraftChanged(e,r,CraftID)
    if self.Data then
        self.IsSelect = self.Data.CraftId == CraftID

        UIUtil.SetWidgetVisible(self.UIItemSelectImg,self.IsSelect)
    end
end

function SemiProduceRecipeEntry:OnUIItemSelectBtn()
    if self.Data then
        BuildProduceModel:SetSemiSelectCraftID(self.Data.CraftId)
    end
end

return SemiProduceRecipeEntry
