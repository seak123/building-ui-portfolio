// Selected implementation; native types and services are external.
#include "PzBuildInteractionSystem.h"

bool UPzBuildInteractionSystem::InteractWithPiece(FGuid BriefId)
{
	auto Brief = GetInteractionBrief(BriefId);
	if (Brief.IsValid() == false)
	{
		return false;
	}
	auto IdMap = Brief.Pin()->InteractCounterMap;
	if (IdMap.Num() == 0)
	{
		return false;
	}
	int32 FinalInteractId =  IdMap.CreateIterator()->Key;
	if (FinalInteractId == 0)
	{
		return false;
	}
	if (FKBinInteractivityTable::NeedInterruptMove(this, FinalInteractId))
	{
		UPzMainUILibrary::InterruptMove(this);
	}

	ABasePiece* Piece = UPzBuildUtil::GetPieceActor(this, Brief.Pin()->PieceGuid);

	FString NoticeMessage;
	if (IsValid(Piece))
	{
		if (CanInteractionMeetConditions(Piece, FinalInteractId, NoticeMessage) == true)
		{
			InteractionExecutor(Piece, FinalInteractId);
			return true;
		}
	}
	else
	{
		NoticeMessage = FString::Printf(TEXT("物件不存在(%s)"), *Brief.Pin()->PieceGuid.ToString());
		UE_LOG(LogTemp, Error, TEXT("交互物件不存在，GUID = %s"), *Brief.Pin()->PieceGuid.ToString())
	}
	PZ_FIRE_EVENT_LUA_TwoParams(this, "AppendNotice", EKGNoticeType::Normal, NoticeMessage)
	return false;
}

bool UPzBuildInteractionSystem::CanInteractionMeetConditions(ABasePiece* Piece, int32 InteractionId, FString& NoticeMsg)
{
	UPzBuildingManager* BuildManager = GameUtil::GetGameInstanceSubsystem<UPzBuildingManager>(this);
	if(!BuildManager)
	{
		return false;
	}

	APzPlayerState* SelfPlayerState = Cast<APzPlayerState>(GameUtil::GetSelfPlayerState(this));
	FText NoticeText;
	bool Succeed = BuildManager->CanInteractionMeetConditions(SelfPlayerState, Piece, InteractionId, NoticeText);
	NoticeMsg = NoticeText.ToString();
	return Succeed;
}

void UPzBuildInteractionSystem::SendCraftMakeReq(FGuid BuildGuid, int32 InteractId, int32 CraftID, int32 Count)
{
	if (!BuildGuid.IsValid())
	{
		return;
	}

	if (const FRES_HOMELAND_OP_CONFIG* InteractConfig = FKBinInteractivityTable::Find(this, InteractId))
	{
		switch (static_cast<tagBUILDING_OP_TYPE>(InteractConfig->iOp_type))
		{
		case tagBUILDING_OP_TYPE::BUILDING_OP_TYPE_CRAFT:
			{
				proto::PZ_OP_OBJ_REQ_DATA OpData;
				proto::PZ_OP_OBJ_CRAFT_MAKE_ITEM_DATA* IncubatorData = OpData.mutable_craft_make_item_data();
				IncubatorData->set_craft_id(CraftID);
				IncubatorData->set_repeat_num(Count);
				UE_LOG(LogTemp, Log, TEXT("UPzBuildInteractionSystem::SendCraftMakeReq: Guid:%s InteractId: %d CraftID:%d Count: %d "), *BuildGuid.ToString(), InteractId, CraftID,
				       Count);
				SendInteractRequest(FGuidToCSPbGuid(BuildGuid), InteractId, 0, OpData);
			}
			break;
		default: break;
		}
	}
}

void UPzBuildInteractionSystem::SendFetch_QueueWorkReq(FGuid BuildGuid, int32 InteractId, TArray<int32> Slots)
{
	if (!BuildGuid.IsValid())
	{
		return;
	}
	if (const FRES_HOMELAND_OP_CONFIG* InteractConfig = FKBinInteractivityTable::Find(this, InteractId))
	{
		switch (static_cast<tagBUILDING_OP_TYPE>(InteractConfig->iOp_type))
		{
		case tagBUILDING_OP_TYPE::BUILDING_OP_TYPE_GET_SEMIPRODUCE:
		case tagBUILDING_OP_TYPE::BUILDING_OP_TYPE_FETCH_PRODUCT:
			{
				proto::PZ_OP_OBJ_REQ_DATA OpData;
				proto::PZ_OP_OBJ_QUEUEWORK_FETCH* FixData = OpData.mutable_fetch_queuework();
				FString TempSlotStr = "";
				for (const auto& Slot : Slots)
				{
					FixData->add_slots(Slot);
					TempSlotStr += FString::Format(TEXT("{0} "), {Slot});
				}
				UE_LOG(LogTemp, Log, TEXT("UPzBuildInteractionSystem::SendFetch_QueueWorkReq: Guid:%s InteractId:%d Slots: %s "), *BuildGuid.ToString(), InteractId, *TempSlotStr);
				SendInteractRequest(FGuidToCSPbGuid(BuildGuid), InteractId, 0, OpData);
			}
			break;
		default:
			break;
		}
	}
}

void UPzBuildInteractionSystem::SendCancel_QueueWorkReq(FGuid BuildGuid, int32 InteractId, int32 Slot)
{
	if (!BuildGuid.IsValid())
	{
		return;
	}
	if (const FRES_HOMELAND_OP_CONFIG* InteractConfig = FKBinInteractivityTable::Find(this, InteractId))
	{
		switch (static_cast<tagBUILDING_OP_TYPE>(InteractConfig->iOp_type))
		{
		case tagBUILDING_OP_TYPE::BUILDING_OP_TYPE_CANCEL_SEMIPRODUCE:
		case tagBUILDING_OP_TYPE::BUILDING_OP_TYPE_CANCEL_CRAFT_MAKE:
			{
				proto::PZ_OP_OBJ_REQ_DATA OpData;
				proto::PZ_OP_OBJ_QUEUEWORK_CANCEL* CancelData = OpData.mutable_cancel_queuework();
				CancelData->set_slot(Slot);
				UE_LOG(LogTemp, Log, TEXT("UPzBuildInteractionSystem::SendCancel_QueueWorkReq: Guid:%s InteractId:%d Slot: %d "), *BuildGuid.ToString(), InteractId, Slot);
				SendInteractRequest(FGuidToCSPbGuid(BuildGuid), InteractId, 0, OpData);
			}
			break;
		default: break;
		}
	}
}

void UPzBuildInteractionSystem::SendInteractRequest(const proto::PZ_CS_GUID& InGuidPro, int32 InteractId, int32 OpActId, const proto::PZ_OP_OBJ_REQ_DATA& OpData)
{
	PZ_PKG_HOUSE_OBJ_OP_REQ body;

	body.mutable_obj_guid()->CopyFrom(InGuidPro);
	body.set_op_id(InteractId);
	body.set_op_action_id(OpActId);
	body.mutable_op_data()->CopyFrom(OpData);

	FPzProtoMessage ReqMsg;
	PzProtoHandler::GetSendProtoMessage(body, ReqMsg);
	UE_LOG(LogTemp, Log, TEXT("UPzBuildInteractionSystem::SendInteractRequest: Guid:%s InteractId:%d OpActId: %d "), *PbGuidToFGuid(InGuidPro).ToString(), InteractId, OpActId);
	BuildingOptionReq(ReqMsg);
}

void UPzBuildInteractionSystem::BuildingOptionReq(const FPzProtoMessage& Sync)
{
	if (APlayerController* Player = GameUtil::GetSelfPlayerController(this))
	{
		if (APzPlayerState* PlayerState = Player->GetPlayerState<APzPlayerState>())
		{
			if (PlayerState->BuildingOptionComponent)
			{
				PlayerState->BuildingOptionComponent->BuildingOptionReq(Sync);
			}
		}
	}
}
