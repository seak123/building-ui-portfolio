-- Selected feature implementation. External runtime and widget assets are not included.
local AdditionModel, super = ModelManager:CreateModel("AdditionModel")
local AdditionFramepath = "WidgetBlueprint'/Game/UI/Panel/Interaction/Survive/WBP_Addition_Frame.WBP_Addition_Frame_C'"
local InteractionConfig = ConfigManager.GetTable("ResHomelandOpConfig")
local BuildingManager  = UE4.BuildingFunctionLibrary.GetBuildingManager(_G.GlobalContext)
local LuaLibrary = UE4.PzGameLuaLibrary

local setting = {

}

local AdditionBehavious = nil

local InteractionColdTime = 0

local LastInteractionTime = 0

local AdditionKeys = {
	None = "None",
	Hang = "Hang",
	TroughAdd = "TroughAdd",
	SingleHook = "SingleHook",
	CreateEntityAddOre = "CreateEntityAddOre",
	CreateEntityAddFuel = "CreateEntityAddFuel",
	PutEgg = "PutEgg",
	BuildCharger = "BuildCharger",
	WeaponShelf = "WeaponShelf",
	AddBathSalt = "AddBathSalt"
}

local AdditionData = nil;

function AdditionModel:_init()
	super._init(self, setting)
	self.ActorGuid = FGuid(0,0,0,0)
	self.CurInteractionType = AdditionKeys.None
end

function AdditionModel:ShowAdditionPanel(data)
	AdditionData = data
	self.ActorGuid = data.ActorGuid
	self.CurInteractionType = data.InteractionType
	if AdditionData then
		UIUtil.AddUniqueFrameAsync(AdditionFramepath, function(frame)
			if frame then
				local targetID = frame:GetUniqueID()
				AdditionBehavious = __BehaviourManager:GetBehaviour(targetID)
				AdditionBehavious:ShowData(AdditionData)
			end
		end)
	else
	end
end

function AdditionModel:RefreshAdditionPanel(data)
	if data then
		AdditionData = data
		if AdditionBehavious then
			if AdditionData and AdditionData.interactionData and #AdditionData.interactionData > 0 then
				AdditionBehavious:RefreshList(data)
			else
				AdditionBehavious:OnHideView()
			end
		end
	end
end

function AdditionModel:GetAdditionData()
	return AdditionData
end

function AdditionModel:GetAdditionKeys()
	return AdditionKeys
end

function AdditionModel:GetInteractionByID(id)
	return InteractionConfig:GetRowByKey(id)
end

function AdditionModel:SetFrameBehaviousNil()
	AdditionBehavious = nil
end

function AdditionModel:SetInteractionColdTime(opId)
	local Time = 0;
	local Config = InteractionConfig:GetRowByKey(opId)
	if Config and Config.OpTypeParams then
		local paramData = Config.OpTypeParams
		if paramData then
			for i = 0, paramData.Length - 1 do
				if paramData[i].ParamType == ResMacros.BUILD_OBJ_OP_PARAM_TYPE_OP_TIME then
					Time = paramData[i].ParamParam
					return
				end
			end
		end
	end
	InteractionColdTime = Time
end

function AdditionModel:CacheInteractionTime()
	LastInteractionTime = GameUtil.GetUtcTimeStampSecond()
end

function AdditionModel:CheckInCold()
	local result = GameUtil.GetUtcTimeStampSecond() - LastInteractionTime >= InteractionColdTime
	if not result then
	end
	return result
end

function AdditionModel:GetInteractionName(opId, pieceId)
	local Config = InteractionConfig:GetRowByKey(opId)
	if Config then
		return UE4.PzBuildUtil.GetBuildInteractionSystem(_G.GlobalContext):GetSpecialInteractionName(opId, pieceId)
	end
end

function AdditionModel:GetInteractionIconByID(id)
	local Config = self:GetInteractionByID(id)
	if Config then
		return Config.ButtonIcon
	end
end

function AdditionModel:CheckIsCurInteractionEntity(ActorGuid,InteractionType)
	if LuaLibrary.CheckGuidIsEqual(self.ActorGuid,ActorGuid) and InteractionType == self.CurInteractionType then
		return true
	end
	return false
end

return AdditionModel
