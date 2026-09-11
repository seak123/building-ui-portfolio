-- Selected feature implementation. External runtime and widget assets are not included.
local BuildProduceModel ,super = ModelManager:CreateModel("BuildProduceModel")
local PzLogicLibrary = UE4.PzLogicLibrary
local CraftConfig = ConfigManager.GetTable("ResCarryonCraft")
local BuildingManager  = UE4.BuildingFunctionLibrary.GetBuildingManager(_G.GlobalContext)
local TimeRound = 0.5
local ProgressManager = UE4.PzGameLuaLibrary.GetCharacterProgressManager(_G.GlobalContext)
local EquipMadeExport = import("EquipMadeExport")
local HomelandTotemSubSystem = UE4.PzBuildUtil.GetHomelandTotemSubSystem(_G.GlobalContext)

local SemiProduceFramePath = "WidgetBlueprint'/Game/UI/Panel/BuildSpace/Production/WBP_SemiProduction_Frame.WBP_SemiProduction_Frame_C'"

local RecipeState =
{
	None = 0,
	Lock = 1,
	CanNotMake_Cond = 2,
	CanNotMake_Material = 3,
	CanMake = 4,
}
local CommonSemiCancelInteractID = 0 --129
local CommonSemiCreateInteractID = 0 --131
local CommonSemiGetInteractID =  0 --132

local setting =
{
    Events =
    {
        ["OpenSemiProduceFrame"] = "OnOpenSemiProduceFrame",
    },
}

function BuildProduceModel:_init()
    super._init(self, setting)

end

local SemiSelectCraftID = 0

function BuildProduceModel:OnOpenSemiProduceFrame(e,r, PieceID,PieceGuid,InteractionID)

    UIUtil.AddUniqueFrameAsync(SemiProduceFramePath, function(frame)
		if frame then
			local targetID = frame:GetUniqueID()
			local Behaviour = __BehaviourManager:GetBehaviour(targetID)
			if Behaviour then
				Behaviour:SetData(PieceID,PieceGuid,InteractionID)
			end
		end
	end)
end

function BuildProduceModel:GetQueueWorkEntityByGuid(PieceGuid)
	return BuildingManager:GetCommonQueueWorkEntityByGuid(PieceGuid)
end

function BuildProduceModel:GetQueueWorkSlotMaxCount(PieceGuid)
	local Entity = BuildingManager:GetCommonQueueWorkEntityByGuid(PieceGuid)
	if Entity then
		return FKBinBuildLvGuideTable.GetMaxQueueCount(_G.GlobalContext,Entity:PieceID(),Entity:Level())
	end
	return 1
end

function BuildProduceModel:SetSemiSelectCraftID(CraftID,Init)
	SemiSelectCraftID = CraftID
	if not Init then
		EventSystem.Fire("OnSemiSelectCraftChanged", SemiSelectCraftID)
	end
end

function BuildProduceModel:GetSemiSelectCraftID()
	return SemiSelectCraftID
end

function BuildProduceModel:GetRecipeState()
	return RecipeState
end

function BuildProduceModel:GetSmeiCreateInteractID()

	if CommonSemiCreateInteractID <= 0 then
		CommonSemiCreateInteractID = FKBinHomelandMiscValue.GetValue(_G.GlobalContext,ResMacros.E_HOMELAND_KVT_SEMIPRODUCE_COMMONINTERACTIONID_CREATE,0)
	end
	return CommonSemiCreateInteractID
end

function BuildProduceModel:GetSmeiCancelInteractID()
	if CommonSemiCancelInteractID <= 0 then
		CommonSemiCancelInteractID = FKBinHomelandMiscValue.GetValue(_G.GlobalContext,ResMacros.E_HOMELAND_KVT_SEMIPRODUCE_COMMONINTERACTIONID_CANCEL,0)
	end
	return CommonSemiCancelInteractID
end

function BuildProduceModel:GetSmeiGetInteractID()
	if CommonSemiGetInteractID <= 0 then
		CommonSemiGetInteractID = FKBinHomelandMiscValue.GetValue(_G.GlobalContext,ResMacros.E_HOMELAND_KVT_SEMIPRODUCE_COMMONINTERACTIONID_GET,0)
	end
	return CommonSemiGetInteractID
end

function BuildProduceModel:GetCraftData(PieceID,PieceGuid)
	local CraftData = {}
	local CraftIDArray = FKBinCarryMakeTable.GetAllCraftIDWithPieceID(_G.GlobalContext,PieceID)

	local WorkLoadScale = FKCraftMiscConfigTable.GetValue(_G.GlobalContext,ResMacros.E_CRAFT_MVKT_WORKLOAD_SCALE)
	if WorkLoadScale <= 0 then
		WorkLoadScale = 1
	end
	for Index = 1 , CraftIDArray:Num() do
		local CraftId = CraftIDArray:Get(Index - 1)

		local Config = CraftConfig:GetRowByKey(CraftId)
		if Config then
			if Config.CraftCondItem == PieceID then
				local ShowCond = self:GetCraftShowConditionValid(CraftId,PieceGuid)
				if ShowCond then
					local Data = {}
					Data.CraftId = CraftId
					Data.RecipeID = Config.CraftRecipeId
					Data.RecipeState = self:GetCraftProduceItemState(CraftId,PieceGuid)
					Data.ProduceItemID = FKBinCraftBasicTable.GetProductItemID(_G.GlobalContext,Config.CraftRecipeId)
					Data.SortID = Config.DisplayPriority[0]
					local RoundValue = (Config.PalWorkloadAmount.WorkloadAmount / WorkLoadScale) + TimeRound
					Data.WorkLoad = math.floor(RoundValue)
					Data.ShowName = Config.Name
					if Data.ShowName == "" then
						Data.ShowName = FKBinItemTable.GetName(_G.GlobalContext, Data.ProduceItemID)
					end
					table.insert(CraftData,Data)
				end
			end
		end
	end
	if #CraftData > 1 then
		table.sort(CraftData, function(a, b)
			if a.RecipeState == b.RecipeState then
				if a.SortID == b.SortID then
					return a.CraftId < b.CraftId
				end
				return a.SortID < b.SortID
			end
			return a.RecipeState > b.RecipeState
		end)
	end

	return CraftData
end

function BuildProduceModel:GetCraftProduceItemState(CraftId,PieceGuid,NeedCount)

	local Config = CraftConfig:GetRowByKey(CraftId)
	if not Config then
		return RecipeState.None
	end
	local IsUnLock = UE4.DimensionalDataExport.IsRecipeUnlock(_G.GlobalContext,Config.CraftRecipeId)
	if not IsUnLock then
		return RecipeState.Lock
	end
	local IsCanMake = self:GetCraftConditionValid(CraftId,PieceGuid)
	if not IsCanMake then
		return RecipeState.CanNotMake_Cond
	end
	if not NeedCount then
		NeedCount = 1
	end
	IsCanMake = self:GetCraftMaterialValid(CraftId,NeedCount)
	if not IsCanMake then
		return RecipeState.CanNotMake_Material
	end
	return RecipeState.CanMake
end

function BuildProduceModel:GetCraftMaterialValid(CraftId,MakeCount)
	local result = true
	local config = CraftConfig:GetRowByKey(CraftId)
	local bagModel = ModelManager:GetModel("BagModel")
	if config then
		local RecipeId = config.CraftRecipeId
		if RecipeId > 0 then
			result = bagModel:GetMaxCountBayCraftID(RecipeId) >= MakeCount
		end
	end
	return result
end

function BuildProduceModel:GetCraftShowConditionValid(CraftId,PieceGuid)
	local result = true
	local config = CraftConfig:GetRowByKey(CraftId)
	if config then
		local conditionCount = config.ShowCond.Length
		if conditionCount > 0 then
			for i = 0, conditionCount - 1 do
				local cData = config.ShowCond[i]
				if cData and cData.Type > 0 then
					if cData.Type == ResMacros.E_CRAFT_COND_TYPE_WORKBENCH_LEVEL then
						result = self:GetPieceLevel(PieceGuid) >= cData.Param[0]
					elseif cData.Type == ResMacros.E_CRAFT_COND_TYPE_ACTOR_LEVEL then
						result = ProgressManager:GetCurPlayerLevel() >= cData.Param[0]
					elseif cData.Type == ResMacros.E_CRAFT_COND_TYPE_MANOR_LEVEL then
						result = HomelandTotemSubSystem:C_GetSelfTotemLv(_G.GlobalContext) >= cData.Param[0]
					end
					if not result then
						return result,cData
					end
				end
			end
		end
	end
	return result,nil
end

function BuildProduceModel:GetCraftConditionValid(CraftId,PieceGuid)
	local result = true
	local config = CraftConfig:GetRowByKey(CraftId)
	if config then
		local conditionCount = config.CraftCond.Length
		if conditionCount > 0 then
			for i = 0, conditionCount - 1 do
				local cData = config.CraftCond[i]
				if cData and cData.Type > 0 then
					if cData.Type == ResMacros.E_CRAFT_COND_TYPE_WORKBENCH_LEVEL then
						result = self:GetPieceLevel(PieceGuid) >= cData.Param[0]
					elseif cData.Type == ResMacros.E_CRAFT_COND_TYPE_ACTOR_LEVEL then
						result = ProgressManager:GetCurPlayerLevel() >= cData.Param[0]
					elseif cData.Type == ResMacros.E_CRAFT_COND_TYPE_MANOR_LEVEL then
						result = HomelandTotemSubSystem:C_GetSelfTotemLv(_G.GlobalContext) >= cData.Param[0]
					end
					if not result then
						return result,cData
					end
				end
			end
		end
	end
	return result,nil
end
function BuildProduceModel:GetRecipeMaterialItemData(RecipeId,Count)
	local ItemData = {}
	local nMaterialCount = EquipMadeExport.CraftRecipe_GetMaterialCount(_G.GlobalContext, RecipeId)
	for i = 1, nMaterialCount do
		local kMaterialData = EquipMadeExport.GetSingleMaterialByRecipeID(_G.GlobalContext, RecipeId, i-1)
		ItemData[i] = {}
		ItemData[i].itemType = UE4.EPzGenItemType.Item
		ItemData[i].itemTypeId = kMaterialData.MaterialItemID
		ItemData[i].minNum = kMaterialData.MaterialNeedCount * Count
		ItemData[i].maxNum = kMaterialData.MaterialNeedCount * Count
	end
	return ItemData
end

function BuildProduceModel:GetPieceByGuid(PieceGuid)
	return BuildingManager:GetPieceByGUID(PieceGuid)
end

function BuildProduceModel:GetPieceLevel(PieceGuid)
	local Entity = self:GetPieceByGuid(PieceGuid)
	if Entity then
		return Entity:Level()
	end
	return 0
end

function BuildProduceModel:GetTimeStringBySecond(Second)
	local Data = {}
	local Hour = math.floor(Second / 3600)
	local Min = math.floor(Second % 3600 / 60)
	local Sec = Second % 60
	Data.Hour = Hour
	Data.Min = Min
	Data.Sec = Sec
	return string.format("%02d:%02d:%02d",Data.Hour,Data.Min,Data.Sec)
end

return BuildProduceModel
