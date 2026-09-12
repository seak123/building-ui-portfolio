// Interface outline only: selected signatures, not a compilable full class.
#pragma once

class UPzBuildInteractionSystem
{
public:
    bool InteractWithPiece(FGuid BriefId);
    bool CanInteractionMeetConditions(ABasePiece* Piece, int32 InteractionId, FString& NoticeMsg);
    void SendCraftMakeReq(FGuid BuildGuid, int32 InteractId, int32 CraftID, int32 Count);
    void SendFetch_QueueWorkReq(FGuid BuildGuid, int32 InteractId, TArray<int32> Slots);
    void SendCancel_QueueWorkReq(FGuid BuildGuid, int32 InteractId, int32 Slot);
    void SendInteractRequest(const proto::PZ_CS_GUID& InGuidPro, int32 InteractId, int32 OpActId, const proto::PZ_OP_OBJ_REQ_DATA& OpData);
    void BuildingOptionReq(const FPzProtoMessage& Sync);
    void SendPutEggReq(FGuid Guid, int32 InteractId, int32 EggID, int32 SlotIndex);
    void SendGetPalReq(FGuid Guid, int32 InteractId, int32 SlotIndex);
    // State, helper declarations, reflection and base classes are external.
};
